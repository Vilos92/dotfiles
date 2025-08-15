#!/bin/bash

# Start copyparty in the background
copyparty -c /app/copyparty.conf &

# Wait a moment for copyparty to start
sleep 2

# Start cloudflared tunnel with correct origin URL
cloudflared tunnel run --token "$COPYPARTY_CLOUDFLARED_TOKEN" --url http://127.0.0.1:8080
