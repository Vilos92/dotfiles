"""Base alert monitor class with common functionality."""

import os
import json
import time
import socket
import requests
import subprocess
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import logging

from .utils import format_nginx_timestamp

logger = logging.getLogger(__name__)


class BaseAlertMonitor:
    """Base class for all alert monitors with common functionality."""
    
    def __init__(self, alert_configs: List[Dict[str, Any]], state_file: str = '/tmp/alert_monitor_state.json'):
        """Initialize the base alert monitor.
        
        Args:
            alert_configs: List of alert configurations for this monitor
            state_file: Path to state file for persistence
        """
        self.loki_url = os.getenv('LOKI_URL', 'http://loki:3100')
        self.webhook_url = os.getenv('WEBHOOK_URL', 'http://discord-webhook:8080/webhook')
        self.check_interval = int(os.getenv('CHECK_INTERVAL', '30'))  # seconds
        self.state_file = state_file
        self.last_check_time = None
        
        # Load previous state
        self.load_state()
        
        # Server state tracking
        self.server_states = {}  # Track online/offline state for each service
        
        # IP monitoring state
        self.known_ips = {}  # Track known IPs and their last seen time
        self.suspicious_ips = set()  # Track IPs that have triggered alerts
        self.ip_alert_cooldown = {}  # Track cooldown periods for IP alerts
        
        # Alert configurations
        self.alert_configs = alert_configs
    
    def load_state(self):
        """Load previous state from file."""
        try:
            if os.path.exists(self.state_file):
                with open(self.state_file, 'r') as f:
                    state = json.load(f)
                    self.last_check_time = datetime.fromisoformat(state.get('last_check_time', '1970-01-01T00:00:00'))
                    self.server_states = state.get('server_states', {})
                    self.known_ips = state.get('known_ips', {})
                    self.suspicious_ips = set(state.get('suspicious_ips', []))
                    self.ip_alert_cooldown = {
                        k: datetime.fromisoformat(v) 
                        for k, v in state.get('ip_alert_cooldown', {}).items()
                    }
                    logger.info(f"Loaded state from {self.state_file}")
        except Exception as e:
            logger.warning(f"Could not load state file: {e}")
            self.last_check_time = None
    
    def save_state(self):
        """Save current state to file."""
        try:
            state = {
                'last_check_time': self.last_check_time.isoformat() if self.last_check_time else None,
                'server_states': self.server_states,
                'known_ips': self.known_ips,
                'suspicious_ips': list(self.suspicious_ips),
                'ip_alert_cooldown': {
                    k: v.isoformat() 
                    for k, v in self.ip_alert_cooldown.items()
                }
            }
            with open(self.state_file, 'w') as f:
                json.dump(state, f, indent=2)
        except Exception as e:
            logger.warning(f"Could not save state file: {e}")
    
    def query_loki(self, query: str) -> List[Dict]:
        """Query Loki for logs."""
        try:
            # Calculate time range (last 5 minutes or since last check)
            end_time = datetime.now()
            if self.last_check_time:
                start_time = self.last_check_time
            else:
                start_time = end_time - timedelta(minutes=5)
            
            # Convert to nanoseconds (Loki expects nanoseconds)
            start_ns = int(start_time.timestamp() * 1_000_000_000)
            end_ns = int(end_time.timestamp() * 1_000_000_000)
            
            # Build Loki query URL
            url = f"{self.loki_url}/loki/api/v1/query_range"
            params = {
                'query': query,
                'start': start_ns,
                'end': end_ns,
                'limit': 1000
            }
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            logs = []
            
            if 'data' in data and 'result' in data['data']:
                for stream in data['data']['result']:
                    if 'values' in stream:
                        for value in stream['values']:
                            logs.append({
                                'timestamp': value[0],
                                'message': value[1],
                                'labels': stream.get('stream', {})
                            })
            
            logger.info(f"Loki query returned {len(logs)} logs")
            return logs
            
        except Exception as e:
            logger.error(f"Error querying Loki: {e}")
            return []
    
    def send_webhook(self, payload: Dict) -> None:
        """Send webhook notification."""
        try:
            response = requests.post(self.webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            logger.info("Webhook sent successfully")
        except Exception as e:
            logger.error(f"Error sending webhook: {e}")
    
    def check_server_health(self, host: str, port: int) -> bool:
        """Check if a server is responding on the given port."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception as e:
            logger.error(f"Error checking server health for {host}:{port}: {e}")
            return False
    
    def run(self):
        """Main monitoring loop - to be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement the run method")
