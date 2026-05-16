# Optional HTTP proxy helpers adapted from the old bash/fish config.
# Source this from ~/.config/my-linux-config/shell/local.sh if you need it.

proxy_on() {
  local port="${1:?usage: proxy_on PORT}"
  export http_proxy="http://127.0.0.1:${port}"
  export https_proxy="${http_proxy}"
  echo "HTTP proxy enabled on 127.0.0.1:${port}"
}

proxy_off() {
  unset http_proxy https_proxy
  echo "HTTP proxy disabled"
}

proxy_git_on() {
  local port="${1:?usage: proxy_git_on PORT}"
  git config --global http.proxy "http://127.0.0.1:${port}"
  git config --global https.proxy "http://127.0.0.1:${port}"
  echo "Git HTTP proxy enabled on 127.0.0.1:${port}"
}

proxy_git_off() {
  git config --global --unset http.proxy 2>/dev/null || true
  git config --global --unset https.proxy 2>/dev/null || true
  echo "Git HTTP proxy disabled"
}
