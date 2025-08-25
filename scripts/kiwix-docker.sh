#!/bin/sh

ZIM_DIR="/Volumes/Elements/Local Vault/media/zim"

if [ ! -d "$ZIM_DIR" ]; then
    echo "Error: ZIM directory does not exist at '$ZIM_DIR'"
    echo "Please make sure your ZIM files are stored in the correct location"
    echo "You can modify the ZIM_DIR variable in this script to point to your ZIM files"
    exit 1
fi

if [ ! "$(find "$ZIM_DIR" -name "*.zim" -type f | head -n 1)" ]; then
    echo "Error: No .zim files found in '$ZIM_DIR'"
    echo "Please make sure you have ZIM files in the directory"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Stopping and removing existing container..."

docker stop kiwix-server 2>/dev/null || true
docker rm kiwix-server 2>/dev/null || true

echo "Pulling the latest kiwix-serve image from Docker Hub..."
docker pull ghcr.io/kiwix/kiwix-serve:latest

if [ $? -ne 0 ]; then
    echo "Error: Failed to pull the ghcr.io/kiwix/kiwix-serve image. Please check your internet connection or Docker configuration."
    exit 1
fi

echo "Starting Kiwix server with all ZIM files from '$ZIM_DIR'..."

docker run -d \
  --name kiwix-server \
  -p 8473:8080 \
  -v "$ZIM_DIR:/data" \
  --restart unless-stopped \
  ghcr.io/kiwix/kiwix-serve:latest '**/*.zim'

echo "Container started! Check logs with: docker logs -f kiwix-server"

echo "Kiwix server available at http://localhost:8473"
echo "All ZIM files from '$ZIM_DIR' are now accessible through the web interface"
