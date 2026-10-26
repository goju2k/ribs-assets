// 리얼 사운드 효과음 만들기 (D-030): audio/sfx-real-recipes.mjs → export/sfx/<id>.wav + index.json
// 녹음 재료(audio/sfx-src/, 모두 CC0)를 ffmpeg로 자르고·음높이·EQ·겹치기·지연·잔향 통일·음량 맞춤.
// 사용: node scripts/sfx-real.mjs [--only id,id] [--drop v<n>]
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ROOT = resolve(import.meta.dirname, '..');
const FF = process.env.FFMPEG || 'C:/Users/User/AppData/Local/Microsoft/WinGet/Links/ffmpeg.exe';
const SRC = join(ROOT, 'audio', 'sfx-src');
const OUT = join(ROOT, 'export', 'sfx');
const { SOUNDS, REVERB, SOURCES } = await import(pathToFileURL(join(ROOT, 'audio', 'sfx-real-recipes.mjs')).href);
const args = process.argv.slice(2);
const only = args.includes('--only') ? args[args.indexOf('--only') + 1].split(',') : null;

const file = key => { const s = SOURCES[key]; if (!s) throw new Error('재료 없음: ' + key); return join(SRC, s.file); };
const ff = a => execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', ...a], { stdio: ['ignore', 'pipe', 'pipe'] });

function chain(l, i) {
  const f = [];
  if (l.ss != null || l.t != null) f.push(`atrim=${l.ss ?? 0}${l.t != null ? ':' + ((l.ss ?? 0) + l.t) : ''}`, 'asetpts=PTS-STARTPTS');
  f.push('aformat=sample_rates=44100:channel_layouts=mono');
  if (l.rev) f.push('areverse');
  if (l.rate && l.rate !== 1) f.push(`asetrate=${Math.round(44100 * l.rate)}`, 'aresample=44100');
  if (l.hp) f.push(`highpass=f=${l.hp}`);
  if (l.lp) f.push(`lowpass=f=${l.lp}`);
  if (l.eq) f.push(...l.eq);
  if (l.fi) f.push(`afade=t=in:d=${l.fi}`);
  if (l.fo) { const dur = (l.t ?? 1) / (l.rate ?? 1); f.push(`afade=t=out:st=${Math.max(0, dur - l.fo).toFixed(3)}:d=${l.fo}`); }
  f.push(`volume=${l.gain ?? 0}dB`);
  if (l.delay) f.push(`adelay=${l.delay}`);
  return `[${i}:a]${f.join(',')}[l${i}]`;
}

function render(s) {
  const tmp = join(OUT, `_tmp_${s.id}.wav`);
  const inputs = s.layers.flatMap(l => ['-i', file(l.src)]);
  const parts = s.layers.map(chain);
  const mix = s.layers.length > 1 ? `${s.layers.map((_, i) => `[l${i}]`).join('')}amix=inputs=${s.layers.length}:normalize=0:duration=longest` : `[l0]anull`;
  const rv = REVERB[s.reverb ?? 'room'];
  const graph = [...parts, `${mix}${rv ? ',' + rv : ''},apad=pad_dur=${s.tail ?? 0.05}[out]`].join(';');
  ff([...inputs, '-filter_complex', graph, '-map', '[out]', '-ac', '1', '-c:a', 'pcm_s16le', tmp]);
  return tmp;
}

function maxVolume(f) {
  const r = require_spawn(f);
  const m = /max_volume: (-?[\d.]+) dB/.exec(r); return m ? +m[1] : 0;
}
function require_spawn(f) { const r = spawnSync(FF, ['-hide_banner', '-nostats', '-i', f, '-af', 'volumedetect', '-f', 'null', '-'], { encoding: 'utf8' }); return r.stderr; }
function durationOf(f) { const r = spawnSync(FF, ['-hide_banner', '-i', f], { encoding: 'utf8' }); const m = /Duration: (\d+):(\d+):([\d.]+)/.exec(r.stderr); return m ? Math.round((+m[1] * 3600 + +m[2] * 60 + +m[3]) * 1000) : 0; }

mkdirSync(OUT, { recursive: true });
if (!only) for (const f of readdirSync(OUT)) if (f.endsWith('.wav')) rmSync(join(OUT, f)); // 예전 합성음 정리
const index = [];
for (const s of SOUNDS) {
  if (only && !only.includes(s.id)) continue;
  const tmp = render(s);
  const gain = (s.peak ?? -3) - maxVolume(tmp);
  ff(['-i', tmp, '-af', `volume=${gain.toFixed(2)}dB,afade=t=out:st=${Math.max(0, durationOf(tmp) / 1000 - 0.02)}:d=0.02`, '-ac', '1', '-c:a', 'pcm_s16le', join(OUT, `${s.id}.wav`)]);
  rmSync(tmp);
  index.push({ id: s.id, group: s.group, label: s.label, note: s.note ?? '', candidate: s.candidate ?? null, ms: durationOf(join(OUT, `${s.id}.wav`)), sources: [...new Set(s.layers.map(l => l.src))] });
  process.stdout.write('.');
}
if (!only) writeFileSync(join(OUT, 'index.json'), JSON.stringify(index, null, 1) + '\n');
console.log(`\n✓ export/sfx: ${index.length}개`);

if (args.includes('--drop')) {
  const dest = join('C:/github-clones/_asset-drop/sfx', args[args.indexOf('--drop') + 1]);
  if (existsSync(dest)) { console.error('이미 있음: ' + dest); process.exit(1); }
  mkdirSync(dest, { recursive: true });
  for (const f of [...index.map(x => x.id + '.wav'), 'index.json']) copyFileSync(join(OUT, f), join(dest, f));
  console.log('→ 전달: ' + dest);
}
