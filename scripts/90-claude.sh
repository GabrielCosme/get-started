#!/usr/bin/env bash
# Claude Code CLI plus its configuration.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Claude Code"
if have claude || [ -x "$HOME/.local/bin/claude" ]; then
    info "claude already installed"
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

log "Claude Code configuration"
mkdir -p "$HOME/.claude"
for f in settings.json statusline.py CLAUDE.md; do
    backup "$HOME/.claude/$f"
    cp "$REPO_DIR/dotfiles/.claude/$f" "$HOME/.claude/$f"
done
chmod +x "$HOME/.claude/statusline.py"
info "settings.json, statusline.py and CLAUDE.md installed"
warn "Authenticate on first launch by running: claude"
