#!/usr/bin/env bash
# .aseprite → export/<id>/<id>.png + <id>.anim.json, 검사까지. 계약: docs/asset-contract.md
# 사용: scripts/export-anim.sh aseprite/<id>/<id>.aseprite [--drop v<n>]
#   --drop v<n> : 결과를 공유 폴더 C:\github-clones\_asset-drop\<id>\v<n>\ 에도 복사 (이미 있으면 멈춤 — 판은 덮어쓰지 않고 쌓음)
set -euo pipefail
cd "$(dirname "$0")/.."
ASEPRITE="${ASEPRITE:-/c/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe}"
DROP_ROOT="${DROP_ROOT:-/c/github-clones/_asset-drop}"
SRC="$1"; shift
DROP=""
if [ "${1:-}" = "--drop" ]; then DROP="$2"; fi
ID="$(basename "$SRC" .aseprite)"
OUT="export/$ID"
mkdir -p "$OUT"
# 출처: 지금 커밋. 커밋 안 된 변경이 있으면 표시만 하고 계속 (전달 v<n>은 작업 중 판일 수 있음)
SOURCE="ribs-assets@$(git rev-parse --short=7 HEAD)"
if [ -n "$(git status --porcelain -- "$SRC" "$(dirname "$SRC")")" ]; then echo "주의: $SRC 쪽에 커밋 안 된 변경이 있음 (source=$SOURCE 는 그 이전 커밋)"; fi
"$ASEPRITE" -b --script-param in="$(cygpath -w "$SRC")" --script-param out="$(cygpath -w "$OUT")" \
  --script-param id="$ID" --script-param source="$SOURCE" --script "$(cygpath -w scripts/export-anim.lua)"
node scripts/check-anim.mjs "$OUT/$ID.anim.json"
if [ -n "$DROP" ]; then
  DEST="$DROP_ROOT/$ID/$DROP"
  if [ -e "$DEST" ]; then echo "이미 있음: $DEST (판 번호를 올리세요)"; exit 1; fi
  mkdir -p "$DEST"; cp "$OUT/$ID.png" "$OUT/$ID.anim.json" "$DEST/"
  echo "→ 전달: $DEST"
fi
