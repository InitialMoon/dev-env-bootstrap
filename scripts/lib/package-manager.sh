#!/usr/bin/env bash

package_manager() {
  if has brew; then
    printf '%s\n' brew
  elif has apt-get; then
    printf '%s\n' apt
  elif has dnf; then
    printf '%s\n' dnf
  elif has pacman; then
    printf '%s\n' pacman
  elif has yum; then
    printf '%s\n' yum
  else
    printf '%s\n' none
  fi
}

package_manager_install_command() {
  local pm="$1"
  shift
  case "${pm}" in
    brew) printf 'brew install';;
    apt) printf 'sudo apt-get update && sudo apt-get install -y';;
    dnf) printf 'sudo dnf install -y';;
    yum) printf 'sudo yum install -y';;
    pacman) printf 'sudo pacman -S --needed --noconfirm';;
    *) printf 'manual install';;
  esac
  printf ' %q' "$@"
  printf '\n'
}

install_packages() {
  local pm="$1"
  shift
  [[ $# -gt 0 ]] || return 0

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    package_manager_install_command "${pm}" "$@"
    return 0
  fi

  case "${pm}" in
    brew)
      brew install "$@"
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "$@"
      ;;
    dnf)
      sudo dnf install -y "$@"
      ;;
    yum)
      sudo yum install -y "$@"
      ;;
    pacman)
      sudo pacman -S --needed --noconfirm "$@"
      ;;
    *)
      warn "no supported package manager found; install manually: $*"
      return 1
      ;;
  esac
}
