#!/bin/sh

# Check .sh files with POSIX sh
find . -type f -name '*.sh' -not -name "ohmyzsh.sh" -exec shellcheck --shell sh {} +

# Check zsh/.local/bin/* files with bash (they use bash features like 'local')
find ./zsh/.local/bin -type f -exec shellcheck --shell bash {} + 2>/dev/null || true
