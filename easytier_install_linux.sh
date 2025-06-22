#!/bin/bash
set -e

# 检查是否已安装 EasyTier
if [ -f "$HOME/easytier/easytier-core" ]; then
    echo "警告: EasyTier 似乎已经安装在 ~/easytier 目录。"
    read -p "是否要重新安装并覆盖现有安装？ (yes/no): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消安装。"
        exit 0
    fi
    echo "继续重新安装，现有 ~/easytier 目录将被覆盖。"
fi

# 检查必要依赖
for dep in wget unzip; do
    if ! command -v $dep &> /dev/null; then
        echo "错误: $dep 未安装。请先安装 $dep。"
        exit 1
    fi
done

# 使用固定版本号
LATEST_VERSION="v2.3.2"
echo "使用固定版本号: $LATEST_VERSION"

# 下载并解压 EasyTier
DOWNLOAD_URL="https://github.com/EasyTier/EasyTier/releases/download/${LATEST_VERSION}/easytier-linux-x86_64-${LATEST_VERSION}.zip"
PACKAGE_NAME="easytier-linux-x86_64-${LATEST_VERSION}.zip"

echo "正在下载 EasyTier..."
wget -q --show-progress "$DOWNLOAD_URL" -O "$PACKAGE_NAME" || {
    echo "错误: 下载 EasyTier 软件包失败。"
    exit 1
}

echo "正在解压安装包..."
unzip -q "$PACKAGE_NAME" -d ~/
mkdir -p ~/easytier
mv ~/easytier-linux-x86_64/* ~/easytier
rm -rf ~/easytier-linux-x86_64
rm -f "$PACKAGE_NAME"

# 获取 USER_TOKEN
while true; do
    echo "温馨提示：USER_TOKEN 是访问 EasyTier 网络所需的唯一密钥"
    read -p "请输入您的 USER_TOKEN: " USER_TOKEN
    if [ -n "$USER_TOKEN" ]; then
        break
    else
        echo "错误: USER_TOKEN 不能为空，请重新输入。"
    fi
done

# 创建 systemd 服务
echo "正在创建系统服务..."
sudo tee /etc/systemd/system/easytier.service > /dev/null <<EOF
[Unit]
Description=EasyTier Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=$HOME/easytier/easytier-core -w $USER_TOKEN
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl restart easytier
sudo systemctl enable easytier

# 检查服务状态
if systemctl is-active --quiet easytier; then
    echo -e "\n\033[32mEasyTier 安装成功！服务正在运行。\033[0m"
    echo -e "您可以使用以下命令管理服务:"
    echo -e "  sudo systemctl restart easytier   # 重启服务"
    echo -e "  sudo systemctl stop easytier      # 停止服务"
    echo -e "  sudo journalctl -u easytier -f    # 查看日志"
else
    echo -e "\n\033[31m错误: EasyTier 服务启动失败。请检查日志: 'journalctl -u easytier -f'\033[0m"
    exit 1
fi
