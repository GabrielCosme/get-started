#!/usr/bin/env bash
# Copy the tracked dotfiles into $HOME (existing files are backed up first).
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Dotfiles"

for f in .zshrc .zshenv .gitconfig .gitignore_global; do
    backup "$HOME/$f"
    cp "$REPO_DIR/dotfiles/$f" "$HOME/$f"
    info "installed ~/$f"
done

mkdir -p "$HOME/.config/clangd"
backup "$HOME/.config/clangd/config.yaml"
cp "$REPO_DIR/dotfiles/.config/clangd/config.yaml" "$HOME/.config/clangd/config.yaml"
info "installed ~/.config/clangd/config.yaml"

warn "Backups of anything replaced are under ~/.get-started-backup/"
