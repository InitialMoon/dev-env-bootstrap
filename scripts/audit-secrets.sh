#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT_DIR}"

exclude_pathspecs=(
  ':(exclude)scripts/audit-secrets.sh'
  ':(exclude)config/optional/oh-my-posh/themes'
  ':(exclude)config/optional/ranger/source'
  ':(exclude)config/optional/legacy/profile.full'
  ':(exclude)config/core/**/*.example'
  ':(exclude)config/core/**/*.example.*'
  ':(exclude)docs/superpowers/specs'
)

secret_pattern="(PRIVATE KEY|BEGIN [A-Z ]*KEY|[A-Za-z0-9_]*([Tt][Oo][Kk][Ee][Nn]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|[Pp][Aa][Ss][Ss][Ww][Dd]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Aa][Pp][Ii][_-]?[Kk][Ee][Yy])[A-Za-z0-9_]*[[:space:]]*=[[:space:]]*['\"]?[^'\"[:space:]]+|\.ovpn|id_rsa|id_ed25519)"
exposure_pattern='(/Users/[^/[:space:]]+|/home/(moon|yingqi)|/root/|Documents/PhD|\.ssh/|localhost:[0-9]+|127\.0\.0\.1:[0-9]+|DDST|ddst|DDST-Server|Vmess|shadowsocks|tun0|icanhazip)'

status=0

scan_pattern() {
  local label="$1"
  local pattern="$2"
  local finding_status="$3"
  local file rc found scan_rc

  found=0
  scan_rc=0

  echo "== ${label} =="
  while IFS= read -r -d '' file; do
    if [[ ! -f "${file}" ]]; then
      continue
    fi

    set +e
    grep -I -nE -- "${pattern}" "${file}" | while IFS= read -r line; do
      printf '%s:%s\n' "${file}" "${line}"
    done
    rc=$?
    set -e

    case "${rc}" in
      0)
        found=1
        ;;
      1)
        ;;
      *)
        echo "audit error: grep scan failed for ${file} with exit ${rc}" >&2
        scan_rc="${rc}"
        ;;
    esac
  done < <(git ls-files -z --cached --others --exclude-standard -- . "${exclude_pathspecs[@]}")

  if [[ ${scan_rc} -ne 0 ]]; then
    exit "${scan_rc}"
  fi

  if [[ ${found} -eq 1 ]]; then
    status="${finding_status}"
  else
    echo "ok: no $(printf '%s' "${label}" | tr '[:upper:]' '[:lower:]') found"
  fi
}

scan_pattern "Secret-like patterns" "${secret_pattern}" 1

echo
scan_pattern "Operational exposure patterns" "${exposure_pattern}" 2

echo
if [[ ${status} -eq 0 ]]; then
  echo "audit passed"
else
  echo "audit found findings; review whether they are acceptable before publishing"
fi

exit "${status}"
