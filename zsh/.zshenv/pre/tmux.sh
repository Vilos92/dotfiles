#!/bin/zsh

attach_tmux_session() {
  if [ -z "$TMUX" ]; then
    # Not inside a tmux session.
    
    # If a second parameter is passed, change to that directory.
    if [ -n "$2" ]; then
      cd "$2"
    fi 

    # Create a new session and attach.
    tmux new-session -A -s "$1"
  else
    # Inside a tmux session, create a new detached session.
    tmux new-session -d -s "$1"
  fi
}
