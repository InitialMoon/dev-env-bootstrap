# Shared fish defaults for macOS and Linux.

set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share

fish_add_path --path $HOME/.local/bin

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if command -q yazi
    function yy
        set tmp (mktemp -t yazi-cwd.XXXXXX); or return
        yazi $argv --cwd-file=$tmp
        if test -f $tmp
            set cwd (cat $tmp)
            if test -n "$cwd"; and test "$cwd" != "$PWD"
                cd $cwd
            end
        end
        rm -f $tmp
    end
    function y
        yy $argv
    end
end

if set -q DEV_ENV_CONFIG_HOME
    set _dev_env_config_home $DEV_ENV_CONFIG_HOME
else
    set _dev_env_config_home "$XDG_CONFIG_HOME/my-linux-config"
end

if test -r "$_dev_env_config_home/fish/local.fish"
    source "$_dev_env_config_home/fish/local.fish"
end

set -e _dev_env_config_home
