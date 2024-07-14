#!/bin/sh

find . \( -type f -name '*.sh' -not -name "ohmyzsh.sh" \) -o -path "./zsh/.local/bin/*" -type f -exec shellcheck --shell sh {} +

