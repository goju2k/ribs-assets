#!/usr/bin/env bash
# .blend → .glb (같은 폴더, 같은 이름). 사용: scripts/export-blend.sh <파일.blend> [출력.glb]
set -euo pipefail
BLENDER="${BLENDER:-/c/Users/User/AppData/Local/Programs/Blender45/blender.exe}"
SRC="$1"
OUT="${2:-${SRC%.blend}.glb}"
"$BLENDER" -b "$SRC" --python-expr "import bpy; bpy.ops.export_scene.gltf(filepath=r'$(cygpath -w "$OUT" 2>/dev/null || echo "$OUT")', export_format='GLB', export_apply=True)"
echo "→ $OUT"
