"""Base alert monitor class with common functionality."""

import os
import json
import requests
import time
import base64
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging
from cryptography.fernet import Fernet


logger = logging.getLogger(__name__)


class BaseAlertMonitor:
    """Base class for all alert monitors with common functionality."""

    def __init__(
        self,
        alert_configs: List[Dict[str, Any]],
        state_file: str = "/tmp/alert_monitor_state.json",
    ):
        """Initialize the base alert monitor.

        Args:
            alert_configs: List of alert configurations for this monitor
            state_file: Path to state file for persistence
        """
        self.loki_url = os.getenv("LOKI_URL", "http://loki:3100")
        self.webhook_url = os.getenv(
            "WEBHOOK_URL", "http://discord-webhook:8080/webhook"
        )
        self.check_interval = int(os.getenv("CHECK_INTERVAL", "30"))  # seconds
        self.state_file = state_file
        self.last_check_time = None

        # Load previous state
        self.load_state()

        # Server state tracking
        self.server_states = {}  # Track online/offline state for each service

        # IP monitoring state
        self.known_ips = {}  # Track known IPs with timestamp and country: {ip: {"last_seen": datetime, "country": str}}
        self.suspicious_ips = set()  # Track IPs that have triggered alerts
        self.ip_alert_cooldown = {}  # Track cooldown periods for IP alerts

        # Alert configurations
        self.alert_configs = alert_configs

    def load_state(self):
        """Load previous state from file."""
        try:
            if os.path.exists(self.state_file):
                with open(self.state_file, "r") as f:
                    state = json.load(f)
                    self.last_check_time = datetime.fromisoformat(
                        state.get("last_check_time", "1970-01-01T00:00:00")
                    )
                    self.server_states = state.get("server_states", {})
                    # Convert known_ips back to proper structure
                    known_ips_data = state.get("known_ips", {})
                    self.known_ips = {}
                    for ip_key, ip_data in known_ips_data.items():
                        logger.debug(f"Loading IP {ip_key}: {type(ip_data)} = {ip_data}")
                        if isinstance(ip_data, dict):
                            # New format: {ip: {"last_seen": datetime, "country": str}}
                            self.known_ips[ip_key] = {
                                "last_seen": datetime.fromisoformat(ip_data["last_seen"]) if isinstance(ip_data["last_seen"], str) else ip_data["last_seen"],
                                "country": ip_data.get("country", "Unknown")
                            }
                        else:
                            # Legacy format: {ip: datetime} - convert to new format
                            last_seen = datetime.fromisoformat(ip_data) if isinstance(ip_data, str) else ip_data
                            self.known_ips[ip_key] = {
                                "last_seen": last_seen,
                                "country": "Unknown"
                            }
                    self.suspicious_ips = set(state.get("suspicious_ips", []))
                    self.ip_alert_cooldown = {
                        k: datetime.fromisoformat(v)
                        for k, v in state.get("ip_alert_cooldown", {}).items()
                    }
                    # Load IP location cache if it exists (legacy support)
                    if hasattr(self, 'ip_location_cache'):
                        self.ip_location_cache = state.get("ip_location_cache", {})
                    logger.info(f"Loaded state from {self.state_file}")
        except Exception as e:
            logger.warning(f"Could not load state file: {e}")
            self.last_check_time = None

    def save_state(self):
        """Save current state to file."""
        try:
            state = {
                "last_check_time": self.last_check_time.isoformat()
                if self.last_check_time
                else None,
                "server_states": self.server_states,
                "known_ips": {
                    k: {
                        "last_seen": v["last_seen"].isoformat() if isinstance(v["last_seen"], datetime) else v["last_seen"],
                        "country": v["country"]
                    }
                    for k, v in self.known_ips.items()
                },
                "suspicious_ips": list(self.suspicious_ips),
                "ip_alert_cooldown": {
                    k: v.isoformat() for k, v in self.ip_alert_cooldown.items()
                },
                "ip_location_cache": getattr(self, 'ip_location_cache', {}),
            }
            with open(self.state_file, "w") as f:
                json.dump(state, f, indent=2)
        except Exception as e:
            logger.warning(f"Could not save state file: {e}")

    def cleanup_old_ips(self, max_age_days: int = 30):
        """Remove IPs that haven't been seen for more than max_age_days."""
        logger.debug(f"Starting cleanup_old_ips with max_age_days={max_age_days}")
        current_time = datetime.now()
        cutoff_time = current_time - timedelta(days=max_age_days)
        
        ips_to_remove = []
        for ip_key, ip_data in self.known_ips.items():
            # Debug logging
            logger.debug(f"Processing IP {ip_key}: {type(ip_data)} = {ip_data}")
            if isinstance(ip_data, dict) and "last_seen" in ip_data:
                if ip_data["last_seen"] < cutoff_time:
                    ips_to_remove.append(ip_key)
            else:
                # Handle legacy format or malformed data
                logger.warning(f"Skipping malformed IP data for {ip_key}: {ip_data}")
        
        for ip_key in ips_to_remove:
            del self.known_ips[ip_key]
        
        if ips_to_remove:
            logger.info(f"Cleaned up {len(ips_to_remove)} old IPs (older than {max_age_days} days)")
        
        # Also cleanup old cooldown entries
        cooldown_to_remove = []
        for ip_key, cooldown_time in self.ip_alert_cooldown.items():
            if cooldown_time < cutoff_time:
                cooldown_to_remove.append(ip_key)
        
        for ip_key in cooldown_to_remove:
            del self.ip_alert_cooldown[ip_key]
        
        if cooldown_to_remove:
            logger.info(f"Cleaned up {len(cooldown_to_remove)} old cooldown entries")

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
            params = {"query": query, "start": start_ns, "end": end_ns, "limit": 1000}

            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()

            data = response.json()
            logs = []

            if "data" in data and "result" in data["data"]:
                for stream in data["data"]["result"]:
                    if "values" in stream:
                        for value in stream["values"]:
                            logs.append(
                                {
                                    "timestamp": value[0],
                                    "message": value[1],
                                    "labels": stream.get("stream", {}),
                                }
                            )

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
            import socket

            # Use TCP connection for standard health checks
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception as e:
            logger.error(f"Error checking server health for {host}:{port}: {e}")
            return False

    def validate_health_check_token(self, received_token: str) -> bool:
        """Validate a health check token by decrypting and checking timestamp."""
        if not hasattr(self, 'alert_monitor_secret') or not self.alert_monitor_secret:
            raise AttributeError("alert_monitor_secret must be set in the subclass to use health check token validation")
        
        try:
            # Create encryption key from secret (pad to 32 bytes)
            key = base64.urlsafe_b64encode(self.alert_monitor_secret.encode()[:32].ljust(32, b"0"))
            f = Fernet(key)

            # Decode and decrypt the token
            encrypted_data = base64.urlsafe_b64decode(received_token.encode())
            decrypted_timestamp = int(f.decrypt(encrypted_data).decode())

            # Check if timestamp is within our window (30 seconds)
            current_time = int(time.time())
            time_diff = abs(current_time - decrypted_timestamp)

            if time_diff <= 30:
                logger.debug(
                    f"Valid health check token: timestamp {decrypted_timestamp}, diff {time_diff}s"
                )
                return True
            else:
                logger.warning(
                    f"Health check token timestamp too old: {time_diff}s ago (token: {decrypted_timestamp}, current: {current_time})"
                )
                return False

        except base64.binascii.Error as e:
            logger.warning(f"Health check token invalid base64 encoding: {e}")
            return False
        except Exception as e:
            logger.warning(
                f"Health check token decryption failed - possible attack or corrupted token: {e}"
            )
            return False

    def generate_health_check_token(self) -> str:
        """Generate a health check token with current timestamp."""
        if not hasattr(self, 'alert_monitor_secret') or not self.alert_monitor_secret:
            raise AttributeError("alert_monitor_secret must be set in the subclass to use health check token generation")
        
        try:
            # Create encryption key from secret (pad to 32 bytes)
            key = base64.urlsafe_b64encode(self.alert_monitor_secret.encode()[:32].ljust(32, b"0"))
            f = Fernet(key)

            # Encrypt current timestamp
            current_timestamp = str(int(time.time()))
            encrypted_data = f.encrypt(current_timestamp.encode())
            
            # Encode as base64 for URL safety
            token = base64.urlsafe_b64encode(encrypted_data).decode()
            return token

        except Exception as e:
            logger.error(f"Failed to generate health check token: {e}")
            raise

    def run(self):
        """Main monitoring loop - to be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement the run method")
