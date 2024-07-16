# zshrc
alias vzshrc='v -p ~/.zshenv ~/.zshrc'

# Fuzzy find
alias ff=fuzzy-find
alias frg=fuzzy-ripgrep
alias fenv='env | fzf --ansi --tmux 80%'

falias () {
  local aliases=$(alias)

  selection=$(echo "$aliases" | fzf --ansi --tmux 80%)
  [ -z "$selection" ] && return

  echo "alias: $selection"
  eval $(echo "$selection" | awk -F= '{print $1}')
}

# tmux
alias g=gmux

# nvim
alias v=nvim

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# bun completions
# shellcheck disable=SC1091
[ -s "/Users/greg.linscheid/.bun/_bun" ] && . "/Users/greg.linscheid/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
