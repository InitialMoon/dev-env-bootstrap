#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
LEGACY="${ROOT_DIR}/config/optional/zsh/install_config_zsh.legacy.sh"

if [[ ! -f "${LEGACY}" ]]; then
  echo "missing legacy zsh installer: ${LEGACY}" >&2
  exit 1
fi

cat <<EOF
The old zsh installer is preserved at:
  ${LEGACY}

It installs zsh, oh-my-zsh, plugins, autojump, and powerlevel10k, and it may modify ~/.zshrc interactively.
Review it before running:
  bash ${LEGACY}
EOF
