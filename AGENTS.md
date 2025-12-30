# Greg's Personal Environment Dotfiles

This is Greg's comprehensive personal environment setup for macOS, designed to work across multiple devices with machine-specific configurations where needed.

## Repository Structure

### Stow-Based Organization

This repository uses GNU Stow for dotfile management. Run `scripts/stow.sh` to interactively symlink configurations to your home directory.

**Stowable Directories:**

- `alacritty/` - Terminal emulator config
- `tmux/` - Terminal multiplexer config
- `zsh/` - Shell configuration and aliases
- `nvim/` - Neovim editor config
- `vim/` - Vim editor config
- `git/` - Git configuration
- `remote/` - Remote server connection configs
- `mac-mini/` - Mac Mini specific configurations
- `front/` - Work laptop specific configurations (symlinked submodule)

**Non-Stowable Directories:**

- `scripts/` - Standalone executable scripts
- `greg-zone/` - Docker infrastructure and services (separate repository, but this AGENTS.md is responsible for documenting it)
- `arch/` - Arch Linux specific configurations (currently empty)
- `mac-productivity/` - Mac productivity configurations (currently empty)

### Binary Commands

Each stowable directory can include a `.local/bin/` directory that gets symlinked to `~/.local/bin/` via stow:

**Available Commands:**

- **mac-mini:** `gbackup-lacie`, `gbackup-t7`, `gllama`
- **alacritty:** `alacritty-theme`, `alacritty-theme-select`
- **tmux:** `attach-tmux-session`, `gmux`
- **zsh:** `compress-video-hevc`, `download-media`, `fuzzy-find`, `fuzzy-ripgrep`, `remux-video`

## Available Commands & Shortcuts

### Key Aliases

**File Operations (eza-based):**

- `ls` → `eza --color=always --group-directories-first --icons=always`
- `ll` → detailed list with permissions and icons
- `la` → long format with all files
- `lt` → tree view (2 levels)
- `lx` → extended detailed view with git info

**Navigation & Search:**

- `cd` → `z` (zoxide smart directory jumping)
- `ff` → `fuzzy-find` (custom fuzzy finder)
- `frg` → `fuzzy-ripgrep` (fuzzy search file contents)
- `fh` → `fuzzy-history` (fuzzy command history)
- `falias` → fuzzy search and execute aliases

**Development:**

- `v` → `nvim`
- `vl` → `nvim -c "normal '0"` (edit last file)
- `vtmp` → temporary nvim buffer
- `voil` → nvim with Oil file manager
- `vconfig` → edit nvim config
- `vdotfiles` → edit this dotfiles repo
- `vzshrc` → edit zsh configs

**Tmux:**

- `g` → `gmux` (custom tmux session manager)
- `tmux-switch` → switch tmux session
- `tmux-kill` → kill tmux session

**Docker:**

- `lzd` → `lazydocker` (TUI for docker)

**Remote Access:**

- `ssh-sparkify` → SSH to Digital Ocean droplet
- `ssh-mini` → SSH to Mac Mini (requires Tailscale)

**Utilities:**

- `kt` → `alacritty-theme-select` (change terminal theme)

### Scripts (scripts/)

**Setup & Installation:**

- `brews.sh` - Install all homebrew packages and applications (macOS)
- `pacs.sh` - Install packages for Arch Linux systems
- `stow.sh` - Interactively stow dotfile configurations

**Code Quality:**

- `ruff.sh` - Python linting and formatting with ruff
- `stylua.sh` - Lua code formatting with stylua
- `shellcheck.sh` - Shell script linting with shellcheck
- `prettier.sh` - JavaScript/JSX code formatting with Prettier

## Docker Services (greg-zone/)

**Note:** The `greg-zone/` directory is a separate repository containing all Docker infrastructure and services. This AGENTS.md is responsible for documenting it as well.

### Service Management

All services are managed via `greg-zone/docker-services.sh`, which wraps docker-compose and provides:

- Unified service management (up, down, restart, logs, etc.)
- Prerequisite checking
- Service status and access information
- Comprehensive error handling

See `greg-zone/README.md` and `./docker-services.sh help` for full command reference.

### Service Overview

**Application Services:**

- **copyparty:** File sharing (port 3923/8080) - https://copyparty.greglinscheid.com
- **freshrss:** RSS reader (port 49153) - https://freshrss.greglinscheid.com
- **kiwix:** Offline content server (port 8473) - https://kiwix.greglinscheid.com
- **transmission:** Torrent client (port 9091)
- **minecraft:** Minecraft Bedrock server (port 19132/udp)

**Monitoring Stack:**

- **prometheus:** Metrics collection (port 9090)
- **grafana:** Dashboards and visualization (port 3000)
- **loki:** Log aggregation (port 3100)
- **promtail:** Log shipping
- **alertmanager:** Alert routing (port 9093)
- **node-exporter:** System metrics (port 9100)
- **cadvisor:** Container metrics (port 8080)
- **docker-stats-exporter:** Docker stats exporter (port 8081)
- **mc-monitor:** Minecraft server metrics (port 8082)

**Networking & Infrastructure:**

- **tailscale:** VPN mesh network
- **cloudflared:** Cloudflare tunnel for public access
- **nginx-tailscale:** Reverse proxy for Tailscale network
- **nginx-cloudflared:** Reverse proxy for Cloudflare tunnel

**Alerting & Webhooks:**

- **discord-webhook:** Discord webhook multiplexer (port 8083)
- **services-alert-monitor:** Monitors nginx, copyparty, freshrss, kiwix
- **infrastructure-alert-monitor:** Monitors loki, prometheus, grafana, etc.
- **minecraft-alert-monitor:** Monitors minecraft server

**Supporting Services:**

- **infra-redis:** Redis database for alert monitor state (port 6379)
- **infra-redis-commander:** Redis management UI (port 8084)
- **playit:** Minecraft server tunneling
- **minecraft-backup:** Automated Minecraft backups

### Service Dependencies

- External drive: `/Volumes/T7/Vaults` (required for copyparty, kiwix) - T7 is now the main data hub
- Wokyis M.2 SSD: `/Volumes/Wokyis M.2 SSD - Storage/Vaults` (required for copyparty, freshrss, transmission, minecraft)
  - GregZone Vault: Contains freshrss, transmission, minecraft data
  - Hobby Vault: Contains llm models and music production files
- Environment variables (in `greg-zone/.env`):
  - `COPYPARTY_CLOUDFLARED_TOKEN` (required for copyparty)
  - `TAILSCALE_AUTH_KEY` (required for Tailscale)
  - `TRANSMISSION_PASSWORD` (required for Transmission)
  - `GRAFANA_PASSWORD` (required for Grafana)
  - `DISCORD_*_WEBHOOK_URL` (various Discord webhooks)
  - `ALERT_MONITOR_SECRET` (required for alert monitors)
  - `INFRA_REDIS_PASSWORD` (required for Redis)
  - `PLAYIT_SECRET_KEY` (required for Playit)

## CLI Tools Available

### Modern Replacements

- `rg` (ripgrep) - faster grep
- `bat` - syntax-highlighted cat
- `fd` - faster find
- `eza` - modern ls with icons
- `zoxide` - smart cd with frecency
- `fzf` - fuzzy finder
- `tealdeer` - tldr for quick help

### Development Tools

- `neovim` - primary editor
- `tmux` - terminal multiplexer
- `docker` + `lazydocker` - container management
- `gh` - GitHub CLI
- Language support: Node.js (fnm), Lua, Gleam, TypeScript

### Media & Utilities

- `ffmpeg` - video/audio processing
- `yt-dlp` - video downloading
- `shellcheck` - shell script linting

### Code Quality Tools

- `ruff` - Python linting and formatting
- `stylua` - Lua code formatting
- `shellcheck` - Shell script linting
- `prettier` - JavaScript/JSX code formatting

## Development Workflow

### Approach

- **Iterative changes:** Small, incremental improvements
- **Extensive testing:** All configurations are actively used (dogfooding)
- **Machine compatibility:** Configurations work across multiple macOS devices
- **Stow-based deployment:** Easy to set up on new machines

### Making Changes

1. Edit configurations in their respective stowable directories
2. Test changes (since this is your live environment)
3. Use `scripts/stow.sh` to apply changes if needed
4. Commit iteratively with descriptive messages

### Environment Variables

- `GREG_DOTFILES_PATH` - Path to this repository (used in aliases)

## Machine-Specific Considerations

### Universal Configs

Most configurations (nvim, tmux, zsh, git) work across all devices.

### Machine-Specific Configs

- **mac-mini/**: Home Mac Mini specific tools and configs
- **front/**: Work laptop specific configurations (private submodule)

### External Dependencies

- `/Volumes/T7/Vaults` - Main external drive for media and backups (data hub)
- Tailscale network for secure remote access
- Cloudflare tunnel for public copyparty access

### Self-Maintenance

This AGENTS.md should be kept up-to-date as the environment evolves. Feel free to update this file when:

- New tools or aliases are added
- Workflow preferences change
- New services or configurations are introduced
- Dependencies change
- Binary commands are added or modified

**Important:** When updating this file, also update `AGENTS_TEMPLATE.md` to keep the "Greg's System Context" section in sync with any universally useful tools, aliases, or practices that would be valuable in other repositories.

### Testing Expectations

- Test all changes locally before committing (dogfooding approach)
- For stow changes: verify symlinks work correctly with `stow -n` (dry run) first
- For scripts: test error conditions and edge cases
- For configs: ensure they don't break existing workflows

### Safety Considerations

- Most files in this repo are version controlled and safe to modify
- **Caution needed for non-committed config files** - check `.gitignore` files throughout the repo to identify which configs are local/personal and not version controlled
- These non-committed files often contain machine-specific paths, credentials, or personal preferences that should be backed up before modification
- When in doubt, check `git status` to see if a file is tracked before making changes

## Notes for AI Assistants

### Preferred Tools

- Use `bat` instead of `cat` for file reading
- Use `rg` instead of `grep` for searching
- Use `fd` instead of `find` for file discovery
- Use `eza` instead of `ls` for directory listing

### Available Scripts

All scripts in `scripts/` directory are executable and well-documented with error handling.

### Available Binaries

All commands in `~/.local/bin/` are available when stow is applied (see Binary Commands section above).

### Docker Services

All Docker services are managed via `greg-zone/docker-services.sh`, which provides a unified interface to docker-compose with additional error checking and convenience features.

**Minimal Impact Testing:**
When making changes or testing services, **always target specific services** rather than affecting the entire infrastructure:

- Use `docker-compose restart <service>` instead of `docker-compose restart` (all services)
- Use `docker-compose stop <service>` instead of `docker-compose down` (all services)
- Use `docker-compose up -d <service>` to start only specific services
- Example: Testing Minecraft changes should only affect `minecraft`, `minecraft-backup`, `minecraft-alert-monitor`, `playit`, and `mc-monitor` - copyparty, freshrss, and monitoring should continue running

**Important: Rebuilding Images for Code Changes**
When making changes to Python files or other source code that Docker services depend on:

1. **Rebuild the image** to ensure changes are reflected: `cd greg-zone && docker-compose build <service>`
2. **Stop the service**: `cd greg-zone && docker-compose down <service>`
3. **Start the service again**: `cd greg-zone && docker-compose up -d <service>`

**Critical Workflow:** Code changes → Build → Down → Up

- **Code changes alone are NOT enough** - even restarting containers won't pick up new code
- **You MUST rebuild the image** after code changes before restarting containers
- This is especially critical for services in `greg-zone/` that build custom images from local Python files (e.g., alert monitors, webhook services)
- Without rebuilding, containers will continue running the old code even after file changes and container restarts

**Volume Mount Changes on macOS**
When adding new external volume mounts to Docker containers on macOS:

- **Use `cd greg-zone && docker-compose down <service> && docker-compose up -d <service>`** instead of just `restart`
- **Restart alone may not properly mount new external volumes**
- This is particularly important when adding new drives or changing volume paths in `greg-zone/docker-compose.yml`
- Always verify volume mounts with `docker exec <container> ls -la <mount-path>` after changes
