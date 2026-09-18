#!/usr/bin/env bash
# Passwordless sudo for the current user.
#
# Trade-off: any process running as you can then escalate to root without a
# prompt. That is the point on a single-user dev box, but skip this module
# (./install.sh --skip sudo) on anything shared or exposed.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Passwordless sudo"

ME="$(id -un)"
SUDOERS_FILE="/etc/sudoers.d/99-${ME}-nopasswd"

if sudo test -f "$SUDOERS_FILE"; then
    info "$SUDOERS_FILE already exists"
else
    tmp="$(mktemp)"
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$ME" > "$tmp"

    # Validate before installing. A malformed sudoers file locks you out of
    # sudo entirely, and visudo -c is the only safe way to check one.
    if sudo visudo -cf "$tmp" >/dev/null; then
        sudo install -m 0440 -o root -g root "$tmp" "$SUDOERS_FILE"
        rm -f "$tmp"
        info "installed $SUDOERS_FILE"
    else
        rm -f "$tmp"
        die "sudoers snippet failed validation - nothing was changed"
    fi
fi

# Prove it works, rather than assuming it does.
if sudo -n true 2>/dev/null; then
    info "verified: sudo no longer prompts for a password"
else
    warn "sudo still prompts; check $SUDOERS_FILE and that no later rule overrides it"
fi
