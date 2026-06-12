#!/bin/sh

# Get the Python 3 bin directory and add it to the PATH, if it exists.
# Cached: python3 -m site is a subprocess and costs ~1s+ on every shell otherwise.
if command -v python3 >/dev/null 2>&1; then
  _python_user_bin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/python-user-bin.path"
  if [ -f "$_python_user_bin_cache" ]; then
    PYTHON_USER_BIN=$(cat "$_python_user_bin_cache")
  else
    PYTHON_USER_BIN="$(python3 -m site --user-base)/bin"
    mkdir -p "${_python_user_bin_cache%/*}"
    printf '%s' "$PYTHON_USER_BIN" > "$_python_user_bin_cache"
  fi

  if [ -d "$PYTHON_USER_BIN" ]; then
    export PATH="$PYTHON_USER_BIN:$PATH"
  fi
  unset _python_user_bin_cache
fi

# Personal scripts.
export PATH="$HOME/.local/bin:$PATH"

# Personal projects.
export GREG_PROJECTS_PATH=~/greg_projects

# Personal dotfiles. 
export GREG_DOTFILES_PATH=$GREG_PROJECTS_PATH/dotfiles

# Alacritty config location.
export ALACRITTY_PATH=~/.config/alacritty
