# dev-env-bootstrap

[English](README.md) | [简体中文](README.zh-CN.md)

Personal machine setup for quickly getting a familiar terminal/development environment on Linux and macOS.

This repository keeps the old one-command setup goal, but separates it into safer layers:

- `bootstrap.sh` prepares the machine and applies the core config.
- `install.sh` safely links config files and manages shell/Git include blocks.
- `config/core/` contains the default cross-platform environment.
- `config/optional/` preserves heavier or more opinionated tools from the old repo.

## Quick start

```bash
git clone git@github.com:InitialMoon/dev-env-bootstrap.git
cd dev-env-bootstrap
./bootstrap.sh doctor
./bootstrap.sh core
```

`bootstrap.sh core` checks/installs basic tools when a package manager is available, then runs `./install.sh link`.

For a fuller one-command setup inspired by the old `run_config.sh`, but with safer defaults:

```bash
./bootstrap.sh all
```

`all` runs core setup, then optional `fish`, `nvim`, and `oh-my-posh` modules. Use `ASSUME_YES=1` to skip package and optional installer prompts, including the Oh My Posh upstream installer, or `DRY_RUN=1` to preview package/link actions.

If you only want to link configuration and avoid package installation:

```bash
./install.sh dry-run
./install.sh link
```

## Core layer

The default core setup manages:

- cross-platform shell snippets for Bash/Zsh under `~/.config/my-linux-config/shell/`, plus Fish snippets under `~/.config/fish/conf.d/` and `~/.config/my-linux-config/fish/`
- `tmux` config: `config/core/tmux/tmux.conf` -> `~/.tmux.conf`
- Git defaults under `~/.config/my-linux-config/git/` and shared ignore rules under `~/.config/git/`
- Yazi config under `~/.config/yazi/`
- Claude Code shared settings, status line template, and local examples under `~/.claude/`
- Codex shared profiles and local examples under `~/.codex/`
- `ssh-socks-proxy` under `~/.local/bin/`

The installer is conservative:

- no overwrite of existing user files
- safe symlink checks
- managed begin/end blocks for shell and Git config
- `unlink` only removes links/blocks owned by this repository

## macOS reproducibility layer

The shared core works on Linux and macOS. macOS-specific toolchain setup is opt-in:

```bash
./bootstrap.sh macos
./bootstrap.sh interactive
```

The macOS menu can install or configure groups such as Homebrew basics, shells, editors, Java, LLVM/OpenMP, Ruby, dotnet, conda/mamba, and AI-tool notes. You can select none of them and still keep the shared core configuration.

## Optional layer

Optional modules preserved from the old repo:

- `config/optional/fish/` — fish and Oh My Fish config
- `config/optional/zsh/` — legacy zsh/oh-my-zsh installer path kept for manual review
- `config/optional/nvim/` — LazyVim-based Neovim config
- `config/optional/vim/` — Vim config
- `config/optional/oh-my-posh/` — old Oh My Posh themes; installer may use upstream script after confirmation
- `config/optional/ranger/` — package install/check plus old vendored ranger source note
- `config/optional/legacy/` — original full config files and `run_config.sh`

These are not installed by default by `core`. Configure or inspect selected modules explicitly:

```bash
./bootstrap.sh optional nvim
./bootstrap.sh optional fish nvim oh-my-posh
./bootstrap.sh optional zsh
./bootstrap.sh optional ranger
```

Linking optional modules uses safe links and skips existing unmanaged paths instead of overwriting user config. `zsh` only prints the preserved legacy installer note and manual review path; `ranger` installs/checks the package and notes the vendored source; `oh-my-posh` may run the upstream installer after confirmation before linking themes.

## Commands

```bash
./bootstrap.sh doctor              # check platform, package manager, and tools
./bootstrap.sh core                # install/check core tools and link config
./bootstrap.sh ai                  # link Claude Code and Codex shared config only
./bootstrap.sh macos               # link macOS config and run macOS setup menu
./bootstrap.sh interactive         # choose optional setup groups interactively
./bootstrap.sh all                 # core + fish + nvim + oh-my-posh
./bootstrap.sh optional            # show optional modules
./bootstrap.sh optional nvim fish  # install/configure selected optional modules

./install.sh dry-run            # preview core + AI links and managed blocks
./install.sh link               # apply core + AI config safely
./install.sh ai                 # link Claude Code and Codex shared config only
./install.sh macos              # link opt-in macOS config only
./install.sh dry-run-ai         # preview AI-tool shared config links
./install.sh dry-run-macos      # preview opt-in macOS config links
./install.sh status             # inspect managed config state
./install.sh unlink             # remove managed links and blocks
./install.sh doctor             # check tool availability
```

## Local/private config

Do not commit secrets, tokens, private paths, SSH key material, or machine-specific identity.

Use local files instead:

- `~/.config/my-linux-config/shell/local.sh`
- `~/.gitconfig` outside the managed block
- `~/.claude/settings.local.json`
- `~/.codex/config.local.toml` if your Codex setup supports it

## macOS notes

The core config is intended to work on macOS and Linux.

### iTerm2 Option key for tmux

If you want to use this tmux config on macOS with iTerm2, configure the Option key to send Esc+/Meta. The tmux bindings use Meta/Alt-style keys, and iTerm2 uses Option for special characters by default.

<img width="978" alt="iTerm2 Option key setting" src="https://github.com/user-attachments/assets/724ddb18-9f40-4212-a3a1-901c8bded73a" />

Steps:

1. Open iTerm2 Preferences.
2. Go to Profiles.
3. Select your profile.
4. Open the Keys tab.
5. Set Left Option Key and Right Option Key to Esc+.

## Legacy notes

The original `run_config.sh` has been moved to `config/optional/legacy/run_config.sh` for reference. It is no longer the default entrypoint because it mixed package installation, config overwrites, plugin downloads, and optional tools in one script.
