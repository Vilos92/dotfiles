#!/bin/sh

prompt_and_install() {
  local message="$1"
  local install_command="$2"
  read -p "Do you want to install $message? (y/n): " answer
  case "$answer" in
    [Yy]* )
      echo "Executing: $install_command";
      eval "$install_command";
      ;;
    [Nn]* )
      echo "Skipped installing $message.";
      ;;
    * )
      echo "Please answer yes or no.";
      exit 1;
      ;;
  esac
}

# Homebrew
prompt_and_install "homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Alt tab window manager
prompt_and_install "alt-tab" 'brew install --cask alt-tab'

# Tiles snapping window manager 
prompt_and_install "tiles" 'brew install --cask tiles'

# Terminal
prompt_and_install "alacritty" 'brew install --cask alacritty'

# Developer environment packages
prompt_and_install "dev packages" 'brew install tmux zsh neovim stow ripgrep lua-language-server font-meslo-lg-nerd-font'

# oh my zsh
prompt_and_install "oh my zsh" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# Powerlevel10k oh my zsh theme
prompt_and_install "powerlevel10k" 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k'

# Browser
prompt_and_install "arc" 'brew install --cask arc'

# Notes
prompt_and_install "notion" 'brew install --cask notion'

# Music
prompt_and_install "spotify" 'brew install --cask spotify'

# Archive manager
prompt_and_install "keka" 'brew install --cask keka'

# Photo editor
prompt_and_install "gimp" 'brew install --cask gimp'

# Visual Studio Code
prompt_and_install "visual studio code" 'brew install --cask visual-studio-code@insiders'

# Text editor
prompt_and_install "coteditor" 'brew install --cask coteditor'

# Database manager
prompt_and_install "dbeaver" 'brew install --cask dbeaver-community'

# Gif recorder
prompt_and_install "gifox" 'brew install --cask gifox'
