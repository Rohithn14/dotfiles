# dotfiles — GNU Stow management
# Each PKG dir mirrors $HOME; stow symlinks its contents into $HOME.

PKGS := zsh git tmux starship mise

.PHONY: install bootstrap link unlink relink dry doctor

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

## doctor : diagnose why tools/binaries may be missing on this machine
doctor:
	@echo "── mise ──────────────────────────────────────────"
	@command -v mise >/dev/null 2>&1 && mise --version || echo "  mise: NOT on PATH (check ~/.local/bin in PATH)"
	@echo "── installed tools (mise) ────────────────────────"
	@command -v mise >/dev/null 2>&1 && mise ls --installed 2>/dev/null || echo "  (mise unavailable)"
	@echo "── shims dir ─────────────────────────────────────"
	@ls $$HOME/.local/share/mise/shims >/dev/null 2>&1 && echo "  present" || echo "  MISSING — run: mise reshim"
	@echo "── binary resolution in THIS shell ───────────────"
	@for b in eza bat fd starship zoxide fzf node gh delta; do printf '  %-9s ' $$b; command -v $$b 2>/dev/null || echo MISSING; done
	@echo "── symlinks ──────────────────────────────────────"
	@for f in $$HOME/.zshrc $$HOME/.gitconfig $$HOME/.config/mise/config.toml; do printf '  %-26s -> ' $$f; readlink $$f 2>/dev/null || echo "NOT A SYMLINK"; done
