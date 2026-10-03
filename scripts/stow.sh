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
      # omp keeps sessions and credentials in ~/.omp. With ~/.omp/agent already
      # present, stow links only the rules/ and agents/ folders. Without it,
      # stow folds all of ~/.omp into a symlink to this repo.
      if [ "$package" = omp ]; then
        mkdir -p ~/.omp/agent
      fi
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

# Dot files related to connecting to remote servers.
prompt_and_stow remote

# Mac productivity configurations.
prompt_and_stow mac-productivity

# Mac Mini specific dotfiles.
prompt_and_stow mac-mini

# Arch specific dotfiles.
prompt_and_stow arch

# dex task tracking for agents.
prompt_and_stow dex

# Claude Code CLAUDE.md, skills, commands, agents, rules and hooks (stow everywhere).
prompt_and_stow claude-md

# omp (Oh My Pi) agents and rules. The rules are symlinks into claude-md/.
prompt_and_stow omp

# Claude Code base settings (stow on non-front machines; front has its own superset).
prompt_and_stow claude-settings

# Cursor user config.
prompt_and_stow cursor

# Submodules for private dotfiles.
prompt_and_stow front
