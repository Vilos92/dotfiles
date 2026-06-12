#!/bin/sh
#
# Regression test for tmux/.local/bin/gmux.
#
# gmux builds an fzf picker of tmux sessions + project directories. It has been
# heavily optimized (no per-row subprocesses, single tmux call, fork-free name
# resolution). This harness pins the externally observable behavior so future
# edits can't silently regress it. It is self-contained: it fabricates project
# directories and a fake tmux/fzf/attach-tmux-session, runs the real script, and
# asserts the picker contents and the `$1` fast-path attach calls against golden
# values.
#
# Behaviors covered:
#   - Directory discovery includes hidden dirs (.secret) like `find` (fd -H -I).
#   - Dotted dir names map to underscore session names (my.proj -> my_proj),
#     while the display keeps the original name.
#   - Dir names with spaces survive discovery, the picker, and attach.
#   - Status markers: attached session (green), other live sessions (blue),
#     project dirs without a session (new-moon).
#   - Picker rows are newline-separated (not concatenated onto one line).
#   - sort -u dedupes a project that is also a live session.
#   - `$1` fast-path: known project attaches with its path; unknown name
#     attaches with the supplied directory argument.
#
# Exits non-zero if any check fails.

set -u

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)
GMUX="$REPO_ROOT/tmux/.local/bin/gmux"

if [ ! -f "$GMUX" ]; then
    echo "FATAL: gmux not found at $GMUX" >&2
    exit 2
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/bin"
mkdir -p "$BIN"

# --- Fixture project directories (note: hidden, dotted, and spaced names) ---
PROJ="$WORK/greg_projects"
OTHER="$WORK/other_projects"
mkdir -p \
    "$PROJ/cynth" \
    "$PROJ/dotfiles" \
    "$PROJ/my.proj" \
    "$PROJ/with space" \
    "$PROJ/.secret" \
    "$OTHER/greg-zone" \
    "$OTHER/sparkify"

# --- Fixture tmux state -----------------------------------------------------
# dotfiles is attached (current); cynth and sparkify are projects that also
# have live sessions; scratch is a live session with no matching project.
MOCK_PIPE="dotfiles|1
cynth|0
scratch|0
sparkify|0"
export MOCK_PIPE

cat >"$BIN/tmux" <<'MOCK'
#!/bin/sh
# Only the pipe-delimited list-sessions form is used by the current gmux.
case "$*" in
    "list-sessions -F #{session_name}|#{session_attached}")
        printf '%s\n' "$MOCK_PIPE" ;;
    *)
        exit 0 ;;
esac
MOCK

cat >"$BIN/fzf" <<'MOCK'
#!/bin/sh
# Capture the candidate list; select nothing so gmux exits cleanly.
cat >"$FZF_CAPTURE"
exit 0
MOCK

cat >"$BIN/attach-tmux-session" <<'MOCK'
#!/bin/sh
printf 'ATTACH name=[%s] dir=[%s]\n' "$1" "$2" >"$ATTACH_CAPTURE"
exit 0
MOCK

chmod +x "$BIN/tmux" "$BIN/fzf" "$BIN/attach-tmux-session"

export PATH="$BIN:$PATH"
export GREG_PROJECTS_PATH="$PROJ"
export FRONTAPP_DIR="$OTHER"

fail=0
check() {
    label=$1
    expected=$2
    actual=$3
    if [ "$expected" = "$actual" ]; then
        printf 'ok   - %s\n' "$label"
    else
        printf 'FAIL - %s\n' "$label"
        printf '  expected:\n%s\n' "$expected" | sed 's/^/    /'
        printf '  actual:\n%s\n' "$actual" | sed 's/^/    /'
        fail=1
    fi
}

# --- Check 1: picker contents (sorted for a stable, order-independent compare).
menu_cap="$WORK/menu"
FZF_CAPTURE="$menu_cap" ATTACH_CAPTURE="$WORK/unused" sh "$GMUX" </dev/null >/dev/null 2>&1
menu_actual=$(sort "$menu_cap")
menu_expected=$(printf '%s\n' \
    '🌑 .secret	_secret' \
    '🌑 greg-zone	greg-zone' \
    '🌑 my.proj	my_proj' \
    '🌑 with space	with space' \
    '🔵 cynth	cynth' \
    '🔵 scratch	scratch' \
    '🔵 sparkify	sparkify' \
    '🟢 dotfiles	dotfiles' | sort)
check "picker rows match (status markers, display vs session name, newline-separated)" \
    "$menu_expected" "$menu_actual"

# Guard specifically against the "all rows mashed onto one line" regression.
menu_lines=$(grep -c . "$menu_cap")
check "picker has one row per option (8 lines)" "8" "$menu_lines"

# --- Check 2: $1 fast-path, known project with a dotted name.
cap="$WORK/a1"
FZF_CAPTURE="$WORK/unused" ATTACH_CAPTURE="$cap" sh "$GMUX" "my.proj" </dev/null >/dev/null 2>&1
actual=$(sed "s#$PROJ#<PROJ>#g" "$cap")
check "fast-path: known dotted project -> session name + project path" \
    'ATTACH name=[my_proj] dir=[<PROJ>/my.proj]' "$actual"

# --- Check 3: $1 fast-path, project name containing a space.
cap="$WORK/a2"
FZF_CAPTURE="$WORK/unused" ATTACH_CAPTURE="$cap" sh "$GMUX" "with space" </dev/null >/dev/null 2>&1
actual=$(sed "s#$PROJ#<PROJ>#g" "$cap")
check "fast-path: spaced project name -> attach with quoted path" \
    'ATTACH name=[with space] dir=[<PROJ>/with space]' "$actual"

# --- Check 4: $1 fast-path, unknown name falls back to the supplied directory.
cap="$WORK/a3"
FZF_CAPTURE="$WORK/unused" ATTACH_CAPTURE="$cap" sh "$GMUX" "nope" "/tmp/x" </dev/null >/dev/null 2>&1
actual=$(cat "$cap")
check "fast-path: unknown name -> attach with provided directory arg" \
    'ATTACH name=[nope] dir=[/tmp/x]' "$actual"

echo "---"
if [ "$fail" -eq 0 ]; then
    echo "PASS: gmux behavior matches the golden spec"
else
    echo "FAIL: gmux behavior regressed (see above)"
fi
exit "$fail"
