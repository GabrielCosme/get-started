#!/usr/bin/env bash
# C/C++ toolchain: build system, GCC, and a pinned LLVM/clang release.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Override with: CLANG_VERSION=21 ./install.sh --only cpp
CLANG_VERSION="${CLANG_VERSION:-22}"

log "Build tooling"
apt_install build-essential make cmake ninja-build gdb doxygen graphviz

log "LLVM / clang ${CLANG_VERSION}"

if pkg_available "clang-${CLANG_VERSION}"; then
    info "clang-${CLANG_VERSION} is already reachable from the configured repos"
else
    info "adding apt.llvm.org"
    # shellcheck disable=SC1091
    . /etc/os-release
    codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

    # apt.llvm.org lags new Ubuntu releases; fall back to the last LTS pocket.
    if ! curl -fsI "https://apt.llvm.org/${codename}/dists/llvm-toolchain-${codename}-${CLANG_VERSION}/Release" >/dev/null 2>&1; then
        warn "no llvm-toolchain-${codename}-${CLANG_VERSION} pocket yet; falling back to 'noble'"
        codename="noble"
    fi

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/llvm.gpg
    sudo chmod a+r /etc/apt/keyrings/llvm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/llvm.gpg] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${CLANG_VERSION} main" \
        | sudo tee "/etc/apt/sources.list.d/llvm-${CLANG_VERSION}.list" >/dev/null
    APT_UPDATED=0
fi

apt_install \
    "clang-${CLANG_VERSION}" \
    "clangd-${CLANG_VERSION}" \
    "clang-format-${CLANG_VERSION}" \
    "clang-tidy-${CLANG_VERSION}" \
    "lld-${CLANG_VERSION}" \
    "lldb-${CLANG_VERSION}"

log "Pointing the unversioned tool names at ${CLANG_VERSION}"
# Projects invoke bare `clang-format` / `run-clang-tidy` (MicrasFirmware's
# cmake/targets.cmake does), so the unversioned names must resolve to this release.
V="$CLANG_VERSION"
# Only the versioned packages are installed above, so these link paths are free
# on a clean machine. Warn rather than abort if an unversioned package owns one.
alt() { sudo update-alternatives --quiet --install "$@" || warn "update-alternatives failed for $2"; }
alt /usr/bin/clang        clang        "/usr/bin/clang-$V"        100 \
    --slave /usr/bin/clang++ clang++ "/usr/bin/clang++-$V"
alt /usr/bin/clangd       clangd       "/usr/bin/clangd-$V"       100
alt /usr/bin/clang-format clang-format "/usr/bin/clang-format-$V" 100
alt /usr/bin/clang-tidy   clang-tidy   "/usr/bin/clang-tidy-$V"   100 \
    --slave /usr/bin/run-clang-tidy run-clang-tidy "/usr/bin/run-clang-tidy-$V"
alt /usr/bin/lldb         lldb         "/usr/bin/lldb-$V"         100

for t in clang clang++ clangd clang-format clang-tidy run-clang-tidy; do
    if have "$t"; then
        info "$(printf '%-16s' "$t") $("$t" --version 2>/dev/null | head -1)"
    else
        warn "$t did not end up on PATH"
    fi
done

warn "clang-format output changes between major versions. Re-running 'make format'"
warn "on a project last formatted with clang-format 18 will produce a diff."

log "clangd configuration"
mkdir -p "$HOME/.config/clangd"
backup "$HOME/.config/clangd/config.yaml"
cp "$REPO_DIR/dotfiles/.config/clangd/config.yaml" "$HOME/.config/clangd/config.yaml"
