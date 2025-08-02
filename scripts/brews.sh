#!/bin/sh

if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo >> /Users/greg.linscheid/.zprofile
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/greg.linscheid/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
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

# Dotfile packages.
install_dotfile_packages() {
  # stow is needed to link dotfiles.
  prompt_and_install "stow" 'brew install stow'
}

# Alt tab window manager.
install_alt_tab() {
  prompt_and_install "alt-tab" 'brew install --cask alt-tab'
}

# Tiles snapping window manager.
install_tiles() {
  prompt_and_install "tiles" 'brew install --cask tiles'
}

# Smooth scrolling.
install_smooth_scroll() {
  prompt_and_install "mos" 'brew install mos'
}

# Terminal environment.
install_terminal_packages() {
  # Alacritty.
  prompt_and_install "alacritty" 'brew install --cask alacritty'

  # Tmux.
  prompt_and_install "tmux" 'brew install tmux'

  # zsh.
  prompt_and_install "zsh" 'brew install zsh'
  prompt_and_install "oh my zsh" "sh $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  prompt_and_install "powerlevel10k" 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k'

  # Neofetch.
  prompt_and_install "neofetch" 'brew install neofetch'
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

# GitHub CLI.
install_gh() {
  prompt_and_install "gh" 'brew install gh'
}

# Docker.
install_docker_packages() {
  prompt_and_install "docker" 'brew install --cask docker'
  prompt_and_install "lazydocker" 'brew install lazydocker'
}

# lua packages.
install_lua_packages() {
  prompt_and_install "lua packages" 'brew install lua\
    lua-language-server\
    luarocks\
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

# Browserosaurus.
install_browserosaurus() {
  prompt_and_install "browserosaurus" 'brew install --cask browserosaurus'
}

# Notes.
install_notion() {
  prompt_and_install "notion" 'brew install --cask notion'
}

# Music.
install_audio_packages() {
  prompt_and_install "ffmpeg" 'brew install pillow ffmpeg'
  prompt_and_install "vlc" 'brew install --cask vlc'
  prompt_and_install "spotify" 'brew install --cask spotify'
}

# Audio engineering.
install_audio_engineering_packages() {
  prompt_and_install "audacity" 'brew install --cask audacity'
  prompt_and_install "ableton" 'brew install --cask ableton-live-suite'
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
  prompt_and_install "visual studio code" 'brew install --cask visual-studio-code'
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

# Timezone data for friends + family.
install_there() {
  prompt_and_install "there" 'brew install --cask there'
}

# Transmission.
install_transmission() {
  prompt_and_install "transmission" 'brew install --cask transmission'
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
    "smooth-scroll" )
      install_smooth_scroll
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
    "gleam" )
      install_gleam
      ;;
    "browserosaurus" )
      install_browserosaurus
      ;;
    "notion" )
      install_notion
      ;;
    "audio-pkgs" )
      install_audio_packages
      ;;
    "audio-engineering-pkgs" )
      install_audio_engineering_packages
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
    "there" )
      install_there
      ;;
    "transmission" )
      install_transmission
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
  install_smooth_scroll
  install_terminal_packages
  install_dev_packages
  install_gh
  install_docker_packages
  install_lua_packages
  install_javascript_packages
  install_gleam
  install_browserosaurus
  install_notion
  install_audio_packages
  install_audio_engineering_packages
  install_keka
  install_gimp
  install_vscode
  install_coteditor
  install_dbeaver
  install_gifox
  install_there
  install_transmission
}

if [ "$#" -eq 0 ]; then
  install_everything
else
  handle_arguments "$1"
fi
