#!/usr/bin/env python3
"""
Minecraft Alert Monitor
Monitors Minecraft server, playit tunnel, and related gaming services.
Handles server health checks and player activity monitoring.
"""

import re
import time
from datetime import datetime
from typing import Dict, List, Any
import logging

from shared.base_alert_monitor import BaseAlertMonitor

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class MinecraftAlertMonitor(BaseAlertMonitor):
    """Alert monitor for Minecraft services: minecraft, playit, mc-monitor, etc."""

    def __init__(self):
        """Initialize the minecraft alert monitor with minecraft-specific configurations."""
        alert_configs = [
            # Minecraft server health monitoring (via mc-monitor metrics)
            {
                "name": "minecraft_server_health",
                "service": "minecraft",
                "check_type": "health_check",  # Special type for health checks
                "host": "minecraft",
                "port": 19132,
                "alert_type": "server_health_change",
                "discord_title": "🎮 Minecraft Alert Monitor",
                "discord_message": "Minecraft server is now {state}!",
                "color_online": 0x00FF00,  # Green for online
                "color_offline": 0xFF0000,  # Red for offline
                "track_state": True,
                "state_key": "minecraft",
            },
            # Minecraft player join/leave monitoring
            {
                "name": "minecraft_player_activity",
                "service": "minecraft",
                "query": '{container_name="minecraft"} |~ "Player (connected|disconnected):"',
                "pattern": r"Player (?P<event_type>connected|disconnected): (?P<player_name>[^,]+), xuid: (?P<xuid>\d+)",
                "alert_type": "player_activity",
                "discord_title": "🎮 Minecraft Alert Monitor",
                "discord_message": "**{player_name}** {event_type} the server",
                "color": 0x0099FF,
                "track_state": False,  # Don't track state for player activity
            },
        ]

        super().__init__(alert_configs, "/tmp/minecraft_alert_monitor_state.json")

    def run(self):
        """Main monitoring loop for Minecraft services."""
        logger.info("Starting Minecraft Alert Monitor")

        while True:
            try:
                current_time = datetime.now()
                logger.info(f"Checking Minecraft services at {current_time}")

                # Process each alert configuration
                for config in self.alert_configs:
                    if config.get("check_type") == "health_check":
                        self.process_server_health_check(config)
                    else:
                        # Query Loki for logs
                        logs = self.query_loki(config["query"])
                        if logs:
                            if config["alert_type"] == "player_activity":
                                self.process_player_activity_alert(config, logs)

                # Update last check time and save state
                self.last_check_time = current_time
                self.save_state()

                # Wait for next check
                time.sleep(self.check_interval)

            except KeyboardInterrupt:
                logger.info("Minecraft Alert Monitor stopped by user")
                break
            except Exception as e:
                logger.error(f"Error in Minecraft Alert Monitor: {e}")
                time.sleep(self.check_interval)

    def process_server_health_check(self, config: Dict[str, Any]):
        """Process server health checks for Minecraft."""
        host = config.get("host")
        port = config.get("port")
        if not host or not port:
            return

        # Check server health
        is_healthy = self.check_server_health(host, port)

        # Determine current state
        current_state = "online" if is_healthy else "offline"
        state_key = config.get("state_key", config["name"])

        # Check if state changed
        previous_state = self.server_states.get(state_key, "unknown")
        if previous_state == current_state:
            logger.info(f"Server health unchanged for {state_key}: {current_state}")
            return

        # Log and alert on initial state detection
        if previous_state == "unknown":
            logger.info(f"🎮 Minecraft server initial check: {current_state}")
            # Always send alert for initial state detection
            self.send_server_health_alert(config, current_state)
            self.server_states[state_key] = current_state
            return

        # State changed - send alert
        logger.info(
            f"Server health changed for {state_key}: {previous_state} -> {current_state}"
        )

        # Send alert
        self.send_server_health_alert(config, current_state)

        # Update state
        self.server_states[state_key] = current_state

    def process_player_activity_alert(self, config: Dict[str, Any], logs: List[Dict]):
        """Process player activity alerts."""
        pattern = re.compile(config["pattern"])

        for log in logs:
            match = pattern.search(log["message"])
            if match:
                match_data = match.groupdict()
                player_name = match_data.get("player_name")
                event_type = match_data.get("event_type")

                if not player_name or not event_type:
                    continue

                logger.info(f"Player activity detected: {player_name} {event_type}")
                self.send_player_activity_alert(config, match_data)

    def send_server_health_alert(self, config: Dict[str, Any], state: str):
        """Send server health change alert."""
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
                f"Sent server health alert: {config.get('state_key', config['name'])} {state}"
            )

        except Exception as e:
            logger.error(f"Error sending server health alert: {e}")

    def send_player_activity_alert(self, config: Dict[str, Any], match_data: Dict):
        """Send player activity alert."""
        try:
            # Use the detailed message template from config with actual log data
            discord_message = config["discord_message"].format(
                player_name=match_data.get("player_name", "Unknown"),
                event_type=match_data.get("event_type", "unknown"),
            )

            payload = {
                "alerts": [
                    {
                        "status": "firing",
                        "labels": {
                            "service": config["service"],
                            "alert_type": config["alert_type"],
                            "player_name": match_data.get("player_name", "Unknown"),
                            "event_type": match_data.get("event_type", "unknown"),
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
                f"Sent player activity alert: {config['service']} - {match_data.get('player_name', 'Unknown')} {match_data.get('event_type', 'unknown')}"
            )

        except Exception as e:
            logger.error(f"Error sending player activity alert: {e}")


if __name__ == "__main__":
    monitor = MinecraftAlertMonitor()
    monitor.run()
