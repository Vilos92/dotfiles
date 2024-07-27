# tmux
alias g=gmux

# nvim
alias v=nvim

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

  eval $(echo "$selection" | awk -F= '{print $1}')
}

fuzzy-history () {
  selection=$(
    history |
    awk '{$1=""; print substr($0,2)}' |
    awk '!seen[$0]++' |
    tail -r |
    fzf
  )

  [ -z "$selection" ] && return

  eval "$selection"
}
