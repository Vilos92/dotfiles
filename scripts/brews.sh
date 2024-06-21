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
      return 1;
      ;;
  esac
}

# Homebrew.
install_homebrew() {
  prompt_and_install "homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
}

# Alt tab window manager.
install_alt_tab() {
  prompt_and_install "alt-tab" 'brew install --cask alt-tab'
}

# Tiles snapping window manager.
install_tiles() {
  prompt_and_install "tiles" 'brew install --cask tiles'
}

# Terminal.
install_alacritty() {
  prompt_and_install "alacritty" 'brew install --cask alacritty'
}

# Developer environment packages.
install_dev_packages() {
  prompt_and_install "dev packages" 'brew install tmux\
    zsh\
    neovim\
    stow\
    ripgrep\
    lua-language-server\
    font-meslo-lg-nerd-font'
}

# oh my zsh.
install_oh_my_zsh() {
  prompt_and_install "oh my zsh" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
}

# Powerlevel10k oh my zsh theme.
install_powerlevel10k() {
  prompt_and_install "powerlevel10k" 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k'
}

# Packer for neovim package management.
install_packer_nvim() {
  prompt_and_install "packer.nvim" 'git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim'
}

# JavaScript/Node.js developement.
install_javascript_packages() {
  prompt_and_install "JavaScript packages" 'brew install fnm\
      oven-sh/bun/bun\
    fsouza/prettierd/prettierd &&
    fnm install 22 &&
    npm install -g eslint_d\
      typescript-language-server\
      typescript'
}

# Gleam.
install_gleam() {
  prompt_and_install "gleam" 'brew install gleam'
}

# Browser.
install_arc() {
  prompt_and_install "arc" 'brew install --cask arc'
}

# Notes.
install_notion() {
  prompt_and_install "notion" 'brew install --cask notion'
}

# Music.
install_spotify() {
  prompt_and_install "spotify" 'brew install --cask spotify'
}

# Archive manager.
install_keka() {
  prompt_and_install "keka" 'brew install --cask keka'
}

# Photo editor.
install_gimp() {
  prompt_and_install "gimp" 'brew install --cask gimp'
}

# Visual Studio Code.
install_vscode() {
  prompt_and_install "visual studio code" 'brew install --cask visual-studio-code@insiders'
}

# Text editor.
install_coteditor() {
  prompt_and_install "coteditor" 'brew install --cask coteditor'
}

# Database manager.
install_dbeaver() {
  prompt_and_install "dbeaver" 'brew install --cask dbeaver-community'
}

# Gif recorder.
install_gifox() {
  prompt_and_install "gifox" 'brew install --cask gifox'
}

handle_arguments() {
  case $1 in
    "homebrew" )
      install_homebrew
      ;;
    "alt-tab" )
      install_alt_tab
      ;;
    "tiles" )
      install_tiles
      ;;
    "alacritty" )
      install_alacritty
      ;;
    "dev-packages" )
      install_dev_packages
      ;;
    "oh-my-zsh" )
      install_oh_my_zsh
      ;;
    "powerlevel10k" )
      install_powerlevel10k
      ;;
    "packer-nvim" )
      install_packer_nvim
      ;;
    "javascript-packages" )
      install_javascript_packages
      ;;
    "gleam" )
      install_gleam
      ;;
    "arc" )
      install_arc
      ;;
    "notion" )
      install_notion
      ;;
    "spotify" )
      install_spotify
      ;;
    "keka" )
      install_keka
      ;;
    "gimp" )
      install_gimp
      ;;
    "vscode" )
      install_vscode
      ;;
    "coteditor" )
      install_coteditor
      ;;
    "dbeaver" )
      install_dbeaver
      ;;
    "gifox" )
      install_gifox
      ;;
    * )
      echo "Invalid argument: $1"
      exit 1
      ;;
  esac
}

install_everything() {
  install_homebrew
  install_alt_tab
  install_tiles
  install_alacritty
  install_dev_packages
  install_oh_my_zsh
  install_powerlevel10k
  install_packer_nvim
  install_javascript_packages
  install_gleam
  install_arc
  install_notion
  install_spotify
  install_keka
  install_gimp
  install_vscode
  install_coteditor
  install_dbeaver
  install_gifox
}

if [ "$#" -eq 0 ]; then
  install_everything
else
  handle_arguments $1
fi
