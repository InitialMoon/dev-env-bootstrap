#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/link.sh"

install_oh_my_posh_upstream() {
  if has oh-my-posh; then
    return 0
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    say "would install oh-my-posh via upstream installer into ${HOME}/.local/bin"
    return 0
  fi

  if [[ "${ASSUME_YES:-0}" != "1" ]]; then
    read -r -p "Install oh-my-posh from https://ohmyposh.dev/install.sh into ~/.local/bin? [y/N] " reply
    [[ "${reply}" == "y" || "${reply}" == "Y" ]] || {
      warn "oh-my-posh upstream install skipped"
      return 0
    }
  fi

  mkdir -p "${HOME}/.local/bin"
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "${HOME}/.local/bin"
}

install_oh_my_posh_upstream
safe_link "${ROOT_DIR}/config/optional/oh-my-posh/themes" "${HOME}/.omp_themes"
