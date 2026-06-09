# dotfiles — GNU Stow management
# Each PKG dir mirrors $HOME; stow symlinks its contents into $HOME.

PKGS := zsh git tmux starship mise

.PHONY: install bootstrap link unlink relink dry

## install : full setup on a fresh machine (bootstrap tools, then link configs)
install: bootstrap link

## bootstrap : install system deps, mise tools, nvim + zsh plugins
bootstrap:
	./bootstrap.sh

## link : symlink all packages into $HOME (restow = safe to re-run)
link:
	stow -v -t $$HOME -R $(PKGS)

## unlink : remove the symlinks
unlink:
	stow -v -t $$HOME -D $(PKGS)

## relink : unlink then link
relink: unlink link

## dry : preview what link would do, no changes
dry:
	stow -n -v -t $$HOME -R $(PKGS)
