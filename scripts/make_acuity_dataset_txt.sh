#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE_DIR="${1:-/home/lzw/Code/ultralytics/dataset_20250826/YOLODataset1/images/train}"
OUT="${2:-$ROOT_DIR/deployment_yulong810a/yolov8s_seg/dataset.txt}"
LIMIT="${LIMIT:-64}"

mkdir -p "$(dirname "$OUT")"
find "$IMAGE_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) \
  | sort \
  | head -n "$LIMIT" > "$OUT"

echo "wrote $(wc -l < "$OUT") images to $OUT"

