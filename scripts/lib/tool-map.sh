#!/usr/bin/env bash

package_for_tool() {
  local tool="$1"
  local pm="$2"

  case "${tool}:${pm}" in
    git:*) printf '%s\n' git ;;
    curl:*) printf '%s\n' curl ;;
    ssh:apt|ssh:dnf|ssh:yum) printf '%s\n' openssh-client ;;
    ssh:pacman) printf '%s\n' openssh ;;
    ssh:brew) printf '%s\n' openssh ;;
    tmux:*) printf '%s\n' tmux ;;
    yazi:brew) printf '%s\n' yazi ;;
    yazi:pacman) printf '%s\n' yazi ;;
    yazi:apt|yazi:dnf|yazi:yum) printf '%s\n' '' ;;
    claude:*|codex:*) printf '%s\n' '' ;;
    fish:*) printf '%s\n' fish ;;
    zsh:*) printf '%s\n' zsh ;;
    nvim:brew) printf '%s\n' neovim ;;
    nvim:*) printf '%s\n' neovim ;;
    oh-my-posh:brew) printf '%s\n' oh-my-posh ;;
    oh-my-posh:*) printf '%s\n' '' ;;
    ranger:*) printf '%s\n' ranger ;;
    unzip:*) printf '%s\n' unzip ;;
    *) printf '%s\n' "${tool}" ;;
  esac
}
