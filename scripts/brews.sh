#!/bin/sh

prompt_and_install() {
  message="$1"
  install_command="$2"

  printf "Do you want to install %s? (y/n): " "$message"
  read -r answer

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

# Dotfile packages.
install_dotfile_packages() {
  # stow is needed to link dotfiles.
  prompt_and_install "stow" 'brew install stow'

  # brew is needed for MacOS package installations.
  prompt_and_install "homebrew" "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
}

# Alt tab window manager.
install_alt_tab() {
  prompt_and_install "alt-tab" 'brew install --cask alt-tab'
}

# Tiles snapping window manager.
install_tiles() {
  prompt_and_install "tiles" 'brew install --cask tiles'
}

# Terminal environment.
install_terminal_packages() {
  # Alacritty.
  prompt_and_install "alacritty" 'brew install --cask alacritty'

  # Tmux.
  prompt_and_install "tmux" 'brew install tmux'

  # zsh.
  prompt_and_install "zsh" 'brew install zsh'
  prompt_and_install "oh my zsh" "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  prompt_and_install "powerlevel10k" 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k'
}

# Developer environment.
install_dev_packages() {
  prompt_and_install "dev packages" 'brew install neovim\
    font-meslo-lg-nerd-font\
    stow\
    ripgrep\
    fzf\
    bat\
    fd\
    eza\
    zoxide\
    tealdeer\
    shellcheck'
}

# Docker.
install_docker_packages() {
  prompt_and_install "docker" 'brew install --cask docker'
  prompt_and_install "lazydocker" 'brew install lazydocker'
}

# lua packages.
install_lua_packages() {
  prompt_and_install "lua packages" 'brew install lua-language-server\
    stylua'
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
install_audio_packages() {
  prompt_and_install "spotify" 'brew install --cask spotify'
  prompt_and_install "nowplaying-cli" 'brew install nowplaying-cli'
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
    "dotfile-pkgs" )
      install_dotfile_packages
      ;;
    "alt-tab" )
      install_alt_tab
      ;;
    "tiles" )
      install_tiles
      ;;
    "terminal-pkgs" )
      install_terminal_packages
      ;;
    "dev-pkgs" )
      install_dev_packages
      ;;
    "docker-pkgs" )
      install_docker_packages
      ;;
    "lua-pkgs" )
      install_lua_packages
      ;;
    "javascript-pkgs" )
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
    "audio-pkgs" )
      install_audio_packages
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
  install_dotfile_packages
  install_alt_tab
  install_tiles
  install_terminal_packages
  install_dev_packages
  install_docker_packages
  install_lua_packages
  install_javascript_packages
  install_gleam
  install_arc
  install_notion
  install_audio_packages
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
  handle_arguments "$1"
fi
