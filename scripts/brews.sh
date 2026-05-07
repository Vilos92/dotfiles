#!/usr/bin/env bash

set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo >> "$HOME/.zprofile"
  # shellcheck disable=SC2016
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

prompt_and_install() {
  local message="$1"
  shift

  printf "Do you want to install %s? (y/n): " "$message"
  local answer
  read -r answer

  case "$answer" in
    [Yy]* )
      echo "Executing: $*"
      "$@"
      ;;
    [Nn]* )
      echo "Skipped installing $message."
      ;;
    * )
      echo "Please answer yes or no."
      return 1
      ;;
  esac
}

prompt_and_install_shell() {
  local message="$1"
  local install_command="$2"

  printf "Do you want to install %s? (y/n): " "$message"
  local answer
  read -r answer

  case "$answer" in
    [Yy]* )
      echo "Executing: $install_command"
      /usr/bin/env bash -lc "$install_command"
      ;;
    [Nn]* )
      echo "Skipped installing $message."
      ;;
    * )
      echo "Please answer yes or no."
      return 1
      ;;
  esac
}

# Dotfile packages.
install_dotfile_packages() {
  # stow is needed to link dotfiles.
  prompt_and_install "stow" brew install stow
}

# ForkLift file manager.
install_forklift() {
  prompt_and_install "forklift" brew install --cask forklift
}


# Better Display for scalable displays.
install_better_display() {
  prompt_and_install "better-display" brew install --cask betterdisplay
}

# Window management packages (alt-tab).
install_window_management_packages() {
  prompt_and_install "alt-tab" brew install --cask alt-tab
}

# Mouse packages.
install_mouse_packages() {
  prompt_and_install "mos" brew install mos
  prompt_and_install "sensible-side-buttons" brew install --cask sensiblesidebuttons
}

# Terminal environment.
install_terminal_packages() {
  # Alacritty.
  prompt_and_install "alacritty" brew install --cask alacritty

  # Tmux.
  prompt_and_install "tmux" brew install tmux

  # zsh.
  prompt_and_install "zsh" brew install zsh
  # shellcheck disable=SC2016
  prompt_and_install_shell "oh my zsh" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  prompt_and_install "powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"

  # Neofetch.
  prompt_and_install "neofetch" brew install neofetch
}

# Password manager.
install_1password() {
  prompt_and_install "1password" brew install --cask 1password
}

# VPN
install_tailscale() {
  prompt_and_install "tailscale" brew install tailscale
  prompt_and_install "tailscale-app" brew install --cask tailscale-app
}

# Hosting.
install_host_packages() {
  # install cloudflared to allow exposing the copyparty instance.
  prompt_and_install "cloudflared" brew install cloudflared

  # install copy party so it's available to use directly via calling 'copyparty'.
  prompt_and_install_shell "copyparty" 'command -v python3 >/dev/null || { echo "python3 not found (install it first)"; exit 1; }; python3 -m pip install --user copyparty'

  # install plex media server to stream my content to my devices.
  prompt_and_install "plex-server" brew install --cask plex-media-server
}

# Rclone.
install_rclone() {
  prompt_and_install "rclone" brew install rclone
}

# Cloud storage.
install_cloud_storage() {
  prompt_and_install "google drive" brew install --cask google-drive
}

# Developer environment.
install_dev_packages() {
  prompt_and_install "dev packages" brew install \
    neovim \
    tree-sitter-cli \
    font-meslo-lg-nerd-font \
    stow \
    ripgrep \
    fzf \
    bat \
    fd \
    eza \
    zoxide \
    tealdeer \
    wget \
    shellcheck
}

# Agent-oriented CLIs (Dex: ~/.bun/bin on PATH via zsh when ~/.zshrc runs javascript.sh).
install_agent_dev_tools() {
  # dmtrKovalenko/fff — MCP server + CLI for indexed ripgrep-style search.
  prompt_and_install_shell "fff (MCP file search)" \
    'curl -fsSL https://raw.githubusercontent.com/dmtrKovalenko/fff/main/install-mcp.sh | bash'

  # @zeeg/dex - global CLI for agent workflows.
  prompt_and_install "Dex CLI (@zeeg/dex)" bun add -g @zeeg/dex
}

# GitHub CLI.
install_gh() {
  prompt_and_install "gh" brew install gh
}

# Docker.
install_docker_packages() {
  prompt_and_install "docker" brew install --cask docker
  prompt_and_install "lazydocker" brew install lazydocker
}

# lua packages.
install_lua_packages() {
  prompt_and_install "lua packages" brew install \
    lua \
    lua-language-server \
    luarocks \
    stylua
  prompt_and_install "jsregexp" sudo luarocks install jsregexp
}

# Python development tools.
install_python_dev_packages() {
  prompt_and_install "pipx" brew install pipx
  prompt_and_install "black" pipx install black
  prompt_and_install "ruff" pipx install ruff
  prompt_and_install "mypy" pipx install mypy
}

# JavaScript/Node.js developement.
install_javascript_packages() {
  prompt_and_install_shell "JavaScript packages" 'brew install fnm oven-sh/bun/bun pnpm fsouza/prettierd/prettierd && fnm install 22 && npm install -g eslint_d typescript-language-server typescript'
}

# Gleam.
install_gleam() {
  prompt_and_install "gleam" brew install gleam
}

# Browsers.
install_browsers() {
  prompt_and_install "zen browser" brew install --cask zen
  prompt_and_install "firefox" brew install --cask firefox
}

# Alfred.
install_alfred() {
  prompt_and_install "alfred" brew install --cask alfred
}

# Notes.
install_notion() {
  prompt_and_install "notion" brew install --cask notion
}

# Music.
install_audio_packages() {
  prompt_and_install "pillow" brew install pillow
  prompt_and_install "vlc" brew install --cask vlc
  prompt_and_install "spotify" brew install --cask spotify
}

# Audio engineering.
install_audio_engineering_packages() {
  prompt_and_install "audacity" brew install --cask audacity
  prompt_and_install "ableton" brew install --cask ableton-live-suite
  prompt_and_install "xld" brew install --cask xld
  prompt_and_install "musicbrainz-picard" brew install --cask musicbrainz-picard
}

# Video engineering.
install_video_engineering_packages() {
  prompt_and_install "ffmpeg" brew install ffmpeg
  prompt_and_install "handbrake" brew install handbrake
}

# Archive manager.
install_keka() {
  prompt_and_install "keka" brew install --cask keka
}

# Photo editor.
install_gimp() {
  prompt_and_install "gimp" brew install --cask gimp
}

# Coding packages.
install_coding_packages() {
  prompt_and_install "visual studio code" brew install --cask visual-studio-code
  prompt_and_install "cursor" brew install --cask cursor
  prompt_and_install "cursor-cli" brew install --cask cursor-cli
  prompt_and_install "claude" brew install --cask claude
  prompt_and_install "claude-code" brew install --cask claude-code
}

# Text editor.
install_coteditor() {
  prompt_and_install "coteditor" brew install --cask coteditor
}

# Database manager.
install_dbeaver() {
  prompt_and_install "dbeaver" brew install --cask dbeaver-community
}

# Gif recorder.
install_gifox() {
  prompt_and_install "gifox" brew install --cask gifox
}

# Timezone data for friends + family.
install_there() {
  prompt_and_install "there" brew install --cask there
}

# Transmission.
install_transmission() {
  prompt_and_install "transmission" brew install --cask transmission
}

# yt-dlp.
install_yt_dlp() {
  prompt_and_install "yt-dlp" brew install yt-dlp
}

# Desktop widgets.
install_desktop_widgets() {
  prompt_and_install "ubersicht" brew install --cask ubersicht
}

# Chat
install_chats() {
  prompt_and_install "whatsapp" brew install --cask whatsapp
  prompt_and_install "slack" brew install --cask slack
  prompt_and_install "discord" brew install --cask discord
}

# Install AI packages.
install_ai_packages() {
  prompt_and_install "llama.cpp" brew install llama.cpp
  prompt_and_install "draw-things" brew install --cask draw-things
}

# Install Kiwix for offline Wikipedia access.
install_kiwix() {
  prompt_and_install "kiwix" brew install --cask kiwix
}

# Install gaming packages.
install_gaming_packages() {
  prompt_and_install "openemu" brew install --cask openemu
  prompt_and_install "mame" brew install mame
}

TASKS=(
  "dotfile-pkgs|stow for dotfile management|install_dotfile_packages"
  "forklift|ForkLift file manager|install_forklift"
  "better-display|BetterDisplay for scalable displays|install_better_display"
  "window-mgmt-pkgs|Window management tools (alt-tab)|install_window_management_packages"
  "mouse-pkgs|mouse management tools|install_mouse_packages"
  "terminal-pkgs|terminal emulator and shell tools|install_terminal_packages"
  "1password|1Password password manager|install_1password"
  "tailscale|Tailscale VPN|install_tailscale"
  "host|hosting and server tools|install_host_packages"
  "rclone|rclone|install_rclone"
  "cloud-storage|cloud storage apps|install_cloud_storage"
  "dev-pkgs|development tools and utilities|install_dev_packages"
  "agent-dev-tools|Agent CLIs: FFF MCP search + Dex CLI|install_agent_dev_tools"
  "gh|GitHub CLI|install_gh"
  "docker-pkgs|Docker and related tools|install_docker_packages"
  "lua-pkgs|Lua development tools|install_lua_packages"
  "javascript-pkgs|Node.js and JavaScript tools|install_javascript_packages"
  "gleam|Gleam programming language|install_gleam"
  "browsers|Zen + Firefox browsers|install_browsers"
  "alfred|Alfred productivity launcher|install_alfred"
  "notion|Notion note-taking app|install_notion"
  "audio-pkgs|audio and video utilities|install_audio_packages"
  "audio-engineering-pkgs|audio engineering tools|install_audio_engineering_packages"
  "video-engineering-pkgs|video engineering tools|install_video_engineering_packages"
  "keka|Keka archive manager|install_keka"
  "gimp|GIMP image editor|install_gimp"
  "coding-pkgs|code editors and IDEs|install_coding_packages"
  "coteditor|CotEditor text editor|install_coteditor"
  "dbeaver|DBeaver database manager|install_dbeaver"
  "gifox|Gifox screen recorder|install_gifox"
  "there|There timezone app|install_there"
  "transmission|Transmission torrent client|install_transmission"
  "yt-dlp|yt-dlp video downloader|install_yt_dlp"
  "desktop-widgets|Übersicht desktop widgets|install_desktop_widgets"
  "chats|chat applications|install_chats"
  "ai-pkgs|AI and machine learning tools|install_ai_packages"
  "python-dev-pkgs|Python development tools (black, ruff, mypy)|install_python_dev_packages"
  "kiwix|Kiwix offline Wikipedia|install_kiwix"
  "gaming-pkgs|gaming tools|install_gaming_packages"
)

usage() {
  echo "Usage: $0 [task]"
  echo
  echo "Available tasks:"
  local entry key desc fn
  for entry in "${TASKS[@]}"; do
    IFS="|" read -r key desc fn <<<"$entry"
    printf "  %-18s - %s\n" "$key" "$desc"
  done
}

run_task() {
  local requested="$1"
  local entry key desc fn

  for entry in "${TASKS[@]}"; do
    IFS="|" read -r key desc fn <<<"$entry"
    if [[ "$key" == "$requested" ]]; then
      "$fn"
      return 0
    fi
  done

  echo "Invalid argument: $requested"
  echo
  usage
  exit 1
}

install_everything() {
  local entry key desc fn
  for entry in "${TASKS[@]}"; do
    IFS="|" read -r key desc fn <<<"$entry"
    "$fn"
  done
}

if [ "$#" -eq 0 ]; then
  install_everything
else
  run_task "$1"
fi
