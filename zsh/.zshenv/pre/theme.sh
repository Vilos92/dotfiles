#!/bin/zsh

# Auto-create ignored theme files if they do not exist
export NVIM_THEME_PATH=$GREG_DOTFILES_PATH/nvim/.config/nvim/lua/greg/theme.lua

echo $NVIM_THEME_PATH
if [ ! -f "$NVIM_THEME_PATH" ]; then
  touch $NVIM_THEME_PATH
  {
    echo "-- Themery block"
    echo "  -- This block will be replaced by Themery."
    echo "-- end themery block"
  } > "$NVIM_THEME_PATH"
fi

# alacritty theme switcher
export ALACRITTY_PATH=~/.config/alacritty
export ALACRITTY_THEME_PATH=$ALACRITTY_PATH/theme
function alacritty-theme() {
  if [ -z "$1" ]; then
    echo "Usage: alacritty-theme <theme>"
    return 1
  fi

  if [ ! -f "$ALACRITTY_THEME_PATH/$1.toml" ]; then
    echo "Theme $1 not found."
    return 1
  fi

  sed -i '' "1s|.*|import = [\"$ALACRITTY_THEME_PATH/$1.toml\"]|" $ALACRITTY_PATH/alacritty.toml
  echo "Theme $1 applied."
}

