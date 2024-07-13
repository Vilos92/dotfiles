#!/bin/sh

# Dotfiles
export GREG_DOTFILES_PATH=~/greg_projects/dotfiles
alias gcd-dotfiles='cd $GREG_DOTFILES_PATH'
alias gtmux-dotfiles='tmux-attach dotfiles $GREG_DOTFILES_PATH'
alias vdotfiles='nvim $GREG_DOTFILES_PATH'

# nvim config
alias vconfig='nvim $GREG_DOTFILES_PATH/nvim/.config/nvim'

# alacritty themes
alias kt='alacritty-theme-select'
alias kt-rose-pine='alacritty-theme rose-pine'
alias kt-rose-pine-moon='alacritty-theme rose-pine-moon'
alias kt-rose-pine-dawn='alacritty-theme rose-pine-dawn'
alias kt-catppuccin-frappe='alacritty-theme catppuccin-frappe'
alias kt-catppuccin-latte='alacritty-theme catppuccin-latte'
alias kt-catppuccin-macchiato='alacritty-theme catppuccin-macchiato'
alias kt-catppuccin-mocha='alacritty-theme catppuccin-mocha'
alias kt-tokyonight-day='alacritty-theme tokyonight_day'
alias kt-tokyonight-moon='alacritty-theme tokyonight_moon'
alias kt-tokyonight-night='alacritty-theme tokyonight_night'
alias kt-tokyonight-storm='alacritty-theme tokyonight_storm'

# greglinscheid.com
export GREG_ASTROGREG_PATH=~/greg_projects/astro-greg
alias gcd-astrogreg='cd $GREG_ASTROGREG_PATH'
alias gtmux-astrogreg='tmux-attach astrogreg $GREG_ASTROGREG_PATH'

# Milo Engine
export GREG_MILOENGINE_PATH=~/greg_projects/milo-engine
alias gcd-miloengine='cd $GREG_MILOENGINE_PATH'
alias gtmux-miloengine='tmux-attach miloengine $GREG_MILOENGINE_PATH'

# Sparkify
export GREG_SPARKIFY_PATH=~/greg_projects/sparkify
alias gcd-sparkify='cd $GREG_SPARKIFY_PATH'
alias gtmux-sparkify='tmux-attach sparkify $GREG_SPARKIFY_PATH'
alias ssh-sparkify='ssh root@147.182.226.122'
