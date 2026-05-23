#!/usr/bin/env python3
"""Patch Pegasus-generated inputmeta for YOLOv8 segmentation quantization.

This script intentionally uses only Python's standard library because the
Acuity/Pegasus environment may not have PyYAML installed.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: patch_acuity_inputmeta.py <inputmeta.yml> <dataset.txt>", file=sys.stderr)
        return 2

    inputmeta_path = Path(sys.argv[1])
    dataset_path = Path(sys.argv[2])
    old_text = inputmeta_path.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r"^\s*-\s*lid:\s*(\S+)\s*$", old_text, flags=re.MULTILINE)
    lid = match.group(1) if match else "images"

    rendered = f"""%YAML 1.2
---
# !!!This file disallow TABs!!!
# Patched for YOLOv8 segmentation.
input_meta:
  databases:
  - path: {dataset_path.name}
    type: TEXT
    ports:
    - lid: {lid}
      category: image
      dtype: float32
      sparse: false
      tensor_name:
      layout: nchw
      shape:
      - 1
      - 3
      - 640
      - 640
      fitting: scale
      preprocess:
        reverse_channel: false
        mean:
        - 0
        - 0
        - 0
        scale: 0.003921568627451
        preproc_node_params:
          add_preproc_node: true
          preproc_type: IMAGE_RGB
          preproc_perm:
          - 0
          - 1
          - 2
          - 3
      redirect_to_output: false
"""
    inputmeta_path.write_text(rendered, encoding="utf-8")
    print(f"patched {inputmeta_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
