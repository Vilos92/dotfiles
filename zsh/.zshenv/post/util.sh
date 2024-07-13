#!/bin/sh

# zshrc
alias vzshrc='v -p ~/.zshenv ~/.zshrc'

# tmux
alias tmux-attach='attach-tmux-session'
alias tmux-kill='tmux kill-session -t'
alias tmux-switch='tmux switch -t'

# Fuzzy find
alias ff=fuzzy-find
alias rgf=ripgrep-fuzzy

# nvim
alias v=nvim

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# bun completions
[ -s "/Users/greg.linscheid/.bun/_bun" ] && source "/Users/greg.linscheid/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
