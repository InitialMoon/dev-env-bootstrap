#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/link.sh"

safe_link "${ROOT_DIR}/config/optional/nvim/config" "${XDG_CONFIG_HOME}/nvim"
