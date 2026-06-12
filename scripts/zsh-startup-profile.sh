#!/bin/sh
#
# Profile zsh startup time and print a per-stage breakdown.
#
# Usage:
#   scripts/zsh-startup-profile.sh          # full interactive startup (realistic)
#   scripts/zsh-startup-profile.sh --detail # per sourced file inside ~/.zshrc
#   scripts/zsh-startup-profile.sh --zprof  # top zsh functions (compinit, omz, p10k)
#
# Exits 0 always; this is a diagnostic tool, not a test harness.

set -u

mode=${1:-}

now_ms() {
    perl -MTime::HiRes=time -e 'printf "%.0f\n", time()*1000'
}

tick() {
    label=$1
    n=$(now_ms)
    printf '%s\t+%sms\ttotal=%sms\n' "$label" "$((n - last))" "$((n - start))"
    last=$n
}

run_timed() {
    label=$1
    shift
    start=$(now_ms)
    last=$start
    "$@" >/dev/null 2>&1
    n=$(now_ms)
    printf '%s\t%sms\n' "$label" "$((n - start))"
}

echo "=== zsh startup profile $(date '+%Y-%m-%dT%H:%M:%S%z') ==="
echo "host=$(hostname -s 2>/dev/null || hostname)"
echo "zsh=$(zsh --version 2>/dev/null | head -1)"
echo

echo "--- wall-clock (what a new pane/window pays) ---"
run_timed "zsh -ic exit (interactive, non-login)" sh -c 'zsh -ic "exit"'
run_timed "zsh -lic exit (interactive, login)" sh -c 'zsh -lic "exit"'
echo

if [ "$mode" = "--zprof" ]; then
    echo "--- zprof (top 15 functions during source ~/.zshrc) ---"
    zsh --no-rcs -ic '
        zmodload zsh/zprof
        source ~/.zshrc
        zprof | head -15
    ' 2>/dev/null
    echo
fi

if [ "$mode" = "--detail" ] || [ "$mode" = "--zprof" ]; then
    echo "--- per-file breakdown (mirrors ~/.zshrc source order) ---"
    zsh --no-rcs -ic '
        _now_ms() {
            local t=$EPOCHREALTIME
            print $(( ${t%%.*} * 1000 + ${t#*.} / 1000000 ))
        }
        _start_ms=$(_now_ms)
        _last_ms=$_start_ms
        _tick() {
            typeset -i now=$(_now_ms)
            print -u2 "$1 +$(( now - _last_ms ))ms total=$(( now - _start_ms ))ms"
            _last_ms=$now
        }

        zshenv_path="$HOME/.zshenv"
        for file in $zshenv_path/init/*.sh(N); do
            source "$file"
            _tick "init/$(basename $file)"
        done

        if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
            source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
            _tick "p10k-instant-prompt"
        fi

        for file in $zshenv_path/pre/*.sh(N); do
            source "$file"
            _tick "pre/$(basename $file)"
        done
        for file in $zshenv_path/post/*.sh(N); do
            source "$file"
            _tick "post/$(basename $file)"
        done
        _tick "done"
    ' 2>&1
    echo
fi

echo "--- subprocess probes (common fork-heavy init) ---"
run_timed "python3 -m site --user-base" sh -c 'python3 -m site --user-base >/dev/null'
if command -v fnm >/dev/null 2>&1; then
    run_timed "fnm env --use-on-cd" sh -c 'fnm env --use-on-cd >/dev/null'
else
    echo "fnm env --use-on-cd	(skipped: fnm not found)"
fi
if command -v zoxide >/dev/null 2>&1; then
    run_timed "zoxide init zsh" sh -c 'zoxide init zsh >/dev/null'
else
    echo "zoxide init zsh	(skipped: zoxide not found)"
fi
echo

echo "--- gitstatus / p10k health ---"
if [ -x "$HOME/.cache/gitstatus/gitstatusd-darwin-arm64" ]; then
    gitstatus_date=$(stat -f '%Sm' -t '%Y-%m-%d' "$HOME/.cache/gitstatus/gitstatusd-darwin-arm64" 2>/dev/null || echo unknown)
    gitstatus_ver=$("$HOME/.cache/gitstatus/gitstatusd-darwin-arm64" --version 2>/dev/null || echo unknown)
    echo "cached gitstatusd: version=$gitstatus_ver built=$gitstatus_date"
else
    echo "cached gitstatusd: (missing)"
fi
if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/.git" ]; then
    p10k_rev=$(git -C "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" log -1 --oneline 2>/dev/null || echo unknown)
    echo "powerlevel10k: $p10k_rev"
fi
if zsh -ic 'exit' 2>&1 | rg -q 'gitstatus failed to initialize'; then
    echo "gitstatus init: ERROR on last zsh -ic (see message above when starting zsh)"
    echo "  try: rm -rf ~/.cache/gitstatus && exec zsh"
    echo "  then: git -C ~/.oh-my-zsh/custom/themes/powerlevel10k pull"
else
    echo "gitstatus init: ok (no error seen on last zsh -ic)"
fi
echo
echo "Tip: run with --detail or --zprof for deeper breakdowns."
