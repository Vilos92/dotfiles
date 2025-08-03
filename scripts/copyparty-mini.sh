#!/bin/sh

# Create the detached session with the first command
tmux new-session -d -s copyparty 'copyparty-mini'

# Send the split command to the new session's first window
tmux split-window -t copyparty:0 -h 'copyparty-cloudflared'

# Optional: apply the layout
tmux select-layout -t copyparty:0 even-horizontal

