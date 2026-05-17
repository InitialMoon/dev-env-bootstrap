# macOS-only shell defaults. Safe to source on non-macOS; it becomes a no-op.

if [[ "$(uname -s)" != "Darwin" ]]; then
  return 0 2>/dev/null || exit 0
fi

_macos_path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) export PATH="$1:${PATH}" ;;
  esac
}

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ -z "${HOMEBREW_BOTTLE_DOMAIN+x}" ]]; then
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
fi

if [[ -x /usr/libexec/java_home ]]; then
  _java_home="$(/usr/libexec/java_home 2>/dev/null || true)"
  if [[ -n "${_java_home}" ]]; then
    export JAVA_HOME="${JAVA_HOME:-${_java_home}}"
    _macos_path_prepend "${JAVA_HOME}/bin"
  fi
  unset _java_home
fi

if [[ -d /opt/homebrew/opt/llvm ]]; then
  _macos_path_prepend "/opt/homebrew/opt/llvm/bin"
  export LDFLAGS="${LDFLAGS:+${LDFLAGS} }-L/opt/homebrew/opt/llvm/lib"
  export CPPFLAGS="${CPPFLAGS:+${CPPFLAGS} }-I/opt/homebrew/opt/llvm/include"
  export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-/opt/homebrew/opt/llvm}"
fi

if [[ -d /opt/homebrew/opt/ruby ]]; then
  _macos_path_prepend "/opt/homebrew/opt/ruby/bin"
  if command -v gem >/dev/null 2>&1; then
    _macos_path_prepend "$(gem env user_gemhome)/bin"
  fi
fi

if [[ -d /opt/homebrew/opt/dotnet@6/bin ]]; then
  _macos_path_prepend "/opt/homebrew/opt/dotnet@6/bin"
fi

if [[ -r "${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config/macos/local.sh" ]]; then
  source "${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config/macos/local.sh"
fi

unset -f _macos_path_prepend
