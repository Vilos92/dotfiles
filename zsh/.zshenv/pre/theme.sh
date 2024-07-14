export ALACRITTY_THEME_DIR_PATH="$ALACRITTY_PATH"/theme

# Auto-create theme config for alacritty-theme if it does not exist.
export ALACRITTY_THEME_PATH="$ALACRITTY_PATH"/theme.toml
if [ ! -f "$ALACRITTY_THEME_PATH" ]; then
  touch "$ALACRITTY_THEME_PATH"
  echo "# This line will be replaced by alacritty-theme." > "$ALACRITTY_THEME_PATH"
fi

# Auto-create nvim themery config if it does not exist.
export NVIM_THEME_PATH="$GREG_DOTFILES_PATH"/nvim/.config/nvim/lua/greg/theme.lua
if [ ! -f "$NVIM_THEME_PATH" ]; then
  touch "$NVIM_THEME_PATH"
  {
    echo "-- Themery block"
    echo "  -- This block will be replaced by Themery."
    echo "-- end themery block"
  } > "$NVIM_THEME_PATH"
fi
