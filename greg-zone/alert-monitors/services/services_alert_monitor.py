#!/usr/bin/env python3
"""
Services Alert Monitor
Monitors nginx, copyparty, freshrss, kiwix, and transmission services.
Handles suspicious activity detection, user activity monitoring, and health checks.
"""

import os
import re
import time
import base64
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict
import logging
from cryptography.fernet import Fernet

from shared.base_alert_monitor import BaseAlertMonitor
from shared.utils import format_nginx_timestamp

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class ServicesAlertMonitor(BaseAlertMonitor):
    """Alert monitor for services: nginx, copyparty, freshrss, kiwix, transmission."""

    def __init__(self):
        """Initialize the services alert monitor with service-specific configurations."""
        alert_configs = [
            # Copyparty user activity monitoring
            {
                "name": "copyparty_user_activity",
                "service": "copyparty",
                "query": '{container_name="copyparty"} |~ "GET.*@"',
                "pattern": r"GET\s+[^\s]+\s+@(?P<username>\w+)",
                "alert_type": "user_activity",
                "discord_title": "",
                "discord_message": "👤 **{username}** is using copyparty",
                "color": 0x00FF99,
                "track_state": True,
                "cooldown_seconds": 3600,  # Only alert if user hasn't been active for 1+ hours
            },
            # Nginx Cloudflare - New IP detection
            {
                "name": "nginx_cloudflare_new_ip",
                "service": "nginx-cloudflared",
                "query": '{container_name="nginx-cloudflared"} |~ "GET|POST|PUT|DELETE"',
                "pattern": r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" host="(?P<host>[^"]*)" cf_ip="(?P<cf_connecting_ip>[^"]*)" cf_country="(?P<cf_country>[^"]*)" cf_ray="(?P<cf_ray>[^"]*)" real_ip="(?P<real_ip>[^"]*)" forwarded_for="(?P<forwarded_for>[^"]*)"',
                "alert_type": "new_ip_access",
                "discord_title": "",
                "discord_message": "🌍 **New IP Access**\n\n**📍 Service:** {service_name}\n**🔗 IP Address:** `{client_ip}`\n**📍 Location:** {location}\n**🕐 Time:** {formatted_time}\n\n**🎯 Request Details:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status}\n• **Size:** {body_bytes_sent} bytes\n• **Protocol:** {protocol}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🔗 Referrer:** {http_referer}\n**☁️ Cloudflare Ray ID:** {cf_ray}",
                "color": 0xFF9900,
                "track_state": True,
                "cooldown_seconds": 3600,  # 1 hour cooldown for same IP
                "ip_field": "client_ip",
            },
            # Nginx Tailscale - New IP detection
            {
                "name": "nginx_tailscale_new_ip",
                "service": "nginx-tailscale",
                "query": '{container_name="nginx-tailscale"} |~ "GET|POST|PUT|DELETE"',
                "pattern": r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" host="(?P<host>[^"]*)"',
                "alert_type": "new_ip_access",
                "discord_title": "",
                "discord_message": "🔒 **New IP Access via Tailscale**\n\n**📍 Service:** {service_name}\n**🔗 IP Address:** `{remote_addr}`\n**🕐 Time:** {formatted_time}\n\n**🎯 Request Details:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status}\n• **Size:** {body_bytes_sent} bytes\n• **Protocol:** {protocol}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🔗 Referrer:** {http_referer}",
                "color": 0x0099FF,
                "track_state": True,
                "cooldown_seconds": 86400,  # 24 hour cooldown for same IP
                "ip_field": "remote_addr",
            },
            # Suspicious activity detection (multiple failed requests)
            {
                "name": "nginx_suspicious_activity",
                "service": "nginx-suspicious",
                "query": '{container_name=~"nginx-.*"} |~ "4[0-9][0-9]|5[0-9][0-9]"',
                "pattern": r'^(?P<remote_addr>\S+) - (?P<remote_user>\S+) \[(?P<time_local>[^\]]+)\] "(?P<method>\S+) (?P<request_uri>\S+) (?P<protocol>\S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)" host="[^"]*" cf_ip="[^"]*" cf_country="[^"]*" cf_ray="[^"]*" real_ip="[^"]*" forwarded_for="[^"]*" health_check="(?P<health_check>[^"]*)"',
                "alert_type": "suspicious_activity",
                "discord_title": "",
                "discord_message": "⚠️ **Suspicious Activity Detected**\n\n**🚨 IP Address:** `{remote_addr}`\n**🕐 Time:** {formatted_time}\n**🌐 Source:** {container_name}\n\n**🎯 Failed Request:**\n• **Method:** {method}\n• **Path:** `{request_uri}`\n• **Status:** {status} ❌\n• **Size:** {body_bytes_sent} bytes\n• **Protocol:** {protocol}\n\n**💻 Device Info:**\n```{http_user_agent}```\n\n**🔗 Referrer:** {http_referer}\n\n**🔐 Health Check Status:** {health_check_status}\n\n**⚠️ Multiple failed requests detected from this IP!**",
                "color": 0xFF0000,
                "track_state": False,
                "cooldown_seconds": 1800,  # 30 minutes cooldown
                "ip_field": "remote_addr",
                "threshold": 5,  # Alert if 5+ failed requests in time window
            },
        ]

        super().__init__(alert_configs, "/tmp/services_alert_monitor_state.json")

    def validate_health_check_token(self, received_token: str) -> bool:
        """Validate a health check token by decrypting and checking timestamp."""
        try:
            # Get secret from environment
            secret = os.getenv("ALERT_MONITOR_SECRET", "default-secret-change-me")

            # Create encryption key from secret (pad to 32 bytes)
            key = base64.urlsafe_b64encode(secret.encode()[:32].ljust(32, b"0"))
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

    def is_legitimate_health_check_request(
        self, log_message: str, parsed_data: Dict = None
    ) -> bool:
        """Check if a log entry represents a legitimate health check request."""
        # If we have parsed data, use the health_check field directly
        if parsed_data and "health_check" in parsed_data:
            health_check_value = parsed_data["health_check"]
            if health_check_value and health_check_value != "-":
                # Extract token from health_check field (format: "alert-monitor-<token>")
                if health_check_value.startswith("alert-monitor-"):
                    token = health_check_value[14:]  # Remove "alert-monitor-" prefix
                    is_valid = self.validate_health_check_token(token)
                    if is_valid:
                        logger.debug(
                            "Legitimate health check request validated successfully"
                        )
                    else:
                        logger.warning(
                            "Health check request with invalid token - possible attack attempt"
                        )
                    return is_valid
                else:
                    logger.warning(
                        f"Health check header found but unexpected format: {health_check_value}"
                    )
                    return False
            return False

        # Fallback to old method for backward compatibility
        if "X-Health-Check: alert-monitor-" in log_message:
            # Extract the token from the log message
            import re

            match = re.search(
                r"X-Health-Check: alert-monitor-([A-Za-z0-9+/=]+)", log_message
            )
            if match:
                token = match.group(1)
                # Validate the token
                is_valid = self.validate_health_check_token(token)
                if is_valid:
                    logger.debug(
                        "Legitimate health check request validated successfully"
                    )
                else:
                    logger.warning(
                        "Health check request with invalid token - possible attack attempt"
                    )
                return is_valid
            else:
                logger.warning(
                    "Health check header found but token extraction failed - malformed request"
                )
                return False
        return False

    def analyze_health_check_status(self, health_check_value: str) -> str:
        """Analyze health check header value and return descriptive status."""
        if not health_check_value or health_check_value == "-":
            return "❌ **No health check header** - Regular malicious request"

        if health_check_value.startswith("alert-monitor-"):
            token = health_check_value[14:]  # Remove "alert-monitor-" prefix
            try:
                # Try to validate the token
                is_valid = self.validate_health_check_token(token)
                if is_valid:
                    return "✅ **Valid health check token** - Legitimate request (should be filtered)"
                else:
                    return f"🚨 **INVALID health check token** - Possible attack attempt with fake token: `{token[:20]}...`"
            except Exception:
                return f"🚨 **MALFORMED health check token** - Attack attempt with corrupted token: `{token[:20]}...`"
        else:
            return f"🚨 **UNEXPECTED health check format** - Possible attack attempt: `{health_check_value[:30]}...`"

    def run(self):
        """Main monitoring loop for services."""
        logger.info("Starting Services Alert Monitor")

        while True:
            try:
                current_time = datetime.now()
                logger.info(
                    f"Checking logs from {self.last_check_time} to {current_time}"
                )

                # Process each alert configuration
                for config in self.alert_configs:
                    if config.get("check_type") == "url_health_check":
                        self.process_url_health_check(config)
                    else:
                        # Query Loki for logs
                        logs = self.query_loki(config["query"])
                        if logs:
                            if config["alert_type"] == "suspicious_activity":
                                self.process_suspicious_activity_alert(config, logs)
                            elif config["alert_type"] == "new_ip_access":
                                self.process_new_ip_alert(config, logs)
                            elif config["alert_type"] == "user_activity":
                                self.process_user_activity_alert(config, logs)

                # Update last check time and save state
                self.last_check_time = current_time
                self.save_state()

                # Wait for next check
                time.sleep(self.check_interval)

            except KeyboardInterrupt:
                logger.info("Services Alert Monitor stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in Services Alert Monitor: {e}")
                time.sleep(self.check_interval)

    def process_url_health_check(self, config: Dict[str, Any]):
        """Process URL health checks for services."""
        urls = config.get("urls", [])
        if not urls:
            return

        # Check all URLs
        all_healthy = True
        for url in urls:
            if not self.check_url_health(url):
                all_healthy = False
                break

        # Determine current state
        current_state = "online" if all_healthy else "offline"
        state_key = config.get("state_key", config["name"])

        # Check if state changed
        if state_key in self.server_states:
            previous_state = self.server_states[state_key]
            if previous_state == current_state:
                logger.info(
                    f"Service health unchanged for {state_key}: {current_state}"
                )
                return

        # State changed - send alert
        logger.info(
            f"Service health changed for {state_key}: {previous_state} -> {current_state}"
        )

        # Send alert
        self.send_service_health_alert(config, current_state)

        # Update state
        self.server_states[state_key] = current_state

    def process_suspicious_activity_alert(
        self, config: Dict[str, Any], logs: List[Dict]
    ):
        """Process suspicious activity alerts (multiple failed requests)."""
        pattern = re.compile(config["pattern"])
        ip_field = config.get("ip_field", "remote_addr")
        threshold = config.get("threshold", 5)
        cooldown_seconds = config.get("cooldown_seconds", 1800)
        current_time = datetime.now()

        # Count failed requests by IP and store the last failed request details
        ip_failed_requests = defaultdict(int)
        ip_last_failed_request = {}

        for log in logs:
            match = pattern.search(log["message"])
            if match:
                match_data = match.groupdict()
                ip_address = match_data.get(ip_field)
                status = match_data.get("status", "200")

                if (
                    not ip_address
                    or ip_address == "-"
                    or not status.startswith(("4", "5"))
                ):
                    continue

                # Skip legitimate health check requests
                if self.is_legitimate_health_check_request(log["message"], match_data):
                    logger.debug(
                        f"Skipping legitimate health check request from {ip_address}"
                    )
                    continue

                # Log malicious requests with bad health check headers
                health_check_value = match_data.get("health_check", "-")
                if health_check_value and health_check_value != "-":
                    if health_check_value.startswith("alert-monitor-"):
                        logger.warning(
                            f"🚨 MALICIOUS REQUEST with fake health check token from {ip_address}: {health_check_value[:30]}..."
                        )
                    else:
                        logger.warning(
                            f"🚨 MALICIOUS REQUEST with unexpected health check format from {ip_address}: {health_check_value[:30]}..."
                        )
                else:
                    logger.info(
                        f"🚨 MALICIOUS REQUEST with no health check header from {ip_address}"
                    )

                # Extract container name from log labels
                container_name = log.get("labels", {}).get(
                    "container_name", "nginx-unknown"
                )
                match_data["container_name"] = container_name

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
                    logger.warning(
                        f"Suspicious activity detected: {ip_address} made {count} failed requests"
                    )
                    self.send_suspicious_activity_alert(
                        config, ip_address, count, ip_last_failed_request[ip_address]
                    )
                    self.ip_alert_cooldown[ip_key] = current_time

    def process_new_ip_alert(self, config: Dict[str, Any], logs: List[Dict]):
        """Process new IP access alerts."""
        pattern = re.compile(config["pattern"])
        ip_field = config.get("ip_field", "remote_addr")
        cooldown_seconds = config.get("cooldown_seconds", 3600)
        current_time = datetime.now()

        for log in logs:
            match = pattern.search(log["message"])
            if match:
                match_data = match.groupdict()
                ip_address = match_data.get(ip_field)

                if not ip_address or ip_address == "-":
                    continue

                # Check if this is a new IP
                ip_key = f"{config['service']}:{ip_address}"
                if ip_key not in self.known_ips:
                    # New IP - check cooldown
                    should_alert = True
                    if ip_key in self.ip_alert_cooldown:
                        time_since_last = current_time - self.ip_alert_cooldown[ip_key]
                        if time_since_last < timedelta(seconds=cooldown_seconds):
                            should_alert = False

                    if should_alert:
                        logger.info(
                            f"New IP detected: {ip_address} accessing {config['service']}"
                        )
                        self.send_ip_access_alert(config, match_data, ip_address)
                        self.ip_alert_cooldown[ip_key] = current_time

                # Update last seen time
                self.known_ips[ip_key] = current_time

    def process_user_activity_alert(self, config: Dict[str, Any], logs: List[Dict]):
        """Process user activity alerts."""
        pattern = re.compile(config["pattern"])
        cooldown_seconds = config.get("cooldown_seconds", 3600)
        current_time = datetime.now()

        for log in logs:
            match = pattern.search(log["message"])
            if match:
                match_data = match.groupdict()
                username = match_data.get("username")

                if not username:
                    continue

                # Check cooldown for this user
                user_key = f"{config['service']}:{username}"
                should_alert = True
                if user_key in self.ip_alert_cooldown:
                    time_since_last = current_time - self.ip_alert_cooldown[user_key]
                    if time_since_last < timedelta(seconds=cooldown_seconds):
                        should_alert = False

                if should_alert:
                    logger.info(
                        f"User activity detected: {username} using {config['service']}"
                    )
                    self.send_user_activity_alert(config, match_data)
                    self.ip_alert_cooldown[user_key] = current_time

    def send_service_health_alert(self, config: Dict[str, Any], state: str):
        """Send service health change alert."""
        try:
            color = config.get(f"color_{state}", config.get("color", 0x00FF00))

            payload = {
                "alerts": [
                    {
                        "status": "firing",
                        "labels": {
                            "service": config["service"],
                            "alert_type": config["alert_type"],
                            "state": state,
                        },
                        "annotations": {
                            "discord_title": config["discord_title"],
                            "discord_message": config["discord_message"].format(
                                state=state
                            ),
                        },
                    }
                ],
                "color": color,
            }

            self.send_webhook(payload)
            logger.info(
                f"Sent state alert: {config.get('state_key', config['name'])} {state}"
            )

        except Exception as e:
            logger.error(f"Error sending service health alert: {e}")

    def send_suspicious_activity_alert(
        self,
        config: Dict[str, Any],
        ip_address: str,
        count: int,
        last_request_data: Dict,
    ):
        """Send alert for suspicious activity."""
        try:
            # Analyze health check status
            health_check_value = last_request_data.get("health_check", "-")
            health_check_status = self.analyze_health_check_status(health_check_value)

            # Use the detailed message template from config with actual log data
            discord_message = config["discord_message"].format(
                remote_addr=ip_address,
                formatted_time=format_nginx_timestamp(
                    last_request_data.get("time_local", "Recent")
                ),
                remote_user=last_request_data.get("remote_user", "-"),
                container_name=last_request_data.get("container_name", "nginx-unknown"),
                method=last_request_data.get("method", "Multiple"),
                request_uri=last_request_data.get("request_uri", "Various paths"),
                status=last_request_data.get("status", "4xx/5xx"),
                body_bytes_sent=last_request_data.get("body_bytes_sent", "0"),
                http_referer=last_request_data.get("http_referer", "-"),
                http_user_agent=last_request_data.get("http_user_agent", "Unknown"),
                protocol=last_request_data.get("protocol", "HTTP/1.1"),
                health_check_status=health_check_status,
            )

            payload = {
                "alerts": [
                    {
                        "status": "firing",
                        "labels": {
                            "service": config["service"],
                            "alert_type": config["alert_type"],
                            "ip_address": ip_address,
                            "failed_requests": str(count),
                        },
                        "annotations": {
                            "discord_title": config["discord_title"],
                            "discord_message": discord_message,
                        },
                    }
                ],
                "color": config["color"],
            }

            self.send_webhook(payload)
            logger.info(
                f"Sent suspicious activity alert: {ip_address} - {count} failed requests"
            )

        except Exception as e:
            logger.error(f"Error sending suspicious activity alert: {e}")

    def send_ip_access_alert(
        self, config: Dict[str, Any], match_data: Dict, ip_address: str
    ):
        """Send alert for new IP access."""
        try:
            # Determine service name from host header
            host = match_data.get("host", "")
            service_name = self.get_service_name_from_host(host)

            # Determine client IP and location
            if config["service"] == "nginx-cloudflared":
                client_ip = match_data.get("cf_connecting_ip", ip_address)
                location = match_data.get("cf_country", "Unknown")
            else:
                client_ip = ip_address
                location = "Tailscale Network"

            # Use the detailed message template from config with actual log data
            discord_message = config["discord_message"].format(
                service_name=service_name,
                client_ip=client_ip,
                remote_addr=ip_address,
                location=location,
                formatted_time=format_nginx_timestamp(
                    match_data.get("time_local", "Recent")
                ),
                method=match_data.get("method", "Unknown"),
                request_uri=match_data.get("request_uri", "Unknown"),
                status=match_data.get("status", "Unknown"),
                body_bytes_sent=match_data.get("body_bytes_sent", "0"),
                protocol=match_data.get("protocol", "HTTP/1.1"),
                http_user_agent=match_data.get("http_user_agent", "Unknown"),
                http_referer=match_data.get("http_referer", "-"),
                cf_ray=match_data.get("cf_ray", "-"),
            )

            payload = {
                "alerts": [
                    {
                        "status": "firing",
                        "labels": {
                            "service": config["service"],
                            "alert_type": config["alert_type"],
                            "ip_address": ip_address,
                        },
                        "annotations": {
                            "discord_title": config["discord_title"],
                            "discord_message": discord_message,
                        },
                    }
                ],
                "color": config["color"],
            }

            self.send_webhook(payload)
            logger.info(
                f"Sent IP access alert: {config['service']} - {ip_address} - {service_name}"
            )

        except Exception as e:
            logger.error(f"Error sending IP access alert: {e}")

    def send_user_activity_alert(self, config: Dict[str, Any], match_data: Dict):
        """Send alert for user activity."""
        try:
            # Use the detailed message template from config with actual log data
            discord_message = config["discord_message"].format(
                username=match_data.get("username", "Unknown")
            )

            payload = {
                "alerts": [
                    {
                        "status": "firing",
                        "labels": {
                            "service": config["service"],
                            "alert_type": config["alert_type"],
                            "username": match_data.get("username", "Unknown"),
                        },
                        "annotations": {
                            "discord_title": config["discord_title"],
                            "discord_message": discord_message,
                        },
                    }
                ],
                "color": config["color"],
            }

            self.send_webhook(payload)
            logger.info(
                f"Sent user activity alert: {config['service']} - {match_data.get('username', 'Unknown')}"
            )

        except Exception as e:
            logger.error(f"Error sending user activity alert: {e}")

    def get_service_name_from_host(self, host: str) -> str:
        """Determine service name from host header."""
        if not host:
            return "Unknown Service"

        # Map hostnames to friendly service names
        host_mapping = {
            "copyparty.greglinscheid.com": "📁 Copyparty (Public)",
            "freshrss.greglinscheid.com": "📰 FreshRSS (Public)",
            "kiwix.greglinscheid.com": "📚 Kiwix (Public)",
            "greg-zone:9000": "📊 Prometheus (Tailscale)",
            "greg-zone:9001": "📈 Grafana (Tailscale)",
            "greg-zone:9002": "📁 Copyparty (Tailscale)",
            "greg-zone:9003": "📰 FreshRSS (Tailscale)",
            "greg-zone:9004": "📚 Kiwix (Tailscale)",
            "greg-zone:9005": "📊 Prometheus (Tailscale)",
            "greg-zone:9006": "📈 Grafana (Tailscale)",
            "greg-zone:9007": "📊 cAdvisor (Tailscale)",
        }

        return host_mapping.get(host, f"🌐 {host}")


if __name__ == "__main__":
    monitor = ServicesAlertMonitor()
    monitor.run()
