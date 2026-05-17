# Shared shell defaults for macOS and Linux.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"

_dev_env_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME}/my-linux-config}"

_dev_env_path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) export PATH="$1:${PATH}" ;;
  esac
}

_dev_env_path_prepend "${HOME}/.local/bin"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if command -v yazi >/dev/null 2>&1; then
  yy() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
      cwd="$(command cat "$tmp")"
      if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd" || return
      fi
    fi
    command rm -f "$tmp"
  }
  y() {
    yy "$@"
  }
fi

if [[ -r "${_dev_env_config_home}/shell/local.sh" ]]; then
  source "${_dev_env_config_home}/shell/local.sh"
fi

unset -f _dev_env_path_prepend
unset _dev_env_config_home
