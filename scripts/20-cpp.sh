#!/usr/bin/env bash
# C/C++ toolchain: compilers, LSP, build system, docs.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "C/C++ toolchain"
apt_install \
    build-essential \
    clang clangd clang-format clang-tidy \
    cmake ninja-build \
    gdb \
    doxygen graphviz

log "clangd configuration"
mkdir -p "$HOME/.config/clangd"
backup "$HOME/.config/clangd/config.yaml"
cp "$REPO_DIR/dotfiles/.config/clangd/config.yaml" "$HOME/.config/clangd/config.yaml"
