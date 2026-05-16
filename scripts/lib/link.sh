#!/usr/bin/env bash

safe_link() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "${src}" ]]; then
    warn "missing source: ${src}"
    return 1
  fi

  if [[ -L "${dest}" ]]; then
    local current
    current="$(readlink "${dest}")"
    if [[ "${current}" == "${src}" ]]; then
      say "ok: ${dest} -> ${src}"
      return 0
    fi
    warn "skip existing symlink: ${dest} -> ${current}"
    return 0
  fi

  if [[ -e "${dest}" ]]; then
    warn "skip existing path: ${dest}"
    return 0
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    say "would link: ${dest} -> ${src}"
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  ln -s "${src}" "${dest}"
  say "linked: ${dest} -> ${src}"
}
