# dotfiles

Single source of truth for my WSL/Ubuntu dev environment, synced across machines with Git.
Configs are symlinked into `$HOME` with **GNU Stow**; tools are reproduced with **mise**.

See [`docs/DEV_TOOLKIT.md`](docs/DEV_TOOLKIT.md) for a full tour of the installed toolchain.

## What's managed

| Package    | Symlinks into                         |
|------------|---------------------------------------|
| `zsh`      | `~/.zshrc`, `~/.aliases`              |
| `git`      | `~/.gitconfig`                       |
| `tmux`     | `~/.tmux.conf`                       |
| `starship` | `~/.config/starship.toml`           |
| `mise`     | `~/.config/mise/config.toml`        |

Not stored here (recreated by `bootstrap.sh`): the **nvim** config (upstream
`kickstart.nvim`) and the **zsh plugins**. Secrets (SSH keys, `gh` token, history) are
git-ignored and never committed.

## New machine

```bash
git clone <repo-url> ~/projects/dotfiles
cd ~/projects/dotfiles
make install        # bootstrap (apt + mise + nvim/plugin clones) then stow-link
exec zsh
```

### Manual one-time steps
1. `ssh-keygen -t ed25519 -C "you@example.com"` → add `~/.ssh/id_ed25519.pub` to
   <https://github.com/settings/keys> → verify `ssh -T git@github.com`
2. `gh auth login`
3. `git config --global user.name "Your Name"` (email is in the tracked `.gitconfig`)
4. Install **JetBrainsMono Nerd Font** on the Windows host and select it in the terminal
   (WSL can't set its own font).

## Daily / Makefile targets

```bash
make link      # (re)create symlinks — run after adding a new package
make dry       # preview links without changing anything
make unlink    # remove symlinks
make bootstrap # (re)install tools only
```

## Syncing between machines (bidirectional)

Because Stow symlinks `~/.zshrc` → this repo, **editing the file in `$HOME` edits the repo
file directly**. So:

```bash
# after changing any config:
cd ~/projects/dotfiles && git commit -am "tweak" && git push

# on the other laptop:
git pull            # symlinks already point here → changes apply instantly
mise install        # only if mise/config.toml changed
make link           # only if a NEW package was added
```

## Machine-specific config

Per-host bits (installer paths, one-off env) go in `~/.zshrc.local`, which the tracked
`.zshrc` sources at the end. It's git-ignored, so each machine keeps its own.
