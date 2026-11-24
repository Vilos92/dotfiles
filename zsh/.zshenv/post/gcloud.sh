#!/bin/sh

# gcloud completions. Zsh only, and only where the Homebrew SDK is installed.
# A .sh file so it loads after compinit. Otherwise the SDK runs its own uncached compinit.
if [ -n "${ZSH_VERSION-}" ]; then
  _gcloud_comp="${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc"
  # shellcheck source=/dev/null
  [ -f "$_gcloud_comp" ] && . "$_gcloud_comp"
  unset _gcloud_comp
fi
