#!/bin/sh
# Claude Code hooks that label tmux while Claude runs, adapted from Louis
# Cherel's Coder workspace setup. Usage: tmux-claude.sh <start|title|label|end>,
# with the hook's JSON on stdin.
#
# Nothing here lives in ~/.tmux.conf. `start` applies the multi-line status bar
# to the tmux session Claude runs in, as session options. `end` unsets them once
# no Claude is left there, so that session falls back to the global config.
# Outside tmux every mode is a no-op.
#
#   start  SessionStart: claim the pane, apply the bar, title the window
#   title  CwdChanged, PostToolUse: rename the window to repo:branch
#   label  UserPromptSubmit, Stop: tab label = session title, PRs as titles
#   end    SessionEnd: release the pane, restore tmux once Claude is gone
#   lines  internal: size the bar to a session's window count

[ -n "$TMUX" ] || exit 0
# tmux's run-shell sets no TMUX_PANE, and `lines` is given its session instead.
[ "$1" = lines ] || [ -n "$TMUX_PANE" ] || exit 0

SELF=$0
MODE=$1

# tmux caps the status bar at 5 lines.
WINDOWS_PER_LINE=3
MAX_STATUS_LINES=5
# Cells pad to a fixed width so columns line up across lines.
CELL_WIDTH=54
# Longest Claude title shown in a cell before it is cut with an ellipsis.
TITLE_WIDTH=48
GH_TIMEOUT_SECONDS=10
PR_TITLE_CACHE="${TMPDIR:-/tmp}/claude-pr-titles"

session_of_pane() {
  tmux display -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null
}

# Status line N lists windows N*3 .. N*3+2. Line 0 also carries the session
# name and clock. Cells are clickable and the active window is reversed.
status_line_format() {
  first=$(($1 * WINDOWS_PER_LINE))
  last=$((first + WINDOWS_PER_LINE))
  in_range="#{&&:#{e|>=:#{window_index},$first},#{e|<:#{window_index},$last}}"
  cell="#[range=window|#{window_index}]#{?window_active,#[reverse],} #{p$CELL_WIDTH:#{E:@tab_label}}#[norange]#[default]"
  printf '%s' "#[align=left]#{W:#{?$in_range,$cell,}}"
  [ "$1" -eq 0 ] && printf '%s' '#[align=right] #{session_name} · %H:%M '
}

# A Claude pane shows its busy glyph plus @claude_title, but only while the
# pane title still matches the title that label was built from. Any other pane
# shows its title, or the window name when the title is just the hostname.
TAB_LABEL="#{?#{&&:#{@claude_title_src},#{==:#{s/^[^ ]+ //:pane_title},#{@claude_title_src}}},#{s/ .*//:pane_title} #{=/$TITLE_WIDTH/…:@claude_title},#{?#{||:#{==:#T,#{host}},#{==:#T,#{host_short}}},#W,#T}}"

apply_layout() {
  session=$1
  # The line-to-window mapping needs contiguous window indices.
  tmux set -t "$session" renumber-windows on
  tmux set -t "$session" @tab_label "$TAB_LABEL"
  line=0
  while [ "$line" -lt "$MAX_STATUS_LINES" ]; do
    tmux set -t "$session" "status-format[$line]" "$(status_line_format "$line")"
    line=$((line + 1))
  done
  for event in window-linked window-unlinked; do
    tmux set-hook -t "$session" "$event" "run-shell \"sh '$SELF' lines '#{session_id}'\""
  done
  set_line_count "$session"
}

remove_layout() {
  session=$1
  for option in renumber-windows @tab_label status-format status; do
    tmux set -u -t "$session" "$option"
  done
  for event in window-linked window-unlinked; do
    tmux set-hook -u -t "$session" "$event"
  done
}

# Per session, not global: a session-wide count would resize every session
# whenever any one of them gained a window.
set_line_count() {
  session=$1
  windows=$(tmux display -p -t "$session" '#{session_windows}') || return
  lines=$(((windows + WINDOWS_PER_LINE - 1) / WINDOWS_PER_LINE))
  [ "$lines" -gt "$MAX_STATUS_LINES" ] && lines=$MAX_STATUS_LINES
  [ "$lines" -le 1 ] && lines=on
  tmux set -t "$session" status "$lines"
}

# Renames the window to repo:branch for the file Claude last edited, else the
# session cwd. The name is remembered per Claude session so a resume restores
# it after the cwd has moved off the repo.
rename_window() {
  input=$1
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
  file=$(printf '%s' "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')

  dir=""
  [ -n "$file" ] && dir=$(dirname "$file")
  [ -z "$dir" ] && dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
  [ -z "$dir" ] && dir=$PWD

  state="${TMPDIR:-/tmp}/claude-tmux-title-${sid:-default}"
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    # The common dir is the main repo's .git, even from inside a worktree.
    common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    repo=$(basename "$(dirname "$common")")
    title="${repo:+$repo:}$branch"
    printf '%s' "$title" >"$state"
  else
    title=$(cat "$state" 2>/dev/null)
  fi

  tmux set -w -t "$TMUX_PANE" automatic-rename off
  tmux rename-window -t "$TMUX_PANE" "${title:-$(basename "$dir")}"
}

# Prints owner/repo for PR $1: a GitHub link in the transcript first, else the
# cwd's origin remote.
pr_repo() {
  repo=""
  if [ -f "$transcript" ]; then
    repo=$(grep -oE "github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/$1([^0-9]|$)" "$transcript" |
      head -1 | cut -d/ -f2,3)
  fi
  if [ -z "$repo" ]; then
    repo=$(git -C "$cwd" remote get-url origin 2>/dev/null |
      sed -nE 's#^.*github\.com[:/]([^/]+/[^/]+)$#\1#p' | sed 's/\.git$//')
  fi
  printf '%s' "$repo"
}

# macOS ships no `timeout`, but Homebrew coreutils provides `gtimeout`. Without
# either, gh runs unbounded, which is acceptable because the hook is async.
fetch_pr_title() {
  limit=$(command -v timeout || command -v gtimeout)
  if [ -n "$limit" ]; then
    "$limit" "$GH_TIMEOUT_SECONDS" gh pr view "$1" -R "$2" --json title -q .title 2>/dev/null
  else
    gh pr view "$1" -R "$2" --json title -q .title 2>/dev/null
  fi
}

# Stores Claude's session title, with PR numbers swapped for PR titles, as the
# window's @claude_title, next to the pane title it came from.
label_window() {
  input=$1
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

  # Same stripping as TAB_LABEL, so tmux can tell whether the label is current.
  src=$(tmux display -p -t "$TMUX_PANE" '#{s/^[^ ]+ //:pane_title}' 2>/dev/null)
  [ -n "$src" ] || return

  mkdir -p "$PR_TITLE_CACHE"
  label=$src
  for n in $(printf '%s' "$src" | grep -oE '(PR ?#?|#)[0-9]{3,}' | grep -oE '[0-9]+' | sort -u); do
    repo=$(pr_repo "$n")
    [ -n "$repo" ] || continue
    key="$PR_TITLE_CACHE/$(printf '%s' "$repo" | tr / _)_$n"
    if [ ! -s "$key" ]; then
      title=$(fetch_pr_title "$n" "$repo")
      [ -n "$title" ] && printf '%s' "$title" >"$key"
    fi
    [ -s "$key" ] || continue
    # Drops a leading ticket id such as "PB-123:" or "[PB-123]".
    title=$(sed -E 's/^\[?[A-Z][A-Z0-9]*-[0-9]+\]?:?[[:space:]]*//' "$key")
    # Replaces "[repo ]PR [#]N" or "#N" with the title. The repo word goes,
    # because the title implies it.
    label=$(printf '%s' "$label" | N="$n" R="$repo" T="$title" perl -pe '
      BEGIN { $r = quotemeta $ENV{R}; ($b = $ENV{R}) =~ s{.*/}{}; $b = quotemeta $b }
      s{(?:\b(?:$r|$b)\s+)?\bPR\s*#?$ENV{N}\b|#$ENV{N}\b}{$ENV{T}}gi')
  done

  tmux set -w -t "$TMUX_PANE" @claude_title "$label"
  tmux set -w -t "$TMUX_PANE" @claude_title_src "$src"
}

case $MODE in
  start)
    input=$(cat)
    session=$(session_of_pane) || exit 0
    tmux set -p -t "$TMUX_PANE" @claude_active 1
    apply_layout "$session"
    rename_window "$input"
    ;;
  title)
    rename_window "$(cat)"
    ;;
  label)
    label_window "$(cat)"
    ;;
  end)
    session=$(session_of_pane) || exit 0
    tmux set -p -u -t "$TMUX_PANE" @claude_active
    for option in @claude_title @claude_title_src automatic-rename; do
      tmux set -w -u -t "$TMUX_PANE" "$option"
    done
    # Another Claude still running in this session keeps the bar.
    tmux list-panes -s -t "$session" -F '#{@claude_active}' | grep -q 1 && exit 0
    remove_layout "$session"
    ;;
  lines)
    set_line_count "$2"
    ;;
esac 2>/dev/null
exit 0
