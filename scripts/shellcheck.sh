#!/bin/sh

find . -type f -name '*.sh' -not -name "ohmyzsh.sh" -exec shellcheck --shell sh {} +
