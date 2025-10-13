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
        self.check_interval = int(os.getenv('CHECK_INTERVAL', '30'))  # seconds
        self.state_file = '/tmp/alert_monitor_state.json'
        self.last_check_time = None
        
        # Load previous state
        self.load_state()
        
        # Server state tracking
        self.server_states = {}  # Track online/offline state for each service
        
        # IP monitoring state
        self.known_ips = {}  # Track known IPs and their last seen time
        self.suspicious_ips = set()  # Track IPs that have triggered alerts
        self.ip_alert_cooldown = {}  # Track cooldown periods for IP alerts
        
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
            # Copyparty user activity monitoring (simplified)
            {
                'name': 'copyparty_user_activity',
                'service': 'copyparty',
                'query': '{container_name="copyparty"} |~ "GET.*@"',
                'pattern': r'GET\s+[^\s]+\s+@(?P<username>\w+)',
                'alert_type': 'user_activity',
                'discord_title': '',
                'discord_message': '👤 **{username}** is using copyparty',
                'color': 0x00ff99,
                'track_state': True,
                'cooldown_seconds': 3600  # Only alert if user hasn't been active for 1+ hours (3600 seconds)
            },
            # Nginx Cloudflare - New IP detection
            {
                'name': 'nginx_cloudflare_new_ip',
                'service': 'nginx-cloudflared',
                'query': '{container_name="nginx-cloudflared"} |~ "GET|POST|PUT|DELETE"',
                'pattern': r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" cf_ip="(?P<cf_connecting_ip>[^"]*)" cf_country="(?P<cf_country>[^"]*)" cf_ray="(?P<cf_ray>[^"]*)"',
                'alert_type': 'new_ip_access',
                'discord_title': '',
                'discord_message': '🌍 **New IP Access via Cloudflare**\n\n**📍 Location:** {cf_country}\n**🔗 IP Address:** `{cf_connecting_ip}`\n**🕐 Time:** {time_local}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🎯 Request Details:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status}\n• **Size:** {body_bytes_sent} bytes\n\n**🔗 Referrer:** {http_referer}\n**☁️ Cloudflare Ray ID:** `{cf_ray}`\n**🌐 Protocol:** {protocol}',
                'color': 0xff9900,
                'track_state': True,
                'cooldown_seconds': 3600,  # 1 hour cooldown for same IP
                'ip_field': 'cf_connecting_ip'
            },
            # Nginx Tailscale - New IP detection
            {
                'name': 'nginx_tailscale_new_ip',
                'service': 'nginx-tailscale',
                'query': '{container_name="nginx-tailscale"} |~ "GET|POST|PUT|DELETE"',
                'pattern': r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"',
                'alert_type': 'new_ip_access',
                'discord_title': '',
                'discord_message': '🔒 **New IP Access via Tailscale**\n\n**🔗 IP Address:** `{remote_addr}`\n**🕐 Time:** {time_local}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🎯 Request Details:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status}\n• **Size:** {body_bytes_sent} bytes\n\n**🔗 Referrer:** {http_referer}\n**🌐 Protocol:** {protocol}',
                'color': 0x0099ff,
                'track_state': True,
                'cooldown_seconds': 3600,  # 1 hour cooldown for same IP
                'ip_field': 'remote_addr'
            },
            # Suspicious activity detection (multiple failed requests)
            {
                'name': 'nginx_suspicious_activity',
                'service': 'nginx-suspicious',
                'query': '{container_name=~"nginx-.*"} |~ "4[0-9][0-9]|5[0-9][0-9]"',
                'pattern': r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"',
                'alert_type': 'suspicious_activity',
                'discord_title': '',
                'discord_message': '⚠️ **Suspicious Activity Detected**\n\n**🚨 IP Address:** `{remote_addr}`\n**🕐 Time:** {time_local}\n**🌐 Source:** {container_name}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🎯 Failed Request:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status} ❌\n• **Size:** {body_bytes_sent} bytes\n\n**🔗 Referrer:** {http_referer}\n**🌐 Protocol:** {protocol}\n\n**⚠️ Multiple failed requests detected from this IP!**',
                'color': 0xff0000,
                'track_state': False,
                'cooldown_seconds': 1800,  # 30 minutes cooldown
                'ip_field': 'remote_addr',
                'threshold': 5  # Alert if 5+ failed requests in time window
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
                    
                    # Load IP tracking data
                    self.known_ips = data.get('known_ips', {})
                    self.suspicious_ips = set(data.get('suspicious_ips', []))
                    ip_cooldown_data = data.get('ip_alert_cooldown', {})
                    self.ip_alert_cooldown = {k: datetime.fromisoformat(v) for k, v in ip_cooldown_data.items()}
                    if self.known_ips:
                        logger.info(f"Loaded {len(self.known_ips)} known IPs")
        except Exception as e:
            logger.warning(f"Could not load state file: {e}")
            self.last_check_time = None
            self.server_states = {}
            self.user_activity_times = {}
            self.known_ips = {}
            self.suspicious_ips = set()
            self.ip_alert_cooldown = {}
    
    def save_state(self):
        """Save the last check time, server states, and user activity times"""
        try:
            with open(self.state_file, 'w') as f:
                json.dump({
                    'last_check_time': self.last_check_time.isoformat() if self.last_check_time else None,
                    'server_states': self.server_states,
                    'user_activity_times': {k: v.isoformat() for k, v in getattr(self, 'user_activity_times', {}).items()},
                    'known_ips': self.known_ips,
                    'suspicious_ips': list(self.suspicious_ips),
                    'ip_alert_cooldown': {k: v.isoformat() for k, v in self.ip_alert_cooldown.items()}
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
        
        # Handle different types of alerts
        if config.get('check_type') == 'health_check':
            # Already handled above
            pass
        elif config.get('alert_type') == 'new_ip_access':
            self.process_ip_access_alert(config, logs)
        elif config.get('alert_type') == 'suspicious_activity':
            self.process_suspicious_activity_alert(config, logs)
        elif config.get('track_state', False):
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
    
    def process_ip_access_alert(self, config: Dict, logs: List[Dict]):
        """Process IP access alerts to detect new IPs"""
        import re
        from datetime import timedelta
        
        pattern = re.compile(config['pattern'])
        ip_field = config.get('ip_field', 'remote_addr')
        cooldown_seconds = config.get('cooldown_seconds', 3600)
        current_time = datetime.now()
        
        for log in logs:
            match = pattern.search(log['message'])
            if match:
                match_data = match.groupdict()
                ip_address = match_data.get(ip_field)
                
                if not ip_address or ip_address == '-':
                    continue
                
                # Check if this is a new IP or if cooldown has expired
                should_alert = False
                ip_key = f"{config['service']}:{ip_address}"
                
                if ip_key not in self.known_ips:
                    # First time seeing this IP
                    should_alert = True
                    logger.info(f"New IP detected: {ip_address} accessing {config['service']}")
                else:
                    # Check if enough time has passed since last alert
                    last_seen = self.known_ips[ip_key]
                    time_since_last = current_time - last_seen
                    if time_since_last >= timedelta(seconds=cooldown_seconds):
                        should_alert = True
                        logger.info(f"IP {ip_address} accessing {config['service']} after {time_since_last}")
                    else:
                        logger.debug(f"IP {ip_address} accessing {config['service']} but within cooldown period")
                
                if should_alert:
                    # Send alert for new IP access
                    self.send_ip_access_alert(config, match_data)
                
                # Update last seen time
                self.known_ips[ip_key] = current_time
    
    def process_suspicious_activity_alert(self, config: Dict, logs: List[Dict]):
        """Process suspicious activity alerts (multiple failed requests)"""
        import re
        from collections import defaultdict
        
        pattern = re.compile(config['pattern'])
        ip_field = config.get('ip_field', 'remote_addr')
        threshold = config.get('threshold', 5)
        cooldown_seconds = config.get('cooldown_seconds', 1800)
        current_time = datetime.now()
        
        # Count failed requests by IP and store the last failed request details
        ip_failed_requests = defaultdict(int)
        ip_last_failed_request = {}
        
        for log in logs:
            match = pattern.search(log['message'])
            if match:
                match_data = match.groupdict()
                ip_address = match_data.get(ip_field)
                status = match_data.get('status', '200')
                
                if not ip_address or ip_address == '-' or not status.startswith(('4', '5')):
                    continue
                
                # Extract container name from log labels
                container_name = log.get('labels', {}).get('container_name', 'nginx-unknown')
                match_data['container_name'] = container_name
                
                ip_failed_requests[ip_address] += 1
                ip_last_failed_request[ip_address] = match_data
        
        # Check for IPs exceeding threshold
        for ip_address, count in ip_failed_requests.items():
            if count >= threshold:
                ip_key = f"{config['service']}:{ip_address}"
                
                # Check cooldown
                should_alert = True
                if ip_key in self.ip_alert_cooldown:
                    time_since_last = current_time - self.ip_alert_cooldown[ip_key]
                    if time_since_last < timedelta(seconds=cooldown_seconds):
                        should_alert = False
                
                if should_alert:
                    logger.warning(f"Suspicious activity detected: {ip_address} made {count} failed requests")
                    self.send_suspicious_activity_alert(config, ip_address, count, ip_last_failed_request[ip_address])
                    self.ip_alert_cooldown[ip_key] = current_time
    
    def send_ip_access_alert(self, config: Dict, match_data: Dict):
        """Send alert for new IP access"""
        try:
            # Format the Discord message with extracted data
            discord_message = config['discord_message'].format(**match_data)
            
            payload = {
                "alerts": [{
                    "status": "firing",
                    "labels": {
                        "service": config['service'],
                        "alert_type": config['alert_type'],
                        **match_data
                    },
                    "annotations": {
                        "discord_title": config['discord_title'],
                        "discord_message": discord_message
                    }
                }]
            }
            
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            
            logger.info(f"Sent IP access alert: {config['service']} - {match_data.get('remote_addr', 'Unknown')}")
            
        except Exception as e:
            logger.error(f"Error sending IP access alert: {e}")
    
    def send_suspicious_activity_alert(self, config: Dict, ip_address: str, count: int, last_request_data: Dict):
        """Send alert for suspicious activity"""
        try:
            # Use the detailed message template from config with actual log data
            discord_message = config['discord_message'].format(
                remote_addr=ip_address,
                time_local=last_request_data.get('time_local', 'Recent'),
                remote_user=last_request_data.get('remote_user', '-'),
                container_name=last_request_data.get('container_name', 'nginx-unknown'),
                method=last_request_data.get('method', 'Multiple'),
                request_uri=last_request_data.get('request_uri', 'Various paths'),
                status=last_request_data.get('status', '4xx/5xx'),
                body_bytes_sent=last_request_data.get('body_bytes_sent', '0'),
                http_referer=last_request_data.get('http_referer', '-'),
                http_user_agent=last_request_data.get('http_user_agent', 'Unknown'),
                protocol=last_request_data.get('protocol', 'HTTP/1.1')
            )
            
            payload = {
                "alerts": [{
                    "status": "firing",
                    "labels": {
                        "service": config['service'],
                        "alert_type": config['alert_type'],
                        "ip_address": ip_address,
                        "failed_requests": str(count)
                    },
                    "annotations": {
                        "discord_title": config['discord_title'],
                        "discord_message": discord_message
                    }
                }]
            }
            
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            
            logger.info(f"Sent suspicious activity alert: {ip_address} - {count} failed requests")
            
        except Exception as e:
            logger.error(f"Error sending suspicious activity alert: {e}")
    
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
