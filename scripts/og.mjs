// 공유 미리보기 og-image.png (1200×630) + 탭 아이콘 (D-050)
// og: aseprite og-build.lua(400×210 픽셀) → 정수 3배 → 불씨 빛 번짐만 부드럽게(가우시안 두 겹, 화면 더하기). 300KB 넘으면 256색으로 줄임
// 아이콘: icon-32.png, icon-192.png, apple-touch-icon.png(180, 바탕 #0b0910) + favicon.ico(16·32·48 PNG 묶음). 이름은 엔진방 태그에 맞춤
// 사용: node scripts/og.mjs [--drop v<n>]
import { execFileSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..');
const FF = process.env.FFMPEG || 'C:/Users/User/AppData/Local/Microsoft/WinGet/Links/ffmpeg.exe';
const ASE = process.env.ASEPRITE || 'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe';
const OUT = join(ROOT, 'export', 'web'); mkdirSync(OUT, { recursive: true });
const LUA = join(ROOT, 'aseprite', '_shared', 'og-build.lua');
const ff = a => execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', ...a]);
const ase = p => execFileSync(ASE, ['-b', ...Object.entries(p).flatMap(([k, v]) => ['--script-param', `${k}=${v}`]), '--script', LUA]);

// 1) og
const base = join(OUT, '_og-base.png');
ase({ which: 'og', root: ROOT, out: base });
const glow = (r, a, col) => `color=c=black@0:s=1200x630,format=rgba,geq=r=${col[0]}:g=${col[1]}:b=${col[2]}:a='${a}*255*exp(-((X-600)*(X-600)+(Y-250)*(Y-250))/(2*${r}*${r}))'`;
const og = join(OUT, 'og-image.png');
ff(['-i', base, '-f', 'lavfi', '-i', glow(110, 0.30, [111, 184, 242]), '-f', 'lavfi', '-i', glow(36, 0.55, [191, 234, 255]),
  '-filter_complex', '[0]scale=1200:630:flags=neighbor,format=rgba[b];[b][1]overlay=format=auto[c];[c][2]overlay=format=auto,format=rgb24', '-frames:v', '1', og]);
if (statSync(og).size > 300 * 1024) {
  ff(['-i', og, '-filter_complex', '[0]split[a][b];[a]palettegen=max_colors=256[p];[b][p]paletteuse=dither=none', '-frames:v', '1', og + '.tmp.png']);
  copyFileSync(og + '.tmp.png', og); execFileSync('node', ['-e', `require('fs').rmSync(${JSON.stringify(og + '.tmp.png')}); require('fs').rmSync(${JSON.stringify(base)})`]);
} else execFileSync('node', ['-e', `require('fs').rmSync(${JSON.stringify(base)})`]);

// 2) 아이콘: 크기마다 직접 그린 판(art) × 정수 배율
const ICONS = [['_ico-16.png', 16, 1], ['icon-32.png', 16, 2], ['_ico-48.png', 16, 3], ['icon-192.png', 32, 6], ['apple-touch-icon.png', 30, 6]];
for (const [name, art, k] of ICONS) {
  const tmp = join(OUT, `_icon-${art}.png`);
  ase({ which: 'icon', size: art, out: tmp });
  ff(['-i', tmp, '-vf', `scale=${art * k}:${art * k}:flags=neighbor`, join(OUT, name)]);
}
// favicon.ico: PNG 세 장(16·32·48)을 담은 ICO (Vista 이후 브라우저 모두 지원)
const SIZES = [16, 32, 48];
const pngs = ['_ico-16.png', 'icon-32.png', '_ico-48.png'].map(f => readFileSync(join(OUT, f)));
const head = Buffer.alloc(6 + 16 * pngs.length); head.writeUInt16LE(0, 0); head.writeUInt16LE(1, 2); head.writeUInt16LE(pngs.length, 4);
let off = head.length;
pngs.forEach((p, i) => { const s = SIZES[i], e = 6 + i * 16;
  head.writeUInt8(s, e); head.writeUInt8(s, e + 1); head.writeUInt8(0, e + 2); head.writeUInt8(0, e + 3);
  head.writeUInt16LE(1, e + 4); head.writeUInt16LE(32, e + 6); head.writeUInt32LE(p.length, e + 8); head.writeUInt32LE(off, e + 12); off += p.length; });
writeFileSync(join(OUT, 'favicon.ico'), Buffer.concat([head, ...pngs]));
for (const f of [16, 30, 32].map(a => join(OUT, `_icon-${a}.png`)).concat([join(OUT, '_ico-16.png'), join(OUT, '_ico-48.png')])) if (existsSync(f)) execFileSync('node', ['-e', `require('fs').rmSync(${JSON.stringify(f)})`]);

const FILES = ['og-image.png', 'favicon.ico', 'icon-32.png', 'icon-192.png', 'apple-touch-icon.png'];
for (const f of FILES) console.log(`${f}\t${(statSync(join(OUT, f)).size / 1024).toFixed(1)}KB`);
const di = process.argv.indexOf('--drop');
if (di > 0) {
  const dest = join('C:/github-clones/_asset-drop/site-icons', process.argv[di + 1]);
  if (existsSync(dest)) { console.error('이미 있음: ' + dest); process.exit(1); }
  mkdirSync(dest, { recursive: true });
  for (const f of FILES) copyFileSync(join(OUT, f), join(dest, f));
  console.log('→ 전달: ' + dest);
}
