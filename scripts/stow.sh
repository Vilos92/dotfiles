#!/bin/sh

if ! command -v stow &> /dev/null
then
  echo "stow could not be found, please run brews.sh"
  exit 1
fi

stow_dir="$(dirname "$(dirname "$0")")"

prompt_and_stow() {
  local package="$1"
  read -p "Do you want to stow $package? (y/n): " answer
  case "$answer" in
    [Yy]* )
      stow -d $stow_dir -t ~/ "$package" &&
      echo "Successfully stowed $package.";
      ;;
    [Nn]* )
      echo "Skipped stowing $package.";
      ;;
    * )
      echo "Please answer yes or no.";
      exit 1;
      ;;
  esac
}

# If user passed a package name, only stow that package
if [ "$#" -eq 1 ]; then
  prompt_and_stow "$1"
  exit 0
fi

prompt_and_stow alacritty
prompt_and_stow nvim
prompt_and_stow tmux
prompt_and_stow vim
prompt_and_stow zsh

