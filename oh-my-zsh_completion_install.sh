#!/bin/zsh

# 脚本用于安装 zsh, oh-my-zsh 和 autocompletion completions (zsh-autosuggestions, zsh-syntax-highlighting, zsh-autocomplete)
# 函数：检查命令是否存在
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# 函数：安装 zsh
install_zsh() {
  echo "开始安装 zsh..."
  echo "脚本将尝试使用 sudo 权限安装 zsh 软件包。"
  echo "这通常需要您输入管理员密码。"

  if command_exists apt-get; then
    echo "检测到 Debian/Ubuntu 系统..."
    sudo apt-get update
    sudo apt-get install -y zsh
  elif command_exists yum; then
    echo "检测到 CentOS/Fedora 系统 (yum)..."
    sudo yum install -y zsh
  elif command_exists dnf; then
    echo "检测到 Fedora 系统 (dnf)..."
    sudo dnf install -y zsh
  elif command_exists brew; then
    echo "检测到 macOS 系统 (Homebrew)..."
    sudo brew update
    sudo brew install zsh
  else
    echo "未检测到受支持的包管理器。请手动安装 zsh。"
    exit 1
  fi

  if command_exists zsh; then
    echo "zsh 安装完成。"
  else
    echo "zsh 安装失败，请检查错误信息。"
    exit 1
  fi
}

# 函数：安装 oh-my-zsh
install_oh_my_zsh() {
  echo "开始安装 oh-my-zsh..."
  if command_exists curl; then
    echo "使用 curl 安装..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  elif command_exists wget; then
    echo "使用 wget 安装..."
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "curl 或 wget 未找到，请确保至少安装其中一个。"
    exit 1
  fi

  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh 安装完成。"
  else
    echo "oh-my-zsh 安装失败，请检查错误信息。"
    exit 1
  fi
}

# 函数：安装自动补全插件
install_autocompletion_plugins() {
  echo "开始安装自动补全插件 (zsh-autosuggestions, zsh-syntax-highlighting, zsh-autocomplete)..."
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if ! [ -d "$ZSH_CUSTOM/plugins" ]; then
    mkdir -p "$ZSH_CUSTOM/plugins"
  fi

  if ! [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    echo "zsh-autosuggestions 插件目录已存在，跳过安装。"
  fi

  if ! [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    echo "zsh-syntax-highlighting 插件目录已存在，跳过安装。"
  fi

  if ! [ -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    git clone https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"
  else
    echo "zsh-autocomplete 插件目录已存在，跳过安装。"
  fi

  echo "自动补全插件安装完成。"
}

# 函数：配置 .zshrc 文件以启用插件
configure_zshrc() {
  echo "配置 ~/.zshrc 文件以启用插件..."
  ZSH_PLUGINS="git zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete"
  PLUGIN_LINE="plugins=(${ZSH_PLUGINS})"

  # 检查 plugins=(...) 行是否已存在
  if fgrep -q "plugins=(" ~/.zshrc; then
    echo "plugins=(...) 行已存在，替换为新的插件列表。"
    if [[ "$(uname -s)" == "Darwin" ]]; then
      sed_i_option="-i ''"
    else
      sed_i_option="-i"
    fi
    sed "$sed_i_option" "s/plugins=(.*)/${PLUGIN_LINE}/" ~/.zshrc
  else
    echo "plugins=(...) 行不存在，添加到 ~/.zshrc 文件开头。"
    # 尝试在 oh-my-zsh 初始化代码之前添加，如果找不到，则添加到文件开头
    if grep -q "source \$ZSH/oh-my-zsh.sh" ~/.zshrc; then
      if [[ "$(uname -s)" == "Darwin" ]]; then
        sed_i_option="-i ''"
      else
        sed_i_option="-i"
      fi
      sed "$sed_i_option" "0,/source \$ZSH\/oh-my-zsh.sh/s/^/${PLUGIN_LINE}\n/" ~/.zshrc
    else
      echo "${PLUGIN_LINE}" > temp_zshrc.tmp
      cat ~/.zshrc >> temp_zshrc.tmp
      mv temp_zshrc.tmp ~/.zshrc
    fi
  fi

  echo "插件已配置到 ~/.zshrc 文件。"
}

# 函数：配置 oh-my-zsh 主题
configure_zsh_theme() {
  echo "配置 oh-my-zsh 主题..."
  echo "您可以通过修改 ~/.zshrc 文件中的 ZSH_THEME 变量来更改主题。"
  echo "默认主题是 'robbyrussell'。"
  echo "您可以选择以下常用主题 (输入数字选择，或输入主题名称自定义):"
  echo "  1. robbyrussell"
  echo "  2. agnoster"
  echo "  3. spaceship"
  echo "  4. powerlevel10k/powerlevel10k"
  echo "  5. avocado"
  echo "  6. ys"
  echo "  7. zsh- শিল্পের-theme"
  echo "  8. lambda"
  echo "  9. minimal"
  echo "  10. clean"
  echo "  c. 自定义主题名称"

  echo -n "请选择主题 (输入数字或 'c' 自定义): "
  read theme_choice

  case "$theme_choice" in
    1) theme="robbyrussell";;
    2) theme="agnoster";;
    3) theme="spaceship";;
    4) theme="powerlevel10k/powerlevel10k";;
    5) theme="avocado";;
    6) theme="ys";;
    7) theme="zsh- শিল্পের-theme";;
    8) theme="lambda";;
    9) theme="minimal";;
    10) theme="clean";;
    c|C) # 处理自定义主题
      echo -n "请输入自定义主题名称: "
      read custom_theme_name
      theme="$custom_theme_name"
      ;;
    *) # 默认情况或输入错误
      theme="robbyrussell"; # 默认主题
      echo "无效的选择，使用默认主题 'robbyrussell'。"
      ;;
  esac

  echo "使用主题 '$theme'."

  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed_i_option="-i ''"
  else
    sed_i_option="-i"
  fi
  sed "$sed_i_option" "s/^ZSH_THEME=.*$/ZSH_THEME=\"${theme}\"/g" ~/.zshrc
}

# 主程序流程
echo "开始安装和配置 zsh, oh-my-zsh 和自动补全插件..."

# 检查 zsh 是否已安装
if ! command_exists zsh; then
  echo "zsh 未安装，脚本将尝试安装 zsh 软件包。"
  install_zsh
else
  echo "zsh 已安装。"
fi

# 检查 oh-my-zsh 是否已安装
if ! [ -d "$HOME/.oh-my-zsh" ]; then
  install_oh_my_zsh
else
  echo "oh-my-zsh 已安装。"
fi

install_autocompletion_plugins
configure_zshrc
configure_zsh_theme

echo "安装和配置完成！"
echo "zsh 配置已修改，为了使更改生效，请尝试使用新的 zsh 终端前，手动重新加载 zsh 配置文件。"
echo "您可以运行 'source ~/.zshrc' 或者重启终端来重新加载配置。"

exit 0