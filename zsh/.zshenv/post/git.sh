#!/bin/sh
# Sourced by zsh, so `local` is available.
# shellcheck disable=SC3043

# Jump to the worktree checked out for a branch.
gwt() {
  if [ $# -ne 1 ]; then
    echo "usage: gwt <branch>" >&2
    return 1
  fi

  local listing
  listing=$(git worktree list --porcelain) || return $?

  # Porcelain keeps paths with spaces intact and skips the locked/prunable suffixes.
  local target
  target=$(printf '%s\n' "$listing" | awk -v ref="refs/heads/$1" '
    /^worktree / { path = substr($0, 10) }
    $1 == "branch" && $2 == ref { print path; exit }')

  if [ -z "$target" ]; then
    echo "gwt: no worktree for branch '$1'" >&2
    return 1
  fi

  builtin cd "$target" || return
}
