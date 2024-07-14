# Dotfiles
export GREG_DOTFILES_PATH=~/greg_projects/dotfiles
alias gcd-dotfiles='cd $GREG_DOTFILES_PATH'
alias gtmux-dotfiles='tmux-attach dotfiles $GREG_DOTFILES_PATH'
alias vdotfiles='nvim $GREG_DOTFILES_PATH'

# nvim config
alias vconfig='nvim $GREG_DOTFILES_PATH/nvim/.config/nvim'

# alacritty themes
alias kt='alacritty-theme-select'

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
