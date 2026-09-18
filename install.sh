#!/usr/bin/env bash
#
# Bootstrap a fresh Ubuntu (WSL2) machine.
#
#   ./install.sh                     run every module
#   ./install.sh --only shell,python run only those modules
#   ./install.sh --skip latex        run everything except those
#   ./install.sh --list              show the modules and exit
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib.sh"

# Order matters: base sets up apt, shell sets up PATH, dotfiles goes last.
MODULES=(
    "sudo:00-sudo.sh:passwordless sudo for this user"
    "base:05-base.sh:apt front-ends, core CLI tools, WSL integration"
    "shell:10-shell.sh:zsh, oh-my-zsh, starship, zoxide, mise, eza, Nerd Font"
    "cpp:20-cpp.sh:gcc, cmake, ninja, gdb, doxygen, LLVM/clang ${CLANG_VERSION:-22}"
    "embedded:30-embedded.sh:arm-none-eabi toolchain, gdb-multiarch, usb groups"
    "python:40-python.sh:python3, pipx -> poetry, ruff, uv"
    "rust:50-rust.sh:rustup with rust-analyzer, clippy, rustfmt"
    "docker:60-docker.sh:Docker CE, buildx, compose"
    "github:70-github.sh:gh CLI, git identity, ssh key"
    "latex:80-latex.sh:TeX Live (large)"
    "claude:90-claude.sh:Claude Code CLI and configuration"
    "vscode:95-vscode.sh:VS Code extensions and remote settings"
    "dotfiles:99-dotfiles.sh:copy .zshrc, .zshenv, .gitconfig, clangd config"
)

module_name() { echo "${1%%:*}"; }
module_file() { echo "$1" | cut -d: -f2; }
module_desc() { echo "$1" | cut -d: -f3-; }

usage() {
    cat <<USAGE
Usage: ./install.sh [--only a,b] [--skip a,b] [--list]

Modules:
USAGE
    for m in "${MODULES[@]}"; do
        printf '  %-10s %s\n' "$(module_name "$m")" "$(module_desc "$m")"
    done
}

ONLY=""; SKIP=""
while [ $# -gt 0 ]; do
    case "$1" in
        --only) ONLY="${2:?--only needs a comma-separated list}"; shift 2 ;;
        --skip) SKIP="${2:?--skip needs a comma-separated list}"; shift 2 ;;
        --list|-l) usage; exit 0 ;;
        --help|-h) usage; exit 0 ;;
        *) die "unknown argument: $1 (try --help)" ;;
    esac
done

in_list() { echo ",$2," | grep -q ",$1,"; }

[ "$(id -u)" -eq 0 ] && die "Run this as your normal user, not root. sudo is called where needed."
have sudo || die "sudo is required."

# Ask for sudo once up front so the run is not interrupted later.
sudo -v

export BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"

log "Starting bootstrap ($(. /etc/os-release && echo "$PRETTY_NAME")$(is_wsl && echo ', WSL'))"

RAN=(); SKIPPED=(); FAILED=()
for m in "${MODULES[@]}"; do
    name="$(module_name "$m")"
    file="$(module_file "$m")"

    if [ -n "$ONLY" ] && ! in_list "$name" "$ONLY"; then SKIPPED+=("$name"); continue; fi
    if [ -n "$SKIP" ] && in_list "$name" "$SKIP";  then SKIPPED+=("$name"); continue; fi

    printf '\n%s========== %s ==========%s\n' "$BOLD" "$name" "$RESET"
    # A failing module should not abort the rest of the bootstrap.
    if bash "$REPO_DIR/scripts/$file"; then
        RAN+=("$name")
    else
        warn "module '$name' failed"
        FAILED+=("$name")
    fi
done

printf '\n%s========== summary ==========%s\n' "$BOLD" "$RESET"
[ ${#RAN[@]}     -gt 0 ] && log  "ran:     ${RAN[*]}"     || true
[ ${#SKIPPED[@]} -gt 0 ] && info "skipped: ${SKIPPED[*]}" || true
[ ${#FAILED[@]}  -gt 0 ] && warn "failed:  ${FAILED[*]}"  || true

cat <<'NEXT'

Next steps:
  1. Close the terminal and reopen it (or run: exec zsh) to pick up the new shell.
  2. Group changes (docker, dialout, plugdev) need a full WSL restart:
       wsl --shutdown        # from Windows
  3. Authenticate the tools that need it:
       gh auth login
       claude
  4. Install FiraCode Nerd Font on Windows too, and select it in Windows Terminal.
NEXT
