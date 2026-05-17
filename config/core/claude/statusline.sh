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
