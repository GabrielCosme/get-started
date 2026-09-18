#!/usr/bin/env bash
#
# Verify what install.sh was supposed to set up. Read-only: changes nothing.
# Exit status is non-zero if any check failed.
#
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
set +e  # a failing check must report, not abort

CLANG_VERSION="${CLANG_VERSION:-22}"
PASS=0; FAIL=0; WARN=0

section() { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; }
ok()   { printf '  %s✔%s %s\n' "$GREEN"  "$RESET" "$1"; PASS=$((PASS+1)); }
bad()  { printf '  %s✘%s %s\n' "$RED"    "$RESET" "$1"; FAIL=$((FAIL+1)); }
meh()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; WARN=$((WARN+1)); }

# check_cmd <command> [version-flag]
check_cmd() {
    local c="$1" flag="${2:---version}" v
    if have "$c"; then
        v="$("$c" $flag 2>/dev/null | head -1 | cut -c1-60)"
        ok "$(printf '%-18s %s' "$c" "${v:-present}")"
    else
        bad "$(printf '%-18s %s' "$c" 'not on PATH')"
    fi
}

check_pkg()  { pkg_installed "$1" && ok "$(printf '%-34s %s' "$1" 'installed')" || bad "$(printf '%-34s %s' "$1" 'missing')"; }
check_file() { [ -e "$1" ] && ok "${1/#$HOME/\~}" || bad "${1/#$HOME/\~} missing"; }
check_dir()  { [ -d "$1" ] && ok "${1/#$HOME/\~}" || bad "${1/#$HOME/\~} missing"; }
check_group(){ id -nG "$USER" | tr ' ' '\n' | grep -qx "$1" && ok "member of group $1" || bad "not in group $1 (re-login after install?)"; }

printf '%sget-started doctor%s  -  %s%s\n' "$BOLD" "$RESET" "$(. /etc/os-release && echo "$PRETTY_NAME")" "$(is_wsl && echo ' (WSL)')"

section "sudo"
# `sudo -n true` alone is a false positive when credentials are merely cached,
# so check that the sudoers drop-in actually exists.
if sudo -n test -f "/etc/sudoers.d/99-$(id -un)-nopasswd" 2>/dev/null; then
    ok "/etc/sudoers.d/99-$(id -un)-nopasswd present"
elif sudo -n true 2>/dev/null; then
    meh "sudo is not prompting, but the drop-in is absent (cached credentials?)"
else
    meh "passwordless sudo not configured (module skipped?)"
fi

section "locale & timezone"
tz="$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)"
[ -n "$tz" ] && ok "timezone $tz  ($(date))" || bad "timezone not set"
if locale -a 2>/dev/null | tr 'A-Z' 'a-z' | tr -d '-' | grep -qx "$(echo "${LOCALE:-en_US.UTF-8}" | tr 'A-Z' 'a-z' | tr -d '-')"; then
    ok "locale ${LOCALE:-en_US.UTF-8} generated"
else
    bad "locale ${LOCALE:-en_US.UTF-8} not generated (LANG=${LANG:-unset})"
fi

section "base tools"
for c in nala aptitude fzf croc w3m; do check_cmd "$c"; done
have bat && ok "$(printf '%-18s %s' bat "$(bat --version 2>/dev/null | head -1)")" \
         || { have batcat && meh "only 'batcat' exists; ~/.local/bin/bat symlink missing" || bad "bat/batcat missing"; }

section "shell"
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] && ok "zsh is the login shell" || bad "login shell is $(getent passwd "$USER" | cut -d: -f7), not zsh"
check_dir "$HOME/.oh-my-zsh"
for p in fzf-tab fast-syntax-highlighting zsh-autosuggestions zsh-bat; do
    check_dir "$HOME/.oh-my-zsh/custom/plugins/$p"
done
for c in starship zoxide mise eza; do check_cmd "$c"; done
compgen -G "$HOME/.local/share/fonts/FiraCodeNerdFont*" >/dev/null && ok "FiraCode Nerd Font installed" || bad "FiraCode Nerd Font missing"
[ -f "$HOME/.config/starship.toml" ] && ok "starship.toml present" || meh "no starship.toml (using starship defaults)"

section "C/C++ (clang $CLANG_VERSION)"
for c in cmake ninja gdb doxygen dot; do check_cmd "$c"; done
for c in clang clang++ clangd clang-format clang-tidy; do
    if have "$c"; then
        v="$("$c" --version 2>/dev/null | grep -oE 'version [0-9]+' | head -1 | awk '{print $2}')"
        if [ "$v" = "$CLANG_VERSION" ]; then ok "$(printf '%-18s version %s' "$c" "$v")"
        else meh "$(printf '%-18s version %s (expected %s)' "$c" "${v:-?}" "$CLANG_VERSION")"; fi
    else
        bad "$(printf '%-18s %s' "$c" 'not on PATH')"
    fi
done
have run-clang-tidy && ok "run-clang-tidy on PATH (projects call it unversioned)" || bad "run-clang-tidy not on PATH"

section "embedded"
check_cmd arm-none-eabi-gcc
check_cmd arm-none-eabi-g++
check_cmd gdb-multiarch
check_pkg libstdc++-arm-none-eabi-newlib
check_pkg libnewlib-arm-none-eabi
for c in openocd st-info dfu-util; do check_cmd "$c"; done
check_group dialout
check_group plugdev

section "python"
check_cmd python3
for c in pipx ruff uv tldr; do check_cmd "$c"; done

section "rust"
for c in rustc cargo rustup; do check_cmd "$c"; done
"$HOME/.cargo/bin/rustup" component list --installed 2>/dev/null | grep -q rust-analyzer && ok "rust-analyzer component" || meh "rust-analyzer component missing"

section "docker"
check_cmd docker
check_group docker
if docker info >/dev/null 2>&1; then ok "docker daemon reachable"
else bad "cannot talk to the docker daemon (needs re-login, or systemd not running)"; fi
docker compose version >/dev/null 2>&1 && ok "docker compose plugin" || bad "docker compose plugin missing"

section "github"
check_cmd gh
gh auth status >/dev/null 2>&1 && ok "gh authenticated as $(gh api user --jq .login 2>/dev/null)" || bad "gh not authenticated"
check_file "$HOME/.ssh/id_ed25519"
if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -q 'successfully authenticated'; then
    ok "SSH key authenticates to github.com"
else
    bad "SSH key does not authenticate to github.com"
fi

section "latex"
check_cmd pdflatex

section "claude"
check_cmd claude
for f in settings.json statusline.py CLAUDE.md; do check_file "$HOME/.claude/$f"; done

section "vscode"
if have code; then
    want=$(grep -cvE '^\s*(#|$)' "$REPO_DIR/vscode-extensions.txt")
    got=$(code --list-extensions 2>/dev/null | wc -l)
    missing=$(comm -23 <(sort "$REPO_DIR/vscode-extensions.txt") <(code --list-extensions 2>/dev/null | tr 'A-Z' 'a-z' | sort) | tr '\n' ' ')
    [ -z "${missing// /}" ] && ok "all $want extensions installed ($got total)" || meh "missing extensions: $missing"
else
    meh "'code' CLI not on PATH - extensions unchecked"
fi
check_file "$HOME/.vscode-server/data/Machine/settings.json"

section "dotfiles"
for f in .zshrc .zshenv .gitconfig .gitignore_global; do check_file "$HOME/$f"; done
check_file "$HOME/.config/clangd/config.yaml"
if is_wsl; then
    if [ -f "$HOME/.config/wsl-env.zsh" ] && grep -q '^export WIN_HOME=' "$HOME/.config/wsl-env.zsh"; then
        wh="$(. "$HOME/.config/wsl-env.zsh" 2>/dev/null && echo "$WIN_HOME")"
        [ -d "$wh" ] && ok "wsl-env.zsh -> WIN_HOME=$wh" || bad "wsl-env.zsh points at $wh, which does not exist"
    else
        bad "~/.config/wsl-env.zsh missing (cube/cmonitor aliases will not be set)"
    fi
fi
for kv in init.defaultBranch=main push.autoSetupRemote=true pull.rebase=true rerere.enabled=true merge.conflictStyle=zdiff3; do
    k="${kv%%=*}"; want="${kv#*=}"; got="$(git config --global --get "$k" 2>/dev/null)"
    [ "$got" = "$want" ] && ok "git $k = $got" || bad "git $k = ${got:-unset} (expected $want)"
done
[ -n "$(git config --global user.email 2>/dev/null)" ] && ok "git identity: $(git config --global user.name) <$(git config --global user.email)>" || bad "git identity unset"

printf '\n%s========================================%s\n' "$BOLD" "$RESET"
printf '%s%d passed%s  %s%d warnings%s  %s%d failed%s\n' \
    "$GREEN" "$PASS" "$RESET" "$YELLOW" "$WARN" "$RESET" "$RED" "$FAIL" "$RESET"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
