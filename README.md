# dotfiles

Minimal, fast zsh setup for macOS. Terminal-agnostic — works in Terminal.app, Ghostty, iTerm2, whatever.

- **Plugin manager:** [Zinit](https://github.com/zdharma-continuum/zinit) with turbo/deferred loading (plugins load after the first prompt)
- **Prompt:** hand-rolled, pure zsh (`zsh/prompt.zsh`) — no prompt binary, nothing to install, fully overridable from `~/.zshrc.local`
- **Runtimes:** [mise](https://mise.jdx.dev) (replaces nvm/pyenv — per-project versions via `.mise.toml` / `.tool-versions`)
- **Tuned for agentic development:** PATH/env live in `.zshenv` so the non-interactive shells coding agents spawn get the right toolchain without paying interactive-startup cost (~0.14s interactive startup, ~0ms for agent-spawned shells)

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
| `zsh/.zprofile` | Login shells: restores `.zshenv`'s PATH ordering after macOS `path_helper` demotes it. |
| `ghostty/config` | Ghostty terminal: same dark palette, quick terminal on Ctrl+`. Uses the bundled JetBrains Mono. |
| `ssh/config.d/*.conf` | ssh defaults for every host — connection multiplexing + keepalives. Included from `~/.ssh/config`, which stays local. |
| `Brewfile` | Core CLI toolchain: mise, fzf, zoxide, eza, fd, bat, ripgrep, delta, gh, bun, uv. |

## Machine-specific config

Anything personal or per-machine stays out of the repo. Two optional files are sourced if they exist — and because every layer of this setup (prompt included) is plain zsh, they can override **all** of it:

- `~/.zshenv.local` — extra PATH entries, private env vars (sourced at the end of `.zshenv`)
- `~/.zshrc.local` — extra aliases, functions, tool hooks, prompt tweaks (sourced at the very end of `.zshrc`)
- `~/.config/ghostty/config.local` — Ghostty overrides, e.g. a licensed font-family (optional include at the end of the base config)
- `~/.ssh/config` — hostnames, IPs, identity files. Not symlinked; the installer only prepends an `Include` line pointing at `ssh/config.d/*.conf`, so host entries stay private and survive re-installs.

## Notable behavior

- ssh multiplexes by default (`ControlMaster auto`, 10m persist). The first connection to a host does the real login; every one after rides it as a channel. This matters for anything that polls a box on a timer — the `herdr-dash` ops board hits the homelab every 6s, and unmultiplexed that was ~13.8k logins/day filling the box's journal. Drop a master with `ssh -O exit <host>` if you need a fresh login.

- History: 1M entries, shared across sessions, timestamped, deduped; lines starting with a space aren't recorded.
- `ls` is left untouched (scripts and agents see stock behavior); `ll` / `la` / `lt` use eza when present.
- Every tool hook is guarded with `command -v` — a missing tool degrades silently instead of erroring.
- Helpers: `mkcd`, `port <n>` / `killport <n>`, `reload`, `update_plugins`.
