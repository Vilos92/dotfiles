#!/bin/zsh

# zshrc
alias vzshrc="v -p ~/.zshenv ~/.zshrc"

# tmux
alias tmux-attach="attach_tmux_session"
alias tmux-kill="tmux kill-session -t"
alias tmux-switch="tmux switch -t"

# nvim
alias v=nvim
alias vconfig="v ~/.config/nvim"

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# bun completions
[ -s "/Users/greg.linscheid/.bun/_bun" ] && source "/Users/greg.linscheid/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
