#!/usr/bin/env python3
"""
Webhook Multiplexer Service
Receives alerts and routes them to appropriate Discord webhooks based on service type
"""

import os
import json
import requests
import logging
from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Discord webhook URLs from environment
DISCORD_WEBHOOKS = {
    'minecraft': os.getenv('DISCORD_JORDANIA_WEBHOOK_URL'),
    'copyparty': os.getenv('DISCORD_COPYPARTY_WEBHOOK_URL')
}

def send_discord_message(service, title, message, color=0x00ff00):
    """Send a formatted message to the appropriate Discord webhook"""
    webhook_url = DISCORD_WEBHOOKS.get(service)
    
    if not webhook_url:
        logger.error(f"No Discord webhook URL configured for service: {service}")
        return False
    
    embed = {
        "title": title,
        "description": message,
        "color": color,
        "timestamp": datetime.utcnow().isoformat(),
        "footer": {
            "text": f"{service.title()} Alert Monitor"
        }
    }
    
    payload = {
        "embeds": [embed]
    }
    
    try:
        logger.info(f"Sending Discord payload to {service}: {json.dumps(payload, indent=2)}")
        response = requests.post(webhook_url, json=payload, timeout=10)
        response.raise_for_status()
        logger.info(f"Discord message sent to {service}: {title}")
        return True
    except Exception as e:
        logger.error(f"Failed to send Discord message to {service}: {e}")
        return False

@app.route('/webhook', methods=['POST'])
def webhook():
    """Handle incoming webhook from alert-monitor"""
    try:
        data = request.get_json()
        logger.info(f"Received webhook: {json.dumps(data, indent=2)}")
        
        # Extract alert information
        alerts = data.get('alerts', [])
        
        for alert in alerts:
            labels = alert.get('labels', {})
            annotations = alert.get('annotations', {})
            status = alert.get('status', 'unknown')
            
            # Only process firing alerts
            if status != 'firing':
                continue
            
            # Extract information
            service = labels.get('service', 'unknown')
            alert_type = labels.get('alert_type', 'unknown')
            player_name = labels.get('player_name', 'Unknown Player')
            xuid = labels.get('xuid', 'Unknown XUID')
            event_type = labels.get('event_type', 'unknown')
            current_state = labels.get('current_state', 'unknown')
            username = labels.get('username', 'Unknown User')
            
            # Get Discord message from annotations
            discord_title = annotations.get('discord_title', f'{service.title()} Alert')
            base_message = annotations.get('discord_message', f'A {service} event occurred')
            
            # Handle different alert types based on service
            if service == 'minecraft':
                if alert_type == 'server_health_change':
                    # Server health alerts - use state-based colors
                    discord_message = base_message
                    color = 0x00ff00 if current_state == 'online' else 0xff0000
                elif alert_type == 'player_activity':
                    # Player activity alerts - add XUID and use event-based colors
                    discord_message = f"{base_message}\n**XUID:** `{xuid}`"
                    color = 0x00ff00 if event_type == 'joined' else 0xff6b6b
                else:
                    # Default for other minecraft alert types
                    discord_message = base_message
                    color = 0x0099ff
                    
            elif service == 'copyparty':
                if alert_type == 'user_activity':
                    # User activity alerts
                    discord_message = f"**{username}** is using copyparty"
                    color = 0x00ff99
                else:
                    # Default for other copyparty alert types
                    discord_message = base_message
                    color = 0x0099ff
            else:
                # Default handling for unknown services
                discord_message = base_message
                color = 0x0099ff
            
            # Send to appropriate Discord webhook
            success = send_discord_message(service, discord_title, discord_message, color)
            
            if success:
                return jsonify({"status": "success", "message": "Alert processed"})
            else:
                return jsonify({"status": "error", "message": "Failed to send Discord message"}), 500
                
    except Exception as e:
        logger.error(f"Error processing webhook: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
    
    return jsonify({"status": "success", "message": "No alerts to process"})

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy", 
        "service": "webhook-mux",
        "configured_services": list(DISCORD_WEBHOOKS.keys())
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)