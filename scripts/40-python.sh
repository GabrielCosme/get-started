#!/usr/bin/env bash
# Python: interpreter tooling plus pipx-managed CLIs.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Python base"
apt_install python3 python3-pip python3-venv python3-dev virtualenv pipx

pipx ensurepath >/dev/null 2>&1 || true

log "pipx tools"
for tool in ruff uv tldr; do
    if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx "$tool"; then
        info "$tool already installed"
    else
        info "installing $tool"
        pipx install "$tool"
    fi
done
