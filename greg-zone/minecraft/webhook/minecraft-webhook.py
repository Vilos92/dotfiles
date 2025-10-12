#!/usr/bin/env python3
"""
Minecraft Discord Webhook Service
Receives Loki alerts and sends formatted messages to Discord
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

# Discord webhook URL from environment
DISCORD_WEBHOOK_URL = os.getenv('DISCORD_JORDANIA_WEBHOOK_URL')

def send_discord_message(title, message, color=0x00ff00):
    """Send a formatted message to Discord"""
    if not DISCORD_WEBHOOK_URL:
        logger.error("DISCORD_JORDANIA_WEBHOOK_URL not set")
        return False
    
    embed = {
        "title": title,
        "description": message,
        "color": color,
        "timestamp": datetime.utcnow().isoformat(),
        "footer": {
            "text": "Minecraft Server Monitor"
        }
    }
    
    payload = {
        "embeds": [embed]
    }
    
    try:
        logger.info(f"Sending Discord payload: {json.dumps(payload, indent=2)}")
        response = requests.post(DISCORD_WEBHOOK_URL, json=payload, timeout=10)
        response.raise_for_status()
        logger.info(f"Discord message sent: {title}")
        return True
    except Exception as e:
        logger.error(f"Failed to send Discord message: {e}")
        return False

@app.route('/webhook', methods=['POST'])
def webhook():
    """Handle incoming webhook from Loki"""
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
            
            # Extract player information
            player_name = labels.get('player_name', 'Unknown Player')
            xuid = labels.get('xuid', 'Unknown XUID')
            event_type = labels.get('event_type', 'unknown')
            
            # Get Discord message from annotations and add XUID
            discord_title = annotations.get('discord_title', 'Minecraft Alert')
            base_message = annotations.get('discord_message', 'A Minecraft event occurred')
            # Replace any hardcoded player name with the actual player name from labels
            base_message = base_message.replace('**vilos5099**', f"**{player_name}**")
            # Format the message with XUID
            discord_message = f"{base_message}\n**XUID:** `{xuid}`"
            
            # Set color based on event type
            color = 0x00ff00 if event_type == 'joined' else 0xff6b6b
            
            # Send to Discord with XUID in the message
            success = send_discord_message(discord_title, discord_message, color)
            
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
    return jsonify({"status": "healthy", "service": "minecraft-webhook"})

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
