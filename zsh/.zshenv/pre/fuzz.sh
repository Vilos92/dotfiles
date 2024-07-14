fuzzy-find() {
  local selected
  selected=$(find . -type f | fzf --ansi --tmux 80% --preview "bat --color=always {}")
  [ -n "$selected" ] && nvim "$selected"
}

fuzzy-ripgrep() {
  [ -z "$1" ] && echo "Usage: rgf <pattern>" && return

  local selected
  selected=$(rg --hidden --color=always --line-number --no-heading --smart-case \
                 --glob '!.git/*' --glob '!node_modules/*' "$1" |
             fzf --ansi \
                 --tmux 80% \
                 --color "hl:-1:underline,hl+:-1:underline:reverse" \
                 --delimiter : \
                 --preview 'bat --color=always {1} --highlight-line {2}' \
             )

  local file
  file=$(echo "$selected" | cut -d: -f1)
  [ -n "$selected" ] && nvim "$file"
}
