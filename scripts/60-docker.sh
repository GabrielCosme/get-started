#!/usr/bin/env bash
# Docker CE from the official Docker repository.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "Docker CE"

if ! pkg_installed docker-ce; then
    info "adding download.docker.com repository"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # shellcheck disable=SC1091
    . /etc/os-release
    codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

    # Docker may not publish a pocket for a brand-new release on day one.
    if ! curl -fsI "https://download.docker.com/linux/ubuntu/dists/${codename}/Release" >/dev/null 2>&1; then
        warn "Docker has no '${codename}' pocket yet; falling back to 'noble'."
        warn "Re-run this module once Docker publishes packages for ${codename}."
        codename="noble"
    fi

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    APT_UPDATED=0
fi

apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    info "already in the docker group"
else
    sudo usermod -aG docker "$USER"
    info "added $USER to the docker group (re-login required)"
fi

# Needs systemd, which /etc/wsl.conf enables in module 00.
if systemctl is-enabled docker >/dev/null 2>&1; then
    info "docker service already enabled"
else
    sudo systemctl enable --now docker || warn "could not enable docker (is systemd running?)"
fi
