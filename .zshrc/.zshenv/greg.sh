#!/bin/zsh

# Dotfiles
alias gcddotfiles='cd ~/greg_projects/dotfiles'
alias gtmuxdotfiles='gcddotfiles && tmux new-session -A -s dotfiles'

# Milo Engine
alias gcdmiloengine='cd ~/greg_projects/milo-engine'
alias gtmuxmiloengine='gcdmiloengine && tmux new-session -A -s miloengine'

# Sparkify
alias gcdsparkify='cd ~/greg_projects/sparkify'
alias gtmuxsparkify='gcdsparkify && tmux new-session -A -s sparkify'
alias ssh-sparkify='ssh root@147.182.226.122'

# Black magic
source ${HOME}/.ghcup/env
