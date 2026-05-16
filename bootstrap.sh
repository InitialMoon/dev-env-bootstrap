#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}" && pwd -P)"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/package-manager.sh"
source "${ROOT_DIR}/scripts/lib/tool-map.sh"

CORE_TOOLS=(git curl ssh tmux yazi claude codex)
OPTIONAL_TOOLS=(fish zsh nvim oh-my-posh ranger)
ASSUME_YES="${ASSUME_YES:-0}"
DRY_RUN="${DRY_RUN:-0}"

usage() {
  cat <<EOF
Usage: $0 <command> [module...]

Commands:
  doctor              Check platform, package manager, and tool availability
  core                Install/check core tools, then run ./install.sh link
  install             Alias for core
  link                Run ./install.sh link only
  optional            Show optional modules
  optional MODULE...  Install/configure optional modules: ${OPTIONAL_TOOLS[*]}
  all                 Run core, then optional fish nvim oh-my-posh

Environment:
  ASSUME_YES=1        Skip package installation confirmation
  DRY_RUN=1           Print install/link actions without applying them where supported

Core tools: ${CORE_TOOLS[*]}
EOF
}

missing_tools() {
  local tool
  for tool in "$@"; do
    if ! has "${tool}"; then
      printf '%s\n' "${tool}"
    fi
  done
}

confirm_install() {
  local packages="$1"
  if [[ -z "${packages}" ]]; then
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" || "${ASSUME_YES}" == "1" ]]; then
    return 0
  fi
  say "packages to install: ${packages}"
  read -r -p "Proceed with package installation? [y/N] " reply
  [[ "${reply}" == "y" || "${reply}" == "Y" ]]
}

install_missing_tools() {
  local pm="$1"
  shift
  local tool package
  local missing=()
  local packages=()

  for tool in "$@"; do
    if ! has "${tool}"; then
      missing+=("${tool}")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  for tool in "${missing[@]}"; do
    package="$(package_for_tool "${tool}" "${pm}")"
    if [[ -n "${package}" ]]; then
      packages+=("${package}")
    else
      warn "no automatic package mapping for missing tool: ${tool}"
    fi
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "missing tools require manual installation: ${missing[*]}"
    return 0
  fi

  if confirm_install "${packages[*]}"; then
    install_packages "${pm}" "${packages[@]}"
  else
    warn "package installation skipped"
  fi
}

cmd_doctor() {
  local platform pm missing
  platform="$(platform_name)"
  pm="$(package_manager)"

  say "platform: ${platform}"
  say "package manager: ${pm}"

  say "core tools:"
  for tool in "${CORE_TOOLS[@]}"; do
    if has "${tool}"; then
      say "  ok: ${tool} ($(command -v "${tool}"))"
    else
      say "  missing: ${tool}"
    fi
  done

  say "optional tools:"
  for tool in "${OPTIONAL_TOOLS[@]}"; do
    if has "${tool}"; then
      say "  ok: ${tool} ($(command -v "${tool}"))"
    else
      say "  missing: ${tool}"
    fi
  done

  if [[ "${pm}" == "none" ]]; then
    warn "no supported package manager detected"
  fi

  if [[ "${platform}" == "linux" && "${pm}" == "apt" ]]; then
    say "note: yazi and oh-my-posh may need snap, cargo, Homebrew on Linux, or upstream installers on older Ubuntu."
  fi

  missing="$(missing_tools "${CORE_TOOLS[@]}" || true)"
  if [[ -z "${missing}" ]]; then
    say "core environment looks ready"
  else
    say "missing core tools:"
    printf '%s\n' "${missing}"
  fi
}

run_install_link() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    "${ROOT_DIR}/install.sh" dry-run
  else
    "${ROOT_DIR}/install.sh" link
  fi
}

cmd_core() {
  local pm
  pm="$(package_manager)"
  install_missing_tools "${pm}" "${CORE_TOOLS[@]}"
  run_install_link
  cmd_doctor
}

run_optional_module() {
  local module="$1"
  local pm="$2"

  case "${module}" in
    fish)
      install_missing_tools "${pm}" fish
      "${ROOT_DIR}/scripts/optional/fish.sh"
      ;;
    zsh)
      install_missing_tools "${pm}" zsh
      "${ROOT_DIR}/scripts/optional/zsh.sh"
      ;;
    nvim|neovim)
      install_missing_tools "${pm}" nvim
      "${ROOT_DIR}/scripts/optional/nvim.sh"
      ;;
    oh-my-posh|omp)
      install_missing_tools "${pm}" unzip
      "${ROOT_DIR}/scripts/optional/oh-my-posh.sh"
      ;;
    ranger)
      install_missing_tools "${pm}" ranger
      "${ROOT_DIR}/scripts/optional/ranger.sh"
      ;;
    *)
      warn "unknown optional module: ${module}"
      return 1
      ;;
  esac
}

cmd_optional() {
  local pm module
  pm="$(package_manager)"

  if [[ $# -eq 0 ]]; then
    cat <<EOF
Optional modules:

  fish        Link old fish and OMF config after installing fish if needed
  zsh         Show preserved legacy zsh/oh-my-zsh installer after installing zsh if needed
  nvim        Link LazyVim-based Neovim config after installing neovim if needed
  oh-my-posh  Link old Oh My Posh themes after installing oh-my-posh when package mapping exists
  ranger      Install ranger package when available and show vendored source note

Examples:
  ./bootstrap.sh optional nvim
  ./bootstrap.sh optional fish nvim oh-my-posh
  ASSUME_YES=1 ./bootstrap.sh all
  DRY_RUN=1 ./bootstrap.sh all
EOF
    return 0
  fi

  for module in "$@"; do
    run_optional_module "${module}" "${pm}"
  done
}

cmd_all() {
  cmd_core
  cmd_optional fish nvim oh-my-posh
}

cmd="${1:-doctor}"
shift || true
case "${cmd}" in
  doctor)
    cmd_doctor
    ;;
  core|install)
    cmd_core
    ;;
  link)
    run_install_link
    ;;
  optional)
    cmd_optional "$@"
    ;;
  all)
    cmd_all
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    warn "unknown command: ${cmd}"
    usage >&2
    exit 2
    ;;
esac
