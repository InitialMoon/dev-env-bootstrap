_my_linux_config_home="${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config"
if [[ -r "${_my_linux_config_home}/shell/common.sh" ]]; then
  source "${_my_linux_config_home}/shell/common.sh"
fi
unset _my_linux_config_home
