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

  if fgrep -q "plugins=(" ~/.zshrc; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      sed_i_option="-i ''"
    else
      sed_i_option="-i"
    fi
    sed "$sed_i_option" "s/plugins=(.*)/plugins=(${ZSH_PLUGINS})/" ~/.zshrc
  else
    echo "plugins=(${ZSH_PLUGINS})" >> ~/.zshrc
  fi

  echo "插件已添加到 ~/.zshrc 文件。"
}

# 函数：配置 oh-my-zsh 主题
configure_zsh_theme() {
  echo "配置 oh-my-zsh 主题..."
  echo "您可以通过修改 ~/.zshrc 文件中的 ZSH_THEME 变量来更改主题。"
  echo "默认主题是 'robbyrussell'。"

  # 常用主题列表 (更新自 Oh My Zsh Themes Wiki)
  declare -A theme_options=(
    [1]="robbyrussell"       # 默认主题，保持不变
    [2]="agnoster"          # 流行的 powerline 风格主题
    [3]="spaceship"         # 功能强大的主题，信息丰富
    [4]="powerlevel10k/powerlevel10k" # 非常流行的高度可定制主题 (需要单独安装 powerlevel10k)
    [5]="avocado"           # 简洁美观的主题
    [6]="ys"                # 另一个简洁的主题
    [7]="zsh- শিল্পের-theme"   #  一个现代感的主题 (themes wiki 上 ' শিল্পীর'  实际是 ' শিল্পীর-theme')
    [8]="lambda"            #  简洁的 lambda 提示符
    [9]="minimal"           #  极简主题
    [10]="clean"            #  非常干净的主题
  )

  if [[ -z "${theme_options[@]}" ]]; then
    echo "警告：主题选项数组未正确初始化。"
    return
  fi

  echo "您可以选择以下常用主题 (输入数字选择，或输入主题名称自定义):"
  local sorted_keys
  sorted_keys=($(printf "%s\n" "${(@k)theme_options}" | sort -n)) # 获取键并数值排序

  for key in "${sorted_keys[@]}"; do
    echo "  $key. ${theme_options[$key]}"
  done
  echo "  c. 自定义主题名称"

  read theme_choice_input

  theme_choice="$theme_choice_input"

  case "$theme_choice" in
    [1-9]|10) #  修改匹配数字的范围，包括 10
      chosen_theme="${theme_options[$theme_choice]}"
      echo "将主题设置为 $chosen_theme ..."
      if [[ "$(uname -s)" == "Darwin" ]]; then
        sed_i_option="-i ''"
      else
        sed_i_option="-i"
      fi
      sed "$sed_i_option" "s/^ZSH_THEME=\"[^\"]*\"/ZSH_THEME=\"${chosen_theme}\"/" ~/.zshrc
      echo "主题已更改为 $chosen_theme。"
      ;;
    c|C)
      read -p "请输入您想要使用的主题名称 (例如 'agnoster'): " custom_theme
      if [[ -n "$custom_theme" ]]; then
        echo "将主题设置为 $custom_theme ..."
        if [[ "$(uname -s)" == "Darwin" ]]; then
          sed_i_option="-i ''"
        else
          sed_i_option="-i"
        fi
        sed "$sed_i_option" "s/^ZSH_THEME=\"[^\"]*\"/ZSH_THEME=\"${custom_theme}\"/" ~/.zshrc
        echo "主题已更改为 $custom_theme。您可以在 https://github.com/ohmyzsh/ohmyzsh/wiki/Themes 查看更多主题。"
      else
        echo "主题名称为空，将使用默认主题 'robbyrussell'。"
      fi
      ;;
    y|Y) # 保持之前的自定义主题逻辑，如果用户输入 y 但不选择数字或 'c'，则进入自定义主题输入
      read -p "请输入您想要使用的主题名称 (例如 'agnoster'): " custom_theme
      if [[ -n "$custom_theme" ]]; then
        echo "将主题设置为 $custom_theme ..."
        if [[ "$(uname -s)" == "Darwin" ]]; then
          sed_i_option="-i ''"
        else
          sed_i_option="-i"
        fi
        sed "$sed_i_option" "s/^ZSH_THEME=\"[^\"]*\"/ZSH_THEME=\"${custom_theme}\"/" ~/.zshrc
        echo "主题已更改为 $custom_theme。您可以在 https://github.com/ohmyzsh/ohmyzsh/wiki/Themes 查看更多主题。"
      else
        echo "主题名称为空，将使用默认主题 'robbyrussell'。"
      fi
      ;;
    *)
      echo "使用默认主题 'robbyrussell'。"
      ;;
  esac
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