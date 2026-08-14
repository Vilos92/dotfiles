#!/bin/sh

# tmux
alias tmux-switch='tmux switch -t'
alias tmux-kill='tmux kill-session -t'

# gmux lives in a public submodule (gmux/) and knows nothing about this machine,
# so the project roots are injected here. A function rather than an exported var
# because $FRONTAPP_DIR is set by the front package, whose post/*.sh hook has no
# guaranteed ordering against this one — a function body resolves at call time,
# long after every hook has run.
#
# Named gmux (not g) on purpose: the Übersicht widget shells out to `gmux <name>`
# directly, so wrapping only the alias would leave that call without roots.
gmux() {
  GMUX_ROOTS="${GREG_PROJECTS_PATH}${FRONTAPP_DIR:+
$FRONTAPP_DIR}" command gmux "$@"
}

alias g=gmux
