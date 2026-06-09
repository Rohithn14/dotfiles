#!/usr/bin/env bash
# bootstrap.sh — stand up the dev environment on a fresh WSL/Ubuntu machine.
# Idempotent: every phase is guarded, so re-running is safe.
#
# Tool philosophy: mise (~/.config/mise/config.toml) is the source of truth for
# CLI tools and runtimes. apt only provides the lifelines mise itself needs.

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PLUGIN_DIR="$HOME/.config/zsh/plugins"
NVIM_DIR="$HOME/.config/nvim"
NVIM_REPO="https://github.com/nvim-lua/kickstart.nvim.git"

_has() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# ── 1. System lifelines (apt, needs sudo) ─────────────────────────────────
# NOTE: must NOT abort the whole bootstrap if apt fails (e.g. sudo password
# cancelled, no network, behind a proxy) — mise installs everything else and
# is the part that actually matters. So this block is best-effort.
APT_BASE=(git curl unzip stow build-essential ca-certificates zsh jq)
if _has apt-get; then
  if ! dpkg -s "${APT_BASE[@]}" >/dev/null 2>&1; then
    log "Installing apt lifelines: ${APT_BASE[*]}"
    sudo apt-get update -y || log "WARN: apt update failed — continuing"
    sudo apt-get install -y "${APT_BASE[@]}" || log "WARN: apt install failed — continuing"
  else
    log "apt lifelines already present — skipping"
  fi
fi

# ── 2. mise + all declared tools ──────────────────────────────────────────
# Resolve mise by ABSOLUTE path — right after the installer it is not yet on
# the inherited PATH, so `command -v mise` can miss it and the tools silently
# never install. This is the #1 cause of "configs present but binaries gone".
MISE_BIN="$HOME/.local/bin/mise"
if ! _has mise && [[ ! -x "$MISE_BIN" ]]; then
  log "Installing mise"
  curl -fsSL https://mise.run | sh
fi
# Prefer a mise already on PATH; otherwise fall back to the known install path.
_has mise && MISE_BIN="$(command -v mise)"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if [[ -x "$MISE_BIN" ]]; then
  log "Trusting + installing tools from mise config.toml"
  "$MISE_BIN" trust --yes "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
  "$MISE_BIN" install --yes
  "$MISE_BIN" reshim >/dev/null 2>&1 || true
  log "Installed tools:"
  "$MISE_BIN" ls --installed 2>/dev/null || "$MISE_BIN" ls
else
  log "ERROR: mise not found after install — cannot provision tools."
  log "Fix: run 'curl https://mise.run | sh' then 're-run ./bootstrap.sh'."
  exit 1
fi

# ── 3. zsh plugins (cloned, not vendored) ─────────────────────────────────
clone_plugin() {  # $1 repo-url  $2 dest-name
  local dest="$PLUGIN_DIR/$2"
  if [[ -d "$dest/.git" ]]; then
    log "plugin $2 present — skipping"
  else
    log "Cloning plugin $2"
    git clone --depth 1 "$1" "$dest"
  fi
}
mkdir -p "$PLUGIN_DIR"
clone_plugin https://github.com/zsh-users/zsh-autosuggestions     zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
clone_plugin https://github.com/zsh-users/zsh-completions         zsh-completions

# ── 4. Neovim config (upstream kickstart.nvim) ────────────────────────────
# NOTE: this clones upstream kickstart. If you customize nvim, fork it and
# point NVIM_REPO at your fork so changes are tracked.
if [[ -e "$NVIM_DIR" ]]; then
  log "nvim config present at $NVIM_DIR — skipping clone"
else
  log "Cloning nvim config (kickstart.nvim)"
  git clone --depth 1 "$NVIM_REPO" "$NVIM_DIR"
fi

# ── 5. Default shell → zsh ─────────────────────────────────────────────────
if _has zsh && [[ "${SHELL:-}" != *zsh ]]; then
  log "Setting login shell to zsh (may prompt for password)"
  chsh -s "$(command -v zsh)" || log "chsh skipped — set it manually with: chsh -s \$(command -v zsh)"
fi

log "Bootstrap complete. Next:  cd $DOTFILES_DIR && make link  (then: exec zsh)"
log "Manual one-time steps: ssh-keygen, gh auth login, git config --global user.name"
