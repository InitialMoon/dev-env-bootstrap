#!/bin/bash
# powered by deepseek

#!/bin/bash

# 安装 Zsh（如果未安装）
if ! command -v zsh &> /dev/null; then
    echo "🔧 安装 zsh..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y zsh
    elif command -v brew &> /dev/null; then
        brew install zsh
    elif command -v yum &> /dev/null; then
        sudo yum install -y zsh
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zsh
    else
        echo "❌ 无法自动安装 zsh，请手动安装后重新运行脚本。"
        exit 1
    fi
fi

# 安装 Oh My Zsh（如果未安装）
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🔧 安装 Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 安装必备插件
echo "🔧 安装插件..."
plugins=(
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
)
for plugin in "${plugins[@]}"; do
    plugin_name=$(basename "$plugin" .git)
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name" ]; then
        git clone "$plugin" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
    fi
done

# 安装 autojump
if ! command -v autojump &> /dev/null; then
    echo "🔧 安装 autojump..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y autojump
    elif command -v brew &> /dev/null; then
        brew install autojump
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm autojump
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y autojump
    else
        echo "⚠️ 无法自动安装 autojump，请手动安装。"
    fi
fi

# 修改 ~/.zshrc 启用插件
echo "🔧 配置 ~/.zshrc..."
sed -i.bak '/^plugins=(/!b; /git/!s/)/ git)/' ~/.zshrc  # 确保 git 插件存在
sed -i.bak '/^plugins=(/!b; /zsh-syntax-highlighting/!s/)/ zsh-syntax-highlighting)/' ~/.zshrc
sed -i.bak '/^plugins=(/!b; /zsh-autosuggestions/!s/)/ zsh-autosuggestions)/' ~/.zshrc
sed -i.bak '/^plugins=(/!b; /autojump/!s/)/ autojump)/' ~/.zshrc
sed -i.bak 's/plugins=(\(.*\) zsh-syntax-highlighting)/plugins=(\1)/' ~/.zshrc  # 修复顺序
sed -i.bak 's/plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' ~/.zshrc  # 确保在最后

# 安装 Powerlevel10k 主题
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "🔧 安装 Powerlevel10k 主题..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i.bak 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
fi

# 应用配置
echo "🔧 重新加载 zsh 配置..."
source ~/.zshrc 2>/dev/null || exec zsh

# 启动 Powerlevel10k 配置向导
echo "🎨 运行 Powerlevel10k 配置向导，请按提示选择主题样式..."
p10k configure

echo "✅ 全部完成！重启终端或运行 'exec zsh' 生效。"
