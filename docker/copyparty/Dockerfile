# Build from scratch using Alpine Linux
FROM alpine:latest

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    ca-certificates \
    ffmpeg \
    imagemagick \
    && rm -rf /var/cache/apk/*

# Install copyparty
RUN pip3 install --break-system-packages copyparty

# Install cloudflared
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

# Create app directory
WORKDIR /app

# Copy the startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose port 3923 (copyparty will be accessible on this port)
EXPOSE 3923

# Set the entrypoint to our startup script
ENTRYPOINT ["/app/start.sh"]
