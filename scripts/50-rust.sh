#!/usr/bin/env bash
# Rust via rustup (sourced from .zshenv).
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Rust"
if have rustup || [ -x "$HOME/.cargo/bin/rustup" ]; then
    info "rustup already installed"
    "$HOME/.cargo/bin/rustup" update stable || warn "rustup update failed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# .zshenv sources ~/.cargo/env; --no-modify-path keeps rustup from duplicating that.
log "rust components"
"$HOME/.cargo/bin/rustup" component add rust-analyzer clippy rustfmt 2>/dev/null || true
