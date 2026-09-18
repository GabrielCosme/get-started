#!/usr/bin/env bash
# GitHub CLI, git configuration, and an SSH key registered with GitHub.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "GitHub CLI"
apt_install gh
# For a newer gh than the archive carries, use the official repo instead:
#   https://github.com/cli/cli/blob/trunk/docs/install_linux.md

log "gh configuration"
gh config set git_protocol https
gh alias set co 'pr checkout' --clobber >/dev/null 2>&1 || true
info "alias: gh co = gh pr checkout"

if ! gh auth status >/dev/null 2>&1; then
    warn "gh is not authenticated."
    if [ -t 0 ]; then
        info "starting 'gh auth login' - pick HTTPS and let it set up git credentials"
        gh auth login || warn "gh auth login did not complete"
    else
        warn "Run 'gh auth login' by hand, then re-run: ./install.sh --only github"
    fi
else
    info "gh already authenticated as $(gh api user --jq .login 2>/dev/null || echo '?')"
fi

log "SSH key"
KEY="$HOME/.ssh/id_ed25519"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
    info "$KEY already exists"
else
    # The private key is deliberately NOT in this repo - one fresh key per machine.
    email="$(git config --global user.email || true)"
    ssh-keygen -t ed25519 -C "${email:-$(id -un)@$(hostname)}" -f "$KEY" -N ""
    info "generated a new ed25519 key"
fi
chmod 600 "$KEY"; chmod 644 "$KEY.pub"

log "Registering the key with GitHub"
title="$(hostname)-$(date +%Y%m%d)"
if ! gh auth status >/dev/null 2>&1; then
    warn "gh not authenticated; add the key manually:"
    warn "  gh ssh-key add $KEY.pub --title '$title'"
elif gh ssh-key list 2>/dev/null | grep -qF "$(awk '{print $2}' "$KEY.pub")"; then
    info "this key is already on your GitHub account"
elif gh ssh-key add "$KEY.pub" --title "$title" 2>/dev/null; then
    info "added to GitHub as '$title'"
else
    # Adding a key needs the admin:public_key scope, which the default login omits.
    warn "Could not add the key - gh is probably missing the admin:public_key scope."
    warn "Grant it and retry with:"
    warn "  gh auth refresh -h github.com -s admin:public_key"
    warn "  gh ssh-key add $KEY.pub --title '$title'"
    echo
    info "Public key (paste at https://github.com/settings/ssh/new):"
    cat "$KEY.pub"
fi

# Confirm the key actually authenticates. GitHub always exits 1 here, so match
# on the greeting text rather than the exit status.
if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q 'successfully authenticated'; then
    info "verified: SSH to github.com authenticates"
else
    warn "SSH to github.com did not authenticate yet (fine if the key was just added)"
fi
