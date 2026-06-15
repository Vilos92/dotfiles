# Tiered startup — instant prompt first, then PATH/exports, lazy tools, full theme, pre/post hooks.

# 1. Instant prompt. Nothing slow can run before this.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 2. PATH and exports. Builtins and cache reads only.
export PATH="$HOME/.local/bin:$PATH"
export GREG_PROJECTS_PATH="$HOME/greg_projects"
export GREG_DOTFILES_PATH="$GREG_PROJECTS_PATH/dotfiles"
export ALACRITTY_PATH="$HOME/.config/alacritty"

_pybin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/python-user-bin.path"
_pybin_added=
if [[ -f "$_pybin_cache" ]]; then
  _pybin="$(<"$_pybin_cache")"
  if [[ -d "$_pybin" ]]; then
    export PATH="$_pybin:$PATH"
    _pybin_added=1
  fi
fi
unset _pybin

if [[ -z $_pybin_added ]] && command -v python3 >/dev/null; then
  ( _c="$_pybin_cache"; mkdir -p "${_c:h}"; print -r -- "$(python3 -m site --user-base)/bin" >| "$_c" ) &!
fi
unset _pybin_cache _pybin_added

zshenv_path="$HOME/.zshenv"

# Early hooks from other stow packages (arch, mac-mini). Not core zsh config.
for _file in "$zshenv_path/init"/*.sh(N); do
  [[ -f "$_file" ]] && source "$_file"
done
unset _file

# 3. Lazy tool wrappers. No subprocess until first use.
# Stowed post/*.zsh first, then dotfiles checkout so new files work before restow.
typeset -A _zsh_post_sourced
for _dir in "$zshenv_path/post" "$GREG_DOTFILES_PATH/zsh/.zshenv/post"(N); do
  for _file in "$_dir"/*.zsh(N); do
    _name=${_file:t}
    (( ${+_zsh_post_sourced[$_name]} )) && continue
    [[ -f "$_file" ]] || continue
    source "$_file"
    _zsh_post_sourced[$_name]=1
  done
done
unset _dir _file _name _zsh_post_sourced

# 4. Full p10k at open — instant prompt alone is too bare.
autoload -Uz compinit
compinit -C

_p10k_theme="$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$_p10k_theme" ]] && source "$_p10k_theme"
unset _p10k_theme

for _file in "$zshenv_path/pre"/*.sh(N); do
  [[ -f "$_file" ]] && source "$_file"
done
unset _file

# 5. Aliases and the rest of post/*.sh.
for _file in "$zshenv_path/post"/*.sh(N); do
  [[ -f "$_file" ]] && source "$_file"
done
unset _file

alias zshsource='source ~/.zshrc'
