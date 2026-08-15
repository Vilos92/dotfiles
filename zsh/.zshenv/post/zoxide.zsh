# zoxide: lazy-init on first z.
function z() {
  unfunction z 2>/dev/null

  if ! command -v zoxide >/dev/null; then
    builtin cd "$@"
    return
  fi

  eval "$(zoxide init zsh)"
  z "$@"
}
