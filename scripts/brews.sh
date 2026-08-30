#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

brew_path="$(command -v brew || true)"
if [[ -z "$brew_path" ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then
      brew_path="$candidate"
      break
    fi
  done
  if [[ -z "$brew_path" ]]; then
    echo "Homebrew installation succeeded but brew executable was not found." >&2
    exit 1
  fi

  # shellcheck disable=SC2016
  printf 'eval "$(%q shellenv)"\n' "$brew_path" >> "$HOME/.zprofile"
  eval "$("$brew_path" shellenv)"
fi

if ! command -v bun >/dev/null 2>&1; then
  "$brew_path" install oven-sh/bun/bun
fi

exec bun run --cwd "$repo_root/brews" start -- "$@"
