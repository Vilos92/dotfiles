# zoxide: lazy-init on first z/cd (~1s saved per shell).
_zoxide_lazy_init() {
  unfunction _zoxide_lazy_init z 2>/dev/null
  eval "$(zoxide init zsh)"
  alias cd='z'
  z "$@"
}
z() { _zoxide_lazy_init "$@" }
