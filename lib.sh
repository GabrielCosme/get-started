#!/usr/bin/env bash
# Shared helpers for all install modules.

set -euo pipefail

BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; DIM=$'\033[2m'; RESET=$'\033[0m'

log()  { printf '%s==>%s %s\n' "$GREEN$BOLD" "$RESET" "$*"; }
info() { printf '%s  ->%s %s\n' "$DIM" "$RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%s[fail]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

# Root of the repo, regardless of where the script is invoked from.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

# True if the command exists on PATH.
have() { command -v "$1" >/dev/null 2>&1; }

# True if the apt package is installed.
pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'; }

# True if apt knows of a candidate for this package.
pkg_available() { [ "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}')" != "(none)" ] \
                  && [ -n "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2}')" ]; }

APT_UPDATED=0
apt_update_once() {
    [ "$APT_UPDATED" -eq 1 ] && return 0
    log "Updating apt index"
    sudo apt-get update -qq
    APT_UPDATED=1
}

# Install only the packages that are missing. Never fails the run on one bad name.
apt_install() {
    local missing=()
    for p in "$@"; do
        pkg_installed "$p" || missing+=("$p")
    done
    if [ ${#missing[@]} -eq 0 ]; then
        info "already installed: $*"
        return 0
    fi
    apt_update_once
    info "installing: ${missing[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
}

# Clone a git repo, or pull if it is already there.
clone_or_pull() {
    local url="$1" dest="$2"
    if [ -d "$dest/.git" ]; then
        info "updating $(basename "$dest")"
        git -C "$dest" pull --quiet --ff-only || warn "could not fast-forward $dest"
    else
        info "cloning $(basename "$dest")"
        git clone --quiet --depth=1 "$url" "$dest"
    fi
}

# Back up a file/dir before overwriting it, once per run.
backup() {
    local target="$1"
    [ -e "$target" ] || return 0
    local stamp="${BACKUP_STAMP:-$(date +%Y%m%d-%H%M%S)}"
    local dest="$HOME/.get-started-backup/$stamp"
    mkdir -p "$dest/$(dirname "${target#"$HOME"/}")"
    cp -a "$target" "$dest/${target#"$HOME"/}"
    info "backed up $target -> $dest/${target#"$HOME"/}"
}
