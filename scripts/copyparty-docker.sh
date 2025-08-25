#!/bin/sh

if [ -z "$COPYPARTY_CLOUDFLARED_TOKEN" ]; then
    echo "Error: COPYPARTY_CLOUDFLARED_TOKEN environment variable is not set"
    echo "Please set it before running this script:"
    echo "export COPYPARTY_CLOUDFLARED_TOKEN=your_token_here"
    exit 1
fi

if [ ! -d "/Volumes/Elements" ]; then
    echo "Error: /Volumes/Elements directory does not exist"
    echo "Please make sure your external drive is mounted at /Volumes/Elements"
    exit 1
fi

if [ ! -d "/Users/greg.linscheid/Desktop/Mac Vault" ]; then
    echo "Error: /Users/greg.linscheid/Desktop/Mac Vault directory does not exist"
    exit 1
fi

# Get the directory where this script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker/copyparty"

echo "Stopping and removing existing container..."

docker stop copyparty-tunnel 2>/dev/null || true
docker rm copyparty-tunnel 2>/dev/null || true

echo "Pulling the latest copyparty-tunnel image from Docker Hub..."
docker pull ghcr.io/vilos92/copyparty-tunnel:latest

if [ $? -ne 0 ]; then
    echo "Error: Failed to pull the ghcr.io/vilos92/copyparty-tunnel image. Please check your internet connection or Docker configuration."
    exit 1
fi

docker run -d \
  --name copyparty-tunnel \
  -p 3923:3923 \
  -u 1000 \
  -v "$DOCKER_DIR/copyparty.conf:/app/copyparty.conf:ro" \
  -v "/Volumes/Elements:/Volumes/Elements" \
  -v "/Users/greg.linscheid/Desktop/Mac Vault:/Volumes/Mac Vault" \
  -e COPYPARTY_CLOUDFLARED_TOKEN="$COPYPARTY_CLOUDFLARED_TOKEN" \
  --restart unless-stopped \
  ghcr.io/vilos92/copyparty-tunnel:latest

echo "Container started! Check logs with: docker logs -f copyparty-tunnel"

echo "Copyparty available at http://localhost:8080"
echo "Cloudflare tunnel will available at https://copyparty.greglinscheid.com"
