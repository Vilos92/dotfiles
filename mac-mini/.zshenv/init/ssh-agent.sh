#!/bin/sh

# Mac Mini only: pin one local ssh-agent to a fixed socket. mosh carries no agent
# forwarding and reattached tmux caches a dead socket path — a stable path lets
# every session and pane reuse the same live agent across reconnects. The key
# loads lazily via AddKeysToAgent + UseKeychain in ~/.ssh/config on first git/ssh
# use, so opening a shell never blocks on a passphrase prompt.
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
ssh-add -l >/dev/null 2>&1
if [ $? -eq 2 ]; then                          # exit 2 = nothing live on the socket
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
fi
