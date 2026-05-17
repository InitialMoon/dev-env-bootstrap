# macOS/Linux Config Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `dev-env-bootstrap` safely shareable while reproducing the current macOS terminal and AI-tool experience, with the same core terminal and AI defaults available on Linux.

**Architecture:** Keep one conservative cross-platform core layer, add an opt-in macOS layer for Apple-specific toolchain setup, and represent all private machine state only as local examples. Installation remains symlink/block based, never overwrites unmanaged user files, and adds interactive selection for optional macOS toolchain groups.

**Tech Stack:** Bash, Git config, tmux, zsh/bash/fish shell snippets, Yazi, Vim, Claude Code settings, Codex TOML settings, Homebrew on macOS.

---

## Scope Check

The approved spec spans terminal core, AI-tool config, macOS reproducibility, installers, docs, and auditing. These are tightly coupled by the bootstrap/install workflow, so one integrated plan is appropriate. Each task below leaves the repo in a testable state and can be reviewed independently.

## File Structure

Create or modify these files:

- Modify `config/core/shell/common.sh` — cross-platform PATH/XDG defaults, aliases, Yazi helper, local hook.
- Modify `config/core/shell/bash.sh` — Bash entry snippet that loads common and Bash-local config.
- Modify `config/core/shell/zsh.sh` — Zsh entry snippet that loads common, guarded Oh My Zsh/Powerlevel10k behavior, and Zsh-local config.
- Modify `config/core/shell/local.example.sh` — documented local/private shell template.
- Create `config/core/fish/dev-env-bootstrap.fish` — cross-platform fish conf.d snippet.
- Create `config/core/fish/local.example.fish` — local/private fish template.
- Create `config/macos/shell/macos.sh` — macOS-only shell environment layer.
- Create `config/macos/shell/local.example.sh` — private macOS shell template.
- Create `scripts/macos.sh` — interactive macOS package/setup menu.
- Modify `bootstrap.sh` — add `ai`, `macos`, and `interactive` commands.
- Modify `install.sh` — split managed links into core, AI, fish, and macOS groups; keep rollback safe.
- Modify `config/core/git/config` — add safe `pf = push --force-with-lease` and keep corrected `rerere.enabled`.
- Create `config/core/git/ignore` — shared global Git ignore patterns.
- Modify `.gitignore` — ignore private/local files across new layers.
- Modify `scripts/audit-secrets.sh` — audit private paths/endpoints across the new layout.
- Modify `config/core/tmux/tmux.conf` — keep guarded plugin loading and make continuation settings explicit.
- Modify `config/core/yazi/keymap.toml` — keep only cross-platform keymaps.
- Modify `config/optional/vim/vimrc` — trim tutorial comments while preserving key behavior.
- Modify `config/core/claude/settings.json` — safe shared Claude Code defaults and status line config.
- Modify `config/core/claude/settings.local.example.json` — private Claude Code template.
- Create `config/core/claude/statusline.sh` — portable status line command.
- Modify `config/core/codex/config.toml` — safe shared Codex defaults/profiles.
- Modify `config/core/codex/config.local.example.toml` — private Codex template.
- Modify `README.md` and `README.zh-CN.md` — document layers and commands.

---

### Task 1: Baseline and Safety Checks

**Files:**
- Read-only validation of repository state.
- No source modifications.

- [ ] **Step 1: Verify missing planned files fail baseline checks**

Run:

```bash
test -f dev-env-bootstrap/config/macos/shell/macos.sh
```

Expected: command exits with status `1` because the macOS layer has not been created yet.

Run:

```bash
test -f dev-env-bootstrap/config/core/claude/statusline.sh
```

Expected: command exits with status `1` because the shared status line script has not been created yet.

- [ ] **Step 2: Capture existing dry-run behavior**

Run:

```bash
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run
```

Expected: command exits with status `0`; output includes conservative messages such as `would link:` and `warn: skip existing path:`.

- [ ] **Step 3: Capture existing bootstrap doctor behavior**

Run:

```bash
dev-env-bootstrap/bootstrap.sh doctor
```

Expected: command exits with status `0`; output includes `platform:` and `core tools:`.

- [ ] **Step 4: Commit checkpoint only if commits are authorized**

If the user has explicitly authorized commits for implementation, run:

```bash
git -C dev-env-bootstrap status --short
git -C dev-env-bootstrap add docs/superpowers/specs/2026-05-17-macos-linux-config-sync-design.md docs/superpowers/plans/2026-05-17-macos-linux-config-sync.md
git -C dev-env-bootstrap commit -m "docs: plan macos linux config sync"
```

Expected: commit succeeds. If commits are not authorized, skip this step and leave changes unstaged.

---

### Task 2: Cross-Platform Shell Core

**Files:**
- Modify: `config/core/shell/common.sh`
- Modify: `config/core/shell/bash.sh`
- Modify: `config/core/shell/zsh.sh`
- Modify: `config/core/shell/local.example.sh`
- Create: `config/core/fish/dev-env-bootstrap.fish`
- Create: `config/core/fish/local.example.fish`

- [ ] **Step 1: Write failing file-presence checks for fish core**

Run:

```bash
test -f dev-env-bootstrap/config/core/fish/dev-env-bootstrap.fish
```

Expected: command exits with status `1`.

Run:

```bash
test -f dev-env-bootstrap/config/core/fish/local.example.fish
```

Expected: command exits with status `1`.

- [ ] **Step 2: Replace `config/core/shell/common.sh`**

Write this exact content:

```bash
# Shared shell defaults for macOS and Linux.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"

_dev_env_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME}/my-linux-config}"

_dev_env_path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) export PATH="$1:${PATH}" ;;
  esac
}

_dev_env_path_prepend "${HOME}/.local/bin"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if command -v yazi >/dev/null 2>&1; then
  yy() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
      cwd="$(command cat "$tmp")"
      if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd" || return
      fi
    fi
    command rm -f "$tmp"
  }
  y() {
    yy "$@"
  }
fi

if [[ -r "${_dev_env_config_home}/shell/local.sh" ]]; then
  source "${_dev_env_config_home}/shell/local.sh"
fi

unset -f _dev_env_path_prepend
unset _dev_env_config_home
```

- [ ] **Step 3: Replace `config/core/shell/bash.sh`**

Write this exact content:

```bash
_dev_env_shell_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config}"

if [[ -r "${_dev_env_shell_config_home}/shell/common.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/common.sh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/bash.local.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/bash.local.sh"
fi

unset _dev_env_shell_config_home
```

- [ ] **Step 4: Replace `config/core/shell/zsh.sh`**

Write this exact content:

```bash
_dev_env_shell_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config}"

if [[ -r "${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/common.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/common.sh"
fi

if [[ -r "${ZSH:-${HOME}/.oh-my-zsh}/oh-my-zsh.sh" ]]; then
  export ZSH="${ZSH:-${HOME}/.oh-my-zsh}"
  ZSH_THEME="${ZSH_THEME:-powerlevel10k/powerlevel10k}"
  _dev_env_zsh_custom="${ZSH_CUSTOM:-${ZSH}/custom}"
  plugins=()
  for _dev_env_plugin in git autojump zsh-syntax-highlighting zsh-autosuggestions vi-mode; do
    if [[ -d "${ZSH}/plugins/${_dev_env_plugin}" || -d "${_dev_env_zsh_custom}/plugins/${_dev_env_plugin}" ]]; then
      plugins+=("${_dev_env_plugin}")
    fi
  done
  unset _dev_env_plugin _dev_env_zsh_custom
  source "${ZSH}/oh-my-zsh.sh"
fi

if [[ -r "${HOME}/.p10k.zsh" ]]; then
  source "${HOME}/.p10k.zsh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/zsh.local.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/zsh.local.sh"
fi

unset _dev_env_shell_config_home
```

- [ ] **Step 5: Replace `config/core/shell/local.example.sh`**

Write this exact content:

```bash
# Copy to ~/.config/my-linux-config/shell/local.sh and edit for this machine.
# Keep this file free of real secrets before committing.

# Load service keys from a private file if you use one.
# if [[ -r "${HOME}/private_service_keys.json" ]]; then
#   export EXAMPLE_SERVICE_KEY="$(python3 -c 'import json, pathlib; print(json.loads(pathlib.Path.home().joinpath("private_service_keys.json").read_text()).get("EXAMPLE_SERVICE_KEY", ""))')"
# fi

# Add private signing or access keys for this machine.
# if command -v ssh-add >/dev/null 2>&1; then
#   ssh-add "${HOME}/path/to/private_key" >/dev/null 2>&1 || true
# fi

# Add private project paths for this machine.
# case ":${PATH}:" in
#   *":${HOME}/example-project/bin:"*) ;;
#   *) export PATH="${HOME}/example-project/bin:${PATH}" ;;
# esac

# Activate a local Python environment only when you want every shell to enter it.
# if command -v mamba >/dev/null 2>&1; then
#   mamba activate daily_use
# fi
```

- [ ] **Step 6: Create `config/core/fish/dev-env-bootstrap.fish`**

Write this exact content:

```fish
# Shared fish defaults for macOS and Linux.

set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share

fish_add_path --path $HOME/.local/bin

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if command -q yazi
    function yy
        set tmp (mktemp -t yazi-cwd.XXXXXX); or return
        yazi $argv --cwd-file=$tmp
        if test -f $tmp
            set cwd (cat $tmp)
            if test -n "$cwd"; and test "$cwd" != "$PWD"
                cd $cwd
            end
        end
        rm -f $tmp
    end
    function y
        yy $argv
    end
end

if set -q DEV_ENV_CONFIG_HOME
    set _dev_env_config_home $DEV_ENV_CONFIG_HOME
else
    set _dev_env_config_home "$XDG_CONFIG_HOME/my-linux-config"
end

if test -r "$_dev_env_config_home/fish/local.fish"
    source "$_dev_env_config_home/fish/local.fish"
end

set -e _dev_env_config_home
```

- [ ] **Step 7: Create `config/core/fish/local.example.fish`**

Write this exact content:

```fish
# Copy to ~/.config/my-linux-config/fish/local.fish and edit for this machine.
# Keep real tokens, private paths, and SSH key names out of the repository.

# set -gx EXAMPLE_API_KEY "replace-me-outside-git"
# fish_add_path $HOME/example-project/bin
```

- [ ] **Step 9: Run syntax checks**

Run:

```bash
bash -n dev-env-bootstrap/config/core/shell/common.sh
bash -n dev-env-bootstrap/config/core/shell/bash.sh
zsh -n dev-env-bootstrap/config/core/shell/zsh.sh
```

Expected: all commands exit with status `0`. If `zsh` is unavailable, record that the zsh syntax check could not run and continue only after `bash -n` passes.

- [ ] **Step 9: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add config/core/shell/common.sh config/core/shell/bash.sh config/core/shell/zsh.sh config/core/shell/local.example.sh config/core/fish/dev-env-bootstrap.fish config/core/fish/local.example.fish
git -C dev-env-bootstrap commit -m "feat: add cross-platform shell core"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 3: macOS Reproducibility Layer

**Files:**
- Create: `config/macos/shell/macos.sh`
- Create: `config/macos/shell/local.example.sh`
- Create: `scripts/macos.sh`

- [ ] **Step 1: Verify macOS layer files are absent before creation**

Run:

```bash
test -f dev-env-bootstrap/config/macos/shell/macos.sh
```

Expected: command exits with status `1`.

Run:

```bash
test -f dev-env-bootstrap/scripts/macos.sh
```

Expected: command exits with status `1`.

- [ ] **Step 2: Create `config/macos/shell/macos.sh`**

Write this exact content:

```bash
# macOS-only shell defaults. Safe to source on non-macOS; it becomes a no-op.

if [[ "$(uname -s)" != "Darwin" ]]; then
  return 0 2>/dev/null || exit 0
fi

_macos_path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) export PATH="$1:${PATH}" ;;
  esac
}

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ -z "${HOMEBREW_BOTTLE_DOMAIN+x}" ]]; then
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
fi

if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home 2>/dev/null || true)"
  if [[ -n "${_java_home}" ]]; then
    export JAVA_HOME="${JAVA_HOME:-${_java_home}}"
    _macos_path_prepend "${JAVA_HOME}/bin"
  fi
  unset _java_home
fi

if [[ -d /opt/homebrew/opt/llvm ]]; then
  _macos_path_prepend "/opt/homebrew/opt/llvm/bin"
  export LDFLAGS="${LDFLAGS:+${LDFLAGS} }-L/opt/homebrew/opt/llvm/lib"
  export CPPFLAGS="${CPPFLAGS:+${CPPFLAGS} }-I/opt/homebrew/opt/llvm/include"
  export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-/opt/homebrew/opt/llvm}"
fi

if [[ -d /opt/homebrew/opt/ruby ]]; then
  _macos_path_prepend "/opt/homebrew/opt/ruby/bin"
  if command -v gem >/dev/null 2>&1; then
    _macos_path_prepend "$(gem env user_gemhome)/bin"
  fi
fi

if [[ -d /opt/homebrew/opt/dotnet@6/bin ]]; then
  _macos_path_prepend "/opt/homebrew/opt/dotnet@6/bin"
fi

if [[ -r "${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config/macos/local.sh" ]]; then
  source "${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config/macos/local.sh"
fi

unset -f _macos_path_prepend
```

- [ ] **Step 3: Create `config/macos/shell/local.example.sh`**

Write this exact content:

```bash
# Copy to ~/.config/my-linux-config/macos/local.sh and edit for this Mac.
# Keep private paths and secrets out of the repository.

# Miniforge/Mamba initialization example for Apple Silicon Homebrew installs.
# if [[ -x /opt/homebrew/bin/mamba ]]; then
#   export MAMBA_EXE='/opt/homebrew/bin/mamba'
#   export MAMBA_ROOT_PREFIX="${HOME}/.local/share/mamba"
#   __mamba_setup="$("${MAMBA_EXE}" shell hook --shell zsh --root-prefix "${MAMBA_ROOT_PREFIX}" 2>/dev/null)"
#   if [[ $? -eq 0 ]]; then
#     eval "$__mamba_setup"
#   fi
#   unset __mamba_setup
# fi
```

- [ ] **Step 4: Create `scripts/macos.sh`**

Write this exact content:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"

source "${ROOT_DIR}/scripts/lib/common.sh"

ASSUME_YES="${ASSUME_YES:-0}"
DRY_RUN="${DRY_RUN:-0}"

usage() {
  cat <<EOF
Usage: $0 <command> [group...]

Commands:
  list                 Show macOS setup groups
  install GROUP...     Install selected groups
  interactive          Choose groups from a prompt
  doctor               Check macOS prerequisites

Groups:
  basics       git curl tmux yazi
  shells       zsh fish autojump zsh plugins
  editors      neovim vim
  java         openjdk
  llvm         llvm libomp
  ruby         ruby
  dotnet       dotnet@6
  conda        miniforge mamba
  ai           claude/codex installation notes only

Environment:
  ASSUME_YES=1         Skip install confirmation
  DRY_RUN=1            Print brew commands without running them
EOF
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    warn "macOS setup is only available on Darwin"
    exit 2
  fi
}

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew is required for package installation"
    warn "Install Homebrew first, then rerun this command"
    exit 1
  fi
}

packages_for_group() {
  case "$1" in
    basics) printf '%s\n' git curl tmux yazi ;;
    shells) printf '%s\n' zsh fish autojump zsh-syntax-highlighting zsh-autosuggestions powerlevel10k ;;
    editors) printf '%s\n' neovim vim ;;
    java) printf '%s\n' openjdk ;;
    llvm) printf '%s\n' llvm libomp ;;
    ruby) printf '%s\n' ruby ;;
    dotnet) printf '%s\n' dotnet@6 ;;
    conda) printf '%s\n' mamba ;;
    ai) printf '%s\n' ;;
    *) return 1 ;;
  esac
}

cmd_list() {
  usage
}

confirm() {
  local groups="$1"
  if [[ "${ASSUME_YES}" == "1" || "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  say "selected macOS groups: ${groups}"
  read -r -p "Proceed with Homebrew installation? [y/N] " reply
  [[ "${reply}" == "y" || "${reply}" == "Y" ]]
}

install_groups() {
  local group package packages=() packages_text
  for group in "$@"; do
    if [[ "${group}" == "ai" ]]; then
      say "ai: install Claude Code and Codex with their official installers, then run ./bootstrap.sh ai"
      continue
    fi
    packages_text="$(packages_for_group "${group}")" || {
      warn "unknown macOS group: ${group}"
      return 1
    }
    while IFS= read -r package; do
      [[ -n "${package}" ]] && packages+=("${package}")
    done <<<"${packages_text}"
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    say "no Homebrew packages selected"
    return 0
  fi

  if ! confirm "$*"; then
    warn "macOS package installation skipped"
    return 0
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    printf 'brew install'
    printf ' %q' "${packages[@]}"
    printf '\n'
  else
    ensure_brew
    brew install "${packages[@]}"
  fi
}

cmd_interactive() {
  cat <<EOF
Select macOS setup groups by number, separated by spaces. Press Enter to skip all.
  1) basics
  2) shells
  3) editors
  4) java
  5) llvm
  6) ruby
  7) dotnet
  8) conda
  9) ai
EOF
  read -r -p "Groups: " selection
  [[ -n "${selection}" ]] || {
    say "no macOS groups selected"
    return 0
  }

  local groups=() item
  for item in ${selection}; do
    case "${item}" in
      1) groups+=(basics) ;;
      2) groups+=(shells) ;;
      3) groups+=(editors) ;;
      4) groups+=(java) ;;
      5) groups+=(llvm) ;;
      6) groups+=(ruby) ;;
      7) groups+=(dotnet) ;;
      8) groups+=(conda) ;;
      9) groups+=(ai) ;;
      *) warn "ignored unknown selection: ${item}" ;;
    esac
  done
  install_groups "${groups[@]}"
}

cmd_doctor() {
  say "platform: $(uname -s)"
  if command -v brew >/dev/null 2>&1; then
    say "ok: brew ($(command -v brew))"
  else
    say "missing: brew"
  fi
}

ensure_macos
cmd="${1:-list}"
shift || true
case "${cmd}" in
  list) cmd_list ;;
  install) install_groups "$@" ;;
  interactive|choose) cmd_interactive ;;
  doctor) cmd_doctor ;;
  -h|--help|help) usage ;;
  *) warn "unknown command: ${cmd}"; usage >&2; exit 2 ;;
esac
```

- [ ] **Step 5: Make `scripts/macos.sh` executable**

Run:

```bash
chmod +x dev-env-bootstrap/scripts/macos.sh
```

Expected: command exits with status `0`.

- [ ] **Step 6: Run syntax checks**

Run:

```bash
bash -n dev-env-bootstrap/config/macos/shell/macos.sh
bash -n dev-env-bootstrap/config/macos/shell/local.example.sh
bash -n dev-env-bootstrap/scripts/macos.sh
```

Expected: all commands exit with status `0`.

- [ ] **Step 7: Run macOS dry-run list**

On macOS, run:

```bash
DRY_RUN=1 dev-env-bootstrap/scripts/macos.sh list
```

Expected: command exits with status `0`; output includes `Groups:` and `basics`.

On Linux, run:

```bash
DRY_RUN=1 dev-env-bootstrap/scripts/macos.sh list
```

Expected: command exits with status `2`; output includes `macOS setup is only available on Darwin`.

- [ ] **Step 8: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add config/macos/shell/macos.sh config/macos/shell/local.example.sh scripts/macos.sh
git -C dev-env-bootstrap commit -m "feat: add opt-in macos setup layer"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 4: Installer Link Groups and Bootstrap Commands

**Files:**
- Modify: `install.sh`
- Modify: `bootstrap.sh`
- Create early placeholder: `config/core/git/ignore`
- Create early placeholder: `config/core/claude/statusline.sh`

Task 4 introduces managed links to the shared Git ignore file and Claude status line. Create minimal safe placeholder versions of those sources in this task so strict missing-source checks remain valid for `dry-run`, `link`, and `ai`; Tasks 5 and 6 will expand them to their final intended contents.

- [ ] **Step 1: Write failing command checks**

Run:

```bash
dev-env-bootstrap/bootstrap.sh ai
```

Expected before implementation: command exits with status `2` and output includes `unknown command: ai`.

Run:

```bash
dev-env-bootstrap/install.sh ai
```

Expected before implementation: command exits with status `2` and output includes `unknown command: ai`.

- [ ] **Step 2: Create early placeholder sources for newly managed links**

Create `config/core/git/ignore` with this minimal safe shared ignore content:

```gitignore
# Local/private Claude Code and Codex files
**/.claude/settings.local.json
**/.codex/config.local.toml
```

Create `config/core/claude/statusline.sh` with this minimal safe executable status line script:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

cwd="${PWD/#${HOME}/~}"
printf 'claude %s\n' "${cwd}"
```

Run:

```bash
chmod +x dev-env-bootstrap/config/core/claude/statusline.sh
bash -n dev-env-bootstrap/config/core/claude/statusline.sh
```

Expected: both commands exit with status `0`. These files are placeholders that keep managed links valid; Task 5 replaces the Git ignore with fuller shared rules and Task 6 replaces the status line with the final shared AI-tool version.

- [ ] **Step 3: In `install.sh`, replace `managed_links()` with grouped link functions**

Replace the current `managed_links()` function with this exact block:

```bash
managed_core_links() {
  cat <<EOF
${ROOT_DIR}/bin/ssh-socks-proxy|${HOME}/.local/bin/ssh-socks-proxy
${ROOT_DIR}/config/core/tmux/tmux.conf|${HOME}/.tmux.conf
${ROOT_DIR}/config/core/shell/common.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/common.sh
${ROOT_DIR}/config/core/shell/bash.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/bash.sh
${ROOT_DIR}/config/core/shell/zsh.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/zsh.sh
${ROOT_DIR}/config/core/shell/local.example.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/local.example.sh
${ROOT_DIR}/config/core/fish/dev-env-bootstrap.fish|${XDG_CONFIG_HOME}/fish/conf.d/dev-env-bootstrap.fish
${ROOT_DIR}/config/core/fish/local.example.fish|${XDG_CONFIG_HOME}/my-linux-config/fish/local.example.fish
${ROOT_DIR}/config/core/git/config|${XDG_CONFIG_HOME}/my-linux-config/git/config
${ROOT_DIR}/config/core/git/local.example|${XDG_CONFIG_HOME}/my-linux-config/git/local.example
${ROOT_DIR}/config/core/git/ignore|${XDG_CONFIG_HOME}/git/ignore
${ROOT_DIR}/config/core/yazi/yazi.toml|${XDG_CONFIG_HOME}/yazi/yazi.toml
${ROOT_DIR}/config/core/yazi/keymap.toml|${XDG_CONFIG_HOME}/yazi/keymap.toml
EOF
}

managed_ai_links() {
  cat <<EOF
${ROOT_DIR}/config/core/claude/settings.json|${HOME}/.claude/settings.json
${ROOT_DIR}/config/core/claude/settings.local.example.json|${HOME}/.claude/settings.local.example.json
${ROOT_DIR}/config/core/claude/CLAUDE.md|${HOME}/.claude/CLAUDE.md
${ROOT_DIR}/config/core/claude/statusline.sh|${HOME}/.claude/statusline.sh
${ROOT_DIR}/config/core/codex/config.toml|${HOME}/.codex/config.toml
${ROOT_DIR}/config/core/codex/config.local.example.toml|${HOME}/.codex/config.local.example.toml
${ROOT_DIR}/config/core/codex/AGENTS.md|${HOME}/.codex/AGENTS.md
EOF
}

managed_macos_links() {
  cat <<EOF
${ROOT_DIR}/config/macos/shell/macos.sh|${XDG_CONFIG_HOME}/my-linux-config/macos/macos.sh
${ROOT_DIR}/config/macos/shell/local.example.sh|${XDG_CONFIG_HOME}/my-linux-config/macos/local.example.sh
EOF
}

managed_links() {
  managed_core_links
  managed_ai_links
}

managed_links_with_platform_opt_ins() {
  managed_links
  if [[ "${PLATFORM}" == "macos" ]]; then
    managed_macos_links
  fi
}
```

Default `managed_links()` must stay core + AI only on all platforms. Use `managed_links_with_platform_opt_ins()` only for rollback/status paths that should cover opt-in platform links.

- [ ] **Step 4: In `install.sh`, add group-aware iteration functions after `for_each_link()`**

Add this exact block immediately after the existing `for_each_link()` function:

```bash
for_each_link_from() {
  local provider="$1"
  local action="$2"
  local src dest
  while IFS='|' read -r src dest; do
    [[ -n "${src}" ]] || continue
    "${action}" "${src}" "${dest}"
  done < <("${provider}")
}
```

- [ ] **Step 5: In `install.sh`, source macOS shell from zsh/bash blocks**

Replace `link_blocks()` with this exact function:

```bash
link_blocks() {
  local git_config_path="${XDG_CONFIG_HOME}/my-linux-config/git/config"
  write_block "${HOME}/.bashrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}" 'if [[ -r "${HOME}/.config/my-linux-config/shell/bash.sh" ]]; then
  source "${HOME}/.config/my-linux-config/shell/bash.sh"
fi
if [[ "$(uname -s)" == "Darwin" && -r "${HOME}/.config/my-linux-config/macos/macos.sh" ]]; then
  source "${HOME}/.config/my-linux-config/macos/macos.sh"
fi'
  prepend_block "${HOME}/.zshrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}" 'if [[ -r "${HOME}/.config/my-linux-config/shell/zsh.sh" ]]; then
  source "${HOME}/.config/my-linux-config/shell/zsh.sh"
fi
if [[ "$(uname -s)" == "Darwin" && -r "${HOME}/.config/my-linux-config/macos/macos.sh" ]]; then
  source "${HOME}/.config/my-linux-config/macos/macos.sh"
fi'
  prepend_block "${HOME}/.gitconfig" "${GIT_BLOCK_BEGIN}" "${GIT_BLOCK_END}" "[include]
	path = ${git_config_path}"
}
```

- [ ] **Step 6: In `install.sh`, add AI and macOS commands**

Add these exact functions before `cmd_link()`:

```bash
dry_run_link_file_allow_missing() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "${src}" ]]; then
    warn "missing source: ${src}"
    return 0
  fi

  link_file "${src}" "${dest}"
}

cmd_ai() {
  MODE="link"
  for_each_link_from managed_ai_links link_file
}

cmd_macos() {
  MODE="link"
  if [[ "${PLATFORM}" != "macos" ]]; then
    warn "macOS links are only available on Darwin"
    return 2
  fi
  for_each_link_from managed_macos_links link_file
}

cmd_dry_run_ai() {
  MODE="dry-run"
  for_each_link_from managed_ai_links dry_run_link_file_allow_missing
}

cmd_dry_run_macos() {
  MODE="dry-run"
  if [[ "${PLATFORM}" != "macos" ]]; then
    warn "macOS links are only available on Darwin"
    return 2
  fi
  for_each_link_from managed_macos_links dry_run_link_file_allow_missing
}
```

Then extend the `case` at the bottom of `install.sh` with these branches:

```bash
  ai)
    cmd_ai
    ;;
  macos)
    cmd_macos
    ;;
  dry-run-ai)
    cmd_dry_run_ai
    ;;
  dry-run-macos)
    cmd_dry_run_macos
    ;;
```

- [ ] **Step 7: Update `install.sh` usage text**

In the usage block, include these command lines:

```text
  ai       Link Claude Code and Codex shared config only
  macos    Link macOS-only shared config only
```

Expected: `dev-env-bootstrap/install.sh help` shows both new commands.

- [ ] **Step 8: In `bootstrap.sh`, update commands and core flow**

In the usage block, include these command lines:

```text
  ai                  Link Claude Code and Codex shared config only
  macos               Link macOS config and run the macOS setup menu
  interactive|choose  Choose optional setup groups interactively
```

Add these exact functions before `cmd_all()`:

```bash
cmd_ai() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    "${ROOT_DIR}/install.sh" dry-run-ai
  else
    "${ROOT_DIR}/install.sh" ai
  fi
}

cmd_macos() {
  if [[ "$(platform_name)" != "macos" ]]; then
    warn "macOS setup is only available on Darwin"
    return 2
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    "${ROOT_DIR}/install.sh" dry-run-macos
    "${ROOT_DIR}/scripts/macos.sh" list
  else
    "${ROOT_DIR}/install.sh" macos
    "${ROOT_DIR}/scripts/macos.sh" interactive
  fi
}

cmd_interactive() {
  cat <<EOF
Choose setup mode:
  1) core
  2) ai
  3) macos
  4) optional fish nvim oh-my-posh
  5) skip
EOF
  read -r -p "Mode: " mode
  case "${mode}" in
    1) cmd_core ;;
    2) cmd_ai ;;
    3) cmd_macos ;;
    4) cmd_optional fish nvim oh-my-posh ;;
    5|"") say "skipped" ;;
    *) warn "unknown selection: ${mode}"; return 2 ;;
  esac
}
```

Add these exact case branches:

```bash
  ai)
    cmd_ai
    ;;
  macos)
    cmd_macos
    ;;
  interactive|choose)
    cmd_interactive
    ;;
```

- [ ] **Step 9: Run syntax checks**

Run:

```bash
bash -n dev-env-bootstrap/install.sh
bash -n dev-env-bootstrap/bootstrap.sh
```

Expected: both commands exit with status `0`.

- [ ] **Step 10: Verify new commands**

Run:

```bash
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run-ai
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh ai
```

Expected: both commands exit with status `0`; output mentions Claude/Codex links or skipped existing paths.

On macOS, run:

```bash
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh macos
```

Expected: command exits with status `0`; output includes macOS links and setup groups. `DRY_RUN=1 dev-env-bootstrap/install.sh dry-run` must not include macOS links; macOS links are opt-in via `dry-run-macos`/`macos`.

On Linux, run:

```bash
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh macos
```

Expected: command exits with status `2`; output includes `macOS setup is only available on Darwin`.

- [ ] **Step 11: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add install.sh bootstrap.sh
git -C dev-env-bootstrap commit -m "feat: add grouped install commands"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 5: Git Defaults, Ignore Rules, and Secret Audit

**Files:**
- Modify: `config/core/git/config`
- Expand existing placeholder: `config/core/git/ignore`
- Modify: `.gitignore`
- Modify: `scripts/audit-secrets.sh`

- [ ] **Step 1: Verify global ignore placeholder exists before expansion**

Run:

```bash
test -f dev-env-bootstrap/config/core/git/ignore
grep -n "settings.local.json" dev-env-bootstrap/config/core/git/ignore
```

Expected: both commands exit with status `0` because Task 4 created a minimal placeholder to keep managed links valid before this task expands it.

- [ ] **Step 2: Replace `config/core/git/config`**

Write this exact content:

```gitconfig
[color]
	ui = auto

[init]
	defaultBranch = master

[pull]
	rebase = true

[push]
	default = upstream

[fetch]
	prune = true

[rerere]
	enabled = true

[core]
	quotepath = false
	autocrlf = false
	excludesFile = ~/.config/git/ignore

[alias]
	co = checkout
	cm = commit
	pf = push --force-with-lease
	fp = fetch --prune
	cb = checkout -b
	st = status -s
	last = log -1 HEAD
	ls = log --oneline
	lg = log --oneline --decorate --graph --all
	lag = log --decorate --graph --all
	db = branch -d
	mg = merge
	tree = log --graph --pretty=format:"%C(auto)%d" --all --simplify-by-decoration
```

- [ ] **Step 3: Replace `config/core/git/ignore` placeholder**

Replace the Task 4 placeholder with this exact expanded content:

```gitignore
# Local/private Claude Code and Codex files
**/.claude/settings.local.json
**/.codex/config.local.toml

# Environment and secret-bearing local files
.env
.env.*
*.local
*.local.*
*.secret
*.secrets

# OS/editor noise
.DS_Store
*.swp
*.swo
```

- [ ] **Step 4: Replace `.gitignore`**

Write this exact content:

```gitignore
# Private/local configuration
.env
.env.*
*.local
*.local.*
*.secret
*.secrets
.claude/settings.local.json
.codex/config.local.toml
config/core/shell/local.sh
config/core/shell/*.local.sh
config/core/fish/local.fish
config/core/claude/settings.local.json
config/core/codex/config.local.toml
config/macos/shell/local.sh

# Build/cache outputs
build/
*.o
*.out

# OS/editor noise
.DS_Store
*.swp
*.swo
```

- [ ] **Step 5: Harden patterns and scan error handling in `scripts/audit-secrets.sh`**

Update the secret scan to keep the existing non-assignment key/material, VPN, and SSH-key filename tokens while detecting assignment-style names containing case-compatible forms of token, password, passwd, secret, and API key, including camelCase names. Require a non-empty value after assignment markers so empty/template examples are not flagged.

Keep the existing `exclude_pathspecs` for examples so example files can show variable names without failing the audit.

Update both `git grep` scans so exit code `1` prints the relevant `ok:` message, while any exit code greater than `1` prints an `audit error:` message to stderr and exits with that nonzero code.

- [ ] **Step 6: Run Git config syntax check**

Run:

```bash
git config --file dev-env-bootstrap/config/core/git/config --list >/dev/null
```

Expected: command exits with status `0`.

- [ ] **Step 7: Run audit**

Run:

```bash
dev-env-bootstrap/scripts/audit-secrets.sh
```

Expected: command exits with status `0` and output ends with `audit passed`. If the spec file is flagged for historical examples, either remove the example from the spec or add a narrow pathspec exclusion for `docs/superpowers/specs/*.md` only after confirming no real secret is present.

- [ ] **Step 8: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add config/core/git/config config/core/git/ignore .gitignore scripts/audit-secrets.sh
git -C dev-env-bootstrap commit -m "feat: harden git defaults and audit"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 6: AI Tool Shared Configuration

**Files:**
- Modify: `config/core/claude/settings.json`
- Modify: `config/core/claude/settings.local.example.json`
- Expand existing placeholder: `config/core/claude/statusline.sh`
- Modify: `config/core/codex/config.toml`
- Modify: `config/core/codex/config.local.example.toml`

- [ ] **Step 1: Verify status line placeholder exists before expansion**

Run:

```bash
test -f dev-env-bootstrap/config/core/claude/statusline.sh
bash -n dev-env-bootstrap/config/core/claude/statusline.sh
```

Expected: both commands exit with status `0` because Task 4 created a minimal executable placeholder to keep managed links valid before this task expands it.

- [ ] **Step 2: Replace `config/core/claude/settings.json`**

Write this exact content:

```json
{
  "editorMode": "vim",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "playground@claude-plugins-official": true
  }
}
```

- [ ] **Step 3: Replace `config/core/claude/settings.local.example.json`**

Write this exact content:

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "keep-real-token-in-settings.local.json",
    "ANTHROPIC_BASE_URL": "https://example.invalid",
    "API_TIMEOUT_MS": "600000"
  },
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {},
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

- [ ] **Step 4: Replace `config/core/claude/statusline.sh` placeholder**

Replace the Task 4 placeholder with this exact expanded status line content:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

cwd="${PWD/#${HOME}/~}"
branch=""

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch_name="$(git branch --show-current 2>/dev/null || true)"
  if [[ -n "${branch_name}" ]]; then
    branch=" ${branch_name}"
  fi
fi

printf 'claude %s%s\n' "${cwd}" "${branch}"
```

- [ ] **Step 5: Make status line executable**

Run:

```bash
chmod +x dev-env-bootstrap/config/core/claude/statusline.sh
```

Expected: command exits with status `0`.

- [ ] **Step 6: Replace `config/core/codex/config.toml`**

Write this exact content:

```toml
# Shared Codex defaults. Keep providers, tokens, private paths, and trusted projects local.

approval_policy = "on-request"
sandbox_mode = "read-only"
model_reasoning_effort = "medium"
plan_mode_reasoning_effort = "high"
model_verbosity = "medium"
project_doc_fallback_filenames = ["CLAUDE.md", "GEMINI.md", "AGENTS.md"]

[features]
enable_request_compression = true
multi_agent = true
hooks = true

[history]
persistence = "save-all"
max_bytes = 25000000

[tui]
notifications = ["agent-turn-complete", "approval-requested"]
notification_method = "auto"
animations = true
show_tooltips = true
alternate_screen = "auto"

[shell_environment_policy]
inherit = "all"
ignore_default_excludes = false
exclude = [
  "*_TOKEN",
  "*_API_KEY",
  "*_SECRET",
  "*_PASSWORD",
  "*_PASSWD",
  "ANTHROPIC_*",
  "AWS_*",
  "AZURE_*",
  "DATABASE_URL",
  "GCP_*",
  "GEMINI_*",
  "GH_TOKEN",
  "GITHUB_TOKEN",
  "GOOGLE_*",
  "HF_TOKEN",
  "HUGGINGFACE_*",
  "NPM_TOKEN",
  "OPENAI_API_KEY",
  "OPENROUTER_*",
  "PYPI_*",
  "SLACK_*",
  "WANDB_*",
]
set = {}
include_only = []
experimental_use_profile = false

[sandbox_workspace_write]
writable_roots = []
network_access = false
exclude_tmpdir_env_var = false
exclude_slash_tmp = false

[profiles.fast]
approval_policy = "on-request"
sandbox_mode = "read-only"
model_reasoning_effort = "low"
plan_mode_reasoning_effort = "medium"
model_verbosity = "low"
web_search = "cached"

[profiles.build]
approval_policy = "never"
sandbox_mode = "workspace-write"
model_reasoning_effort = "medium"
plan_mode_reasoning_effort = "high"
model_verbosity = "medium"
web_search = "cached"

[profiles.auto]
approval_policy = "never"
sandbox_mode = "workspace-write"
model_reasoning_effort = "high"
plan_mode_reasoning_effort = "high"
model_verbosity = "medium"
web_search = "live"
```

- [ ] **Step 7: Replace `config/core/codex/config.local.example.toml`**

Write this exact content:

```toml
# Copy machine-specific Codex settings to ~/.codex/config.local.toml if your Codex setup supports it.
# Do not commit API keys, local model endpoints, private paths, or work-only settings.

# model_provider = "LocalProvider"
# model = "example-model"
# file_opener = "vscode"

# [model_providers.LocalProvider]
# name = "LocalProvider"
# base_url = "https://local-provider.example.invalid"
# wire_api = "responses"
# requires_openai_auth = true

# [projects."/path/to/private/project"]
# trust_level = "trusted"

# [tui]
# notify = ["/path/to/private/notify-script"]
```

- [ ] **Step 8: Validate JSON, TOML, and shell syntax**

Run:

```bash
python3 -m json.tool dev-env-bootstrap/config/core/claude/settings.json >/dev/null
python3 -m json.tool dev-env-bootstrap/config/core/claude/settings.local.example.json >/dev/null
python3 - <<'PY'
import tomllib
from pathlib import Path
for path in [
    Path('dev-env-bootstrap/config/core/codex/config.toml'),
    Path('dev-env-bootstrap/config/core/codex/config.local.example.toml'),
]:
    tomllib.loads(path.read_text())
PY
bash -n dev-env-bootstrap/config/core/claude/statusline.sh
```

Expected: all commands exit with status `0`.

- [ ] **Step 9: Run status line smoke test**

Run:

```bash
( cd dev-env-bootstrap && config/core/claude/statusline.sh )
```

Expected: command exits with status `0`; output starts with `claude ` and includes the repository path.

- [ ] **Step 11: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add config/core/claude/settings.json config/core/claude/settings.local.example.json config/core/claude/statusline.sh config/core/codex/config.toml config/core/codex/config.local.example.toml
git -C dev-env-bootstrap commit -m "feat: add shared ai tool defaults"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 7: Terminal App Config Refinement

**Files:**
- Modify: `config/core/tmux/tmux.conf`
- Modify: `config/core/yazi/keymap.toml`
- Modify: `config/optional/vim/vimrc`

- [ ] **Step 1: Verify current tmux config parses before editing**

Run:

```bash
tmux -f dev-env-bootstrap/config/core/tmux/tmux.conf start-server \; source-file dev-env-bootstrap/config/core/tmux/tmux.conf \; kill-server
```

Expected: command exits with status `0`. If `tmux` is unavailable, record that parser verification could not run and continue only after reviewing syntax manually.

- [ ] **Step 2: In `config/core/tmux/tmux.conf`, ensure guarded continuum settings and distinct copy-mode bindings**

Ensure the existing `update-environment` continuation keeps a trailing space before line continuation so `XDG_DATA_HOME` and `XDG_MENU_PREFIX` remain separate entries:

```tmux
XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME \
XDG_MENU_PREFIX XDG_RUNTIME_DIR XDG_SESSION_CLASS \
```

Ensure guarded continuum settings remain after the existing tmux-continuum plugin declaration:

```tmux
set -g @continuum-save-interval '5'
set -g @continuum-restore 'enabled'
```

Ensure copy-mode vi movement and search keys are distinct:

```tmux
bind -T copy-mode-vi h send-keys -X cursor-left
bind -T copy-mode-vi j send-keys -X cursor-down
bind -T copy-mode-vi k send-keys -X cursor-up
bind -T copy-mode-vi l send-keys -X cursor-right
bind -T copy-mode-vi = send-keys -X search-again
bind -T copy-mode-vi ? send-keys -X search-reverse
```

Do not add unguarded `run '~/.tmux/plugins/tpm/tpm'`; keep the existing guarded `if-shell` plugin loading at the bottom.

- [ ] **Step 3: In `config/core/yazi/keymap.toml`, keep cross-platform navigation only**

Ensure the file has this exact content:

```toml
[manager]
prepend_keymap = [
  { on = [ "g", "h" ], run = "cd ~", desc = "Go home" },
  { on = [ "g", "c" ], run = "cd ~/.config", desc = "Go config" },
  { on = [ "g", "d" ], run = "cd ~/Downloads", desc = "Go downloads" },
]
```

- [ ] **Step 4: Replace `config/optional/vim/vimrc` with focused config**

Write this exact content:

```vim
let mapleader=" "

syntax on
filetype indent on

set expandtab
set softtabstop=4
set shiftwidth=4
set tabstop=4
set autoindent
set smartindent
set number
set relativenumber
set showcmd
set cursorline
set scrolloff=5
set ruler
set hlsearch
set incsearch
set ignorecase
set smartcase
set wrap
set wildmenu

nnoremap s <Nop>
nnoremap S :w<CR>
nnoremap Q :q<CR>
nnoremap R :source $MYVIMRC<CR>

nnoremap <LEADER><CR> :nohlsearch<CR>
nnoremap sj :set splitbelow<CR>:split<CR>
nnoremap sk :set nosplitright<CR>:split<CR>
nnoremap sl :set splitright<CR>:vsplit<CR>
nnoremap sh :set nosplitright<CR>:vsplit<CR>

nnoremap <LEADER>l <C-w>l
nnoremap <LEADER>j <C-w>j
nnoremap <LEADER>k <C-w>k
nnoremap <LEADER>h <C-w>h

nnoremap <up> :res +5<CR>
nnoremap <down> :res -5<CR>
nnoremap <left> :vertical resize-5<CR>
nnoremap <right> :vertical resize+5<CR>

nnoremap <LEADER>q :q<CR>

function! AddComment()
    let line = getline('.')
    call setline('.', '// ' . line)
endfunction

nnoremap <C-/> :call AddComment()<CR>
nnoremap <C-_> :call AddComment()<CR>
```

- [ ] **Step 5: Run parser checks**

Run:

```bash
tmux -f dev-env-bootstrap/config/core/tmux/tmux.conf start-server \; source-file dev-env-bootstrap/config/core/tmux/tmux.conf \; kill-server
python3 - <<'PY'
import tomllib
from pathlib import Path
tomllib.loads(Path('dev-env-bootstrap/config/core/yazi/keymap.toml').read_text())
PY
vim -Nu dev-env-bootstrap/config/optional/vim/vimrc -n -es -c 'q'
```

Expected: all available commands exit with status `0`. If `tmux` or `vim` is unavailable, record the missing tool and verify the remaining commands.

- [ ] **Step 6: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add config/core/tmux/tmux.conf config/core/yazi/keymap.toml config/optional/vim/vimrc
git -C dev-env-bootstrap commit -m "refactor: polish terminal app defaults"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 8: Documentation Update

**Files:**
- Modify: `README.md`
- Modify: `README.zh-CN.md`

- [ ] **Step 1: Check docs do not mention new commands yet**

Run:

```bash
grep -n "bootstrap.sh ai" dev-env-bootstrap/README.md
```

Expected before implementation: command exits with status `1`.

- [ ] **Step 2: Update `README.md` core layer section**

In `README.md`, ensure the core layer list includes these bullets:

```markdown
- cross-platform shell snippets for Bash/Zsh/Fish under `~/.config/my-linux-config/`
- tmux config: `config/core/tmux/tmux.conf` -> `~/.tmux.conf`
- Git defaults and shared ignore rules under `~/.config/git/`
- Yazi config under `~/.config/yazi/`
- Claude Code shared settings, status line template, and local examples under `~/.claude/`
- Codex shared profiles and local examples under `~/.codex/`
- `ssh-socks-proxy` under `~/.local/bin/`
```

- [ ] **Step 3: Add English macOS section**

Add this exact section after the core layer section:

```markdown
## macOS reproducibility layer

The shared core works on Linux and macOS. macOS-specific toolchain setup is opt-in:

```bash
./bootstrap.sh macos
./bootstrap.sh interactive
```

The macOS menu can install or configure groups such as Homebrew basics, shells, editors, Java, LLVM/OpenMP, Ruby, dotnet, conda/mamba, and AI-tool notes. You can select none of them and still keep the shared core configuration.
```

- [ ] **Step 4: Add English AI command docs**

In the commands block, add:

```markdown
./bootstrap.sh ai                  # link Claude Code and Codex shared config only
./bootstrap.sh macos               # link macOS config and run macOS setup menu
./bootstrap.sh interactive         # choose optional setup groups interactively
```

- [ ] **Step 5: Update `README.zh-CN.md` with equivalent Chinese text**

Add this exact section near the core/optional layer description:

```markdown
## macOS 可复现层

共享 core 层同时服务 Linux 和 macOS。macOS 专属的工具链初始化是可选项：

```bash
./bootstrap.sh macos
./bootstrap.sh interactive
```

macOS 菜单会列出 Homebrew 基础工具、shell、编辑器、Java、LLVM/OpenMP、Ruby、dotnet、conda/mamba、AI 工具提示等分组。你可以手动选择需要安装的分组，也可以一个都不选，只使用共享 core 配置。
```

Add these commands to the Chinese commands block:

```markdown
./bootstrap.sh ai                  # 只链接 Claude Code 和 Codex 的共享配置
./bootstrap.sh macos               # 链接 macOS 配置并进入 macOS 设置菜单
./bootstrap.sh interactive         # 交互式选择可选配置分组
```

- [ ] **Step 6: Check docs contain new commands**

Run:

```bash
grep -n "bootstrap.sh ai" dev-env-bootstrap/README.md
grep -n "bootstrap.sh ai" dev-env-bootstrap/README.zh-CN.md
```

Expected: both commands exit with status `0`.

- [ ] **Step 7: Commit checkpoint only if commits are authorized**

If commits are authorized, run:

```bash
git -C dev-env-bootstrap add README.md README.zh-CN.md
git -C dev-env-bootstrap commit -m "docs: document layered setup workflow"
```

Expected: commit succeeds. If commits are not authorized, skip this step.

---

### Task 9: Final Verification

**Files:**
- No planned source modifications unless verification finds an implementation error.

- [ ] **Step 1: Run shell syntax checks**

Run:

```bash
find dev-env-bootstrap -name '*.sh' -not -path '*/config/optional/legacy/*' -print0 | xargs -0 -n1 bash -n
```

Expected: command exits with status `0`.

- [ ] **Step 2: Run JSON/TOML validation**

Run:

```bash
python3 - <<'PY'
import json
import tomllib
from pathlib import Path
for path in Path('dev-env-bootstrap').rglob('*.json'):
    json.loads(path.read_text())
for path in Path('dev-env-bootstrap').rglob('*.toml'):
    tomllib.loads(path.read_text())
PY
```

Expected: command exits with status `0`.

- [ ] **Step 3: Run installer dry-runs**

Run:

```bash
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run-ai
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh doctor
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh ai
```

Expected: all commands exit with status `0`.

- [ ] **Step 4: Run macOS command verification**

On macOS, run:

```bash
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run-macos
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh macos
DRY_RUN=1 dev-env-bootstrap/scripts/macos.sh list
```

Expected: all commands exit with status `0`; output lists macOS setup groups and does not install packages.

On Linux, run:

```bash
DRY_RUN=1 dev-env-bootstrap/install.sh dry-run-macos
DRY_RUN=1 dev-env-bootstrap/bootstrap.sh macos
```

Expected: both commands exit with status `2`; output explains the command is Darwin-only.

- [ ] **Step 5: Run audit**

Run:

```bash
dev-env-bootstrap/scripts/audit-secrets.sh
```

Expected: command exits with status `0`; output ends with `audit passed`.

- [ ] **Step 6: Inspect git diff for private data**

Run:

```bash
git -C dev-env-bootstrap diff -- . ':(exclude)docs/superpowers/plans/2026-05-17-macos-linux-config-sync.md'
```

Expected: no real tokens, private SSH key names, user-specific home paths, private project paths, or local model endpoints appear in the diff. Exclude `scripts/audit-secrets.sh` from private-value grep checks because it must contain audit detection patterns.

- [ ] **Step 7: Report final state**

Run:

```bash
git -C dev-env-bootstrap status --short
```

Expected: output shows only intended modified/new files. If commits were authorized and performed, working tree should be clean or contain only intentionally uncommitted docs.

- [ ] **Step 8: Final commit only if commits are authorized**

If commits are authorized and previous task commits were skipped, run:

```bash
git -C dev-env-bootstrap add .gitignore README.md README.zh-CN.md bootstrap.sh install.sh scripts/audit-secrets.sh scripts/macos.sh config/core config/macos docs/superpowers/specs/2026-05-17-macos-linux-config-sync-design.md docs/superpowers/plans/2026-05-17-macos-linux-config-sync.md
git -C dev-env-bootstrap commit -m "feat: sync safe macos linux dev environment"
```

Expected: commit succeeds. If commits are not authorized, skip this step and leave changes uncommitted for review.
