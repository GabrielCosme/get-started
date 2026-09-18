#!/usr/bin/env bash
# zsh + oh-my-zsh + plugins, starship, zoxide, mise, eza, Nerd Font.
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

log "zsh"
apt_install zsh

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
    info "setting zsh as the login shell"
    sudo chsh -s "$(command -v zsh)" "$USER"
else
    info "zsh is already the login shell"
fi

log "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "oh-my-zsh already present"
else
    # --unattended keeps it from launching zsh and from rewriting .zshrc.
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

log "oh-my-zsh custom plugins"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone_or_pull https://github.com/Aloxaf/fzf-tab.git                  "$ZSH_CUSTOM/plugins/fzf-tab"
clone_or_pull https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
clone_or_pull https://github.com/zsh-users/zsh-autosuggestions.git   "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_or_pull https://github.com/fdellwing/zsh-bat.git              "$ZSH_CUSTOM/plugins/zsh-bat"
# command-not-found, extract and sudo are oh-my-zsh built-ins; nothing to clone.

log "starship prompt"
if have starship; then
    info "starship already installed"
else
    curl -fsSL https://starship.rs/install.sh | sudo sh -s -- --yes
fi

log "zoxide"
if have zoxide; then
    info "zoxide already installed"
else
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

log "mise (runtime version manager)"
if have mise || [ -x "$HOME/.local/bin/mise" ]; then
    info "mise already installed"
else
    curl -fsSL https://mise.run | sh
fi
mkdir -p "$HOME/.config/mise"
cp "$REPO_DIR/dotfiles/mise-config.toml" "$HOME/.config/mise/config.toml"
info "mise config installed (node = latest)"
"$HOME/.local/bin/mise" install || warn "mise install failed; run it by hand later"

log "eza"
if pkg_available eza; then
    # 26.04 is expected to carry eza in universe; prefer the archive when it does.
    apt_install eza
elif ! have eza; then
    info "eza not in the archive, adding deb.gierens.de"
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    APT_UPDATED=0
    apt_install eza
else
    info "eza already installed"
fi

log "FiraCode Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
if compgen -G "$FONT_DIR/FiraCodeNerdFont*" >/dev/null; then
    info "FiraCode Nerd Font already present"
else
    apt_install fontconfig
    mkdir -p "$FONT_DIR"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/FiraCode.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -qo "$tmp/FiraCode.zip" -d "$tmp/FiraCode"
    cp "$tmp"/FiraCode/FiraCodeNerdFontMono-*.ttf "$FONT_DIR/"
    rm -rf "$tmp"
    fc-cache -f "$FONT_DIR" >/dev/null
    info "installed FiraCode Nerd Font Mono"
fi

if is_wsl; then
    warn "On WSL the font must ALSO be installed on Windows for Windows Terminal to render it."
    warn "Download FiraCode from https://github.com/ryanoasis/nerd-fonts/releases and install it there."
fi
