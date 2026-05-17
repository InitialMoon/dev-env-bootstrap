#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT_DIR}"

exclude_pathspecs=(
  ':(exclude)scripts/audit-secrets.sh'
  ':(exclude)config/optional/oh-my-posh/themes'
  ':(exclude)config/optional/ranger/source'
  ':(exclude)config/core/**/*.example'
  ':(exclude)config/core/**/*.example.*'
)

secret_pattern='(PRIVATE KEY|BEGIN [A-Z ]*KEY|OPENAI_API_KEY|ANTHROPIC_API_KEY|api[_-]?key[[:space:]]*=|token[[:space:]]*=|password[[:space:]]*=|passwd[[:space:]]*=|\.ovpn|id_rsa|id_ed25519)'
exposure_pattern='(DDST|ddst|DDST-Server|/home/(moon|yingqi)|/root/|ssh-keygen|Vmess|shadowsocks|tun0|icanhazip)'

status=0

echo "== Secret-like patterns =="
if git grep -nE "${secret_pattern}" -- . "${exclude_pathspecs[@]}"; then
  status=1
else
  echo "ok: no secret-like patterns found"
fi

echo
echo "== Operational exposure patterns =="
if git grep -nE "${exposure_pattern}" -- . "${exclude_pathspecs[@]}"; then
  status=2
else
  echo "ok: no operational exposure patterns found"
fi

echo
if [[ ${status} -eq 0 ]]; then
  echo "audit passed"
else
  echo "audit found findings; review whether they are acceptable before publishing"
fi

exit "${status}"
