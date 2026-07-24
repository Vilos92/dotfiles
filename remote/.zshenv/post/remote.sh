#!/bin/sh

# Sparkify (Digital Ocean Droplet)
alias ssh-sparkify='ssh root@147.182.226.122'

# Mac Mini (Must be on tailwind)
alias ssh-mini='ssh greg.linscheid@gregs-mac-mini'
# Interactive login zsh: -i for .zshrc (~/.local/bin on PATH), -l for
# /etc/zprofile & .zprofile (docker/homebrew on PATH).
# hermes attaches/creates the persistent "hermes" tmux session running the TUI.
alias ssh-mini-hermes='ssh -t greg.linscheid@gregs-mac-mini "zsh -ilc hermes"'
