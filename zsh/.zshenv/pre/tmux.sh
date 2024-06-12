attach_tmux_session() {
  if [ -z "$TMUX" ]; then
    # Not inside a tmux session, create a new attached session.
    tmux new-session -A -s "$1"
  else
    # Inside a tmux session, create a new detached session.
    tmux new-session -d -s "$1"
  fi
}
