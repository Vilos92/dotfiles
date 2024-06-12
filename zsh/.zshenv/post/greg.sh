#!/bin/zsh

# Dotfiles
alias gcd-dotfiles='cd ~/greg_projects/dotfiles'
alias gtmux-dotfiles='gcd-dotfiles && tmux-attach dotfiles'

# Milo Engine
alias gcd-miloengine='cd ~/greg_projects/milo-engine'
alias gtmux-miloengine='gcd-miloengine && tmux-attach miloengine'

# Sparkify
alias gcd-sparkify='cd ~/greg_projects/sparkify'
alias gtmux-sparkify='gcd-sparkify && tmux-attach sparkify'
alias ssh-sparkify='ssh root@147.182.226.122'

# Black magic
source ${HOME}/.ghcup/env
