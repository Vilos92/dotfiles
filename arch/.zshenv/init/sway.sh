#!/bin/sh

# Arch only: auto-start sway on tty1.
if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec sway
fi
