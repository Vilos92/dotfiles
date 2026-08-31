import type {Catalog, GroupDefinition, PackageDefinition} from './types.ts';

const brew = (
  id: string,
  label: string,
  description: string,
  token: string,
  brewKind: 'formula' | 'cask' = 'formula',
  requires?: string[]
): PackageDefinition => ({
  id,
  label,
  description,
  action: {kind: 'brew', brewKind, token},
  probe: {kind: 'brew', brewKind, token},
  requires
});

const shell = (
  id: string,
  label: string,
  description: string,
  command: string,
  probe: PackageDefinition['probe'],
  requires?: string[]
): PackageDefinition => ({
  id,
  label,
  description,
  action: {kind: 'shell', command},
  probe,
  requires
});

const groups: GroupDefinition[] = [
  {
    id: 'dotfile-pkgs',
    label: 'Dotfiles',
    packages: [brew('stow', 'stow', 'Link dotfile packages', 'stow')]
  },
  {
    id: 'desktop',
    label: 'Desktop',
    packages: [
      brew('forklift', 'ForkLift', 'File manager', 'forklift', 'cask'),
      brew('betterdisplay', 'BetterDisplay', 'Scalable display controls', 'betterdisplay', 'cask')
    ]
  },
  {
    id: 'mouse-pkgs',
    label: 'Mouse',
    packages: [
      brew('mos', 'Mos', 'Smooth mouse scrolling', 'mos'),
      brew(
        'sensiblesidebuttons',
        'SensibleSideButtons',
        'Mouse side-button support',
        'sensiblesidebuttons',
        'cask'
      )
    ]
  },
  {
    id: 'terminal-pkgs',
    label: 'Terminal',
    packages: [
      brew('alacritty', 'Alacritty', 'Terminal emulator', 'alacritty', 'cask'),
      brew('tmux', 'tmux', 'Terminal multiplexer', 'tmux'),
      brew('zsh', 'zsh', 'Shell', 'zsh'),
      shell(
        'oh-my-zsh',
        'Oh My Zsh',
        'Zsh configuration framework',
        'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"',
        {kind: 'path', path: '$HOME/.oh-my-zsh'},
        ['zsh']
      ),
      shell(
        'powerlevel10k',
        'Powerlevel10k',
        'Zsh prompt theme',
        'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"',
        {kind: 'path', path: '$HOME/powerlevel10k'},
        ['oh-my-zsh']
      ),
      brew('neofetch', 'Neofetch', 'System information display', 'neofetch')
    ]
  },
  {
    id: 'security',
    label: 'Security and networking',
    packages: [
      brew('1password', '1Password', 'Password manager', '1password', 'cask'),
      brew('tailscale', 'Tailscale CLI', 'Tailscale VPN command-line client', 'tailscale'),
      brew('tailscale-app', 'Tailscale', 'Tailscale macOS app', 'tailscale-app', 'cask'),
      brew('mosh', 'mosh', 'Remote shell', 'mosh')
    ]
  },
  {
    id: 'host',
    label: 'Hosting and cloud',
    packages: [
      brew('cloudflared', 'cloudflared', 'Cloudflare tunnel client', 'cloudflared'),
      brew('ngrok', 'ngrok', 'Secure tunnel client', 'ngrok', 'cask'),
      shell(
        'copyparty',
        'copyparty',
        'File-sharing server',
        'command -v python3 >/dev/null || { echo "python3 not found (install it first)"; exit 1; }; python3 -m pip install --user copyparty',
        {kind: 'command', command: 'copyparty'}
      ),
      brew('plex-media-server', 'Plex Media Server', 'Media server', 'plex-media-server', 'cask'),
      brew('flyctl', 'flyctl', 'Fly.io deployment CLI', 'flyctl'),
      brew('rclone', 'rclone', 'Cloud storage sync', 'rclone'),
      brew('google-drive', 'Google Drive', 'Google Drive desktop app', 'google-drive', 'cask')
    ]
  },
  {
    id: 'dev-pkgs',
    label: 'Development tools',
    packages: [
      brew('neovim', 'Neovim', 'Text editor', 'neovim'),
      brew('tree-sitter-cli', 'tree-sitter-cli', 'Parser generator CLI', 'tree-sitter-cli'),
      brew('font-meslo-lg-nerd-font', 'Meslo Nerd Font', 'Developer font', 'font-meslo-lg-nerd-font', 'cask'),
      brew('ripgrep', 'ripgrep', 'Text search', 'ripgrep'),
      brew('fzf', 'fzf', 'Fuzzy finder', 'fzf'),
      brew('bat', 'bat', 'Syntax-highlighted file viewer', 'bat'),
      brew('fd', 'fd', 'File finder', 'fd'),
      brew('eza', 'eza', 'Directory listing', 'eza'),
      brew('zoxide', 'zoxide', 'Directory jumper', 'zoxide'),
      brew('tealdeer', 'tealdeer', 'Command cheat sheets', 'tealdeer'),
      brew('wget', 'wget', 'Download utility', 'wget'),
      brew('shellcheck', 'ShellCheck', 'Shell linter', 'shellcheck'),
      shell(
        'fff',
        'fff',
        'MCP file search server and CLI',
        'curl -fsSL https://raw.githubusercontent.com/dmtrKovalenko/fff/main/install-mcp.sh | bash',
        {kind: 'command', command: 'fff'}
      ),
      shell(
        'dex',
        'Dex',
        'Agent workflow tracker',
        'bun add -g @zeeg/dex',
        {kind: 'command', command: 'dex'},
        ['bun']
      ),
      brew('hunk', 'hunk', 'Interactive diff viewer', 'hunk'),
      brew('gh', 'GitHub CLI', 'GitHub command-line client', 'gh')
    ]
  },
  {
    id: 'docker-pkgs',
    label: 'Docker',
    packages: [
      brew('docker', 'Docker Desktop', 'Container runtime', 'docker', 'cask'),
      brew('lazydocker', 'lazydocker', 'Docker terminal UI', 'lazydocker')
    ]
  },
  {
    id: 'lua-pkgs',
    label: 'Lua',
    packages: [
      brew('lua', 'Lua', 'Lua runtime', 'lua'),
      brew('lua-language-server', 'Lua language server', 'Lua LSP', 'lua-language-server'),
      brew('luarocks', 'LuaRocks', 'Lua package manager', 'luarocks'),
      brew('stylua', 'StyLua', 'Lua formatter', 'stylua'),
      shell(
        'jsregexp',
        'jsregexp',
        'Lua regexp module',
        'sudo luarocks install jsregexp',
        {kind: 'unknown'},
        ['luarocks']
      )
    ]
  },
  {
    id: 'python-dev-pkgs',
    label: 'Python',
    packages: [
      brew('pipx', 'pipx', 'Isolated Python app installer', 'pipx'),
      shell('black', 'Black', 'Python formatter', 'pipx install black', {kind: 'command', command: 'black'}, [
        'pipx'
      ]),
      shell(
        'ruff',
        'Ruff',
        'Python linter and formatter',
        'pipx install ruff',
        {kind: 'command', command: 'ruff'},
        ['pipx']
      ),
      shell('mypy', 'mypy', 'Python type checker', 'pipx install mypy', {kind: 'command', command: 'mypy'}, [
        'pipx'
      ])
    ]
  },
  {
    id: 'javascript-pkgs',
    label: 'JavaScript',
    packages: [
      brew('fnm', 'fnm', 'Fast Node.js version manager', 'fnm'),
      brew('bun', 'Bun', 'JavaScript runtime and package manager', 'oven-sh/bun/bun'),
      brew('pnpm', 'pnpm', 'JavaScript package manager', 'pnpm'),
      shell(
        'node-lts',
        'Node.js LTS',
        'Latest Node.js long-term support runtime',
        'fnm install --lts && fnm default lts-latest && eval "$(fnm env)"',
        {kind: 'command', command: 'node'},
        ['fnm']
      ),
      shell(
        'prettierd',
        'prettierd',
        'Prettier daemon',
        'npm install -g @fsouza/prettierd',
        {kind: 'command', command: 'prettierd'},
        ['node-lts']
      ),
      shell(
        'eslint-d',
        'eslint_d',
        'ESLint daemon',
        'npm install -g eslint_d@15',
        {kind: 'command', command: 'eslint_d'},
        ['node-lts']
      ),
      shell(
        'typescript-language-server',
        'TypeScript language server',
        'TypeScript LSP',
        'npm install -g typescript-language-server typescript',
        {kind: 'command', command: 'typescript-language-server'},
        ['node-lts']
      )
    ]
  },
  {
    id: 'native-dev',
    label: 'Native development',
    packages: [
      brew('gleam', 'Gleam', 'Gleam programming language', 'gleam'),
      brew('rustup', 'rustup', 'Rust toolchain manager', 'rustup'),
      shell(
        'rust-stable',
        'Rust stable toolchain',
        'Stable Rust compiler and Cargo',
        'PATH="$(brew --prefix rustup)/bin:$PATH" rustup-init -y --default-toolchain stable --no-modify-path',
        {kind: 'command', command: 'rustc'},
        ['rustup']
      ),
      brew('just', 'just', 'Rust package runner', 'just')
    ]
  },
  {
    id: 'browsers',
    label: 'Browsers',
    packages: [
      brew('zen', 'Zen Browser', 'Web browser', 'zen', 'cask'),
      brew('firefox', 'Firefox', 'Web browser', 'firefox', 'cask'),
      brew('microsoft-edge', 'Microsoft Edge', 'Web browser', 'microsoft-edge', 'cask')
    ]
  },
  {
    id: 'mac-productivity',
    label: 'macOS productivity',
    packages: [
      brew('alfred', 'Alfred', 'Launcher', 'alfred', 'cask'),
      brew('rectangle', 'Rectangle', 'Window manager', 'rectangle', 'cask'),
      brew('mole', 'mole', 'macOS cleanup and disk analysis', 'mole'),
      brew('notion', 'Notion', 'Note-taking app', 'notion', 'cask')
    ]
  },
  {
    id: 'media',
    label: 'Media',
    packages: [
      brew('pillow', 'Pillow', 'Image tools', 'pillow'),
      brew('vlc', 'VLC', 'Media player', 'vlc', 'cask'),
      brew('spotify', 'Spotify', 'Music streaming app', 'spotify', 'cask'),
      brew('audacity', 'Audacity', 'Audio editor', 'audacity', 'cask'),
      brew('ableton-live-suite', 'Ableton Live Suite', 'Audio workstation', 'ableton-live-suite', 'cask'),
      brew('xld', 'XLD', 'Lossless audio decoder', 'xld', 'cask'),
      brew('musicbrainz-picard', 'MusicBrainz Picard', 'Music tagger', 'musicbrainz-picard', 'cask'),
      brew('ffmpeg', 'FFmpeg', 'Audio and video toolkit', 'ffmpeg'),
      brew('handbrake', 'HandBrake', 'Video transcoder', 'handbrake'),
      brew('keka', 'Keka', 'Archive manager', 'keka', 'cask'),
      brew('gimp', 'GIMP', 'Image editor', 'gimp', 'cask'),
      brew('gifox', 'Gifox', 'GIF recorder', 'gifox', 'cask')
    ]
  },
  {
    id: 'coding-pkgs',
    label: 'Coding applications',
    packages: [
      brew('visual-studio-code', 'Visual Studio Code', 'Code editor', 'visual-studio-code', 'cask'),
      brew('claude-code', 'Claude Code', 'Coding agent', 'claude-code', 'cask'),
      brew('codex', 'Codex', 'Coding agent', 'codex', 'cask'),
      brew('omp', 'Oh My Pi', 'Coding harness', 'can1357/tap/omp'),
      brew('coteditor', 'CotEditor', 'Text editor', 'coteditor', 'cask'),
      brew('dbeaver-community', 'DBeaver', 'Database manager', 'dbeaver-community', 'cask')
    ]
  },
  {
    id: 'utilities',
    label: 'Utilities',
    packages: [
      brew('there', 'There', 'Timezone app', 'there', 'cask'),
      brew('transmission', 'Transmission', 'Torrent client', 'transmission', 'cask'),
      brew('yt-dlp', 'yt-dlp', 'Media downloader', 'yt-dlp')
    ]
  },
  {
    id: 'chats',
    label: 'Chat',
    packages: [
      brew('whatsapp', 'WhatsApp', 'Chat app', 'whatsapp', 'cask'),
      brew('slack', 'Slack', 'Chat app', 'slack', 'cask'),
      brew('discord', 'Discord', 'Chat app', 'discord', 'cask')
    ]
  },
  {
    id: 'ai-pkgs',
    label: 'AI',
    packages: [
      brew('llama.cpp', 'llama.cpp', 'Local LLM inference', 'llama.cpp'),
      brew('ollama', 'Ollama', 'Local LLM runtime', 'ollama'),
      brew('grepai', 'grepai', 'AI code search', 'yoanbernabeu/tap/grepai'),
      brew('draw-things', 'Draw Things', 'Local image generation', 'draw-things', 'cask'),
      brew('claude', 'Claude', 'Claude desktop app', 'claude', 'cask'),
      brew('google-gemini', 'Google Gemini', 'Gemini desktop app', 'google-gemini', 'cask'),
      brew('gemini-cli', 'Gemini CLI', 'Gemini command-line client', 'gemini-cli')
    ]
  },
  {
    id: 'offline-and-gaming',
    label: 'Offline and gaming',
    packages: [
      brew('kiwix', 'Kiwix', 'Offline Wikipedia reader', 'kiwix', 'cask'),
      brew('openemu', 'OpenEmu', 'Game emulator', 'openemu', 'cask'),
      brew('mame', 'MAME', 'Arcade emulator', 'mame')
    ]
  }
];

export const catalog: Catalog = {groups};

export const v92Banner = `        ___ ____  
__   __/ _ \\___ \\ 
\\ \\ / / (_) |__) |
 \\ V / \\, / __/ 
  \\_/    /_/_____|`;

export const allPackages = (source: Catalog = catalog): PackageDefinition[] =>
  source.groups.flatMap(group => group.packages);

export const packageById = (source: Catalog = catalog): Map<string, PackageDefinition> =>
  new Map(allPackages(source).map(pkg => [pkg.id, pkg]));
