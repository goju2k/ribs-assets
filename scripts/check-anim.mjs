// .anim.json 검사 (docs/asset-contract.md): 스키마 규칙 + 스키마로 표현 못 하는 규칙. 의존성 없음.
// 사용: node scripts/check-anim.mjs <파일.anim.json> [...]   — 문제 있으면 종료 코드 1
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';

const CONTRACT = 1;
const NAME = /^[a-z0-9-]+$/;
const TAG = /^[a-z0-9-]+:[a-z0-9-]+$/;
const isInt = (v, min = 0) => Number.isInteger(v) && v >= min;
const isPair = v => Array.isArray(v) && v.length === 2 && v.every(n => isInt(n));

function pngSize(file) {
  const b = readFileSync(file);
  if (b.readUInt32BE(0) !== 0x89504e47 || b.toString('ascii', 12, 16) !== 'IHDR') throw new Error('png가 아님');
  return [b.readUInt32BE(16), b.readUInt32BE(20)];
}

function check(file) {
  const errs = [];
  const err = m => errs.push(m);
  let a;
  try { a = JSON.parse(readFileSync(file, 'utf8')); } catch (e) { return [`읽기 실패: ${e.message}`]; }

  const allowed = ['contract', 'id', 'texture', 'frameSize', 'anchor', 'source', 'clips'];
  for (const k of Object.keys(a)) if (!allowed.includes(k)) err(`모르는 필드: ${k}`);
  if (a.contract !== CONTRACT) err(`contract는 ${CONTRACT}이어야 함 (지금 ${a.contract})`);
  if (typeof a.id !== 'string' || !NAME.test(a.id)) err('id: 소문자·숫자·하이픈');
  if (typeof a.texture !== 'string' || !a.texture.endsWith('.png')) err('texture: .png 경로');
  if (!isPair(a.frameSize) || a.frameSize.some(n => n < 1)) err('frameSize: [w, h] 양의 정수');
  if (!isPair(a.anchor)) err('anchor: [x, y] 정수 (필수)');
  if (a.source !== undefined && !/^ribs-assets@[0-9a-f]{7,40}$/.test(a.source)) err('source: ribs-assets@<커밋>');
  if (!a.clips || typeof a.clips !== 'object' || !Object.keys(a.clips).length) err('clips: 하나 이상');

  let size = null;
  if (typeof a.texture === 'string') {
    try { size = pngSize(join(dirname(file), a.texture)); } catch (e) { err(`texture 열기 실패: ${e.message}`); }
  }
  const [fw, fh] = isPair(a.frameSize) ? a.frameSize : [0, 0];
  if (isPair(a.anchor) && fw && (a.anchor[0] > fw || a.anchor[1] > fh)) err(`anchor ${a.anchor}가 프레임(${fw}x${fh}) 밖`);

  for (const [name, clip] of Object.entries(a.clips || {})) {
    const at = `clips.${name}`;
    if (!NAME.test(name)) err(`${at}: 이름은 소문자·숫자·하이픈`);
    for (const k of Object.keys(clip)) if (!['loop', 'frames'].includes(k)) err(`${at}: 모르는 필드 ${k}`);
    if (typeof clip.loop !== 'boolean') err(`${at}.loop: true/false`);
    if (!Array.isArray(clip.frames) || !clip.frames.length) { err(`${at}.frames: 하나 이상`); continue; }
    clip.frames.forEach((f, i) => {
      const fa = `${at}.frames[${i}]`;
      for (const k of Object.keys(f)) if (!['sx', 'sy', 'sWidth', 'sHeight', 'durationMs', 'tags'].includes(k)) err(`${fa}: 모르는 필드 ${k}`);
      if (!isInt(f.sx) || !isInt(f.sy)) err(`${fa}: sx/sy 0 이상 정수`);
      if (!isInt(f.durationMs, 1)) err(`${fa}: durationMs 1 이상 정수`);
      if (f.sWidth !== fw || f.sHeight !== fh) err(`${fa}: 크기 ${f.sWidth}x${f.sHeight} ≠ frameSize ${fw}x${fh}`);
      if (size && (f.sx + f.sWidth > size[0] || f.sy + f.sHeight > size[1])) err(`${fa}: 사각형이 png(${size[0]}x${size[1]}) 밖`);
      if (f.tags !== undefined && (!Array.isArray(f.tags) || f.tags.some(t => !TAG.test(t)))) err(`${fa}.tags: <동작>:<구간>`);
    });
  }
  return errs;
}

const files = process.argv.slice(2);
if (!files.length) { console.error('사용: node scripts/check-anim.mjs <파일.anim.json> [...]'); process.exit(2); }
let bad = 0;
for (const f of files) {
  const errs = check(f);
  if (errs.length) { bad++; console.log(`✗ ${f}`); for (const e of errs) console.log(`  - ${e}`); }
  else console.log(`✓ ${f}`);
}
process.exit(bad ? 1 : 0);
