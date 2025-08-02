#!/bin/sh

if ! command -v stow > /dev/null 2>&1
then
  echo "stow could not be found, please run brews.sh"
  exit 1
fi

stow_dir="$(dirname "$(dirname "$0")")"

prompt_and_stow() {
  package="$1"

  printf "Do you want to stow %s? (y/n): " "$package"
  read -r answer

  case "$answer" in
    [Yy]* )
      stow -d "$stow_dir" -t ~/ "$package" &&
      echo "Successfully stowed $package.";
      ;;
    * )
      echo "Skipped stowing $package.";
      ;;
  esac
}

# If user passed a package name, only stow that package.
if [ "$#" -eq 1 ]; then
  prompt_and_stow "$1"
  exit 0
fi

prompt_and_stow alacritty
prompt_and_stow tmux
prompt_and_stow zsh
prompt_and_stow nvim
prompt_and_stow vim
prompt_and_stow git

# Mac Mini specific dotfiles.
prompt_and_stow mac-mini

# Submodules for private dotfiles.
prompt_and_stow front
