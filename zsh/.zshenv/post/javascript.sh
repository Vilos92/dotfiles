#!/bin/sh

# bun
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
case ":${PATH}:" in
*":${BUN_INSTALL}/bin:"*) ;;
*) PATH="${BUN_INSTALL}/bin:${PATH}" && export PATH ;;
esac

# pnpm
export PNPM_HOME="/Users/greg.linscheid/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# bun completions
_bun_comp="${BUN_INSTALL}/_bun"
[ -s "$_bun_comp" ] && . "$_bun_comp"
unset _bun_comp

# Vite+ (https://viteplus.dev) — PATH, vp() wrapper, completions
[ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"
