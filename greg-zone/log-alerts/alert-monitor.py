#!/usr/bin/env python3
"""
Generalized Log Alert Monitor
Monitors various log sources and triggers alerts based on configured patterns.
Prevents duplicate alerts by tracking processed log entries.
"""

import os
import json
import time
import requests
from datetime import datetime, timedelta
from typing import Dict, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class LogAlertMonitor:
    def __init__(self):
        self.loki_url = os.getenv('LOKI_URL', 'http://loki:3100')
        self.webhook_url = os.getenv('WEBHOOK_URL', 'http://minecraft-webhook:8080/webhook')
        self.check_interval = int(os.getenv('CHECK_INTERVAL', '5'))  # seconds
        self.state_file = '/tmp/alert_monitor_state.json'
        self.last_check_time = None
        
        # Load previous state
        self.load_state()
        
        # Server state tracking
        self.server_states = {}  # Track online/offline state for each service
        
        # Alert configurations - easily extensible for different services
        self.alert_configs = [
            # Minecraft server state monitoring
            {
                'name': 'minecraft_server_state',
                'service': 'minecraft',
                'query': '{container_name="minecraft"} |~ "Player (connected|disconnected):"',
                'pattern': r'(?:Player connected: (?P<player_name>\w+), xuid: (?P<xuid>\d+))|(?:Player disconnected: (?P<player_name>\w+), xuid: (?P<xuid>\d+))',
                'alert_type': 'server_state_change',
                'discord_title': '🎮 Server Status Changed',
                'discord_message': 'Minecraft server is now {state}!',
                'color': 0x00ff00,
                'track_state': True  # This alert tracks server state
            },
            # TODO: Add more alert types as needed
            # {
            #     'name': 'minecraft_server_down',
            #     'service': 'minecraft',
            #     'query': '{container_name="minecraft"} |= "Server stopped"',
            #     'pattern': r'Server stopped',
            #     'alert_type': 'server_down',
            #     'discord_title': '🚨 Server Down!',
            #     'discord_message': 'The Minecraft server has stopped!',
            #     'color': 0xff0000
            # },
            # {
            #     'name': 'copyparty_file_uploaded',
            #     'service': 'copyparty',
            #     'query': '{container_name="copyparty"} |= "file uploaded"',
            #     'pattern': r'file uploaded: (?P<filename>\S+) by (?P<user>\S+)',
            #     'alert_type': 'file_uploaded',
            #     'discord_title': '📁 File Uploaded',
            #     'discord_message': '**{filename}** uploaded by {user}',
            #     'color': 0x0099ff
            # }
        ]
    
    def load_state(self):
        """Load the last check time and server states"""
        try:
            if os.path.exists(self.state_file):
                with open(self.state_file, 'r') as f:
                    data = json.load(f)
                    last_time_str = data.get('last_check_time')
                    if last_time_str:
                        self.last_check_time = datetime.fromisoformat(last_time_str)
                        logger.info(f"Loaded last check time: {self.last_check_time}")
                    
                    # Load server states
                    self.server_states = data.get('server_states', {})
                    logger.info(f"Loaded server states: {self.server_states}")
        except Exception as e:
            logger.warning(f"Could not load state file: {e}")
            self.last_check_time = None
            self.server_states = {}
    
    def save_state(self):
        """Save the last check time and server states"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump({
                    'last_check_time': self.last_check_time.isoformat() if self.last_check_time else None,
                    'server_states': self.server_states
                }, f)
        except Exception as e:
            logger.warning(f"Could not save state file: {e}")
    
    def query_loki(self, query: str, start_time: datetime, end_time: datetime) -> List[Dict]:
        """Query Loki for log entries"""
        try:
            url = f"{self.loki_url}/loki/api/v1/query_range"
            params = {
                'query': query,
                'start': start_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
                'end': end_time.strftime('%Y-%m-%dT%H:%M:%SZ')
            }
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            results = []
            
            for result in data.get('data', {}).get('result', []):
                for value in result.get('values', []):
                    if len(value) >= 2:
                        timestamp, message = value[0], value[1]
                        results.append({
                            'timestamp': timestamp,
                            'message': message,
                            'labels': result.get('stream', {})
                        })
            
            return results
        except Exception as e:
            logger.error(f"Error querying Loki: {e}")
            return []
    
    def send_alert(self, config: Dict, matches: List[Dict]):
        """Send alert to webhook"""
        try:
            for match in matches:
                # Format the Discord message with extracted data
                discord_message = config['discord_message'].format(**match)
                
                # Add XUID if available
                if 'xuid' in match:
                    discord_message += f"\n**XUID:** `{match['xuid']}`"
                
                payload = {
                    "alerts": [{
                        "status": "firing",
                        "labels": {
                            "service": config.get('service', 'unknown'),
                            "alert_type": config['alert_type'],
                            **match  # Include all extracted fields (player_name, xuid, etc.)
                        },
                        "annotations": {
                            "discord_title": config['discord_title'],
                            "discord_message": discord_message
                        }
                    }]
                }
                
                response = requests.post(self.webhook_url, json=payload, timeout=10)
                response.raise_for_status()
                
                logger.info(f"Sent alert: {config['name']} - {match.get('player_name', 'Unknown')}")
                
        except Exception as e:
            logger.error(f"Error sending alert: {e}")
    
    def send_state_alert(self, config: Dict, current_state: str, previous_state: str):
        """Send alert for server state transition"""
        try:
            # Format the Discord message with state
            discord_message = config['discord_message'].format(state=current_state)
            
            # Choose appropriate emoji and color based on state
            if current_state == 'online':
                discord_title = '🟢 Server Online'
                color = 0x00ff00
            else:
                discord_title = '🔴 Server Offline'
                color = 0xff0000
            
            payload = {
                "alerts": [{
                    "status": "firing",
                    "labels": {
                        "service": config['service'],
                        "alert_type": config['alert_type'],
                        "current_state": current_state,
                        "previous_state": previous_state
                    },
                    "annotations": {
                        "discord_title": discord_title,
                        "discord_message": discord_message
                    }
                }]
            }
            
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            
            logger.info(f"Sent state alert: {config['service']} {previous_state} -> {current_state}")
            
        except Exception as e:
            logger.error(f"Error sending state alert: {e}")
    
    def process_alert_config(self, config: Dict, start_time: datetime, end_time: datetime):
        """Process a single alert configuration"""
        import re
        
        # Query Loki for matching logs
        logs = self.query_loki(config['query'], start_time, end_time)
        
        if not logs:
            return
        
        # Handle state-tracking alerts differently
        if config.get('track_state', False):
            self.process_state_tracking_alert(config, logs)
        else:
            # Handle regular alerts (like file uploads, etc.)
            self.process_regular_alert(config, logs)
    
    def process_state_tracking_alert(self, config: Dict, logs: List[Dict]):
        """Process alerts that track server state transitions"""
        import re
        
        service = config['service']
        pattern = re.compile(config['pattern'])
        
        # Determine current server state based on recent activity
        current_state = 'offline'  # Default to offline
        
        for log in logs:
            match = pattern.search(log['message'])
            if match:
                # If we see any player activity, server is online
                current_state = 'online'
                break
        
        # Check if state has changed
        previous_state = self.server_states.get(service, 'offline')
        
        if current_state != previous_state:
            logger.info(f"Server state changed for {service}: {previous_state} -> {current_state}")
            
            # Send alert for state transition
            self.send_state_alert(config, current_state, previous_state)
            
            # Update state
            self.server_states[service] = current_state
        else:
            logger.debug(f"Server state unchanged for {service}: {current_state}")
    
    def process_regular_alert(self, config: Dict, logs: List[Dict]):
        """Process regular alerts (non-state-tracking)"""
        import re
        
        pattern = re.compile(config['pattern'])
        matches = []
        
        for log in logs:
            match = pattern.search(log['message'])
            if match:
                match_data = match.groupdict()
                matches.append(match_data)
                logger.info(f"Found match for {config['name']}: {match_data}")
        
        # Send alerts for new matches
        if matches:
            self.send_alert(config, matches)
    
    def run_check(self):
        """Run a single check cycle"""
        # Calculate time range for this check
        end_time = datetime.now()
        
        # Use last check time if available, otherwise go back one interval
        if self.last_check_time:
            start_time = self.last_check_time
        else:
            start_time = end_time - timedelta(seconds=self.check_interval)
        
        logger.info(f"Checking logs from {start_time} to {end_time}")
        
        # Process each alert configuration
        for config in self.alert_configs:
            try:
                self.process_alert_config(config, start_time, end_time)
            except Exception as e:
                logger.error(f"Error processing alert config {config['name']}: {e}")
        
        # Update last check time and save state
        self.last_check_time = end_time
        self.save_state()
    
    def run(self):
        """Main run loop"""
        logger.info(f"Starting Log Alert Monitor (checking every {self.check_interval} seconds)")
        
        while True:
            try:
                self.run_check()
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
            
            time.sleep(self.check_interval)

if __name__ == '__main__':
    monitor = LogAlertMonitor()
    monitor.run()
