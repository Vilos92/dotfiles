#!/bin/sh

# Sparkify (Digital Ocean Droplet)
alias ssh-sparkify='ssh root@147.182.226.122'

# Mac Mini (Must be on tailwind)
alias ssh-mini='ssh greg.linscheid@gregs-mac-mini'
# Interactive zsh so ~/.local/bin and homebrew land on PATH (set in .zshrc).
# hermes attaches/creates the persistent "hermes" tmux session running the TUI.
alias ssh-mini-hermes='ssh -t greg.linscheid@gregs-mac-mini "zsh -ic hermes"'
