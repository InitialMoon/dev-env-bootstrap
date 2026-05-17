# dev-env-bootstrap

[English](README.md) | [简体中文](README.zh-CN.md)

这是一个用于快速初始化个人终端和开发环境的配置仓库，目标是在 Linux 和 macOS 上尽量保持一致、顺手、可重复执行的基础体验。

这个仓库保留了旧版“一键配置新机器”的目标，但把内容拆成了更安全、可维护的层次：

- `bootstrap.sh`：准备机器环境，并应用核心配置。
- `install.sh`：安全链接配置文件，并维护 shell/Git 的 include 标记块。
- `config/core/`：默认启用的跨平台基础配置。
- `config/optional/`：从旧仓库保留下来的可选工具或更重的配置。

## 快速开始

```bash
git clone git@github.com:InitialMoon/dev-env-bootstrap.git
cd dev-env-bootstrap
./bootstrap.sh doctor
./bootstrap.sh core
```

`bootstrap.sh core` 会检查/安装基础工具，然后运行 `./install.sh link` 应用核心配置。

如果你想要更接近旧版 `run_config.sh` 的一键体验，但仍保留更安全的默认行为：

```bash
./bootstrap.sh all
```

`all` 会执行 core 设置，并继续配置可选的 `fish`、`nvim` 和 `oh-my-posh` 模块。可以使用：

```bash
ASSUME_YES=1 ./bootstrap.sh all
```

跳过包安装确认；或者使用：

```bash
DRY_RUN=1 ./bootstrap.sh all
```

预览将要执行的安装和链接操作。

如果你只想链接配置，不想安装任何软件：

```bash
./install.sh dry-run
./install.sh link
```

## Core 层

默认 core 配置管理这些内容：

- `tmux` 配置：`config/core/tmux/tmux.conf` -> `~/.tmux.conf`
- Bash/Zsh 共享片段：安装到 `~/.config/my-linux-config/shell/`
- Git 默认配置：通过 `~/.gitconfig` 里的 include 标记块引入
- Yazi 配置：安装到 `~/.config/yazi/`
- Claude Code 模板：安装到 `~/.claude/`
- Codex 模板：安装到 `~/.codex/`
- `ssh-socks-proxy`：安装到 `~/.local/bin/`

安装器默认是保守的：

- 不覆盖已有用户文件。
- 对符号链接做归属检查。
- 只维护自己写入的 begin/end 标记块。
- `unlink` 只移除本仓库管理的链接和标记块。

## Optional 层

从旧仓库保留下来的可选模块：

- `config/optional/fish/`：fish 和 Oh My Fish 配置
- `config/optional/zsh/`：旧版 zsh/oh-my-zsh 安装脚本
- `config/optional/nvim/`：基于 LazyVim 的 Neovim 配置
- `config/optional/vim/`：Vim 配置
- `config/optional/oh-my-posh/`：旧版 Oh My Posh 主题；安装器只有在确认后才会使用 upstream 安装脚本
- `config/optional/ranger/`：旧仓库保留的 ranger 源码
- `config/optional/legacy/`：旧版完整配置文件和原始 `run_config.sh`

这些模块不会被 `core` 默认安装。需要时可以显式运行：

```bash
./bootstrap.sh optional nvim
./bootstrap.sh optional fish nvim oh-my-posh
./bootstrap.sh optional zsh
./bootstrap.sh optional ranger
```

optional 脚本也使用安全链接：遇到已有的非本仓库配置时会跳过，不会直接覆盖。

## 常用命令

```bash
./bootstrap.sh doctor              # 检查平台、包管理器和工具可用性
./bootstrap.sh core                # 安装/检查 core 工具并链接配置
./bootstrap.sh all                 # core + fish + nvim + oh-my-posh
./bootstrap.sh optional            # 查看可选模块
./bootstrap.sh optional nvim fish  # 安装/配置指定 optional 模块

./install.sh dry-run      # 预览链接和标记块变更
./install.sh link         # 安全应用 core 配置
./install.sh status       # 查看当前管理状态
./install.sh unlink       # 移除本仓库管理的链接和标记块
./install.sh doctor       # 检查工具可用性
```

## 本机私有配置

不要把 secrets、token、私有路径、SSH key material 或强机器相关身份信息提交到仓库。

这些内容应该放在本机：

- `~/.config/my-linux-config/shell/local.sh`
- `~/.gitconfig` 中本仓库标记块之外的位置
- `~/.claude/settings.local.json`
- 如果你的 Codex 配置支持，可以使用 `~/.codex/config.local.toml`

## macOS 说明

core 配置的目标是同时支持 macOS 和 Linux。

### iTerm2 中 tmux 的 Option 键设置

如果你在 macOS 的 iTerm2 里使用这个 tmux 配置，建议把 Option 键设置为 Esc+/Meta。这个 tmux 配置里有不少 Meta/Alt 风格快捷键，而 iTerm2 默认会把 Option 当作输入特殊字符使用。

<img width="978" alt="iTerm2 Option key setting" src="https://github.com/user-attachments/assets/724ddb18-9f40-4212-a3a1-901c8bded73a" />

步骤：

1. 打开 iTerm2 Preferences。
2. 进入 Profiles。
3. 选择你正在使用的 Profile。
4. 打开 Keys 标签。
5. 将 Left Option Key 和 Right Option Key 都设置为 Esc+。

## Legacy 说明

原始的 `run_config.sh` 已经移动到：

```text
config/optional/legacy/run_config.sh
```

它只作为历史参考保留，不再作为默认入口。原因是旧脚本把包安装、配置覆盖、插件下载和 optional 工具都混在一起了，不适合作为公开仓库里的默认安装流程。
