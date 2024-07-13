# Auto-create theme config for alacritty-theme if it does not exist.
export ALACRITTY_THEME_PATH=$ALACRITTY_PATH/theme.toml
if [ ! -f "$ALACRITTY_THEME_PATH" ]; then
  touch $ALACRITTY_THEME_PATH
  echo "# This line will be replaced by alacritty-theme." > $ALACRITTY_THEME_PATH
fi

# Auto-create nvim themery config if it does not exist.
export NVIM_THEME_PATH=$GREG_DOTFILES_PATH/nvim/.config/nvim/lua/greg/theme.lua
if [ ! -f "$NVIM_THEME_PATH" ]; then
  touch $NVIM_THEME_PATH
  {
    echo "-- Themery block"
    echo "  -- This block will be replaced by Themery."
    echo "-- end themery block"
  } > "$NVIM_THEME_PATH"
fi

# alacritty theme switcher
export ALACRITTY_THEME_DIR_PATH=$ALACRITTY_PATH/theme
function alacritty-theme() {
  if [ -z "$1" ]; then
    echo "Usage: alacritty-theme <theme>"
    return 1
  fi

  if [ ! -f "$ALACRITTY_THEME_DIR_PATH/$1.toml" ]; then
    echo "Theme $1 not found."
    return 1
  fi

  sed -i '' "1s|.*|import = [\"$ALACRITTY_THEME_DIR_PATH/$1.toml\"]|" $ALACRITTY_PATH/theme.toml
  touch $ALACRITTY_PATH/alacritty.toml
  echo "Theme $1 applied."
}

function alacritty-theme-select() {
  theme=$(ls $ALACRITTY_THEME_DIR_PATH | sed 's/\.toml$//g' | fzf --tmux --preview 'bat --color=always $ALACRITTY_THEME_DIR_PATH/{}.toml')

  if [ -z "$theme" ]; then
    echo "Theme not selected."
    return 1
  fi

  alacritty-theme $theme
}
