#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$(cd "${SCRIPT_DIR}" && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
MODE="dry-run"
PLATFORM="unknown"

SHELL_BLOCK_BEGIN="# >>> my-linux-config shell >>>"
SHELL_BLOCK_END="# <<< my-linux-config shell <<<"
GIT_BLOCK_BEGIN="# >>> my-linux-config git >>>"
GIT_BLOCK_END="# <<< my-linux-config git <<<"

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  dry-run  Show what would be linked or updated
  link     Link core configuration and update shell/Git include blocks
  unlink   Remove links and blocks managed by this repository
  status   Show current managed configuration status
  doctor   Check basic tool availability and platform notes

The installer is conservative: it never overwrites existing user files.
EOF
}

set_platform() {
  case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux) PLATFORM="linux" ;;
    *) PLATFORM="unknown" ;;
  esac
}

is_mutating() {
  [[ "${MODE}" == "link" || "${MODE}" == "unlink" ]]
}

say() {
  printf '%s\n' "$*"
}

warn() {
  printf 'warn: %s\n' "$*" >&2
}

make_temp() {
  mktemp "${TMPDIR:-/tmp}/my-linux-config.XXXXXX"
}

ensure_dir() {
  local dir="$1"
  if [[ -d "${dir}" ]]; then
    return 0
  fi
  if [[ -e "${dir}" ]]; then
    warn "skip non-directory parent: ${dir}"
    return 1
  fi
  if is_mutating; then
    mkdir -p "${dir}"
    say "created directory: ${dir}"
  else
    say "would create directory: ${dir}"
  fi
}

link_file() {
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

  ensure_dir "$(dirname "${dest}")" || return 0
  if is_mutating; then
    ln -s "${src}" "${dest}"
    say "linked: ${dest} -> ${src}"
  else
    say "would link: ${dest} -> ${src}"
  fi
}

unlink_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -L "${dest}" ]]; then
    say "skip: ${dest} is not a managed symlink"
    return 0
  fi

  local current
  current="$(readlink "${dest}")"
  if [[ "${current}" != "${src}" ]]; then
    warn "skip symlink not owned by this repo: ${dest} -> ${current}"
    return 0
  fi

  if is_mutating; then
    rm "${dest}"
    say "unlinked: ${dest}"
  else
    say "would unlink: ${dest}"
  fi
}

replace_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local body="$4"
  local tmp
  tmp="$(make_temp)"
  awk -v begin="${begin}" -v end="${end}" -v body="${body}" '
    BEGIN { body_count = split(body, body_lines, "\n"); skipping = 0 }
    $0 == begin {
      print begin
      for (i = 1; i <= body_count; i++) print body_lines[i]
      print end
      skipping = 1
      next
    }
    skipping && $0 == end { skipping = 0; next }
    skipping { next }
    { print }
  ' "${file}" >"${tmp}"
  if cmp -s "${tmp}" "${file}"; then
    rm "${tmp}"
    return 1
  fi
  mv "${tmp}" "${file}"
}

write_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local body="$4"

  if [[ -e "${file}" && ! -f "${file}" ]]; then
    warn "skip non-file target: ${file}"
    return 0
  fi

  if [[ -f "${file}" ]] && grep -Fqx "${begin}" "${file}"; then
    if ! grep -Fqx "${end}" "${file}"; then
      warn "skip incomplete managed block: ${file}"
      return 0
    fi
    if is_mutating; then
      if replace_block "${file}" "${begin}" "${end}" "${body}"; then
        say "updated block: ${file}"
      else
        say "ok: block in ${file}"
      fi
    else
      say "would update block: ${file}"
    fi
    return 0
  fi

  if is_mutating; then
    ensure_dir "$(dirname "${file}")" || return 0
    {
      [[ -s "${file}" ]] && printf '\n'
      printf '%s\n' "${begin}"
      printf '%s\n' "${body}"
      printf '%s\n' "${end}"
    } >>"${file}"
    say "added block: ${file}"
  else
    say "would add block: ${file}"
  fi
}

prepend_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local body="$4"

  if [[ -e "${file}" && ! -f "${file}" ]]; then
    warn "skip non-file target: ${file}"
    return 0
  fi

  local exists="no"
  if [[ -f "${file}" ]] && grep -Fqx "${begin}" "${file}"; then
    if ! grep -Fqx "${end}" "${file}"; then
      warn "skip incomplete managed block: ${file}"
      return 0
    fi
    exists="yes"
  fi

  if is_mutating; then
    ensure_dir "$(dirname "${file}")" || return 0
    local rest tmp
    rest="$(make_temp)"
    tmp="$(make_temp)"
    if [[ -s "${file}" ]]; then
      awk -v begin="${begin}" -v end="${end}" '
        $0 == begin { skipping = 1; next }
        skipping && $0 == end { skipping = 0; next }
        skipping { next }
        !started && $0 == "" { next }
        { started = 1; print }
      ' "${file}" >"${rest}"
    fi
    {
      printf '%s\n' "${begin}"
      printf '%s\n' "${body}"
      printf '%s\n' "${end}"
      if [[ -s "${rest}" ]]; then
        printf '\n'
        while IFS= read -r line || [[ -n "${line}" ]]; do
          printf '%s\n' "${line}"
        done <"${rest}"
      fi
    } >"${tmp}"
    rm "${rest}"
    if [[ -f "${file}" ]] && cmp -s "${tmp}" "${file}"; then
      rm "${tmp}"
      say "ok: block in ${file}"
    else
      mv "${tmp}" "${file}"
      if [[ "${exists}" == "yes" ]]; then
        say "moved block to top: ${file}"
      else
        say "added block: ${file}"
      fi
    fi
  elif [[ "${exists}" == "yes" ]]; then
    say "would move/update block: ${file}"
  else
    say "would add block: ${file}"
  fi
}

remove_block() {
  local file="$1"
  local begin="$2"
  local end="$3"

  if [[ ! -f "${file}" ]]; then
    say "skip missing block target: ${file}"
    return 0
  fi

  if ! grep -Fqx "${begin}" "${file}"; then
    say "skip unmanaged block target: ${file}"
    return 0
  fi

  if ! grep -Fqx "${end}" "${file}"; then
    warn "skip incomplete managed block: ${file}"
    return 0
  fi

  if is_mutating; then
    local tmp
    tmp="$(make_temp)"
    awk -v begin="${begin}" -v end="${end}" '
      $0 == begin { skipping = 1; next }
      skipping && $0 == end { skipping = 0; next }
      skipping { next }
      { print }
    ' "${file}" >"${tmp}"
    mv "${tmp}" "${file}"
    say "removed block: ${file}"
  else
    say "would remove block: ${file}"
  fi
}

check_path() {
  local src="$1"
  local dest="$2"

  if [[ -L "${dest}" ]]; then
    local current
    current="$(readlink "${dest}")"
    if [[ "${current}" == "${src}" ]]; then
      say "ok: ${dest} -> ${src}"
    else
      say "other symlink: ${dest} -> ${current}"
    fi
  elif [[ -e "${dest}" ]]; then
    say "existing unmanaged path: ${dest}"
  else
    say "missing: ${dest}"
  fi
}

managed_links() {
  cat <<EOF
${ROOT_DIR}/bin/ssh-socks-proxy|${HOME}/.local/bin/ssh-socks-proxy
${ROOT_DIR}/config/core/tmux/tmux.conf|${HOME}/.tmux.conf
${ROOT_DIR}/config/core/shell/common.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/common.sh
${ROOT_DIR}/config/core/shell/bash.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/bash.sh
${ROOT_DIR}/config/core/shell/zsh.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/zsh.sh
${ROOT_DIR}/config/core/shell/local.example.sh|${XDG_CONFIG_HOME}/my-linux-config/shell/local.example.sh
${ROOT_DIR}/config/core/git/config|${XDG_CONFIG_HOME}/my-linux-config/git/config
${ROOT_DIR}/config/core/git/local.example|${XDG_CONFIG_HOME}/my-linux-config/git/local.example
${ROOT_DIR}/config/core/yazi/yazi.toml|${XDG_CONFIG_HOME}/yazi/yazi.toml
${ROOT_DIR}/config/core/yazi/keymap.toml|${XDG_CONFIG_HOME}/yazi/keymap.toml
${ROOT_DIR}/config/core/claude/settings.json|${HOME}/.claude/settings.json
${ROOT_DIR}/config/core/claude/settings.local.example.json|${HOME}/.claude/settings.local.example.json
${ROOT_DIR}/config/core/claude/CLAUDE.md|${HOME}/.claude/CLAUDE.md
${ROOT_DIR}/config/core/codex/config.toml|${HOME}/.codex/config.toml
${ROOT_DIR}/config/core/codex/config.local.example.toml|${HOME}/.codex/config.local.example.toml
${ROOT_DIR}/config/core/codex/AGENTS.md|${HOME}/.codex/AGENTS.md
EOF
}

for_each_link() {
  local action="$1"
  local src dest
  while IFS='|' read -r src dest; do
    [[ -n "${src}" ]] || continue
    "${action}" "${src}" "${dest}"
  done < <(managed_links)
}

link_blocks() {
  local git_config_path="${XDG_CONFIG_HOME}/my-linux-config/git/config"
  write_block "${HOME}/.bashrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}" 'if [[ -r "${HOME}/.config/my-linux-config/shell/bash.sh" ]]; then
  source "${HOME}/.config/my-linux-config/shell/bash.sh"
fi'
  write_block "${HOME}/.zshrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}" 'if [[ -r "${HOME}/.config/my-linux-config/shell/zsh.sh" ]]; then
  source "${HOME}/.config/my-linux-config/shell/zsh.sh"
fi'
  prepend_block "${HOME}/.gitconfig" "${GIT_BLOCK_BEGIN}" "${GIT_BLOCK_END}" "[include]
	path = ${git_config_path}"
}

unlink_blocks() {
  remove_block "${HOME}/.bashrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}"
  remove_block "${HOME}/.zshrc" "${SHELL_BLOCK_BEGIN}" "${SHELL_BLOCK_END}"
  remove_block "${HOME}/.gitconfig" "${GIT_BLOCK_BEGIN}" "${GIT_BLOCK_END}"
}

status_blocks() {
  local file begin label
  for spec in \
    "${HOME}/.bashrc|${SHELL_BLOCK_BEGIN}|bash shell block" \
    "${HOME}/.zshrc|${SHELL_BLOCK_BEGIN}|zsh shell block" \
    "${HOME}/.gitconfig|${GIT_BLOCK_BEGIN}|git include block"; do
    IFS='|' read -r file begin label <<<"${spec}"
    if [[ -f "${file}" ]] && grep -Fqx "${begin}" "${file}"; then
      say "ok: ${label} in ${file}"
    else
      say "missing: ${label} in ${file}"
    fi
  done
}

cmd_link() {
  MODE="link"
  for_each_link link_file
  link_blocks
}

cmd_dry_run() {
  MODE="dry-run"
  for_each_link link_file
  link_blocks
}

cmd_unlink() {
  MODE="unlink"
  for_each_link unlink_file
  unlink_blocks
}

cmd_status() {
  MODE="status"
  say "platform: ${PLATFORM}"
  for_each_link check_path
  status_blocks
  if [[ -e "${ROOT_DIR}/.codex" && ! -d "${ROOT_DIR}/.codex" ]]; then
    say "legacy placeholder: ${ROOT_DIR}/.codex"
  fi
}

check_tool() {
  local tool="$1"
  if command -v "${tool}" >/dev/null 2>&1; then
    say "ok: ${tool} ($(command -v "${tool}"))"
  else
    say "missing optional tool: ${tool}"
  fi
}

cmd_doctor() {
  say "platform: ${PLATFORM}"
  check_tool bash
  check_tool git
  check_tool tmux
  check_tool yazi
  check_tool claude
  check_tool codex
  check_tool ssh
  check_tool curl

  case "${PLATFORM}" in
    macos)
      check_tool brew
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1 || command -v pacman >/dev/null 2>&1 || command -v apk >/dev/null 2>&1; then
        say "ok: Linux package manager detected"
      else
        say "missing optional tool: supported Linux package manager"
      fi
      ;;
    *)
      warn "unsupported platform; core links may still work"
      ;;
  esac
}

set_platform
cmd="${1:-dry-run}"
case "${cmd}" in
  dry-run)
    cmd_dry_run
    ;;
  link)
    cmd_link
    ;;
  unlink)
    cmd_unlink
    ;;
  status)
    cmd_status
    ;;
  doctor)
    cmd_doctor
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    warn "unknown command: ${cmd}"
    usage >&2
    exit 2
    ;;
esac
