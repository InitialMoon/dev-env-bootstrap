#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/link.sh"

safe_link "${ROOT_DIR}/config/optional/fish/config/config.fish" "${XDG_CONFIG_HOME}/fish/config.fish"
safe_link "${ROOT_DIR}/config/optional/fish/config/fish_variables" "${XDG_CONFIG_HOME}/fish/fish_variables"
safe_link "${ROOT_DIR}/config/optional/fish/config/conf.d/omf.fish" "${XDG_CONFIG_HOME}/fish/conf.d/omf.fish"
safe_link "${ROOT_DIR}/config/optional/fish/omf" "${XDG_CONFIG_HOME}/omf"
