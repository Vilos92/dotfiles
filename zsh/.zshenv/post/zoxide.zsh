# zoxide: lazy-init on first z/cd.
# cd must be a function (not alias) — zsh can't define cd() while cd is aliased.
unalias cd 2>/dev/null

_zoxide_lazy_init() {
  unfunction _zoxide_lazy_init z cd 2>/dev/null
  unalias cd 2>/dev/null

  if ! command -v zoxide >/dev/null; then
    unfunction z 2>/dev/null
    function cd() { builtin cd "$@"; }
    builtin cd "$@"
    return
  fi

  eval "$(zoxide init zsh)"
  function cd() { z "$@"; }
  z "$@"
}

function z() { _zoxide_lazy_init "$@"; }
function cd() { _zoxide_lazy_init "$@"; }
