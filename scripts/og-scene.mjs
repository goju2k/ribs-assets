// og-image v2 (D-050 후속): 실제 게임 화면 같은 던전 한 장면 → 1200×630
// 실제 타일셋(dungeon-part1, 벽 윗면 47칸 자동 연결) + 벽 수정 + 푸른 불씨를 400×210에 깔고,
// 엔진과 같은 색 공식 L(1+kL)의 조명을 8단 + 디더로 픽셀 단위로 입힌 뒤 정수 4배. 불씨 빛 번짐만 부드럽게.
// 별 입자·제목 없음. 반전 요소 없음. 핵심(불씨와 빛)은 가운데 630×630 안.
import { execFileSync, spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export function buildScene(ROOT, FF, out) {
  // png → RGBA 바이트 + 폭 (anim 시트는 클립마다 한 줄, 폭 = 가장 긴 클립)
  const raw = f => { const b = execFileSync(FF, ['-v', 'error', '-i', f, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-'], { maxBuffer: 1e8 });
    const probe = spawnSync(FF, ['-hide_banner', '-i', f], { encoding: 'utf8' }).stderr; const m = /, (\d+)x(\d+)/.exec(probe); b.w = +m[1]; return b; };
  const TS = 'dungeon-part1';
  const meta = JSON.parse(readFileSync(join(ROOT, 'aseprite', TS, 'tileset.json'), 'utf8'));
  const tiles = raw(join(ROOT, 'export', TS, `${TS}.png`)); const TW = tiles.w;
  const W = 300, H = 158,   // 정수 4배 → 1200×632, 아래 2px 자름
   buf = Buffer.alloc(W * H * 4);
  const put = (x, y, r, g, b) => { if (x < 0 || y < 0 || x >= W || y >= H) return; const i = (y * W + x) * 4; buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = 255; };
  for (let i = 0; i < W * H; i++) { buf[i * 4] = 11; buf[i * 4 + 1] = 9; buf[i * 4 + 2] = 16; buf[i * 4 + 3] = 255; }
  const tile = (t, col, row) => { const sx = (t % meta.columns) * 16, sy = Math.floor(t / meta.columns) * 16;
    for (let y = 0; y < 16; y++) for (let x = 0; x < 16; x++) { const si = ((sy + y) * TW + sx + x) * 4; if (tiles[si + 3] === 0) continue; put(col * 16 + x, row * 16 + y, tiles[si], tiles[si + 1], tiles[si + 2]); } };
  const sprite = (file, sx, sy, sw, sh, dx, dy) => { const img = raw(file), fw = img.w;
    for (let y = 0; y < sh; y++) for (let x = 0; x < sw; x++) { const si = ((sy + y) * fw + sx + x) * 4; if (img[si + 3] === 0) continue; put(dx + x, dy + y, img[si], img[si + 1], img[si + 2]); } };

  // 지도 19×10: C 벽 윗면(자동 연결) · U/F 벽면 위/아래 · [ { 벽면 왼 끝 기둥 · . 바닥 · s/l/q 바닥 그늘
  const MAP = [
    'CCCCCCCCCCCCCCCCCCC',
    'C[UUUUUUUUUUUUUUUUU',
    'C{FFFFFFFFFFFFFFFFF',
    'Cqsssssssssssssssss',
    'Cl.................',
    'Cl.................',
    'Cl.................',
    'Cl.................',
    'Cl.................',
    'Cl.................',
  ];
  const FIX = { U: 20, F: 22, '[': 55, '{': 65, s: 6, l: 7, q: 9 };
  const A = meta.autotile.walltop;
  const isTop = (c, r) => r < 0 || c < 0 || r >= MAP.length || c >= MAP[0].length || MAP[r][c] === 'C';
  const floorTile = (c, r) => { const h = ((c * 73856093) ^ (r * 19349663)) >>> 0, k = h % 100; return k < 5 ? 4 : k < 10 ? 5 : k < 19 ? 3 : k < 26 ? 2 : k < 32 ? 1 : 0; };
  MAP.forEach((line, r) => [...line].forEach((ch, c) => {
    if (ch === 'C') {
      const n = (dc, dr) => isTop(c + dc, r + dr);
      const N = n(0, -1), E = n(1, 0), S = n(0, 1), Wd = n(-1, 0);
      const m = (N ? 1 : 0) | (N && E && n(1, -1) ? 2 : 0) | (E ? 4 : 0) | (E && S && n(1, 1) ? 8 : 0) | (S ? 16 : 0) | (S && Wd && n(-1, 1) ? 32 : 0) | (Wd ? 64 : 0) | (Wd && N && n(-1, -1) ? 128 : 0);
      tile(A.base + A.masks.indexOf(m), c, r);
    } else if (ch === '.') tile(floorTile(c, r), c, r);
    else tile(FIX[ch], c, r);
  }));
  // 바닥 소품: 봉인 문양(2×2, 불씨 아래) · 쓰러진 수호체 잔해(오른쪽)
  [[34, 8, 6], [35, 9, 6], [44, 8, 7], [45, 9, 7], [36, 14, 4], [37, 15, 4], [46, 14, 5], [47, 15, 5], [32, 4, 7], [31, 12, 8]].forEach(([t, c, r]) => tile(t, c, r));
  // 벽 수정 2개 (벽면 위 칸, 기준점 = 그 칸 아래 가운데) — 밝은 장(3번째)
  const WC = join(ROOT, 'export', 'prop-wall-crystal', 'prop-wall-crystal.png');
  const CRY = [[4, 1], [13, 1]];
  for (const [c, r] of CRY) sprite(WC, 32, 0, 16, 16, c * 16, r * 16);
  // 푸른 불씨 (가운데)
  const drawEmber = () => { const R = 5; for (let y = -R - 1; y <= R + 1; y++) for (let x = -R - 1; x <= R + 1; x++) { const d = Math.hypot(x, y);
    const c = d <= R * 0.42 ? [255, 255, 255] : d <= R * 0.75 ? [191, 234, 255] : d <= R + 0.3 ? [111, 184, 242] : null; if (c) put(EX + x, EY + y, ...c); }
    put(EX + 1, EY - R - 3, 191, 234, 255); put(EX - 1, EY - R - 5, 111, 184, 242); put(EX + 2, EY - R - 7, 111, 184, 242); };
  const EX = 150, EY = 76;
  drawEmber();

  // 조명 (엔진 값): 주변 0.30, 빛 띠 40/70/100% → 1/0.75/0.55, 세로 0.75 타원, 색 k
  const AMB = [0.30, 0.30, 0.33];
  const LIGHTS = [
    { x: EX, y: EY + 8, r: 96, s: 1.15, k: [-0.15, 0.05, 0.3] },                // 불씨 (미리보기라 반지름을 크게)
    ...CRY.map(([c, r]) => ({ x: c * 16 + 8, y: r * 16 + 10, r: 64, s: 1.25, k: [-0.2, 0.15, 0.35] })),
  ];
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const m = [...AMB];
    for (const L of LIGHTS) {
      const d = Math.hypot(x - L.x, (y - L.y) / 0.75) / L.r;
      const BAY = [[0, 0.5], [0.75, 0.25]];
      const f = d < 1 ? Math.pow(1 - d, 1.3) : 0;
      const b = Math.min(8, Math.floor(f * 8 + BAY[y % 2][x % 2])) / 8;
      if (b) { const l = b * L.s; for (let ch = 0; ch < 3; ch++) m[ch] += l * (1 + L.k[ch] * l) * 0.7; }
    }
    const i = (y * W + x) * 4;
    for (let ch = 0; ch < 3; ch++) buf[i + ch] = Math.min(255, Math.round(buf[i + ch] * Math.min(1.5, m[ch])));
  }
  // 불씨 자체는 조명 영향 없이 원래 색 (스스로 빛남)
  drawEmber();
  for (const [c, r] of CRY) sprite(WC, 32, 0, 16, 16, c * 16, r * 16);

  const glow = (r, a, col, cx, cy) => `color=c=black@0:s=1200x632,format=rgba,geq=r=${col[0]}:g=${col[1]}:b=${col[2]}:a='${a}*255*exp(-((X-${cx})*(X-${cx})+(Y-${cy})*(Y-${cy}))/(2*${r}*${r}))'`;
  execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${W}x${H}`, '-i', '-',
    '-f', 'lavfi', '-i', glow(90, 0.22, [111, 184, 242], EX * 4, EY * 4), '-f', 'lavfi', '-i', glow(30, 0.5, [191, 234, 255], EX * 4, EY * 4),
    '-filter_complex', '[0]scale=1200:632:flags=neighbor,format=rgba[b];[b][1]overlay=format=auto[c];[c][2]overlay=format=auto,format=rgb24', '-frames:v', '1', out], { input: buf });
  execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', '-i', out, '-vf', 'crop=1200:630:0:0', out + '.c.png']);
  execFileSync('node', ['-e', `const fs=require('fs');fs.copyFileSync(${JSON.stringify(out + '.c.png')},${JSON.stringify(out)});fs.rmSync(${JSON.stringify(out + '.c.png')})`]);
}
