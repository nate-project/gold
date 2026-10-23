#!/usr/bin/env bash
# 抓取每日金价并保存为 data/YYYY-MM-DD.json
# 用法: bash scripts/fetch_gold_price.sh

# 遇到未定义变量/命令失败/管道错误即退出，保证脚本健壮性
set -euo pipefail

# 金价接口地址
API_URL="https://tmini.net/api/gold-price"
# 数据保存目录
DATA_DIR="data"

# 确保保存目录存在（不存在则创建）
mkdir -p "$DATA_DIR"

# 请求接口并保存原始返回内容
echo "Fetching gold price from $API_URL ..."
RESPONSE=$(curl -fsSL "$API_URL")

# 从返回数据中提取日期（如 "2026-10-23"），失败则回退到当天日期
DATE=$(echo "$RESPONSE" | sed -n 's/.*"date":"\([0-9-]*\)".*/\1/p' | head -1)
if [ -z "$DATE" ]; then
  DATE=$(date +%Y-%m-%d)
fi

# 按日期拼接输出文件路径
OUT_FILE="$DATA_DIR/$DATE.json"

# 每小时都会覆盖写入当天的文件，以反映日内最新行情
# （git 仅在内容真正变化时提交，无变化则跳过，避免空提交）

# 美化 JSON 后保存（优先 jq，其次 python3，都不可用则保留原样）
if command -v jq >/dev/null 2>&1; then
  # jq: 标准格式化，中文正常输出
  echo "$RESPONSE" | jq . > "$OUT_FILE"
elif command -v python3 >/dev/null 2>&1; then
  # python3: 关闭 ensure_ascii 以保留中文，indent=4 缩进美化
  echo "$RESPONSE" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), ensure_ascii=False, indent=4))" > "$OUT_FILE"
else
  # 兜底: 原样写入
  echo "$RESPONSE" > "$OUT_FILE"
fi

echo "Saved data for $DATE to $OUT_FILE"
