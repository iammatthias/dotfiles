# ~/.zshenv — sourced for EVERY zsh: login, interactive, scripts, and the
# non-interactive shells that coding agents (Claude Code, etc.) spawn per command.
# Keep this lean and silent (no output, no slow evals): it runs on every invocation.
# Putting PATH/env here (not just in .zshrc) is what makes agent shells find the
# right tools without paying the full interactive-startup cost.

# Auto-deduplicate PATH/fpath (keeps first occurrence, drops repeats)
typeset -U path PATH fpath FPATH

# Homebrew (Apple Silicon / Intel). `brew shellenv` costs ~30ms, so skip it when
# a parent shell already ran it (nested and agent-spawned shells inherit the env).
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Go
export GOPATH="$HOME/go"

# Highest-priority bin dirs first. mise shims lead so a project's pinned
# Node/Python/etc. (via .mise.toml / .tool-versions) wins automatically —
# in agent shells too.
_zenv_prepend=(
  "$HOME/.local/share/mise/shims"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$GOPATH/bin"
  "$HOME/.bun/bin"        # `bun install -g` global binaries
  "$HOME/.opencode/bin"
  # OrbStack (docker/kubectl/orb shims). .zprofile used to source the generated
  # ~/.orbstack/shell/init.zsh, which hardcodes an absolute /Users/<name> path.
  # That script only sets PATH + fpath, both reproduced here and in .zshrc.
  "$HOME/.orbstack/bin"
  # Homebrew listed here too (not only via shellenv): nested shells inherit
  # HOMEBREW_PREFIX and skip the eval above, and path_helper re-promotes
  # /usr/bin in every login shell — this keeps brew ahead of system dirs.
  "${HOMEBREW_PREFIX:-/opt/homebrew}/bin"
  "${HOMEBREW_PREFIX:-/opt/homebrew}/sbin"
)
# Keep only the ones that actually exist (N-/ = nullglob, existing dirs), in order
path=( ${^_zenv_prepend}(N-/) $path )
unset _zenv_prepend
export PATH

# Machine-specific environment (extra PATH entries, private env vars, etc.).
# Not tracked in the dotfiles repo — create the file if you need it.
[[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"

# Snapshot the PATH we just built. On macOS login shells, /etc/zprofile runs
# path_helper AFTER this file and moves system dirs (/usr/bin, …) ahead of
# everything above; ~/.zprofile uses this snapshot to restore our ordering.
typeset -g _ZENV_PATH="$PATH"
