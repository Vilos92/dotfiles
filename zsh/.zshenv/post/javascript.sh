#!/bin/sh

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# pnpm zsh completions
if command -v pnpm >/dev/null 2>&1; then
  . <(pnpm completion zsh)
fi

# bun
export BUN_INSTALL="$HOME/.bun"

# bun completions
[ -s "/Users/greg.linscheid/.bun/_bun" ] && . "/Users/greg.linscheid/.bun/_bun"
