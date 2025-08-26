#!/bin/sh

# Remove the old container if it exists
docker rm -f freshrss 2>/dev/null || true

echo "Pulling the latest FreshRSS image from Docker Hub..."
docker pull freshrss/freshrss:latest

if [ $? -ne 0 ]; then
    echo "Error: Failed to pull the freshrss/freshrss image. Please check your internet connection or Docker configuration."
    exit 1
fi

docker run -d --restart unless-stopped --log-opt max-size=10m \
  -p 49153:80 \
  -e TZ=America/Los_Angeles \
  -e 'CRON_MIN=1,31' \
  -v ~/Desktop/Mac\ Vault/Greg\ News/freshrss-data:/var/www/FreshRSS/data \
  -v ~/Desktop/Mac\ Vault/Greg\ News/freshrss-extensions:/var/www/FreshRSS/extensions \
  --name freshrss \
  freshrss/freshrss
