# ~/.zshrc — interactive zsh config
# Authored during dev-env setup. Safe to re-source; all tool hooks are guarded.

# ---------------------------------------------------------------------------
# PATH (single, de-duplicated ~/.local/bin entry — fixes the bash duplication)
# ---------------------------------------------------------------------------
typeset -U path PATH                       # keep PATH entries unique
path=("$HOME/.local/bin" $path)
export PATH

# mise shims (added by `mise activate` below, but ensure present early too)
[[ -d "$HOME/.local/share/mise/shims" ]] && path=("$HOME/.local/share/mise/shims" $path)

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt APPEND_HISTORY INC_APPEND_HISTORY

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ---------------------------------------------------------------------------
# Plugins (cloned into ~/.config/zsh/plugins). Order matters:
# autosuggestions before syntax-highlighting; highlighting must load last.
# ---------------------------------------------------------------------------
ZSH_PLUGIN_DIR="$HOME/.config/zsh/plugins"
[[ -f "$ZSH_PLUGIN_DIR/zsh-completions/zsh-completions.plugin.zsh" ]] && \
  fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)
[[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ---------------------------------------------------------------------------
# Tool integrations (each guarded; no-op if the tool is not installed)
# ---------------------------------------------------------------------------
command -v mise     >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf keybindings + completion (works with apt fzf >= 0.48 and mise fzf)
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# uv / cargo / local env shims if present
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# ---------------------------------------------------------------------------
# Aliases (eza/bat replacements are guarded so plain ls/cat still work)
# ---------------------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -alF'
  alias la='ls -A'
fi
command -v bat    >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && alias bat='batcat'
command -v nvim   >/dev/null 2>&1 && { alias vim='nvim'; export EDITOR='nvim'; export VISUAL='nvim'; }

# git shortcuts
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

# safety / qol
alias mkdir='mkdir -p'
alias grep='grep --color=auto'

[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# ---------------------------------------------------------------------------
# Machine-local overrides (NOT tracked in dotfiles) — installer paths,
# per-host tweaks, secrets-adjacent env. Create ~/.zshrc.local as needed.
# ---------------------------------------------------------------------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
