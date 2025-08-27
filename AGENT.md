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
- `docker/` - Docker service configurations

### Binary Commands
Each stowable directory can include a `.local/bin/` directory that gets symlinked to `~/.local/bin/` via stow:

**Available Commands:**
- **mac-mini:** `gelements-lacie-backup`, `gllama`
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
- `brews.sh` - Install all homebrew packages and applications
- `stow.sh` - Interactively stow dotfile configurations

**Docker Services:**
- `copyparty-docker.sh` - File sharing server with Cloudflare tunnel
- `freshrss-docker.sh` - RSS reader 
- `kiwix-docker.sh` - Offline Wikipedia/content server

## Docker Services

### Service Overview
- **copyparty:** File sharing (port 3923/8080) - https://copyparty.greglinscheid.com
- **freshrss:** RSS reader (port 49153) 
- **kiwix:** Offline content server (port 8473)

All services include:
- Automatic container cleanup and restart
- Volume dependency checking
- Latest image pulling
- Comprehensive error handling

### Service Dependencies
- External drive: `/Volumes/Elements` (required for copyparty, kiwix)
- Mac Vault: `~/Desktop/Mac Vault` (required for copyparty, freshrss)
- Environment variables: `COPYPARTY_CLOUDFLARED_TOKEN` (required for copyparty)

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
- `/Volumes/Elements` - External drive for media and backups
- Tailscale network for secure remote access
- Cloudflare tunnel for public copyparty access

### Self-Maintenance
This AGENT.md should be kept up-to-date as the environment evolves. Feel free to update this file when:
- New tools or aliases are added
- Workflow preferences change  
- New services or configurations are introduced
- Dependencies change
- Binary commands are added or modified

**Important:** When updating this file, also update `AGENT_TEMPLATE.md` to keep the "Greg's System Context" section in sync with any universally useful tools, aliases, or practices that would be valuable in other repositories.

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
Individual service management scripts are preferred over docker-compose for the granular control and error checking they provide.
