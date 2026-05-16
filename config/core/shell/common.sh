# Shared shell defaults for macOS and Linux.

case ":${PATH}:" in
  *":${HOME}/.local/bin:"*) ;;
  *) export PATH="${HOME}/.local/bin:${PATH}" ;;
esac

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if command -v yazi >/dev/null 2>&1; then
  yy() {
    local tmp
    tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
    yazi "$@" --cwd-file="$tmp"
    if [[ -f "$tmp" ]]; then
      local cwd
      cwd="$(command cat "$tmp")"
      if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd" || return
      fi
    fi
    command rm -f "$tmp"
  }
fi

if [[ -r "${XDG_CONFIG_HOME}/my-linux-config/shell/local.sh" ]]; then
  source "${XDG_CONFIG_HOME}/my-linux-config/shell/local.sh"
fi
