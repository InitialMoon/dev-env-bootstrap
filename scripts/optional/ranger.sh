#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

cat <<EOF
Ranger source is preserved at:
  ${ROOT_DIR}/config/optional/ranger/source

This repository no longer runs 'sudo make install' by default. Prefer your system package manager:
  ./bootstrap.sh optional ranger

If you intentionally want the vendored source install, review it first:
  cd ${ROOT_DIR}/config/optional/ranger/source && sudo make install
EOF
