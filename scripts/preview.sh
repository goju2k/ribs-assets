#!/usr/bin/env bash
# 미리보기 서버 켜기 (이미 켜져 있으면 그대로). 외부: http://home.ribs.kr:3108
set -euo pipefail
cd "$(dirname "$0")/.."
docker inspect -f '{{.State.Running}}' dev-proxy-3108 2>/dev/null | grep -q true || scripts/preview-proxy.sh
curl -s -o /dev/null --max-time 2 http://127.0.0.1:3208/ && { echo "이미 실행 중: http://home.ribs.kr:3108"; exit 0; }
exec node scripts/preview-server.mjs
