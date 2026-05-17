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
    conda) printf '%s\n' miniforge mamba ;;
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
