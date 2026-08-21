# ============================================================================
#  ~/.zshrc — interactive shell config
#  Plugin manager: Zinit (turbo / deferred loading)  •  Prompt: zsh/prompt.zsh
#  Tuned for agentic development: fast startup, lean non-interactive shells
#  (PATH/env live in ~/.zshenv), deterministic per-project toolchains (mise).
#  Machine-specific additions go in ~/.zshrc.local (sourced at the end).
# ============================================================================

# ------------------------------------
# History Configuration
# ------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=1200000              # > SAVEHIST so HIST_EXPIRE_DUPS_FIRST has room to work
SAVEHIST=1000000
setopt SHARE_HISTORY          # share across sessions; implies incremental append
setopt EXTENDED_HISTORY       # record timestamps
setopt HIST_EXPIRE_DUPS_FIRST # expire duplicates first when trimming history
setopt HIST_IGNORE_DUPS       # don't record an entry that was just recorded
setopt HIST_FIND_NO_DUPS      # don't display a line previously found
setopt HIST_IGNORE_SPACE      # leading space = don't record
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt AUTO_CD
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_MENU
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt (pasting snippets)

# Pin emacs keybindings — otherwise zsh silently switches to vi mode
# whenever $EDITOR/$VISUAL contains "vi" (e.g. set in ~/.zshrc.local)
bindkey -e

# ------------------------------------
# TERM sanity — keep inbound ssh sessions from garbling input
# ------------------------------------
# Ghostty/kitty/WezTerm ship their own terminfo *inside the app bundle* and point
# shells at it via $TERMINFO. sshd-spawned shells never inherit that variable, so
# an inbound ssh session arrives with a $TERM ncurses can't resolve (the entry is
# on disk, just not on the search path). ZLE then repaints the line with bogus
# cursor caps and every keystroke smears. Generic on purpose: it catches any
# $TERM the local database can't load, whatever emulator or multiplexer set it.
# Runs before Zinit so the plugins below bind keys against a valid $terminfo.
zmodload -i zsh/terminfo 2>/dev/null
if [[ -z "${terminfo[cuu1]}" ]]; then
    export TERM=xterm-256color
    zmodload -u zsh/terminfo 2>/dev/null
    zmodload -i zsh/terminfo 2>/dev/null
fi

# ------------------------------------
# Zinit — bootstrap (self-installs on first run)
# ------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33}▓▒░ Installing Zinit…%f"
    command mkdir -p "$(dirname "$ZINIT_HOME")"
    command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" && \
        print -P "%F{34}▓▒░ Zinit installed.%f" || \
        print -P "%F{160}▓▒░ Zinit clone failed.%f"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ------------------------------------
# Completion system
# ------------------------------------
# Extra completion definitions onto fpath BEFORE compinit (synchronous, cheap —
# clones once, then just extends fpath). Deferring these would miss the dump.
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

# OrbStack ships its own compdefs (docker, orb) — the other half of the
# init.zsh we stopped sourcing.
fpath+=( "$HOME/.orbstack/shell/completions/zsh"(N-/) )

# Initialize completions with a cached dump; full rebuild at most once per day.
# Tool inits below (zoxide/fzf/uv) call compdef, so this must run before them.
autoload -Uz compinit
() {
    setopt local_options extended_glob
    local zcd="${ZDOTDIR:-$HOME}/.zcompdump"
    local -a stale=( $zcd(N.mh+24) )                # dump older than 24h?
    if (( $#stale )) || [[ ! -e $zcd ]]; then
        compinit -i -d $zcd                         # full rebuild
    else
        compinit -C -i -d $zcd                      # fast: trust cached dump
    fi
}
zinit cdreplay -q   # replay compdefs queued before compinit ran

# ------------------------------------
# Plugins (turbo: loaded asynchronously just after the first prompt → fast start)
# ------------------------------------
zinit wait lucid for \
    Aloxaf/fzf-tab \
    atload'_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions \
    atload'
        bindkey "^[[A" history-substring-search-up
        bindkey "^[[B" history-substring-search-down
        [[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
        [[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
    ' \
        zsh-users/zsh-history-substring-search

# Syntax highlighting MUST be loaded last (after all other ZLE widgets)
zinit wait lucid for \
    zsh-users/zsh-syntax-highlighting

# ------------------------------------
# Completion styling (works with fzf-tab)
# ------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'  # case-insensitive
# LS_COLORS is usually unset on macOS; '' falls back to zsh's default colors
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS:-''}"
zstyle ':completion:*' menu no                       # required by fzf-tab
zstyle ':completion:*:descriptions' format '[%d]'
# fzf-tab UI
zstyle ':fzf-tab:*' fzf-flags --height=50% --layout=reverse --border
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --group-directories-first $realpath 2>/dev/null || ls -1 $realpath'

# ------------------------------------
# Theme / Syntax Highlighting (Custom Dark)
# ------------------------------------
# Colors:
# Teal: #5f8787, Peach: #fbcb97, Orange: #e78a53, Grey: #888888, LightGrey: #c1c1c1

# zsh-syntax-highlighting Customization
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

typeset -A ZSH_HIGHLIGHT_STYLES

# Commands / Keywords -> Teal
ZSH_HIGHLIGHT_STYLES[command]='fg=#5f8787,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#5f8787,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#5f8787,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#5f8787,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#5f8787'

# Strings -> Peach
ZSH_HIGHLIGHT_STYLES[string]='fg=#fbcb97'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#fbcb97'

# Numbers / Constants -> Orange
ZSH_HIGHLIGHT_STYLES[number]='fg=#e78a53'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#e78a53'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#e78a53'

# Paths / Files -> Light Grey / Default
ZSH_HIGHLIGHT_STYLES[path]='fg=#c1c1c1'
ZSH_HIGHLIGHT_STYLES[default]='fg=#ffffff'

# Comments -> Grey
ZSH_HIGHLIGHT_STYLES[comment]='fg=#888888'

# zsh-autosuggestions Customization
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#888888'          # Grey (Comment color)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)         # smarter suggestions

# ------------------------------------
# Tool Initializations (each guarded — absent tools are silently skipped)
# ------------------------------------

# Cache slow `<tool> init` output to a file and source that instead — spawning
# the tool costs 40–80ms per shell; sourcing the cache is ~1ms. Regenerates
# whenever the tool binary is newer than the cache (i.e. after upgrades).
_cached_init() {
    local bin=$1 cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$2.zsh"
    shift 2
    if [[ ! -s $cache || $bin -nt $cache ]]; then
        command mkdir -p "${cache:h}"
        # write to a temp file + rename so concurrent shells never source a
        # half-written cache
        if "$bin" "$@" > "$cache.$$" 2>/dev/null; then
            # Strip any PATH the tool baked into its output. `mise activate`
            # emits a literal `export PATH='<absolute snapshot>'` first line;
            # cached, that snapshot is replayed into every future shell and
            # silently clobbers whatever ~/.zshenv built. ~/.zshenv owns PATH.
            command sed '/^export PATH=/d' "$cache.$$" > "$cache.$$.f" \
                && command mv -f "$cache.$$.f" "$cache.$$"
            command mv -f "$cache.$$" "$cache"
        else
            command rm -f "$cache.$$" "$cache.$$.f"
        fi
    fi
    [[ -s $cache ]] && source "$cache"
}

# mise — runtime version manager (Node/Python/Go/…). Replaces nvm + pyenv.
# Shims are already on PATH via ~/.zshenv; this adds the interactive hook
# (auto-switches versions on cd into a project with .mise.toml / .tool-versions).
(( $+commands[mise] )) && _cached_init "$commands[mise]" mise-activate activate zsh

# zoxide — smarter cd. Provides `z` and `zi`.
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fzf — Ctrl-R history, Ctrl-T files, Alt-C cd, plus completion
command -v fzf &>/dev/null && source <(fzf --zsh 2>/dev/null)

# uv (Python package manager) completions
(( $+commands[uv] )) && _cached_init "$commands[uv]" uv-completion generate-shell-completion zsh

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ------------------------------------
# Helper Functions
# ------------------------------------
function reload() {
    # exec, not `source ~/.zshrc`. PATH and env live in ~/.zshenv, which runs
    # only at shell startup — re-sourcing .zshrc silently picks up none of it,
    # while still printing a cheerful "reloaded". Replace the shell so the whole
    # chain (.zshenv -> .zprofile -> .zshrc) actually re-runs.
    if [[ -o login ]]; then
        exec zsh -l
    else
        exec zsh
    fi
}

function mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <dir>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Show what's listening on a port
function port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port>"
        return 1
    fi
    lsof -i tcp:"$1" || echo "No process found on port $1"
}

# Kill whatever is listening on a port (handles multiple PIDs)
function killport() {
    if [[ -z "$1" ]]; then
        echo "Usage: killport <port>"
        return 1
    fi
    local -a pids
    pids=( ${(f)"$(lsof -t -i tcp:"$1")"} )
    if (( $#pids )); then
        kill "${pids[@]}" && echo "Killed: ${pids[*]}"
    else
        echo "No process found on port $1"
    fi
}

# Update Zinit and all plugins
function update_plugins() {
    zinit self-update
    zinit update --all
    echo "Zinit + plugins updated."
}

# ------------------------------------
# Aliases
# ------------------------------------
alias home='cd ~'
alias back='cd -'
alias ..='cd ..'
alias c='clear'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias finder='open .'
alias zshconfig='${EDITOR:-nano} ~/.zshrc'
alias pingme='ping -c 4 8.8.8.8'
alias myip='curl -s https://api.ipify.org; echo'
alias diskusage='df -h'
alias updateall='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup'

# Modern file listing via eza (bare `ls` left untouched so scripts/agents are unaffected)
if command -v eza &>/dev/null; then
    alias ll='eza -lah --git --group-directories-first --icons=auto'
    alias la='eza -a --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
else
    alias ll='ls -lAh'
    alias la='ls -A'
fi

# ------------------------------------
# Prompt — hand-rolled, zsh-native (zsh/prompt.zsh, next to this file;
# falls back to the default zsh prompt if this .zshrc was copied standalone)
# ------------------------------------
_prompt_file="${${(%):-%N}:A:h}/prompt.zsh"
[[ -f "$_prompt_file" ]] && source "$_prompt_file"
unset _prompt_file

# ------------------------------------
# Machine-specific config (not tracked) — kept last so it can override
# anything above, including the prompt
# ------------------------------------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
