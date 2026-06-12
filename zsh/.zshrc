# Fast zsh startup: instant prompt first, full p10k immediately after, lazy zoxide.

# 1. Instant prompt — must run before anything slow.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. Fast PATH + exports (builtins / cached reads only).
export PATH="$HOME/.local/bin:$PATH"
export GREG_PROJECTS_PATH="$HOME/greg_projects"
export GREG_DOTFILES_PATH="$GREG_PROJECTS_PATH/dotfiles"
export ALACRITTY_PATH="$HOME/.config/alacritty"

_pybin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/python-user-bin.path"
if [[ -f "$_pybin_cache" ]]; then
  _pybin="$(<"$_pybin_cache")"
  [[ -d "$_pybin/bin" ]] && export PATH="$_pybin/bin:$PATH"
fi
unset _pybin_cache _pybin

if [[ ! -f "${XDG_CACHE_HOME:-$HOME/.cache}/python-user-bin.path" ]] && command -v python3 >/dev/null; then
  ( _c="${XDG_CACHE_HOME:-$HOME/.cache}/python-user-bin.path"; mkdir -p "${_c:h}"; python3 -m site --user-base >|"$_c" ) &!
fi

zshenv_path="$HOME/.zshenv"
[[ -f "$zshenv_path/init/sway.sh" ]] && source "$zshenv_path/init/sway.sh"

# 3. Lazy tool wrappers (no subprocess until first use).
for _file in "$zshenv_path/post"/*.zsh(N); do
  source "$_file"
done
unset _file

# 4. Full prompt — load right after instant prompt so the rich p10k UI appears at open.
autoload -Uz compinit
compinit -C

_p10k_theme="$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$_p10k_theme" ]] && source "$_p10k_theme"
unset _p10k_theme

for _file in "$zshenv_path/pre"/*.sh(N); do
  [[ "$(basename "$_file")" == ohmyzsh.sh ]] && continue
  source "$_file"
done
unset _file

# 5. Aliases and remaining config.
for _file in "$zshenv_path/post"/*.sh(N); do
  source "$_file"
done
unset _file

alias zshsource='source ~/.zshrc'
