#!/usr/bin/env python3
"""
Infrastructure Alert Monitor
Monitors the monitoring infrastructure: loki, prometheus, grafana, alertmanager, etc.
Handles infrastructure service health monitoring.
"""

import time
import os
import base64
import requests
from datetime import datetime
from typing import Dict, Any
import logging
from cryptography.fernet import Fernet

from shared.base_alert_monitor import BaseAlertMonitor

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class InfrastructureAlertMonitor(BaseAlertMonitor):
    """Alert monitor for infrastructure services: loki, prometheus, grafana, etc."""

    def __init__(self):
        """Initialize the infrastructure alert monitor with infrastructure-specific configurations."""
        alert_configs = [
            # Loki health monitoring
            {
                "name": "loki_health",
                "service": "loki",
                "check_type": "http_health_check",
                "url": "http://loki:3100/ready",
                "alert_type": "service_health_change",
                "discord_title": "📊 Loki Alert",
                "discord_message": "Loki is now {state}!\n\n🌐 **URL:** http://loki:3100",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "loki",
            },
            # Prometheus health monitoring
            {
                "name": "prometheus_health",
                "service": "prometheus",
                "check_type": "http_health_check",
                "url": "http://prometheus:9090/-/healthy",
                "alert_type": "service_health_change",
                "discord_title": "📈 Prometheus Alert",
                "discord_message": "Prometheus is now {state}!\n\n🌐 **URL:** http://prometheus:9090",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "prometheus",
            },
            # Grafana health monitoring
            {
                "name": "grafana_health",
                "service": "grafana",
                "check_type": "http_health_check",
                "url": "http://grafana:3000/api/health",
                "alert_type": "service_health_change",
                "discord_title": "📊 Grafana Alert",
                "discord_message": "Grafana is now {state}!\n\n🌐 **URL:** http://grafana:3000",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "grafana",
            },
            # Alertmanager health monitoring
            {
                "name": "alertmanager_health",
                "service": "alertmanager",
                "check_type": "http_health_check",
                "url": "http://alertmanager:9093/-/healthy",
                "alert_type": "service_health_change",
                "discord_title": "🚨 Alertmanager Alert",
                "discord_message": "Alertmanager is now {state}!\n\n🌐 **URL:** http://alertmanager:9093",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "alertmanager",
            },
            # Discord webhook health monitoring
            {
                "name": "discord_webhook_health",
                "service": "discord-webhook",
                "check_type": "http_health_check",
                "url": "http://discord-webhook:8080/health",
                "alert_type": "service_health_change",
                "discord_title": "💬 Discord Webhook Alert",
                "discord_message": "Discord webhook is now {state}!\n\n🌐 **URL:** http://discord-webhook:8080",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "discord_webhook",
            },
            # Promtail health monitoring
            {
                "name": "promtail_health",
                "service": "promtail",
                "check_type": "http_health_check",
                "url": "http://promtail:9080/ready",
                "alert_type": "service_health_change",
                "discord_title": "📝 Promtail Alert",
                "discord_message": "Promtail is now {state}!\n\n🌐 **URL:** http://promtail:9080",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "promtail",
            },
            # Node exporter health monitoring
            {
                "name": "node_exporter_health",
                "service": "node-exporter",
                "check_type": "http_health_check",
                "url": "http://node-exporter:9100/metrics",
                "alert_type": "service_health_change",
                "discord_title": "🖥️ Node Exporter Alert",
                "discord_message": "Node exporter is now {state}!\n\n🌐 **URL:** http://node-exporter:9100",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "node_exporter",
            },
            # Docker stats exporter health monitoring
            {
                "name": "docker_stats_exporter_health",
                "service": "docker-stats-exporter",
                "check_type": "http_health_check",
                "url": "http://docker-stats-exporter:8080/metrics",
                "alert_type": "service_health_change",
                "discord_title": "🐳 Docker Stats Exporter Alert",
                "discord_message": "Docker stats exporter is now {state}!\n\n🌐 **URL:** http://docker-stats-exporter:8080",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "docker_stats_exporter",
            },
            # cAdvisor health monitoring
            {
                "name": "cadvisor_health",
                "service": "cadvisor",
                "check_type": "http_health_check",
                "url": "http://cadvisor:8080/healthz",
                "alert_type": "service_health_change",
                "discord_title": "📊 cAdvisor Alert",
                "discord_message": "cAdvisor is now {state}!\n\n🌐 **URL:** http://cadvisor:8080",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "cadvisor",
            },
            # Public service health monitoring
            {
                "name": "copyparty_public_health",
                "service": "infra",
                "check_type": "url_health_check",
                "urls": ["https://copyparty.greglinscheid.com"],
                "alert_type": "service_health_change",
                "discord_title": "📁 Copyparty Alert",
                "discord_message": "Copyparty is now {state}!\n\n🌐 **URL:** https://copyparty.greglinscheid.com",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "copyparty_public",
            },
            {
                "name": "freshrss_public_health",
                "service": "infra",
                "check_type": "url_health_check",
                "urls": ["https://freshrss.greglinscheid.com"],
                "alert_type": "service_health_change",
                "discord_title": "📰 FreshRSS Alert",
                "discord_message": "FreshRSS is now {state}!\n\n🌐 **URL:** https://freshrss.greglinscheid.com",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "freshrss_public",
            },
            {
                "name": "kiwix_public_health",
                "service": "infra",
                "check_type": "url_health_check",
                "urls": ["https://kiwix.greglinscheid.com"],
                "alert_type": "service_health_change",
                "discord_title": "📚 Kiwix Alert",
                "discord_message": "Kiwix is now {state}!\n\n🌐 **URL:** https://kiwix.greglinscheid.com",
                "color_online": 0x00FF00,
                "color_offline": 0xFF0000,
                "track_state": True,
                "state_key": "kiwix_public",
            },
        ]

        super().__init__(alert_configs, "/tmp/infrastructure_alert_monitor_state.json")

    def generate_health_check_token(self) -> str:
        """Generate a secure health check token with encrypted timestamp."""
        try:
            # Create a timestamp
            timestamp = int(time.time())

            # Get secret from environment
            secret = os.getenv("ALERT_MONITOR_SECRET", "default-secret-change-me")

            # Create encryption key from secret (pad to 32 bytes)
            key = base64.urlsafe_b64encode(secret.encode()[:32].ljust(32, b"0"))
            f = Fernet(key)

            # Encrypt the timestamp
            encrypted_timestamp = f.encrypt(str(timestamp).encode())
            return base64.urlsafe_b64encode(encrypted_timestamp).decode()
        except Exception as e:
            logger.warning(f"Failed to generate health check token: {e}")
            return "fallback-token"

    def check_url_health(self, url: str, timeout: int = 10) -> bool:
        """Check if a URL is responding with a healthy status code."""
        try:
            health_token = self.generate_health_check_token()
            headers = {
                "X-Health-Check": f"alert-monitor-{health_token}",
                "User-Agent": "alert-monitor-health-check/1.0",
            }
            response = requests.head(
                url, timeout=timeout, allow_redirects=True, headers=headers
            )
            return response.status_code < 400
        except Exception as e:
            logger.error(f"Error checking URL health for {url}: {e}")
            return False

    def run(self):
        """Main monitoring loop for infrastructure services."""
        logger.info("Starting Infrastructure Alert Monitor")

        while True:
            try:
                current_time = datetime.now()
                logger.info(f"Checking infrastructure services at {current_time}")

                # Process each alert configuration
                for config in self.alert_configs:
                    if config.get("check_type") == "http_health_check":
                        self.process_http_health_check(config)

                # Update last check time and save state
                self.last_check_time = current_time
                self.save_state()

                # Wait for next check
                time.sleep(self.check_interval)

            except KeyboardInterrupt:
                logger.info("Infrastructure Alert Monitor stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in Infrastructure Alert Monitor: {e}")
                time.sleep(self.check_interval)

    def process_http_health_check(self, config: Dict[str, Any]):
        """Process HTTP health checks for infrastructure services."""
        url = config.get("url")
        if not url:
            return

        # Check service health
        is_healthy = self.check_http_health(url)

        # Determine current state
        current_state = "online" if is_healthy else "offline"
        state_key = config.get("state_key", config["name"])

        # Check if state changed
        if state_key in self.server_states:
            previous_state = self.server_states[state_key]
            if previous_state == current_state:
                logger.info(
                    f"Infrastructure service health unchanged for {state_key}: {current_state}"
                )
                return

        # State changed - send alert
        logger.info(
            f"Infrastructure service health changed for {state_key}: {previous_state} -> {current_state}"
        )

        # Send alert
        self.send_service_health_alert(config, current_state)

        # Update state
        self.server_states[state_key] = current_state

    def check_http_health(self, url: str, timeout: int = 10) -> bool:
        """Check if an HTTP service is responding with a healthy status code."""
        try:
            response = requests.get(url, timeout=timeout)
            # For infrastructure services, we consider 200-299 as healthy
            # Some services might return 404 for /health but be healthy otherwise
            return response.status_code < 500
        except Exception as e:
            logger.error(f"Error checking HTTP health for {url}: {e}")
            return False

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
                f"Sent infrastructure state alert: {config.get('state_key', config['name'])} {state}"
            )

        except Exception as e:
            logger.error(f"Error sending infrastructure service health alert: {e}")


if __name__ == "__main__":
    monitor = InfrastructureAlertMonitor()
    monitor.run()
