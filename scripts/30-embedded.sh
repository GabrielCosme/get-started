#!/usr/bin/env bash
# Embedded / STM32: ARM cross-toolchain, C++ runtime, debug servers.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "ARM embedded toolchain"
# libstdc++-arm-none-eabi-newlib is required for C++ firmware; without it the
# cross-compiler has no C++ standard library and the link fails.
apt_install \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    gdb-multiarch

log "Debug servers / flashing tools"
apt_install openocd stlink-tools dfu-util

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
    warn "USB debug probes need 'usbipd-win' on the Windows side to reach WSL:"
    warn "  winget install usbipd    then: usbipd list / usbipd attach --wsl --busid <id>"
    warn "STM32CubeMX / CubeProgrammer stay on Windows; the cube alias points at CubeMX."
else
    # On bare metal the probes need udev rules to be usable without root.
    log "udev rules for debug probes"
    if [ -f /etc/udev/rules.d/49-stlinkv2.rules ] || [ -f /lib/udev/rules.d/60-openocd.rules ]; then
        info "probe udev rules already present (shipped by openocd/stlink-tools)"
        sudo udevadm control --reload-rules && sudo udevadm trigger || warn "udev reload failed"
    fi
fi
