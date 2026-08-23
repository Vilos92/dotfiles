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
- `claude-md/` - Claude Code config (`~/.claude`: skills, settings, CLAUDE.md)
- `remote/` - Remote server connection configs
- `mac-mini/` - Mac Mini specific configurations
- `front/` - Work laptop specific configurations (symlinked submodule)

**Non-Stowable Directories:**

- `scripts/` - Standalone executable scripts
- `greg-zone/` - Docker infrastructure and services (separate repository, but this AGENTS.md is responsible for documenting it)
- `gmux/` - Public tmux session switcher (separate repository: https://github.com/Vilos92/gmux)
- `arch/` - Arch Linux specific configurations (currently empty)
- `mac-productivity/` - Mac productivity configurations (Alfred)

### Submodules

| Submodule | Visibility | Pulled |
| --- | --- | --- |
| `gmux/` | public | **automatically** on any clone |
| `front/` | private | opt-in |
| `greg-zone/` | private | opt-in |

`front` and `greg-zone` carry `update = none` in `.gitmodules`, so `git clone
--recurse-submodules` and `git submodule update --init` skip them while still
populating `gmux`. Bringing an opt-in submodule in needs an explicit `--checkout`:

```sh
git submodule update --init --checkout front
```

`gmux` is intentionally agnostic of this repo and contains nothing
machine-specific. Never add machine-specific paths to the `gmux/` submodule.

**Project roots come from config files, not the environment.** `tmux/.config/gmux/config`
is stowed to `~/.config/gmux/config` and lists `~/greg_projects`. Machine-specific
roots go in `~/.config/gmux/config.d/`, which gmux merges with the main file — that
is how the `front` package supplies the work-laptop root without two stow packages
fighting over one file.

This must not be an exported variable or a shell function. The `bind g
run-shell ...` binding in `tmux/.tmux.conf` invokes gmux from a bare `sh -c`
that sources no shell rc, where neither is visible (it inherits only the tmux
server's PATH, which is why the binding uses an absolute path, single-quoted so
`sh` rather than tmux expands it — tmux parses `${VAR}` itself and rejects the
`:-` default form).

Regressing this to an export "works" in an interactive shell and silently breaks
that binding.

### Binary Commands

Each stowable directory can include a `.local/bin/` directory that gets symlinked to `~/.local/bin/` via stow:

**Available Commands:**

- **mac-mini:** `gbackup-lacie`, `gbackup-t7`, `gllama`, `hermes` (opens the Hermes TUI in a persistent tmux session named `hermes`)
- **alacritty:** `alacritty-theme`, `alacritty-theme-select`
- **zsh:** `compress-video-hevc`, `download-media`, `fuzzy-find`, `fuzzy-ripgrep`, `remux-video`

`gmux` and `attach-tmux-session` are the exception: they live in the public
`gmux/` submodule rather than a stow package, so `zsh/.zshrc` puts
`$GREG_DOTFILES_PATH/gmux/bin` on `$PATH` directly instead of symlinking them.

## Available Commands & Shortcuts

### Key Aliases

**File Operations (eza-based):**

- `ls` → `eza --color=always --group-directories-first --icons=always`
- `ll` → detailed list with permissions and icons
- `la` → long format with all files
- `lt` → tree view (2 levels)
- `lx` → extended detailed view with git info

**Navigation & Search:**

- `z` → zoxide smart directory jumping
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

- `ssh-mini` → SSH to Mac Mini (requires Tailscale)
- `ssh-mini-hermes` → SSH to Mac Mini and attach the persistent Hermes TUI tmux session (detach with tmux prefix + d; survives disconnects)
- `mosh-mini` / `mosh-mini-hermes` → mosh variants of the two `ssh-mini` aliases, for when the link is laggy. Requires mosh on both ends

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
- **freshrss:** RSS reader (port 49153) - Tailscale-only at greg-zone:9002 (removed from Cloudflare Aug 2026 due to scraper traffic)
- **kiwix:** Offline content server (port 8473) - https://kiwix.greglinscheid.com
- **transmission:** Torrent client (port 9091)
- **prowlarr:** Indexer search (Tailscale :9009)
- **hermes:** Hermes Agent dashboard (Tailscale :9010) — data under GregZone Vault/hermes
- **minecraft:** Minecraft Bedrock server (port 19132/udp) — **profile-gated; do not start unless Greg explicitly asks** (see Minecraft Profile below)
- **sparkify:** Slack/Spotify bot (no ports — Socket Mode, outbound only). Submodule at `greg-zone/sparkify`; see its `AGENTS.md`, and the `spotify-refresh-token` skill there for rotating `SPOTIFY_REFRESH_TOKEN`. Only ever run one instance, or Slack replies double.

**Monitoring Stack:**

- **prometheus:** Metrics collection (port 9090)
- **grafana:** Dashboards and visualization (port 3000)
- **loki:** Log aggregation (port 3100)
- **promtail:** Log shipping
- **alertmanager:** Alert routing (port 9093)
- **node-exporter:** System metrics (port 9100)
- **cadvisor:** Container metrics (port 8080)
- **docker-stats-exporter:** Docker stats exporter (port 8081)
- **mc-monitor:** Minecraft server metrics (port 8082) — **profile-gated; do not start unless Greg explicitly asks.** Its Prometheus scrape job is commented out to match; leave it commented unless the profile is coming back up.

**Networking & Infrastructure:**

- **tailscale:** VPN mesh network
- **cloudflared:** Cloudflare tunnel for public access
- **nginx-tailscale:** Reverse proxy for Tailscale network
- **nginx-cloudflared:** Reverse proxy for Cloudflare tunnel

**Alerting & Webhooks:**

- **discord-webhook:** Discord webhook multiplexer (port 8083)
- **services-alert-monitor:** Monitors nginx, copyparty, freshrss, kiwix
- **infrastructure-alert-monitor:** Monitors loki, prometheus, grafana, etc.
- **minecraft-alert-monitor:** Monitors minecraft server — **profile-gated; do not start unless Greg explicitly asks**

**Supporting Services:**

- **infra-redis:** Redis database for alert monitor state (port 6379)
- **infra-redis-commander:** Redis management UI (port 8084)
- **playit:** Minecraft server tunneling — **profile-gated; do not start unless Greg explicitly asks.** Keep `PLAYIT_SECRET_KEY` in `.env` so the tunnel reclaims the same address whenever it does come back. The top-level `playit` *network* is still defined and in use — promtail and nginx-tailscale attach to it — so do not remove it.
- **minecraft-backup:** Automated Minecraft backups — **profile-gated; do not start unless Greg explicitly asks**
- **woodpecker-server / woodpecker-agent:** Woodpecker CI (UI Tailscale-only at :9011; one instance serves any GitHub repo via per-repo opt-in in the UI). GitHub login uses a classic OAuth app (callback `http://greg-zone:9011/authorize`); webhooks arrive publicly at https://woodpecker.greglinscheid.com/api/hook through the Cloudflare tunnel (all other paths refused, except a `Disallow: /` robots.txt and a 404 on sitemap.xml — see Crawlers below). Agent runs pipeline steps as containers via the Docker socket — keep repos "untrusted" in Woodpecker unless privileged features are needed. Metrics scraped by Prometheus on internal port 9001. Pipeline step images that need extra tools are built locally on the Mini under `greg-zone/ci/` (e.g. `greg-zone/bun-git`, oven/bun + git) — they exist only in the host Docker daemon, so rebuild them after a `docker system prune -a` (see each Dockerfile).

### Minecraft Profile

The five Minecraft services — `minecraft`, `minecraft-backup`, `playit`,
`mc-monitor`, `minecraft-alert-monitor` — carry `profiles: ['minecraft']` in
`greg-zone/docker-compose.yml`, so a plain `docker-compose up -d` skips them.

**Do not bring these up unless Greg explicitly asks for Minecraft.** The gate is
deliberate, not an outage or a bug to fix. In particular:

- Never add `COMPOSE_PROFILES=minecraft` to a command on your own initiative.
- Never un-gate a service by deleting its `profiles:` key to "fix" something.
- An absent minecraft container, an empty `minecraft-monitoring` Grafana
  dashboard, and the commented-out `minecraft-monitor` scrape job are all the
  intended state. Leave them.

Every service definition and all world data stays intact, so returning is one
command whenever Greg does ask:

```sh
cd greg-zone && COMPOSE_PROFILES=minecraft ./docker-services.sh up
```

No change to `docker-services.sh` is needed — Compose reads `COMPOSE_PROFILES`
natively, so the existing `docker-compose -f docker-compose.yml up -d` honors it.
When re-enabling, also uncomment the `minecraft-monitor` scrape job in
`greg-zone/prometheus/prometheus.yml` and restart prometheus, or the Grafana
dashboard stays empty.

World data lives at `/Volumes/Wokyis M.2 SSD - Storage/Vaults/GregZone Vault/Minecraft/Jordania`
and `Jordania_backups`. Never touch either path — the profile change does not,
and neither should any cleanup.

### Crawlers and robots.txt

Every public vhost in `greg-zone/nginx/nginx-cloudflare.conf` serves a real
`User-agent: *` / `Disallow: /` robots.txt, and woodpecker answers
`/sitemap.xml` with 404. This is not decoration — it is the only thing that
actually makes a well-behaved crawler stop.

Refusing robots.txt does the opposite of what it looks like. Per RFC 9309, a
4xx means "no rules exist, crawl freely", and an unreachable robots.txt (our
`return 444`, which the client sees as a dropped connection) means "assume
disallowed *for now*, retry later" — forever. Claude-SearchBot spent a week
polling woodpecker's robots.txt and sitemap.xml every ~90 minutes for exactly
this reason, never crawling anything, just re-asking. One served `Disallow`
ends it.

Consequences to preserve when editing these vhosts:

- `location = /robots.txt` must sit **outside** `location /`, because the
  `if ($is_bot)` bot block runs in the rewrite phase, before a location is
  chosen. That is why copyparty's and kiwix's bot checks were moved inside
  their `location /` blocks — a server-level `if` would 403 robots.txt too.
- Kiwix's robots.txt location carries `auth_basic off;`. A 401 is a 4xx, so
  gating it behind basic auth reads as "crawl freely".
- Never answer robots.txt with 403, 444, or 401.

`services_alert_monitor.py` treats `/robots.txt` and `/sitemap.xml` as
crawler-protocol requests and never fires a new-IP or suspicious-activity
alert for them, at any status — crawlers rotate IPs, so each visit would
otherwise page Discord. It also skips new-IP alerts for both edge-reject
statuses (403 from the bot block, 444 from woodpecker's catch-all). Scanners
hitting *other* paths for 4xx/5xx are still caught by the suspicious-activity
rule.

### Service Dependencies

- External drive: `/Volumes/T7/Vaults` (required for copyparty, kiwix) - T7 is now the main data hub
- Wokyis M.2 SSD: `/Volumes/Wokyis M.2 SSD - Storage/Vaults` (required for copyparty, freshrss, transmission, minecraft, hermes)
  - GregZone Vault: Contains freshrss, transmission, minecraft, hermes data
  - Hobby Vault: Contains llm models and music production files
- Environment variables (in `greg-zone/.env`):
  - `COPYPARTY_CLOUDFLARED_TOKEN` (required for copyparty)
  - `TAILSCALE_AUTH_KEY` (required for Tailscale)
  - `TRANSMISSION_PASSWORD` (required for Transmission)
  - `GRAFANA_PASSWORD` (required for Grafana)
  - `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` / `PASSWORD` / `SECRET` (required for Hermes dashboard)
  - `DISCORD_*_WEBHOOK_URL` (various Discord webhooks)
  - `ALERT_MONITOR_SECRET` (required for alert monitors)
  - `INFRA_REDIS_PASSWORD` (required for Redis)
  - `PLAYIT_SECRET_KEY` (required for Playit)
  - `WOODPECKER_GITHUB_CLIENT` / `WOODPECKER_GITHUB_SECRET` (classic GitHub OAuth app for Woodpecker CI login)
  - `WOODPECKER_AGENT_SECRET` (shared secret for Woodpecker agent<->server gRPC)

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

### Mac Mini Power Management

The Mac Mini runs greg-zone 24/7, so it must never sleep. macOS defaults assume a
personal workstation and will sleep it on slight provocation. Current settings:

| Setting | Value | Why |
| --- | --- | --- |
| `pmset -c sleep` | `0` | Never idle-sleep on AC |
| `pmset -u sleep` | `0` | **Non-default.** Don't sleep just because the UPS took over |
| `pmset -u womp` | `1` | **Non-default.** Stay network-wakeable on UPS power |
| `pmset -u haltremain` | `5` | Clean shutdown when the UPS has 5 min runtime left |

`-c` is the AC profile, `-u` the UPS profile; macOS switches the instant the UPS
reports battery. The two non-defaults were set 2026-08-17, after a 67-second
outage slept the Mini (UPS at 100%) and it stayed down four hours — it never woke
when AC returned, and `womp 0` left it unreachable until physically touched.
Sleep does not auto-recover; `haltremain` + `autorestart 1` do. Keep low-battery
handling as a shutdown and never reintroduce sleep here.

**If greg-zone misbehaves across unrelated containers** — Sparkify
restart-storming, Grafana gaps, containers "up" but silent — check whether the
host slept before debugging any single service:

```sh
pmset -g log | grep -E "Entering Sleep state|DarkWake"
pmset -g ps   # power source + UPS charge
```

Prometheus, Alertmanager, and the alert monitors all run **on** the Mini, so a
sleeping host silences its own alerting — nothing pages you. The UPS reported
only ~6 min runtime at "100%" (aged battery), so ride-through is minimal.

### Self-Maintenance

This AGENTS.md should be kept up-to-date as the environment evolves. Feel free to update this file when:

- New tools or aliases are added
- Workflow preferences change
- New services or configurations are introduced
- Dependencies change
- Binary commands are added or modified

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
- Example: Testing Minecraft changes should only affect `minecraft`, `minecraft-backup`, `minecraft-alert-monitor`, `playit`, and `mc-monitor` - copyparty, freshrss, and monitoring should continue running (these five are currently profile-gated — see Minecraft Profile above)
- Never run `COMPOSE_PROFILES=minecraft docker-compose down` — `down` ignores service arguments and would take the entire stack down

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
