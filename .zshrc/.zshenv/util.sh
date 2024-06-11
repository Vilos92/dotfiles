#!/bin/zsh

# nvim
alias v=nvim
alias vconfig="v ~/.config/nvim"

# zshrc configs
alias vzshrc="v -p ~/.zshenv ~/.zshrc"

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# bun completions
[ -s "/Users/greg.linscheid/.bun/_bun" ] && source "/Users/greg.linscheid/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
