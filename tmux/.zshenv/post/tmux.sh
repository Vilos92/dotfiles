#!/bin/sh

# tmux
alias tmux-switch='tmux switch -t'
alias tmux-kill='tmux kill-session -t'

# gmux lives in a public submodule (gmux/) and knows nothing about this machine.
# Its project roots come from ~/.config/gmux/config (stowed from this package)
# plus ~/.config/gmux/config.d/, NOT from anything exported here — `tmux
# run-shell` invokes gmux from a bare `sh -c` that sources no rc, so a
# variable or function set here would be invisible to it.
alias g=gmux
