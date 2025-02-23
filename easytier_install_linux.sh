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

# 检查 wget 是否安装
if ! command -v wget &> /dev/null
then
    echo "错误: wget 未安装。请先安装 wget。"
    exit 1
fi

# 检查 unzip 是否安装
if ! command -v unzip &> /dev/null
then
    echo "错误: unzip 未安装。请先安装 unzip。"
    exit 1
fi

# 检查 jq 是否安装 (用于 JSON 解析，但现在可能不需要严格依赖)
if ! command -v jq &> /dev/null
then
    echo "警告: jq 未安装。HTML 解析方式对 jq 的依赖性降低，但推荐安装以便未来可能的功能增强。"
fi

# **已移除动态获取版本号的逻辑，现在使用固定版本号**
LATEST_VERSION="v2.2.2"  # **固定版本号，需要通过 CI 定期更新**
echo "使用固定版本号: $LATEST_VERSION"

# 构造下载链接 (假设文件名格式不变)
DOWNLOAD_URL="https://github.com/EasyTier/EasyTier/releases/download/${LATEST_VERSION}/easytier-linux-x86_64-${LATEST_VERSION}.zip"
echo "下载链接 (固定版本): $DOWNLOAD_URL"

# Download and extract EasyTier
PACKAGE_NAME="easytier-linux-x86_64-${LATEST_VERSION}.zip"
wget "$DOWNLOAD_URL" -O "$PACKAGE_NAME"
if [ ! -f "$PACKAGE_NAME" ]; then
    echo "错误: 下载 EasyTier 软件包失败。"
    exit 1
fi

unzip "$PACKAGE_NAME" -d ~/
mkdir -p ~/easytier
mv ~/easytier-linux-x86_64/* ~/easytier
rm -rf ~/easytier-linux-x86_64
# Clean up downloaded zip file
rm "$PACKAGE_NAME"

# Get IPv4 address from user
while true; do
    read -p "请输入 EasyTier 的 IPv4 地址: " IP_ADDRESS
    # 验证 IPv4 地址格式 (简单的正则表达式)
    if [[ "$IP_ADDRESS" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        break
    else
        echo "无效的 IPv4 地址格式。请重新输入。"
    fi
done

# Get network secret from user
read -p "请输入 EasyTier 的网络密钥 (network secret): " NETWORK_SECRET
echo

# Get network name from user
read -p "请输入 EasyTier 的网络名称 (network name): " NETWORK_NAME
echo

# Create systemd service
sudo tee /etc/systemd/system/easytier.service > /dev/null <<EOF
[Unit]
Description=EasyTier Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=$HOME/easytier/easytier-core --ipv4 ${IP_ADDRESS} \
    --network-name ${NETWORK_NAME} \
    --network-secret ${NETWORK_SECRET} \
    -p tcp://public.easytier.cn:11010

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
if ! sudo systemctl enable easytier; then
    echo "启用 easytier 服务失败。"
    exit 1
fi
if ! sudo systemctl restart easytier; then
    echo "启动 easytier 服务失败。"
    exit 1
fi

echo "EasyTier 安装完成!"
