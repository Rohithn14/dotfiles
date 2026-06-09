# 🧰 Dev Toolkit Reference — Ubuntu 26.04 (WSL2)

A practical guide to the development environment installed on this machine: **what each
tool is, why it's here, and how to actually use it.** Written to be skimmed when you need
a command and read end-to-end to build fluency.

- **OS:** Ubuntu 26.04 LTS (Resolute Raccoon) on WSL2 · kernel 6.6
- **Shell:** `zsh` (login shell) · prompt: `starship`
- **Tool manager:** `mise` (user-level, no sudo) · **Python:** `uv` + `pipx`
- **Config style:** dotfiles symlinked from `~/projects/dotfiles` (cloned from
  [Aman1337g/dotfiles](https://github.com/Aman1337g/dotfiles))

> **Mental model.** Three layers:
> 1. **System (apt, needs sudo):** compilers, libraries, the `zsh` binary — things the OS owns.
> 2. **User CLI tools (`mise`):** modern command-line tools + language runtimes, all under `~/.local`. No sudo, easy to upgrade/pin/remove.
> 3. **Per-project (`uv`, `npm`):** dependencies isolated to each project, never global.

---

## Table of contents
1. [mise — the tool & runtime manager](#1-mise)
2. [Shell: zsh + starship + plugins](#2-shell)
3. [Modern CLI replacements (eza, bat, fd, ripgrep, fzf, zoxide)](#3-modern-cli)
4. [yazi — terminal file manager](#4-yazi)
5. [Node.js & npm](#5-node)
6. [Python: uv & pipx](#6-python)
7. [C / C++ toolchain & cmake](#7-cpp)
8. [Git + delta](#8-git)
9. [GitHub CLI (gh) & SSH](#9-gh)
10. [Neovim (LazyVim)](#10-neovim)
11. [tmux — terminal multiplexer](#11-tmux)
12. [Where everything lives (paths)](#12-paths)
13. [Day-to-day cheat sheet](#13-cheatsheet)
14. [Maintenance, upgrades & rollback](#14-maintenance)
15. [Still to do (manual)](#15-todo)

---

<a name="1-mise"></a>
## 1. mise — the tool & runtime manager   `v2026.5`

**What it is.** A single tool that installs and version-manages CLI tools *and* language
runtimes (the job previously split across `nvm`, `pyenv`, `asdf`, `rbenv`, …). It reads a
declarative config and puts shims on your `PATH`.

**Why it's here.** Everything modern in this setup (neovim, node, eza, gh, delta…) is
installed through mise. One file describes the whole toolbox; reproducible on any machine.

**Config:** `~/.config/mise/config.toml` — the source of truth.
```toml
[tools]
neovim = "latest"
node   = "lts"
# eza, bat, fd, fzf, zoxide, yazi, starship, usage,
# aqua:cli/cli (gh), aqua:dandavison/delta ...
```

**Everyday commands**
```bash
mise ls                 # what's installed + versions
mise install            # install everything in config.toml
mise use -g node@22     # pin a global version (writes to config)
mise use node@20        # pin a version for THIS project (creates ./.mise.toml)
mise upgrade            # upgrade tools tracking "latest"
mise outdated           # show what could be upgraded
mise which node         # real path behind a shim
mise reshim             # regenerate shims after manual installs
mise doctor             # diagnose setup problems
```

**Key idea — per-project versions.** Drop a `.mise.toml` (or `.tool-versions`) in a repo
to pin its runtime. `cd` into the dir → mise auto-switches. This is activated in `~/.zshrc`
via `eval "$(mise activate zsh)"`.

> **Adding a new language** (e.g. Go, Rust, Java) is one line:
> `mise use -g go@latest` — then `go` is on your PATH. No other setup.

---

<a name="2-shell"></a>
## 2. Shell: zsh + starship + plugins

**zsh** is your login shell (`/usr/bin/zsh`). Config: `~/.zshrc`. Your original bash files
are preserved as `~/.bashrc.orig` / `~/.profile.orig`.

**starship** `v1.25` — a fast, language-aware prompt. Shows git branch/status, language
versions, exit codes, durations. Theme config: `~/.config/starship.toml` (Nord). Edit that
file to change segments; changes apply on the next prompt.

**Plugins** (in `~/.config/zsh/plugins`, sourced by `.zshrc`):
- **zsh-autosuggestions** — ghost-text suggestions from history. Press **→** (right arrow) or **End** to accept.
- **zsh-syntax-highlighting** — commands turn green (valid) / red (typo) as you type.
- **zsh-completions** — extra completion definitions.

**Useful zsh behaviors configured**
- Shared, de-duplicated history (50k lines) across all tabs.
- `Tab` → menu-select completion; case-insensitive matching.
- Aliases (see [cheat sheet](#13-cheatsheet)).

```bash
exec zsh        # reload the shell after editing ~/.zshrc
```

---

<a name="3-modern-cli"></a>
## 3. Modern CLI replacements

Faster, friendlier rewrites of classic Unix tools. Aliases in `~/.zshrc` wire some to the
familiar names.

### eza — `ls` replacement   `v0.23`
Colorful, git-aware listings. Aliased: `ls`, `ll`, `la`, `lt`.
```bash
ll                         # long, all, human sizes, git status (alias)
eza --tree --level=3       # tree view
eza -l --sort=modified     # sort by mtime
eza -l --git --header      # show git status column
```

### bat — `cat` replacement   `v0.26`
`cat` with syntax highlighting + line numbers + git diff gutter. Aliased to `cat`.
```bash
bat file.py                # pretty print
bat -p file.py             # plain (no decorations) — good for piping
bat -A file                # show whitespace/non-printing chars
bat -l json < data         # force a language
```

### fd — `find` replacement   `v10.4`
Intuitive, fast file search. Respects `.gitignore` by default.
```bash
fd report                  # find files matching "report"
fd -e md                   # all .md files
fd -H pattern              # include hidden files
fd -t d src                # directories only
fd pattern -x wc -l        # run a command per match
```

### ripgrep (rg) — `grep` replacement   `v15`
Recursively search file *contents* extremely fast. `.gitignore`-aware.
```bash
rg "TODO"                  # search everything under cwd
rg -i "error" -t py        # case-insensitive, Python files only
rg -l "import requests"    # list matching files only
rg -A3 -B3 "panic"         # 3 lines of context around matches
rg "func (\w+)" -r '$1'    # regex with replacement preview
```

### fzf — fuzzy finder   `v0.73`
Interactive filter for *any* list. Integrated into zsh:
- **Ctrl-R** — fuzzy-search command history (huge productivity win).
- **Ctrl-T** — insert a file path into the current command.
- **Alt-C** — `cd` into a fuzzy-picked subdirectory.
```bash
vim "$(fzf)"               # pick a file, open it
git switch "$(git branch | fzf)"   # pick a branch
fd -t f | fzf --preview 'bat --color=always {}'   # picker with preview
```

### zoxide — smarter `cd`   `v0.9`
Learns your most-used directories. After visiting dirs a few times:
```bash
z proj          # jump to the best match for "proj"
z dot fig       # match on multiple fragments
zi              # interactive pick (fzf) among known dirs
```

---

<a name="4-yazi"></a>
## 4. yazi — terminal file manager   `v26.5`

A fast, visual file manager in the terminal with image previews.
```bash
yazi            # launch (q to quit)
```
**Keys:** `h/j/k/l` navigate · `Enter` open · `Space` select · `y` yank · `p` paste ·
`d` cut · `/` search · `.` toggle hidden. Great for bulk file ops without leaving the shell.

---

<a name="5-node"></a>
## 5. Node.js & npm   `node v24 (LTS) · npm v11`

Managed by mise (native Linux build — replaces the slow Windows `node` that used to shadow
the PATH via `/mnt/c`).
```bash
node -v ; npm -v
npm init -y                # new project
npm install <pkg>          # add dependency (to ./node_modules)
npm install -g <cli>       # global CLI (lands under mise's node)
npx <tool>                 # run a package without installing
corepack enable            # turn on pnpm / yarn shims (mise-managed node)
```
**Pin a version per project:** `mise use node@20` → writes `.mise.toml`, auto-switches on `cd`.

---

<a name="6-python"></a>
## 6. Python: uv & pipx   `uv v0.11 · pipx v1.13 · python 3.14`

> **Important:** system Python 3.14 is *externally managed* (PEP 668). **Never**
> `sudo pip install` or `pip install` into it — it's blocked and would break the OS.
> Use the tools below instead.

### uv — project & environment manager (the fast one)
Replaces `pip`, `venv`, `pip-tools`, and `pyenv` for project work. Rust-fast.
```bash
uv venv                       # create .venv in current project
source .venv/bin/activate     # (or let uv run things for you)
uv pip install requests       # install into the venv
uv add requests               # add to pyproject.toml + lockfile (project mode)
uv run script.py              # run in the project env (auto-creates/syncs)
uv python install 3.12        # install another Python version
uv sync                       # reproduce env from uv.lock
uv tool run <cli>             # run a CLI tool ephemerally (alias: uvx)
```

### pipx — install Python CLI apps globally but isolated
Each app gets its own venv; no dependency clashes. (Installed via `uv tool`.)
```bash
pipx install ruff             # global CLI, isolated
pipx list                     # what's installed
pipx upgrade-all
pipx run <tool>               # one-off without installing
```
**Rule of thumb:** project libraries → `uv`; standalone command-line apps → `pipx` (or `uv tool`).

---

<a name="7-cpp"></a>
## 7. C / C++ toolchain & cmake   `gcc/g++ 15 · cmake`

From `build-essential` (apt). Needed to compile native code — including npm native modules
and some Python wheels.
```bash
gcc main.c -o main && ./main
g++ -std=c++23 -O2 main.cpp -o main
make                          # uses a Makefile
# CMake project:
cmake -S . -B build && cmake --build build -j
```

---

<a name="8-git"></a>
## 8. Git + delta   `git 2.53 · delta 0.19`

Global config: `~/.gitconfig` (your email is set; **set your name** — see [§15](#15-todo)).
Defaults configured: `init.defaultBranch=main`, `push.autoSetupRemote=true`,
`pull.rebase=false`, editor `nvim`.

**delta** is the pager: syntax-highlighted, side-by-side-capable diffs with line numbers.
It activates automatically for `git diff`, `git log -p`, `git show`.
```bash
git diff                      # now rendered by delta
git log -p                    # highlighted history
git config --global delta.side-by-side true   # toggle split view
```
**Handy aliases** (from `~/.zshrc`): `gs` status · `ga` add · `gc` commit · `gp` push ·
`gl` pretty log · `gd` diff.

---

<a name="9-gh"></a>
## 9. GitHub CLI (gh) & SSH   `gh 2.93`

**gh** drives GitHub from the terminal — PRs, issues, repos, releases, Actions.
```bash
gh auth login                 # one-time: authenticate (do this — see §15)
gh repo clone owner/name
gh repo create myproj --private --source=. --push
gh pr create --fill           # open a PR from the current branch
gh pr status / gh pr checkout 123
gh issue list / gh issue create
gh run watch                  # watch the latest Actions run
```
**SSH:** an `ed25519` key exists at `~/.ssh/id_ed25519`. Add the public key to GitHub
(`~/.ssh/id_ed25519.pub`), then `ssh -T git@github.com` to verify. Or let gh manage it:
`gh ssh-key add ~/.ssh/id_ed25519.pub`.

---

<a name="10-neovim"></a>
## 10. Neovim (LazyVim)   `v0.12`

Config: `~/.config/nvim` → symlinked to `~/projects/dotfiles/nvim`. It's a
[LazyVim](https://www.lazyvim.org/) distribution (sensible IDE-like defaults, DevOps-leaning).
```bash
nvim                          # launch
```
**First launch** finishes installing LSP servers/formatters via **Mason** (a few were still
downloading when we bootstrapped headlessly — they complete automatically now).

**Essential keys** (LazyVim, leader = `Space`):
- `Space` (alone) — pop-up which-key menu of everything.
- `Space ff` — find files (fzf) · `Space fg` — live grep · `Space e` — file explorer.
- `Space ,` — switch buffers · `Space bd` — close buffer.
- `gd` go to definition · `gr` references · `K` hover docs · `Space ca` code action.
- `:Lazy` — plugin manager UI · `:Mason` — LSP/tool installer · `:checkhealth` — diagnostics.

> If glyphs/icons look broken, install a **Nerd Font on Windows** and select it in the
> terminal (see [§15](#15-todo)) — WSL can't set its own terminal font.

---

<a name="11-tmux"></a>
## 11. tmux — terminal multiplexer

Keep multiple shells/panes in one window; sessions survive disconnects. Config:
`~/.tmux.conf` → `~/projects/dotfiles/tmux` (Nord theme; pane nav on `Alt+h/j/k/l`).
```bash
tmux                          # start a session
tmux new -s work              # named session
tmux ls                       # list sessions
tmux attach -t work           # reattach
```
**Inside** (prefix is `Ctrl-b` unless remapped): `prefix "` split horizontal ·
`prefix %` split vertical · `Alt+h/j/k/l` move between panes · `prefix d` detach ·
`prefix c` new window · `prefix [` scroll/copy mode (`q` to exit).

---

<a name="12-paths"></a>
## 12. Where everything lives

| Path | What |
|---|---|
| `~/.config/mise/config.toml` | Declared tools & runtimes (edit to add/remove) |
| `~/.local/share/mise/shims/` | Shims that put mise tools on PATH |
| `~/.local/share/mise/installs/` | Actual tool binaries |
| `~/.local/bin/` | `mise`, `uv`, `pipx`, `delta` symlink |
| `~/.zshrc` | Shell config, aliases, tool hooks |
| `~/.config/zsh/plugins/` | zsh plugins |
| `~/.config/starship.toml` | Prompt theme (→ `~/projects/dotfiles`) |
| `~/.config/nvim` | Neovim config (→ `~/projects/dotfiles`) |
| `~/.tmux.conf` | tmux config (→ `~/projects/dotfiles`) |
| `~/.gitconfig` | Git identity & delta settings |
| `~/projects/dotfiles/` | Cloned dotfiles repo (symlink source) |
| `~/.bashrc.orig`, `~/.profile.orig` | Pre-setup backups |
| `~/setup-baseline-pkgs.txt` | apt package snapshot from before setup |

---

<a name="13-cheatsheet"></a>
## 13. Day-to-day cheat sheet

```text
# Navigation / files
z <dir>            jump to a frequent directory      (zoxide)
ll / la / lt       list / list all / tree            (eza)
cat <file>         syntax-highlighted view           (bat)
fd <name>          find files                        (fd)
rg <text>          search file contents              (ripgrep)
yazi               visual file manager
Ctrl-R             fuzzy history search              (fzf)
Ctrl-T             insert file path                  (fzf)
Alt-C              fuzzy cd                          (fzf)

# Git
gs / ga / gc / gp  status / add / commit / push
gl                 pretty graph log
git diff           delta-rendered diff
gh pr create --fill open a PR

# Runtimes
mise ls            installed tools & versions
mise use node@20   pin node for this project
uv venv && uv add  python project env + deps
npm i <pkg>        node deps

# Editor / multiplexer
nvim               LazyVim (Space = menu)
tmux               multiplexer
```

---

<a name="14-maintenance"></a>
## 14. Maintenance, upgrades & rollback

**Upgrade tools**
```bash
mise upgrade          # CLI tools + runtimes on "latest"
mise outdated         # preview first
uv self update        # uv itself
pipx upgrade-all      # pipx apps
sudo apt update && sudo apt upgrade   # system packages (run in a real terminal — needs password)
```

**Add a tool** → edit `~/.config/mise/config.toml`, then `mise install`.
Or quick: `mise use -g <tool>@latest`.

**Remove a tool** → delete its line from the config (or `mise rm <tool>`), then `mise prune`.

**Rollback the whole setup**
- Restore the old shell config: `cp ~/.bashrc.orig ~/.bashrc` and `chsh -s /bin/bash`.
- Remove user tools: everything is under `~/.local` and `~/.config` — deleting those dirs reverts the user layer.
- Config symlinks: `rm ~/.config/nvim ~/.tmux.conf ~/.config/starship.toml` removes the dotfile links (originals stay in `~/projects/dotfiles`).

> **WSL-level safety net:** from Windows PowerShell you can snapshot/restore the entire distro:
> `wsl --export Ubuntu C:\wsl-backups\ubuntu.tar` and `wsl --import ... `.

---

<a name="15-todo"></a>
## 15. Still to do (manual, one-time)

These need an interactive terminal / browser / Windows host and weren't automatable:

1. **Set your git name:** `git config --global user.name "Your Name"`
2. **Add SSH key to GitHub:** copy `~/.ssh/id_ed25519.pub` → https://github.com/settings/keys,
   then verify: `ssh -T git@github.com`
3. **Authenticate gh:** `gh auth login`
4. **Nerd Font on Windows:** install *JetBrainsMono Nerd Font* on the Windows host and select
   it in your terminal profile (so nvim/starship icons render). WSL can't set its own font.
5. **(Recommended) Change your password:** `passwd` — it was exposed in a chat session during setup.

---

*Generated as part of the WSL dev-environment setup. Tweak any config in the paths above;
they're all plain text and version-controllable.*
