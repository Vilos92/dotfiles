#!/bin/sh

# Mac Mini (must be on tailscale). mosh needs an absolute --server path because
# homebrew is not on the mini's non-interactive PATH.
alias ssh-mini='ssh greg.linscheid@gregs-mac-mini'
alias mosh-mini='mosh --server=/opt/homebrew/bin/mosh-server greg.linscheid@gregs-mac-mini'

# Attach the persistent "hermes" tmux session running the TUI. zsh -il: -i for
# .zshrc (~/.local/bin on PATH), -l for zprofile (docker/homebrew on PATH).
alias ssh-mini-hermes='ssh -t greg.linscheid@gregs-mac-mini "zsh -ilc hermes"'
alias mosh-mini-hermes='mosh --server=/opt/homebrew/bin/mosh-server greg.linscheid@gregs-mac-mini -- zsh -ilc hermes'
