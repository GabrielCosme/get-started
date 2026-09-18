# get-started

Bootstrap script for a fresh **Ubuntu on WSL2** machine, rebuilt from the setup
captured on `DESKTOP-392HJ56` (Ubuntu 24.04.5) in September 2026.

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
./install.sh --only shell,dotfiles
```

## Modules

| Module | Contents |
|---|---|
| `base` | `nala`, `aptitude`, `ppa-purge`, `fzf`, `bat`, `tldr`, `neofetch`, `w3m`, `croc`, `net-tools`, `ubuntu-wsl`, `/etc/wsl.conf` with systemd |
| `shell` | `zsh` + oh-my-zsh, plugins (`fzf-tab`, `fast-syntax-highlighting`, `zsh-autosuggestions`), `starship`, `zoxide`, `mise` (node = latest), `eza`, FiraCode Nerd Font |
| `cpp` | `build-essential`, `clang`/`clangd`/`clang-format`/`clang-tidy`, `cmake`, `ninja-build`, `gdb`, `doxygen`, `graphviz`, `~/.config/clangd/config.yaml` |
| `embedded` | `gcc-arm-none-eabi`, `gdb-multiarch`, newlib, `dialout`+`plugdev` groups |
| `python` | `python3-*`, `virtualenv`, `pipx` → `poetry`, `ruff`, `uv` |
| `rust` | `rustup` + `rust-analyzer`, `clippy`, `rustfmt` |
| `docker` | Docker CE, CLI, containerd, buildx, compose; `docker` group; service enabled |
| `github` | `gh` CLI, `gh co` alias, HTTPS protocol, ed25519 key generation |
| `latex` | `texlive-latex-extra`, `texlive-fonts-extra` (~2 GB) |
| `claude` | Claude Code CLI, `settings.json`, `statusline.py`, `CLAUDE.md` |
| `vscode` | 45 extensions from `vscode-extensions.txt`, Machine `settings.json` |
| `dotfiles` | `.zshrc`, `.zshenv`, `.gitconfig`, clangd config |

## Deliberately not included

These were on the old machine but were left out on purpose:

- **ROS 2 Jazzy, `ros-dev-tools`, Gazebo `gz-harmonic`, the `ros2-env` zsh plugin.**
  Jazzy is pinned to 24.04 and will not install on a newer release.
- **CUDA toolkit 12.9, Nsight Systems/Compute.**
- **Graphics stack**: oibaf PPA, mesa dev packages, LunarG `vulkan-sdk`, `xorg`,
  `xpra`, `mesaflash`, `vainfo`, and MuJoCo under `~/.mujoco`.
- **Codex and GitHub Copilot CLI**, and the `openai.chatgpt` VS Code extension.

To bring any of these back, add a module under `scripts/` and register it in the
`MODULES` array in `install.sh`.

## Secrets — not in this repo

- `~/.ssh/id_ed25519` — the `github` module generates a fresh key per machine.
- `gh` and Claude Code credentials — authenticate interactively after install.

## Version caveats

- **Docker** may not publish a pocket for a brand-new Ubuntu release on day one.
  The `docker` module detects this and falls back to `noble`; re-run
  `./install.sh --only docker` once the real pocket exists.
- **`eza`** is installed from the Ubuntu archive when available, and from
  `deb.gierens.de` otherwise.
- **`gcc-arm-none-eabi`** tracks the Ubuntu archive, so its version moves with the
  release (24.04 shipped 13.2.rel1). Pin it manually from the Arm Developer site
  if a firmware project requires a specific toolchain.

## After installing

1. `exec zsh`, or reopen the terminal.
2. `wsl --shutdown` from Windows — group membership (`docker`, `dialout`,
   `plugdev`) and systemd only take effect after a full restart.
3. `gh auth login` and `claude` to authenticate.
4. Install FiraCode Nerd Font **on Windows** as well, then select it in Windows
   Terminal — the Linux-side font does not affect the terminal's rendering.
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
