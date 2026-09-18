#!/usr/bin/env bash
# Base system: apt front-ends, core CLI utilities, WSL integration.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Base system packages"

apt_install \
    ca-certificates curl wget gnupg gpg git unzip xz-utils \
    software-properties-common apt-transport-https \
    net-tools less

log "apt front-ends"
apt_install nala aptitude ppa-purge

log "CLI utilities"
apt_install fzf bat tldr neofetch w3m

# Ubuntu ships bat as `batcat` to avoid a name clash. Restore the usual name.
if have batcat && ! have bat; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    info "linked batcat -> ~/.local/bin/bat"
fi

# croc (file transfer) is not in the Ubuntu archive.
if have croc; then
    info "croc already installed"
else
    log "Installing croc"
    curl -fsSL https://getcroc.schollz.com | sudo bash
fi

if is_wsl; then
    log "WSL integration"
    apt_install ubuntu-wsl
    if [ ! -f /etc/wsl.conf ] || ! grep -q 'systemd=true' /etc/wsl.conf; then
        info "enabling systemd in /etc/wsl.conf (needs a 'wsl --shutdown' to take effect)"
        sudo cp "$REPO_DIR/wsl.conf" /etc/wsl.conf
    else
        info "systemd already enabled in /etc/wsl.conf"
    fi
fi
