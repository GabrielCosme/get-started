#!/usr/bin/env bash
# Embedded / STM32: ARM cross-toolchain and multi-arch debugger.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "ARM embedded toolchain"
apt_install gcc-arm-none-eabi gdb-multiarch binutils-arm-none-eabi libnewlib-arm-none-eabi

info "arm-none-eabi-gcc: $(arm-none-eabi-gcc --version 2>/dev/null | head -1 || echo 'not on PATH')"
warn "The archive version differs per Ubuntu release (24.04 shipped 13.2.rel1)."
warn "If a project pins a toolchain version, install it from the Arm Developer site instead."

# dialout/plugdev are what ST-Link and USB serial adapters need.
for grp in dialout plugdev; do
    if id -nG "$USER" | tr ' ' '\n' | grep -qx "$grp"; then
        info "already in group $grp"
    else
        sudo usermod -aG "$grp" "$USER"
        info "added $USER to group $grp (re-login required)"
    fi
done

if is_wsl; then
    warn "USB debug probes need 'usbipd-win' on the Windows side to reach WSL."
    warn "STM32CubeMX / CubeMonitor stay on Windows; the cube/cmonitor aliases point at them."
fi
