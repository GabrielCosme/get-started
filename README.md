# get-started

Bootstrap script for a fresh **Ubuntu on WSL2** machine.

```bash
git clone https://github.com/GabrielCosme/get-started.git
cd get-started
./install.sh
```

Everything is idempotent — re-running is safe, and anything it replaces in `$HOME`
is copied to `~/.get-started-backup/<timestamp>/` first.

## Usage

```bash
./install.sh                      # everything
./install.sh --list               # show modules
./install.sh --skip latex         # everything but TeX Live
./install.sh --skip sudo          # keep the sudo password prompt
./install.sh --only shell,dotfiles
CLANG_VERSION=21 ./install.sh --only cpp   # pin a different LLVM release
```

## Modules

| Module | Contents |
|---|---|
| `sudo` | passwordless sudo via `/etc/sudoers.d/`, validated with `visudo -c` before install |
| `locale` | timezone `America/Sao_Paulo`, generates `en_US.UTF-8` (+ `pt_BR.UTF-8`) and sets `LANG` |
| `base` | `nala`, `aptitude`, `ppa-purge`, `fzf`, `bat`, `w3m`, `croc`, `command-not-found`, `net-tools`, `ubuntu-wsl`, `/etc/wsl.conf` with systemd |
| `shell` | `zsh` + oh-my-zsh, cloned plugins (`fzf-tab`, `fast-syntax-highlighting`, `zsh-autosuggestions`, `zsh-bat`), built-in plugins (`command-not-found`, `extract`, `sudo`, `web-search`), `starship`, `zoxide`, `mise` (node = latest), `eza`, FiraCode Nerd Font |
| `cpp` | `build-essential`, `cmake`, `ninja-build` (`.zshrc` sets `CMAKE_GENERATOR=Ninja`), `gdb`, `doxygen`, `graphviz`, **LLVM/clang 22** from `apt.llvm.org` (`clang`, `clangd`, `clang-format`, `clang-tidy`, `lld`, `lldb`) wired to the unversioned names via `update-alternatives`, `~/.config/clangd/config.yaml` |
| `embedded` | `gcc-arm-none-eabi`, `binutils-arm-none-eabi`, `libnewlib-arm-none-eabi`, `libstdc++-arm-none-eabi-newlib`, `gdb-multiarch`, `openocd`, `stlink-tools`, `dfu-util`, `dialout`+`plugdev` groups |
| `python` | `python3-*`, `virtualenv`, `pipx` → `ruff`, `uv`, `tldr` |
| `rust` | `rustup` + `rust-analyzer`, `clippy`, `rustfmt` |
| `docker` | Docker CE, CLI, containerd, buildx, compose; `docker` group; service enabled |
| `github` | `gh` CLI, `gh co` alias, HTTPS protocol, ed25519 key generated **and registered on GitHub** via `gh ssh-key add`, then verified |
| `latex` | `texlive-latex-extra`, `texlive-fonts-extra` (~2 GB) |
| `claude` | Claude Code CLI, `settings.json`, `statusline.py`, `CLAUDE.md` |
| `vscode` | 45 extensions from `vscode-extensions.txt`, Machine `settings.json` |
| `dotfiles` | `.zshrc`, `.zshenv`, `.gitconfig`, `.gitignore_global`, clangd config, generated `~/.config/wsl-env.zsh` |

## Checking the result

```bash
./doctor.sh     # read-only; exits non-zero if anything is missing
```

Verifies every module's deliverables — versions, group membership, the sudoers
drop-in, cloned zsh plugins, clang major version, `run-clang-tidy` on `PATH`,
docker reachability, SSH authentication to GitHub, and the git settings below.

## WSL interop paths

The `cube` and `cmonitor` aliases and `OPENOCD_SCRIPTS_PATH` point into the
Windows user profile, whose name differs per machine. Rather than hardcode it,
the `dotfiles` module detects it at install time and writes:

```sh
# ~/.config/wsl-env.zsh
export WIN_USER="<detected>"
export WIN_HOME="/mnt/c/Users/<detected>"
```

`.zshrc` sources that file if it exists and defines the Windows-facing aliases
inside the guard, so on a non-WSL machine the block is simply skipped.

Detection tries `cmd.exe` (~65 ms), then `powershell.exe` (~350 ms), then falls
back to the single non-system profile under `/mnt/c/Users`. It runs **once, in
the installer** — shell startup only does a file test and a `source`, never a
subprocess. Re-run it with `./install.sh --only dotfiles`.

## Git configuration

`dotfiles/.gitconfig` carries more than identity. The notable settings:

| Setting | Effect |
|---|---|
| `push.autoSetupRemote` | `git push` on a new branch just works, no `--set-upstream` |
| `pull.rebase` | rebase instead of creating merge bubbles |
| `fetch.prune` | delete refs for branches gone from the remote |
| `rebase.autoStash` | rebase with a dirty tree instead of refusing |
| `merge.conflictStyle = zdiff3` | conflicts show the common ancestor, not just the two sides |
| `rerere.enabled` | remember a conflict resolution and replay it |
| `diff.algorithm = histogram` | noticeably better diffs than the default |
| `core.autocrlf = input` | normalise CRLF on commit, never on checkout |
| `branch.sort = -committerdate` | `git branch` lists most recent first |
| `core.excludesfile` | points at `~/.gitignore_global` |

These live in the dotfile rather than in a module that runs `git config --global`,
because the `dotfiles` module runs last and would overwrite anything such a
module had written.

## Passwordless sudo

The `sudo` module writes `/etc/sudoers.d/99-<user>-nopasswd`, validated with
`visudo -c` before it is installed — an invalid sudoers file would otherwise lock
you out of `sudo` entirely. Any process running as you can then become root with
no prompt, which is the trade-off. Skip it with `./install.sh --skip sudo`.

## Secrets — not in this repo

- `~/.ssh/id_ed25519` — the `github` module generates a fresh key per machine.
- `gh` and Claude Code credentials — authenticate interactively after install.

## Version caveats

- **Docker** may not publish a pocket for a brand-new Ubuntu release on day one.
  The `docker` module detects this and falls back to `noble`; re-run
  `./install.sh --only docker` once the real pocket exists.
- **`eza`** is installed from the Ubuntu archive when available, and from
  `deb.gierens.de` otherwise.
- **`bat`** is `batcat` on Ubuntu. The `zsh-bat` plugin aliases `cat` -> `batcat`
  (the real one stays available as `rcat`) and routes man pages through it; the
  `base` module additionally symlinks `~/.local/bin/bat` so a plain `bat` command
  works in bash and in non-interactive shells.
- **clang 22** comes from `apt.llvm.org`. The module probes for a pocket matching
  the release codename and falls back to `noble` if LLVM has not published one
  yet. `clang-format` output changes between major versions, so re-running
  `make format` on a project last formatted with clang-format 18 will produce a
  diff — expect one commit of churn per project.
- **`gcc-arm-none-eabi`** tracks the Ubuntu archive, so its version moves with the
  release (24.04 shipped 13.2.rel1). Pin it manually from the Arm Developer site
  if a firmware project requires a specific toolchain.

## After installing

1. `exec zsh`, or reopen the terminal.
2. `wsl --shutdown` from Windows — group membership (`docker`, `dialout`,
   `plugdev`) and systemd only take effect after a full restart.
3. `gh auth login` and `claude` to authenticate.
4. Nothing on the Windows side is managed here — Windows Terminal and the
   VS Code UI use fonts installed on Windows, which is a one-time manual step.
5. If VS Code extensions were skipped, connect VS Code to WSL once and re-run
   `./install.sh --only vscode`.

## Updating this repo from a live machine

After changing `~/.zshrc` and friends, copy them back and commit:

```bash
cp ~/.zshrc ~/.zshenv ~/.gitconfig dotfiles/
cp ~/.config/clangd/config.yaml dotfiles/.config/clangd/
cp ~/.claude/{settings.json,statusline.py,CLAUDE.md} dotfiles/.claude/
cp ~/.vscode-server/data/Machine/settings.json dotfiles/vscode/
code --list-extensions > vscode-extensions.txt
```
