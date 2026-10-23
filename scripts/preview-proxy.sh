#!/usr/bin/env bash
# 외부 공개 중계 컨테이너 (한 번만 만들면 재부팅 후에도 유지): http://home.ribs.kr:3108 → host:3208
# ribs-home의 dev-proxy-3100과 같은 방식 (node:24-alpine + net 파이프)
set -euo pipefail
docker rm -f dev-proxy-3108 >/dev/null 2>&1 || true
docker run -d --name dev-proxy-3108 --restart unless-stopped -p 3108:3108 -e TARGET_PORT=3208 node:24-alpine \
  node -e "const net=require('net');net.createServer(c=>{const u=net.connect(+process.env.TARGET_PORT,'host.docker.internal');c.pipe(u).pipe(c);u.on('error',()=>c.destroy());c.on('error',()=>u.destroy());}).listen(3108,()=>console.log('proxy 3108 -> host:'+process.env.TARGET_PORT));"
