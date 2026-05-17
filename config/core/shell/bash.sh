_dev_env_shell_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config}"

if [[ -r "${_dev_env_shell_config_home}/shell/common.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/common.sh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/bash.local.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/bash.local.sh"
fi

unset _dev_env_shell_config_home
