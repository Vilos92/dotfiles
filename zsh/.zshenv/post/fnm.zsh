if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd --log-level quiet 2>/dev/null)"
fi
