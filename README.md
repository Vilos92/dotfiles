# dotfiles 

My personal dotfiles and other configurations.

Be sure to include that `-a` flag.

## Packages

To install the packages I use, run the following script:

```bash
sh scripts/brews.sh
```

## Stow

To create symlinks for the dotfiles, use `stow`. 

A convenience script exists to do this:

```bash
sh scripts/stow.sh
```

For each package, the above script will ask if you want to stow it.

To stow a specific package, you can run the following:

```bash
sh scripts/stow.sh <package>
```

## Notes

These are dot files, so if you want to see them:

```bash
ls -a
```
