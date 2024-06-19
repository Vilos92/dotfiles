#!/bin/zsh

# Dotfiles
export GREG_DOTFILES_PATH=~/greg_projects/dotfiles
alias gcd-dotfiles='cd $GREG_DOTFILES_PATH'
alias gtmux-dotfiles='tmux-attach dotfiles $GREG_DOTFILES_PATH'
alias vdotfiles='nvim $GREG_DOTFILES_PATH'

# nvim config
alias vconfig='nvim $GREG_DOTFILES_PATH/nvim/.config/nvim'

# alacritty theme
export ALACRITTY_PATH=~/.config/alacritty
export ALACRITTY_THEME_PATH=$ALACRITTY_PATH/theme
function alacritty-theme() {
  if [ -z "$1" ]; then
    echo "Usage: alacritty-theme <theme>"
    return 1
  fi

  if [ ! -f "$ALACRITTY_THEME_PATH/$1.toml" ]; then
    echo "Theme $1 not found"
    return 1
  fi

  sed -i '' "1s|.*|import = [\"$ALACRITTY_THEME_PATH/$1.toml\"]|" $ALACRITTY_PATH/alacritty.toml
  echo "Theme $1 applied"
}
alias at=alacritty-theme
alias at-rose-pine-moon='alacritty-theme rose-pine-moon'
alias at-rose-pine-dawn='alacritty-theme rose-pine-dawn'
alias at-catppuccin-frappe='alacritty-theme catppuccin-frappe'
alias at-catppuccin-latte='alacritty-theme catppuccin-latte'
alias at-catppuccin-macchiato='alacritty-theme catppuccin-macchiato'
alias at-catppuccin-mocha='alacritty-theme catppuccin-mocha'

# Milo Engine
export GREG_MILOENGINE_PATH=~/greg_projects/milo-engine
alias gcd-miloengine='cd $GREG_MILOENGINE_PATH'
alias gtmux-miloengine='tmux-attach miloengine $GREG_MILOENGINE_PATH'

# Sparkify
export GREG_SPARKIFY_PATH=~/greg_projects/sparkify
alias gcd-sparkify='cd $GREG_SPARKIFY_PATH'
alias gtmux-sparkify='tmux-attach sparkify $GREG_SPARKIFY_PATH'
alias ssh-sparkify='ssh root@147.182.226.122'
