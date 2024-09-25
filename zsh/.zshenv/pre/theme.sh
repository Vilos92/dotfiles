#!/bin/sh

export ALACRITTY_THEME_DIR_PATH="$ALACRITTY_PATH"/theme

# Auto-create theme config for alacritty-theme if it does not exist.
export ALACRITTY_THEME_PATH="$ALACRITTY_PATH"/theme.toml
if [ ! -f "$ALACRITTY_THEME_PATH" ]; then
  touch "$ALACRITTY_THEME_PATH"
  echo "# This line will be replaced by alacritty-theme." > "$ALACRITTY_THEME_PATH"
fi

