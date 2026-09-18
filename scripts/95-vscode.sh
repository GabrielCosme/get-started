#!/usr/bin/env bash
# VS Code: extensions and remote (Machine) settings.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "VS Code extensions"

if ! have code; then
    warn "The 'code' CLI is not on PATH."
    if is_wsl; then
        warn "Open this folder once from Windows VS Code ('code .' in Windows, or the WSL extension)"
        warn "so the server is installed, then re-run: ./install.sh --only vscode"
    fi
    warn "Skipping extension installation."
else
    installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    while read -r ext; do
        [ -z "$ext" ] && continue
        case "$ext" in \#*) continue ;; esac
        if grep -qx "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$installed"; then
            info "already installed: $ext"
        else
            info "installing: $ext"
            code --install-extension "$ext" --force >/dev/null 2>&1 || warn "failed: $ext"
        fi
    done < "$REPO_DIR/vscode-extensions.txt"
fi

log "VS Code remote settings"
# Machine-scope settings live server-side and so belong in the Linux home.
VSCODE_MACHINE_DIR="$HOME/.vscode-server/data/Machine"
if [ -d "$HOME/.vscode-server" ]; then
    mkdir -p "$VSCODE_MACHINE_DIR"
    backup "$VSCODE_MACHINE_DIR/settings.json"
    cp "$REPO_DIR/dotfiles/vscode/settings.json" "$VSCODE_MACHINE_DIR/settings.json"
    info "installed Machine settings.json"
else
    warn "~/.vscode-server not found; connect VS Code to WSL once, then re-run this module."
fi
