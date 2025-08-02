#!/bin/sh

# Get the Python 3 bin directory and add it to the PATH, if it exists.
if command -v python3 >/dev/null 2>&1; then
  # Use Python's built-in `site` module to find the user's install base.
  PYTHON_USER_BIN="$(python3 -m site --user-base)/bin"
  
  # Check if the directory exists before adding it to avoid clutter.
  if [ -d "$PYTHON_USER_BIN" ]; then
    export PATH="$PYTHON_USER_BIN:$PATH"
  fi
fi

# Personal scripts.
export PATH="$HOME/.local/bin:$PATH"

# Personal projects.
export GREG_PROJECTS_PATH=~/greg_projects

# Personal dotfiles. 
export GREG_DOTFILES_PATH=$GREG_PROJECTS_PATH/dotfiles

# Alacritty config location.
export ALACRITTY_PATH=~/.config/alacritty
