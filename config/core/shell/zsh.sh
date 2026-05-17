_dev_env_shell_config_home="${DEV_ENV_CONFIG_HOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/my-linux-config}"

if [[ -r "${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-${HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/common.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/common.sh"
fi

if [[ -r "${ZSH:-${HOME}/.oh-my-zsh}/oh-my-zsh.sh" ]]; then
  export ZSH="${ZSH:-${HOME}/.oh-my-zsh}"
  ZSH_THEME="${ZSH_THEME:-powerlevel10k/powerlevel10k}"
  _dev_env_zsh_custom="${ZSH_CUSTOM:-${ZSH}/custom}"
  plugins=()
  for _dev_env_plugin in git autojump zsh-syntax-highlighting zsh-autosuggestions vi-mode; do
    if [[ -d "${ZSH}/plugins/${_dev_env_plugin}" || -d "${_dev_env_zsh_custom}/plugins/${_dev_env_plugin}" ]]; then
      plugins+=("${_dev_env_plugin}")
    fi
  done
  unset _dev_env_plugin _dev_env_zsh_custom
  source "${ZSH}/oh-my-zsh.sh"
fi

if [[ -r "${HOME}/.p10k.zsh" ]]; then
  source "${HOME}/.p10k.zsh"
fi

if [[ -r "${_dev_env_shell_config_home}/shell/zsh.local.sh" ]]; then
  source "${_dev_env_shell_config_home}/shell/zsh.local.sh"
fi

unset _dev_env_shell_config_home
