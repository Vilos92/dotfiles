#!/bin/zsh

# Dotfiles
alias gcd-dotfiles='cd ~/greg_projects/dotfiles'
alias gtmux-dotfiles='gcddotfiles && tmux new-session -A -s dotfiles'

# Milo Engine
alias gcd-miloengine='cd ~/greg_projects/milo-engine'
alias gtmux-miloengine='gcdmiloengine && tmux new-session -A -s miloengine'

# Sparkify
alias gcd-sparkify='cd ~/greg_projects/sparkify'
alias gtmux-sparkify='gcdsparkify && tmux new-session -A -s sparkify'
alias ssh-sparkify='ssh root@147.182.226.122'

# Black magic
source ${HOME}/.ghcup/env
