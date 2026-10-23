#!/usr/bin/env bash
# .aseprite → 스프라이트 시트 .png + .json (같은 폴더, 같은 이름). 사용: scripts/export-aseprite.sh <파일.aseprite>
set -euo pipefail
ASEPRITE="${ASEPRITE:-/c/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe}"
SRC="$1"
BASE="${SRC%.*}"
"$ASEPRITE" -b "$SRC" \
  --sheet "$BASE.png" --sheet-type packed \
  --data "$BASE.json" --format json-array \
  --list-tags --list-layers --trim
echo "→ $BASE.png, $BASE.json"
