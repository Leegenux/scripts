#!/usr/bin/env bash
# control_user_cpu.sh
# 限制某个用户的 CPU 配额为 N 个核，并可选设置 CPU 权重
# 需要 root 权限、systemd + cgroup v2 环境

set -euo pipefail

usage() {
  echo "用法: sudo $0 <username> <cores> [weight] [--runtime]"
  echo "  <username>  目标用户"
  echo "  <cores>     允许的最大核数 (正整数), 例如 4 表示 CPUQuota=400%"
  echo "  [weight]    可选 CPU 权重 1..10000，默认不改（systemd 默认 100）"
  echo "  --runtime   可选，仅本次启动有效（不写入持久配置）"
}

if [[ ${EUID} -ne 0 ]]; then
  echo "请用 root 运行（sudo）。" >&2
  exit 1
fi

if [[ $# -lt 2 ]]; then
  usage; exit 1
fi

USERNAME="$1"; shift
CORES="$1"; shift || true

RUNTIME_FLAG=""
WEIGHT=""
while (( "$#" )); do
  case "$1" in
    --runtime) RUNTIME_FLAG="--runtime";;
    '' ) ;;
    *) WEIGHT="$1";;
  esac
  shift || true
done

# 校验用户
if ! id "$USERNAME" &>/dev/null; then
  echo "用户不存在: $USERNAME" >&2
  exit 1
fi

# 校验核数
if ! [[ "$CORES" =~ ^[1-9][0-9]*$ ]]; then
  echo "无效的核数: $CORES（需要正整数）" >&2
  exit 1
fi

# 校验权重（如果提供）
if [[ -n "$WEIGHT" ]]; then
  if ! [[ "$WEIGHT" =~ ^[1-9][0-9]*$ ]] || (( WEIGHT < 1 || WEIGHT > 10000 )); then
    echo "无效的权重: $WEIGHT（范围 1..10000）" >&2
    exit 1
  fi
fi

TARGET_UID="$(id -u "$USERNAME")"
SLICE="user-${TARGET_UID}.slice"

# 1) 确保启用 CPUAccounting
CONF="/etc/systemd/system.conf"
NEED_REEXEC=0
if ! grep -q '^DefaultCPUAccounting=yes' "$CONF" 2>/dev/null; then
  if grep -Eq '^[#]?DefaultCPUAccounting=' "$CONF"; then
    sed -i 's/^[#]*DefaultCPUAccounting=.*/DefaultCPUAccounting=yes/' "$CONF"
  else
    echo "DefaultCPUAccounting=yes" >> "$CONF"
  fi
  NEED_REEXEC=1
fi

if (( NEED_REEXEC )); then
  echo "启用 DefaultCPUAccounting 并重载 systemd..."
  systemctl daemon-reexec
fi

# 2) 设置 CPUQuota
QUOTA="$(( CORES * 100 ))%"
echo "为 $USERNAME (UID=$TARGET_UID) 设置 CPUQuota=$QUOTA $RUNTIME_FLAG"
systemctl set-property $RUNTIME_FLAG "$SLICE" "CPUQuota=$QUOTA"

# 3) 可选设置 CPUWeight
if [[ -n "$WEIGHT" ]]; then
  echo "为 $USERNAME 设置 CPUWeight=$WEIGHT $RUNTIME_FLAG"
  systemctl set-property $RUNTIME_FLAG "$SLICE" "CPUWeight=$WEIGHT"
fi

# 4) 显示当前状态
echo
echo "当前 slice 状态："
systemctl status "$SLICE" --no-pager || true

echo
echo "提示：使用 'systemd-cgtop' 观察实时 CPU；按 'c' 切换到 CPU 视图。"
echo "撤销限制：sudo systemctl revert $SLICE"