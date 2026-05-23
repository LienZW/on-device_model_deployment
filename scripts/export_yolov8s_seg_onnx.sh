#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHON="${PYTHON:-/home/lzw/anaconda3/envs/yolov8/bin/python}"
YOLO="${YOLO:-/home/lzw/anaconda3/envs/yolov8/bin/yolo}"
WEIGHTS="${1:-$ROOT_DIR/runs_202508026/segment/train2_s/weights/best.pt}"

export MPLCONFIGDIR="${MPLCONFIGDIR:-/tmp/mpl}"
export YOLO_CONFIG_DIR="${YOLO_CONFIG_DIR:-/tmp/ultralytics}"

"$PYTHON" - <<PY
from ultralytics import YOLO
m = YOLO("$WEIGHTS")
print("weights:", "$WEIGHTS")
print("names:", m.names)
print("num_classes:", len(m.names))
PY

"$YOLO" export \
  model="$WEIGHTS" \
  format=onnx \
  imgsz=640 \
  batch=1 \
  opset=12 \
  simplify=False \
  dynamic=False \
  nms=False

