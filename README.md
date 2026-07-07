# dotfiles

Minimal, fast zsh setup for macOS. Terminal-agnostic — works in Terminal.app, Ghostty, iTerm2, whatever.

- **Plugin manager:** [Zinit](https://github.com/zdharma-continuum/zinit) with turbo/deferred loading (plugins load after the first prompt)
- **Prompt:** hand-rolled, pure zsh (`zsh/prompt.zsh`) — no prompt binary, nothing to install, fully overridable from `~/.zshrc.local`
- **Runtimes:** [mise](https://mise.jdx.dev) (replaces nvm/pyenv — per-project versions via `.mise.toml` / `.tool-versions`)
- **Tuned for agentic development:** PATH/env live in `.zshenv` so the non-interactive shells coding agents spawn get the right toolchain without paying interactive-startup cost (~0.2s interactive startup)

## Install

```sh
git clone https://github.com/iammatthias/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

The installer symlinks the files into `$HOME` (backing up anything already there to `~/.dotfiles-backup-<timestamp>/`) and runs `brew bundle` if Homebrew is installed. Pass `--no-brew` to skip the package install. Zinit and its plugins self-install on the first shell launch.

## Layout

| File | Role |
|---|---|
| `zsh/.zshenv` | PATH + env for **every** shell (login, scripts, agent-spawned). Lean and silent. |
| `zsh/.zshrc` | Interactive-only: plugins, completions, aliases. |
| `zsh/prompt.zsh` | The prompt (☀ dir git ➜, cmd duration on the right). Pure zsh: `vcs_info` + precmd hooks. |
| `zsh/.zprofile` | Intentionally empty (env lives in `.zshenv`). |
| `Brewfile` | Core CLI toolchain: mise, fzf, zoxide, eza, fd, bat, ripgrep, delta, gh. |

## Machine-specific config

Anything personal or per-machine stays out of the repo. Two optional files are sourced if they exist — and because every layer of this setup (prompt included) is plain zsh, they can override **all** of it:

- `~/.zshenv.local` — extra PATH entries, private env vars (sourced at the end of `.zshenv`)
- `~/.zshrc.local` — extra aliases, functions, tool hooks, prompt tweaks (sourced at the very end of `.zshrc`)

## Notable behavior

- History: 1M entries, shared across sessions, timestamped, deduped; lines starting with a space aren't recorded.
- `ls` is left untouched (scripts and agents see stock behavior); `ll` / `la` / `lt` use eza when present.
- Every tool hook is guarded with `command -v` — a missing tool degrades silently instead of erroring.
- Helpers: `mkcd`, `port <n>` / `killport <n>`, `reload`, `update_plugins`.
