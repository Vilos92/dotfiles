#!/bin/sh

# Check if running on Arch Linux.
if ! command -v pacman &> /dev/null; then
  echo "Error: This script is designed for Arch Linux systems with pacman package manager."
  exit 1
fi

# Check if running as root (required for pacman).
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)"
  echo "Note: yay installation should be done separately as a non-root user"
  exit 1
fi

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

# Package manager setup.
install_package_manager() {
  # Install yay for AUR packages (must be done as non-root user).
  echo "Note: yay installation requires running as a non-root user."
  echo "Please install yay manually with:"
  echo "  pacman -S --needed git base-devel"
  echo "  git clone https://aur.archlinux.org/yay.git"
  echo "  cd yay && makepkg -si --noconfirm"
  echo "  cd .. && rm -rf yay"
  echo ""
  echo "Or use: yay -S yay"
  echo ""
}

# Dotfile packages.
install_dotfile_packages() {
  # stow is needed to link dotfiles.
  prompt_and_install "stow" 'pacman -S stow'
}

# Terminal environment.
install_terminal_packages() {
  # Alacritty.
  prompt_and_install "alacritty" 'pacman -S alacritty'

  # Tmux.
  prompt_and_install "tmux" 'pacman -S tmux'

  # zsh.
  prompt_and_install "zsh" 'pacman -S zsh'
  # prompt_and_install "oh my zsh" "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
  prompt_and_install "powerlevel10k" 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k'

  # Neofetch.
  # prompt_and_install "neofetch" 'pacman -S neofetch'
}

# Developer environment.
install_dev_packages() {
  prompt_and_install "dev packages" 'pacman -S neovim\
    ttf-meslo-nerd-font-powerlevel10k\
    stow\
    ripgrep\
    fzf\
    bat\
    fd\
    eza\
    zoxide\
    tealdeer\
    shellcheck\
    git\
    base-devel'
}

# GitHub CLI.
install_gh() {
  prompt_and_install "gh" 'pacman -S github-cli'
}

# Docker.
install_docker_packages() {
  prompt_and_install "docker" 'pacman -S docker docker-compose'
  # prompt_and_install "lazydocker" 'yay -S lazydocker'
}

# lua packages.
install_lua_packages() {
  prompt_and_install "lua packages" 'pacman -S lua\
    lua-language-server\
    luarocks\
    stylua'
}

# JavaScript/Node.js development.
install_javascript_packages() {
  prompt_and_install "JavaScript packages" 'pacman -S nodejs npm &&\
    npm install -g fnm &&\
    fnm install 22 &&\
    npm install -g eslint_d\
      typescript-language-server\
      typescript'
}

# Go development.
install_go_packages() {
  prompt_and_install "go" 'pacman -S go'
  prompt_and_install "gopls" 'pacman -S gopls'
}

# Rust development.
install_rust_packages() {
  prompt_and_install "rust" 'pacman -S rust'
  prompt_and_install "rust-analyzer" 'pacman -S rust-analyzer'
}

# Python development.
install_python_packages() {
  prompt_and_install "python packages" 'pacman -S python python-pip\
    python-lsp-server\
    flake8'
}

# Utilities.
install_utility_packages() {
  prompt_and_install "utility packages" 'pacman -S ffmpeg\
    vlc\
    transmission-gtk\
    yt-dlp\
    unzip\
    zip\
    wget\
    curl\
    htop\
    tree\
    jq\
    yq'
}

# Music.
install_music_packages() {
  # prompt_and_install "spotify" 'yay -S spotify'
  prompt_and_install "mpv" 'pacman -S mpv'
  prompt_and_install "pulseaudio" 'pacman -S pulseaudio pulseaudio-alsa'
}

# Editors and IDEs.
install_editor_packages() {
  # prompt_and_install "visual studio code" 'yay -S visual-studio-code-bin'
  # prompt_and_install "cursor" 'yay -S cursor-bin'
  prompt_and_install "vim" 'pacman -S vim'
  prompt_and_install "emacs" 'pacman -S emacs'
}

# Database tools.
install_database_packages() {
  # prompt_and_install "dbeaver" 'yay -S dbeaver'
  prompt_and_install "postgresql" 'pacman -S postgresql'
  prompt_and_install "sqlite" 'pacman -S sqlite'
}

# Chat applications.
install_chat_packages() {
  # prompt_and_install "whatsapp" 'yay -S whatsapp-for-linux'
  # prompt_and_install "slack" 'yay -S slack-desktop'
  prompt_and_install "discord" 'pacman -S discord'
}

# AI and ML tools.
install_ai_packages() {
  # prompt_and_install "llama.cpp" 'yay -S llama-cpp'
  # prompt_and_install "ollama" 'yay -S ollama'
}

# System tools.
install_system_packages() {
  prompt_and_install "gimp" 'pacman -S gimp'
}



handle_arguments() {
  case $1 in
    "package-manager" )
      install_package_manager
      ;;
    "dotfile-pkgs" )
      install_dotfile_packages
      ;;
    "terminal-pkgs" )
      install_terminal_packages
      ;;
    "dev-pkgs" )
      install_dev_packages
      ;;
    "gh" )
      install_gh
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
    "go-pkgs" )
      install_go_packages
      ;;
    "rust-pkgs" )
      install_rust_packages
      ;;
    "python-pkgs" )
      install_python_packages
      ;;
    "utility-pkgs" )
      install_utility_packages
      ;;
    "music-pkgs" )
      install_music_packages
      ;;
    "editor-pkgs" )
      install_editor_packages
      ;;
    "database-pkgs" )
      install_database_packages
      ;;
    "chat-pkgs" )
      install_chat_packages
      ;;
    "ai-pkgs" )
      install_ai_packages
      ;;
    "system-pkgs" )
      install_system_packages
      ;;

    * )
      echo "Invalid argument: $1"
      echo "Available options:"
      echo "  package-manager  - install yay AUR helper"
      echo "  dotfile-pkgs     - stow for dotfile management"
      echo "  terminal-pkgs    - terminal emulator and shell tools"
      echo "  dev-pkgs         - development tools and utilities"
      echo "  gh               - GitHub CLI"
      echo "  docker-pkgs      - Docker and related tools"
      echo "  lua-pkgs         - Lua development tools"
      echo "  javascript-pkgs  - Node.js and JavaScript tools"
      echo "  go-pkgs          - Go development tools"
      echo "  rust-pkgs        - Rust development tools"
      echo "  python-pkgs      - Python development tools"
      echo "  utility-pkgs     - general utilities (ffmpeg, vlc, etc.)"
      echo "  music-pkgs       - music applications"
      echo "  editor-pkgs      - text editors and IDEs"
      echo "  database-pkgs    - database tools"
      echo "  chat-pkgs        - chat applications"
      echo "  ai-pkgs          - AI and machine learning tools"
      echo "  system-pkgs      - system applications"

      exit 1
      ;;
  esac
}

install_everything() {
  install_package_manager
  install_dotfile_packages
  install_terminal_packages
  install_dev_packages
  install_gh
  install_docker_packages
  install_lua_packages
  install_javascript_packages
  install_go_packages
  install_rust_packages
  install_python_packages
  install_utility_packages
  install_music_packages
  install_editor_packages
  install_database_packages
  install_chat_packages
  install_ai_packages
  install_system_packages
}

if [ "$#" -eq 0 ]; then
  install_everything
else
  handle_arguments "$1"
fi
