#!/usr/bin/env python3
"""
Generalized Log Alert Monitor
Monitors various log sources and triggers alerts based on configured patterns.
Prevents duplicate alerts by tracking processed log entries.
"""

import os
import json
import time
import socket
import requests
import subprocess
from datetime import datetime, timedelta
from typing import Dict, List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class LogAlertMonitor:
    def __init__(self):
        self.loki_url = os.getenv('LOKI_URL', 'http://loki:3100')
        self.webhook_url = os.getenv('WEBHOOK_URL', 'http://discord-webhook:8080/webhook')
        self.check_interval = int(os.getenv('CHECK_INTERVAL', '5'))  # seconds
        self.state_file = '/tmp/alert_monitor_state.json'
        self.last_check_time = None
        
        # Load previous state
        self.load_state()
        
        # Server state tracking
        self.server_states = {}  # Track online/offline state for each service
        
        # Alert configurations - easily extensible for different services
        self.alert_configs = [
            # Minecraft server health monitoring (up/down)
            {
                'name': 'minecraft_server_health',
                'service': 'minecraft',
                'check_type': 'health_check',  # Special type for health checks
                'host': 'minecraft',
                'port': 19132,
                'alert_type': 'server_health_change',
                'discord_title': '🎮 Minecraft Alert Monitor',
                'discord_message': 'Minecraft server is now {state}!',
                'color_online': 0x00ff00,  # Green for online
                'color_offline': 0xff0000,  # Red for offline
                'track_state': True
            },
            # Minecraft player join/leave monitoring
            {
                'name': 'minecraft_player_activity',
                'service': 'minecraft',
                'query': '{container_name="minecraft"} |~ "Player (connected|disconnected):"',
                'pattern': r'Player (?P<event_type>connected|disconnected): (?P<player_name>[^,]+), xuid: (?P<xuid>\d+)',
                'alert_type': 'player_activity',
                'discord_title': '🎮 Minecraft Alert Monitor',
                'discord_message': '**{player_name}** {event_type} the server',
                'color': 0x0099ff
            },
            # Copyparty user activity monitoring (with 1-hour cooldown)
            {
                'name': 'copyparty_user_activity',
                'service': 'copyparty',
                'query': '{container_name="copyparty"} |~ "GET.*@"',
                'pattern': r'GET\s+([^\s]+)\s+@(?P<username>\w+)',
                'alert_type': 'user_activity',
                'discord_title': '👤 Copyparty Alert Monitor',
                'discord_message': '**{username}** is using copyparty',
                'color': 0x00ff99,
                'track_state': True,
                'cooldown_seconds': 3600  # Only alert if user hasn't been active for 1+ hours (3600 seconds)
            }
        ]
    
    def load_state(self):
        """Load the last check time, server states, and user activity times"""
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
                    
                    # Load user activity times
                    user_activity_data = data.get('user_activity_times', {})
                    self.user_activity_times = {k: datetime.fromisoformat(v) for k, v in user_activity_data.items()}
                    if self.user_activity_times:
                        logger.info(f"Loaded user activity times: {self.user_activity_times}")
        except Exception as e:
            logger.warning(f"Could not load state file: {e}")
            self.last_check_time = None
            self.server_states = {}
            self.user_activity_times = {}
    
    def save_state(self):
        """Save the last check time, server states, and user activity times"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump({
                    'last_check_time': self.last_check_time.isoformat() if self.last_check_time else None,
                    'server_states': self.server_states,
                    'user_activity_times': {k: v.isoformat() for k, v in getattr(self, 'user_activity_times', {}).items()}
                }, f)
        except Exception as e:
            logger.warning(f"Could not save state file: {e}")
    
    def check_server_health(self, host: str, port: int, timeout: int = 5) -> bool:
        """Check if a server is responding on the given host:port"""
        try:
            # For Minecraft, use mc-monitor metrics endpoint
            if host == 'minecraft':
                try:
                    response = requests.get('http://mc-monitor:8080/metrics', timeout=timeout)
                    if response.status_code == 200:
                        # Check if minecraft_status_healthy metric exists and is 1
                        metrics_text = response.text
                        for line in metrics_text.split('\n'):
                            if line.startswith('minecraft_status_healthy') and '1' in line:
                                logger.debug(f"mc-monitor reports minecraft as healthy")
                                return True
                        logger.debug(f"mc-monitor reports minecraft as unhealthy")
                        return False
                    else:
                        logger.debug(f"mc-monitor returned status {response.status_code}")
                        return False
                except Exception as e:
                    logger.debug(f"Failed to check mc-monitor: {e}")
                    return False
            else:
                # For other hosts, use TCP connection
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(timeout)
                result = sock.connect_ex((host, port))
                sock.close()
                return result == 0
                
        except Exception as e:
            logger.debug(f"Health check failed for {host}:{port}: {e}")
            return False
    
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
            
            if results:
                logger.info(f"Loki query returned {len(results)} logs")
            return results
        except Exception as e:
            logger.error(f"Error querying Loki: {e}")
            return []
    
    def send_state_alert(self, config: Dict, current_state: str, previous_state: str):
        """Send alert for server state transition"""
        try:
            # Format the Discord message with state
            discord_message = config['discord_message'].format(state=current_state)
            
            # Choose appropriate emoji and color based on state
            if current_state == 'online':
                discord_title = '🟢 Server Online'
                color = config.get('color_online', 0x00ff00)
            else:
                discord_title = '🔴 Server Offline'
                color = config.get('color_offline', 0xff0000)
            
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
    
    def process_health_check_alert(self, config: Dict):
        """Process health check alerts"""
        service = config['service']
        host = config['host']
        port = config['port']
        
        logger.info(f"Running health check for {service} at {host}:{port}")
        
        # Check if server is responding
        is_healthy = self.check_server_health(host, port)
        current_state = 'online' if is_healthy else 'offline'
        
        logger.info(f"Health check result for {service}: {current_state} (healthy: {is_healthy})")
        
        # Check if state has changed
        previous_state = self.server_states.get(service, 'offline')
        
        if current_state != previous_state:
            logger.info(f"Server health changed for {service}: {previous_state} -> {current_state}")
            
            # Send alert for state transition
            self.send_state_alert(config, current_state, previous_state)
            
            # Update state
            self.server_states[service] = current_state
        else:
            logger.info(f"Server health unchanged for {service}: {current_state}")
    
    def process_alert_config(self, config: Dict, start_time: datetime, end_time: datetime):
        """Process a single alert configuration"""
        import re
        
        # Handle health checks differently
        if config.get('check_type') == 'health_check':
            self.process_health_check_alert(config)
            return
        
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
        
        # Check if this is a user activity alert with cooldown
        if config.get('cooldown_seconds'):
            self.process_user_activity_alert(config, logs)
            return
        
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
    
    def process_user_activity_alert(self, config: Dict, logs: List[Dict]):
        """Process user activity alerts with cooldown"""
        import re
        from datetime import timedelta
        
        pattern = re.compile(config['pattern'])
        cooldown_seconds = config.get('cooldown_seconds', 3600)  # Default to 3600 seconds (1 hour)
        current_time = datetime.now()
        
        # Track user activity timestamps
        if not hasattr(self, 'user_activity_times'):
            self.user_activity_times = {}
        
        for log in logs:
            match = pattern.search(log['message'])
            if match:
                username = match.group('username')
                
                # Check if we should alert for this user
                last_activity = self.user_activity_times.get(username)
                should_alert = False
                
                if last_activity is None:
                    # First time seeing this user
                    should_alert = True
                    logger.info(f"First activity detected for user: {username}")
                else:
                    # Check if enough time has passed
                    time_since_last = current_time - last_activity
                    if time_since_last >= timedelta(seconds=cooldown_seconds):
                        should_alert = True
                        logger.info(f"User {username} active after {time_since_last}")
                    else:
                        logger.debug(f"User {username} active but within cooldown period")
                
                if should_alert:
                    # Send alert for user activity
                    self.send_user_activity_alert(config, username)
                
                # Update last activity time
                self.user_activity_times[username] = current_time
    
    def send_user_activity_alert(self, config: Dict, username: str):
        """Send alert for user activity"""
        try:
            # Format the Discord message with username
            discord_message = config['discord_message'].format(username=username)
            
            payload = {
                "alerts": [{
                    "status": "firing",
                    "labels": {
                        "service": config['service'],
                        "alert_type": config['alert_type'],
                        "username": username
                    },
                    "annotations": {
                        "discord_title": config['discord_title'],
                        "discord_message": discord_message
                    }
                }]
            }
            
            # Send to webhook service
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            
            logger.info(f"Sent user activity alert: {username} using {config['service']}")
            
        except Exception as e:
            logger.error(f"Error sending user activity alert: {e}")
    
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
            for match in matches:
                # Format the Discord message with extracted data
                # Convert event_type to past tense for better readability
                if 'event_type' in match:
                    event_type = match['event_type']
                    if event_type == 'connected':
                        match['event_type'] = 'joined'
                    elif event_type == 'disconnected':
                        match['event_type'] = 'left'
                
                discord_message = config['discord_message'].format(**match)
                
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
                
                # Send to webhook service
                response = requests.post(self.webhook_url, json=payload, timeout=10)
                response.raise_for_status()
                
                logger.info(f"Sent alert: {config['name']} - {match.get('player_name', 'Unknown')}")
    
    def run_check(self):
        """Run a single check cycle"""
        # Calculate time range for this check
        end_time = datetime.now()
        
        # Use last check time if available, otherwise go back a reasonable window
        if self.last_check_time:
            start_time = self.last_check_time
        else:
            # On first run, look back 5 minutes to catch any events that happened while down
            start_time = end_time - timedelta(minutes=5)
        
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
