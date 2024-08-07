# tmux
alias g=gmux

# nvim
alias v=nvim
# last file
alias vl='nvim -c "normal '\''0"'
# temporary buffer
alias vtmp='nvim -c "setlocal buftype=nofile bufhidden=wipe" -c "nnoremap <buffer> q :q!<CR>" -'
# Oil
alias voil='nvim -c Oil'


# zshrc
alias vzshrc='v -p ~/.zshenv ~/.zshrc'

# Fuzzy find
alias ff=fuzzy-find
alias frg=fuzzy-ripgrep
alias fenv='env | fzf --ansi --tmux 80%'
alias fh=fuzzy-history

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


  printf "Command: %s" "$selection"
  printf "\nExecute? (y/n)"

  stty -echo -icanon
  key=$(dd bs=1 count=1 2>/dev/null)
  stty echo icanon

  printf "\n"

  [ "$key" = "y" ] && eval "$selection"
}
