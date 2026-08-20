#!/usr/bin/env bash
# Symlinks the dotfiles into $HOME, backing up anything already there.
# Idempotent: safe to re-run after a `git pull`.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

link() {
    local src="$1" dest="$2"

    # Already linked to this repo → nothing to do
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "  ok      $dest"
        return
    fi

    # Back up whatever is there (file or foreign symlink)
    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
        echo "  backup  $dest -> $BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "  link    $dest -> $src"
}

echo "Linking dotfiles from $DOTFILES_DIR"
link "$DOTFILES_DIR/zsh/.zshenv"          "$HOME/.zshenv"
link "$DOTFILES_DIR/zsh/.zshrc"           "$HOME/.zshrc"
link "$DOTFILES_DIR/zsh/.zprofile"        "$HOME/.zprofile"
link "$DOTFILES_DIR/ghostty/config"       "$HOME/.config/ghostty/config"
# Optional amber-CRT layer the main config pulls in with `config-file = ?…`,
# plus the shader dir it references relatively
link "$DOTFILES_DIR/ghostty/config.retro" "$HOME/.config/ghostty/config.retro"
link "$DOTFILES_DIR/ghostty/shaders"      "$HOME/.config/ghostty/shaders"
link "$DOTFILES_DIR/herdr/config.toml"    "$HOME/.config/herdr/config.toml"

# Ghostty also reads the macOS-native location; back up any config there so it
# can't fight the XDG one we just linked
GHOSTTY_APPSUPPORT="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -f "$GHOSTTY_APPSUPPORT" && ! -L "$GHOSTTY_APPSUPPORT" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$GHOSTTY_APPSUPPORT" "$BACKUP_DIR/ghostty-appsupport-config"
    echo "  backup  $GHOSTTY_APPSUPPORT -> $BACKUP_DIR/"
fi

# Install the CLI toolchain if Homebrew is available (skip with --no-brew)
if [[ "${1:-}" != "--no-brew" ]]; then
    if command -v brew &>/dev/null; then
        echo "Installing Brewfile packages…"
        brew bundle --file="$DOTFILES_DIR/Brewfile"
    else
        echo "Homebrew not found — install it from https://brew.sh, then run:"
        echo "  brew bundle --file=$DOTFILES_DIR/Brewfile"
    fi
fi

echo
echo "Done. Open a new shell (or run: exec zsh)."
echo "Machine-specific config goes in ~/.zshenv.local and ~/.zshrc.local."
