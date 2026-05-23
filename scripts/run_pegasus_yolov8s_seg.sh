#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_DIR="${1:-$ROOT_DIR/deployment_yulong810a/yolov8s_seg}"
MODEL_NAME="${MODEL_NAME:-yolov8s_seg}"
QUANT_TYPE="${QUANT_TYPE:-uint8}"

: "${ACUITY_PATH:?Set ACUITY_PATH to acuity-toolkit bin directory, for example /path/to/acuity-toolkit-whl-6.21.18/bin}"

PEGASUS="$ACUITY_PATH/pegasus"
if [[ ! -e "$PEGASUS" ]]; then
  PEGASUS="python3 $ACUITY_PATH/pegasus.py"
fi

cd "$MODEL_DIR"
test -f "$MODEL_NAME.onnx"
test -f dataset.txt

$PEGASUS import onnx \
  --model "$MODEL_NAME.onnx" \
  --output-model "$MODEL_NAME.json" \
  --output-data "$MODEL_NAME.data"

$PEGASUS generate inputmeta \
  --model "$MODEL_NAME.json" \
  --input-meta-output "$MODEL_NAME""_inputmeta.yml"

python3 "$ROOT_DIR/deployment_yulong810a/scripts/patch_acuity_inputmeta.py" \
  "$MODEL_NAME""_inputmeta.yml" \
  dataset.txt

$PEGASUS generate postprocess-file \
  --model "$MODEL_NAME.json" \
  --postprocess-file-output "$MODEL_NAME""_postprocess_file.yml"

$PEGASUS quantize \
  --model "$MODEL_NAME.json" \
  --model-data "$MODEL_NAME.data" \
  --batch-size 1 \
  --device CPU \
  --with-input-meta "$MODEL_NAME""_inputmeta.yml" \
  --rebuild \
  --model-quantize "$MODEL_NAME""_$QUANT_TYPE.quantize" \
  --quantizer asymmetric_affine \
  --qtype "$QUANT_TYPE"

EXPORT_ARGS=(
  export ovxlib
  --model "$MODEL_NAME.json"
  --model-data "$MODEL_NAME.data"
  --dtype quantized
  --model-quantize "$MODEL_NAME""_$QUANT_TYPE.quantize"
  --batch-size 1
  --save-fused-graph
  --target-ide-project linux64
  --with-input-meta "$MODEL_NAME""_inputmeta.yml"
  --output-path "wksp/$MODEL_NAME""_$QUANT_TYPE"
  --optimize VIP8000OI_PID0XA4
  --pack-nbg-unify
)

if [[ -n "${VIV_SDK:-}" ]]; then
  EXPORT_ARGS+=(--viv-sdk "$VIV_SDK")
fi

$PEGASUS "${EXPORT_ARGS[@]}"

echo "Acuity export finished under $MODEL_DIR/wksp/$MODEL_NAME""_$QUANT_TYPE"

