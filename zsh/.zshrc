export GREG_DOTFILES_PATH=~/greg_projects/dotfiles

# zsh environment setup.
zshenv_path="$HOME/.zshenv"

# Run all environment pre-scripts.
for file in $zshenv_path/pre/*.sh; do
  if [ -f "$file" ]; then
    source "$file"
  fi
done

# Run all environment post-scripts.
for file in $zshenv_path/post/*.sh; do
  if [ -f "$file" ]; then
    source "$file"
  fi
done
