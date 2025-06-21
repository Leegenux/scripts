#!/bin/bash
# auto-update-lobe-chat-v2-preferred-fix1.sh
#
# 脚本应该和 docker-compose.yml 以及 .env 文件放在同一个目录下

# --- 自动切换到脚本所在目录 (确保在正确的位置执行) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1 # 如果切换失败则退出
echo "== 工作目录已切换至: $SCRIPT_DIR =="
echo ""

echo "开始检查 LobeChat 更新..."

# 检查 .env 文件是否存在
if [ ! -f ".env" ]; then
  echo "错误：在此目录下找不到 .env 文件。" >&2
  echo "请根据 docker-compose.yml 创建并配置 .env 文件后再运行此脚本。" >&2
  exit 1
fi
echo " .env 文件存在。"

# 定义 Compose 文件名
COMPOSE_FILE="docker-compose.yml" # 如果你的文件名不同，请修改这里

# 检查 Compose 文件是否存在
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "错误：在当前目录下找不到 $COMPOSE_FILE 文件。" >&2
    exit 1
fi
echo " 使用 Compose 文件: $COMPOSE_FILE"
echo ""

# --- 检测 Docker Compose 命令 (优先检测 V2 'docker compose') ---
COMPOSE_CMD=""
# 检查 V2 ('docker compose')
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    echo "== 检测到 Docker Compose V2 ('docker compose') =="
# 如果 V2 不可用，再检查 V1 ('docker-compose')
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    echo "== 检测到 Docker Compose V1 ('docker-compose') =="
else
    echo "错误：未找到 'docker-compose' 或 'docker compose' 命令。" >&2
    echo "请确保 Docker 和 Docker Compose 已正确安装并配置在 PATH 中。" >&2
    exit 1
fi
echo "== 将使用命令: '$COMPOSE_CMD' =="
echo ""

# Set proxy (optional) - 如果你需要代理，取消下面这行的注释
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

# --- 第 1 步：拉取最新的 lobe-chat-database 核心镜像 ---
echo "== 正在拉取 lobehub/lobe-chat-database:latest ... =="

# 创建临时文件用于存储输出
TMP_OUTPUT=$(mktemp)

# 使用 tee 命令实现实时输出同时保存内容
docker pull lobehub/lobe-chat-database:latest 2>&1 | tee "$TMP_OUTPUT"
pull_status=${PIPESTATUS[0]}  # 获取 docker pull 的实际退出状态

# 检查拉取结果
if [ $pull_status -ne 0 ]; then
  echo "错误：无法拉取镜像 lobehub/lobe-chat-database:latest" >&2
  echo "Docker 输出：" >&2
  cat "$TMP_OUTPUT" >&2
  rm -f "$TMP_OUTPUT"
  exit 1
fi

# 检查是否已是最新版本
if grep -q "Image is up to date for lobehub/lobe-chat-database:latest" "$TMP_OUTPUT"; then
  echo " LobeChat 核心镜像已经是最新版本，无需执行更新。"
  rm -f "$TMP_OUTPUT"
  exit 0
else
  echo " 检测到 LobeChat 核心镜像有新版本，开始执行完整更新流程..."
fi

# 清理临时文件
rm -f "$TMP_OUTPUT"
echo ""

# --- 第 2 步：停止并删除旧的服务 ---
echo "== 正在停止并删除旧的服务容器和网络 ('$COMPOSE_CMD down')... =="

$COMPOSE_CMD -f "$COMPOSE_FILE" down
if [ $? -ne 0 ]; then
    echo " 警告：'$COMPOSE_CMD down' 命令执行可能遇到问题，脚本将继续。请留意后续步骤的输出。"
fi
echo ""

# --- 第 3 步：拉取 Compose 文件中定义的所有服务的最新镜像 ---
echo "== 正在拉取 Compose 文件中定义的所有服务的最新镜像 ('$COMPOSE_CMD pull')... =="

# 直接执行不捕获输出，实现实时显示
$COMPOSE_CMD -f "$COMPOSE_FILE" pull
if [ $? -ne 0 ]; then
  echo " 警告：拉取部分或所有服务镜像时出错，请检查上面的日志。脚本将继续尝试启动服务..."
fi
echo ""

# --- 第 4 步：重新创建并启动所有服务 ---
echo "== 正在重新创建并启动所有服务 ('$COMPOSE_CMD up -d')... =="

$COMPOSE_CMD -f "$COMPOSE_FILE" up -d --remove-orphans
UP_EXIT_CODE=$? # 获取 up 命令的退出状态码

if [ $UP_EXIT_CODE -ne 0 ]; then
  echo "错误：'$COMPOSE_CMD up -d' 命令执行失败，退出码: $UP_EXIT_CODE" >&2
  echo "请检查服务日志（例如：$COMPOSE_CMD -f '$COMPOSE_FILE' logs lobe-chat）以确定问题。" >&2
else
  echo " '$COMPOSE_CMD up -d' 执行成功。"
  echo "(注意：如果看到关于 'MINIO_PID' 或 'LOBE_PID' 的警告是 Docker Compose V2 的预期行为)"
fi
echo ""

# --- 后续步骤（获取版本、打印总结、清理镜像）不变 ---
if [ $UP_EXIT_CODE -eq 0 ]; then
    version=$(docker inspect lobehub/lobe-chat-database:latest --format='{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null)
    if [ -z "$version" ]; then
        version="未知 (镜像标签 org.opencontainers.image.version 未找到)"
    fi

    echo "-------------------------------------"
    echo " LobeChat 及相关服务更新完成！"
    echo "更新时间: $(date)"
    echo "LobeChat 镜像版本: $version"
    echo "-------------------------------------"
    echo ""

    echo "== 正在清理旧的、未使用的 Docker 镜像 ('docker image prune')... =="
    docker image prune -af
    echo " 镜像清理完成。"
    echo ""
    echo " 脚本执行完毕，所有服务已成功更新并启动。"

else
    echo "-------------------------------------"
    echo " LobeChat 更新过程中断。"
    echo "更新时间: $(date)"
    echo "'$COMPOSE_CMD up -d' 步骤失败，服务可能未完全启动。"
    echo "请检查上面的错误日志。"
    echo "-------------------------------------"
fi

exit $UP_EXIT_CODE
