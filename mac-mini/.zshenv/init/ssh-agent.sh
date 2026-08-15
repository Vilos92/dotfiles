#!/bin/sh

# Mac Mini only: pin one local agent to a fixed socket. mosh carries no agent
# forwarding and reattached tmux caches a dead socket path — a stable path means
# every session and pane keeps finding the same live agent across reconnects.
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
ssh-add -l >/dev/null 2>&1
if [ $? -eq 2 ]; then                          # exit 2 = nothing live on the socket
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" >/dev/null 2>&1
fi
