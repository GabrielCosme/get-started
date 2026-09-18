#!/usr/bin/env bash
# GitHub CLI and git identity.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "GitHub CLI"
apt_install gh
# For a newer gh than the archive carries, use the official repo instead:
#   https://github.com/cli/cli/blob/trunk/docs/install_linux.md

log "gh configuration"
gh config set git_protocol https
gh alias set co 'pr checkout' --clobber >/dev/null 2>&1 || true
info "alias: gh co = gh pr checkout"

if gh auth status >/dev/null 2>&1; then
    info "gh already authenticated"
else
    warn "gh is not authenticated. Run: gh auth login"
fi

log "SSH key"
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    info "~/.ssh/id_ed25519 already exists"
else
    # The key is deliberately NOT in this repo. Generate a fresh one per machine.
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519" -N ""
    info "new key generated. Add it to GitHub with:"
    info "  gh ssh-key add ~/.ssh/id_ed25519.pub --title \"\$(hostname)\""
fi
