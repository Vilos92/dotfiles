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

# ForkLift file manager.
install_forklift() {
  prompt_and_install "forklift" 'brew install --cask forklift'
}


# Better Display for scalable displays.
install_better_display() {
  prompt_and_install "better-display" 'brew install --cask betterdisplay'
}

# Window management packages (alt-tab).
install_window_management_packages() {
  prompt_and_install "alt-tab" 'brew install --cask alt-tab'
}

# Mouse packages.
install_mouse_packages() {
  prompt_and_install "mos" 'brew install mos'
  prompt_and_install "sensible-side-buttons" 'brew install --cask sensiblesidebuttons'
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

# Password manager.
install_1password() {
  prompt_and_install "1password" 'brew install --cask 1password'
}

# VPN
install_tailscale() {
  prompt_and_install "tailscale" 'brew install tailscale'
  prompt_and_install "tailscale-app" 'brew install --cask tailscale-app'
}

# Hosting.
install_host_packages() {
  # install cloudflared to allow exposing the copyparty instance.
  prompt_and_install "cloudflared" 'brew install cloudflared'

  # install copy party so it's available to use directly via calling 'copyparty'.
  prompt_and_install "copyparty" 'pip3 install --user copyparty'

  # install plex media server to stream my content to my devices.
  prompt_and_install "plex-server" 'brew install --cask plex-media-server'
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

# Python development tools.
install_python_dev_packages() {
  prompt_and_install "pipx" 'brew install pipx'
  prompt_and_install "black" 'pipx install black'
  prompt_and_install "ruff" 'pipx install ruff'
  prompt_and_install "mypy" 'pipx install mypy'
}

# JavaScript/Node.js developement.
install_javascript_packages() {
  prompt_and_install "JavaScript packages" 'brew install fnm\
      oven-sh/bun/bun\
      pnpm\
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

# Browsers.
install_browsers() {
  prompt_and_install "zen browser" 'brew install --cask zen'
  prompt_and_install "firefox" 'brew install --cask firefox'
}

# Alfred.
install_alfred() {
  prompt_and_install "alfred" 'brew install --cask alfred'
}

# Notes.
install_notion() {
  prompt_and_install "notion" 'brew install --cask notion'
}

# Music.
install_audio_packages() {
  prompt_and_install "pillow" 'brew install pillow'
  prompt_and_install "vlc" 'brew install --cask vlc'
  prompt_and_install "spotify" 'brew install --cask spotify'
}

# Audio engineering.
install_audio_engineering_packages() {
  prompt_and_install "audacity" 'brew install --cask audacity'
  prompt_and_install "ableton" 'brew install --cask ableton-live-suite'
  prompt_and_install "xld" 'brew install --cask xld'
}

# Video engineering.
install_video_engineering_packages() {
  prompt_and_install "ffmpeg" 'brew install ffmpeg'
  prompt_and_install "handbrake" 'brew install handbrake'
}

# Archive manager.
install_keka() {
  prompt_and_install "keka" 'brew install --cask keka'
}

# Photo editor.
install_gimp() {
  prompt_and_install "gimp" 'brew install --cask gimp'
}

# Coding packages.
install_coding_packages() {
  prompt_and_install "visual studio code" 'brew install --cask visual-studio-code'
  prompt_and_install "cursor" 'brew install --cask cursor'
  prompt_and_install "cursor-cli" 'brew install --cask cursor-cli'
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

# yt-dlp.
install_yt_dlp() {
  prompt_and_install "yt-dlp" 'brew install yt-dlp'
}

# Chat
install_chats() {
  prompt_and_install "whatsapp" 'brew install --cask whatsapp'
  prompt_and_install "slack" 'brew install --cask slack'
  prompt_and_install "discord" 'brew install --cask discord'
}

# Install AI packages.
install_ai_packages() {
  prompt_and_install "llama.cpp" 'brew install llama.cpp'
  prompt_and_install "draw-things" 'brew install --cask draw-things'
}

# Install Kiwix for offline Wikipedia access.
install_kiwix() {
  prompt_and_install "kiwix" 'brew install --cask kiwix'
}

# Install gaming packages.
install_gaming_packages() {
  prompt_and_install "openemu" 'brew install --cask openemu'
  prompt_and_install "mame" 'brew install mame'
}

handle_arguments() {
  case $1 in
    "dotfile-pkgs" )
      install_dotfile_packages
      ;;
    "forklift" )
      install_forklift
      ;;
    "better-display" )
      install_better_display
      ;;
    "window-mgmt-pkgs" )
      install_window_management_packages
      ;;
    "mouse-pkgs" )
      install_mouse_packages
      ;;
    "terminal-pkgs" )
      install_terminal_packages
      ;;
    "1password" )
      install_1password
      ;;
    "tailscale" )
      install_tailscale
      ;;
    "host" )
      install_host_packages
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
    "browsers" )
      install_browsers
      ;;
    "alfred" )
      install_alfred
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
    "video-engineering-pkgs" )
      install_video_engineering_packages
      ;;
    "keka" )
      install_keka
      ;;
    "gimp" )
      install_gimp
      ;;
    "coding-pkgs" )
      install_coding_packages
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
    "yt-dlp" )
      install_yt_dlp
      ;;
    "chats" )
      install_chats
      ;;
    "ai-pkgs" )
      install_ai_packages
      ;;

    "python-dev-pkgs" )
      install_python_dev_packages
      ;;
    "kiwix" )
      install_kiwix
      ;;
    "gaming-pkgs" )
      install_gaming_packages
      ;;
    * )
      echo "Invalid argument: $1"
      echo "Available options:"
      echo "  dotfile-pkgs     - stow for dotfile management"
      echo "  better-display   - BetterDisplay for scalable displays"
      echo "  window-mgmt-pkgs - Window management tools (alt-tab)"
      echo "  mouse-pkgs       - mouse management tools"
      echo "  terminal-pkgs    - terminal emulator and shell tools"
      echo "  1password       - 1Password password manager"
      echo "  host             - hosting and server tools"
      echo "  dev-pkgs         - development tools and utilities"
      echo "  gh               - GitHub CLI"
      echo "  docker-pkgs      - Docker and related tools"
      echo "  lua-pkgs         - Lua development tools"
      echo "  javascript-pkgs  - Node.js and JavaScript tools"
      echo "  gleam            - Gleam programming language"
      echo "  browsers         - Zen, Firefox, and Browserosaurus browsers"
      echo "  alfred           - Alfred productivity launcher"
      echo "  notion           - Notion note-taking app"
      echo "  audio-pkgs       - audio and video utilities"
      echo "  audio-engineering-pkgs - audio engineering tools"
      echo "  video-engineering-pkgs - video engineering tools"
      echo "  keka             - Keka archive manager"
      echo "  gimp             - GIMP image editor"
      echo "  coding-pkgs      - code editors and IDEs"
      echo "  coteditor        - CotEditor text editor"
      echo "  dbeaver          - DBeaver database manager"
      echo "  gifox            - Gifox screen recorder"
      echo "  there            - There timezone app"
      echo "  transmission     - Transmission torrent client"
      echo "  yt-dlp           - yt-dlp video downloader"
      echo "  chats            - chat applications"
      echo "  ai-pkgs          - AI and machine learning tools"

      echo "  python-dev-pkgs  - Python development tools (black, ruff, mypy)"
      echo "  kiwix            - Kiwix offline Wikipedia"
      echo "  gaming-pkgs      - gaming tools"
      exit 1
      ;;
  esac
}

install_everything() {
  install_dotfile_packages
  install_forklift
  install_better_display
  install_window_management_packages
  install_mouse_packages
  install_terminal_packages
  install_1password
  install_tailscale
  install_host_packages
  install_dev_packages
  install_gh
  install_docker_packages
  install_lua_packages
  install_javascript_packages
  install_gleam
  install_browsers
  install_notion
  install_audio_packages
  install_audio_engineering_packages
  install_video_engineering_packages
  install_keka
  install_gimp
  install_coding_packages
  install_coteditor
  install_dbeaver
  install_gifox
  install_there
  install_transmission
  install_yt_dlp
  install_chats
  install_ai_packages

  install_python_dev_packages
  install_kiwix
  install_gaming_packages
}

if [ "$#" -eq 0 ]; then
  install_everything
else
  handle_arguments "$1"
fi
