// 배경음 만들기: audio/bgm-src/ → export/bgm/<id>.ogg (vorbis) + <id>.m4a (AAC, 예전 사파리 대체) + loop-check/<id>-seam.ogg
// D-049: 웹 용량 줄임 — 곡당 약 1~1.5MB. 드론(part0)은 모노 + 낮은 비트레이트, 반복 구간도 줄임.
// 반복: 끝 xf초를 처음 xf초에 겹쳐(엇갈린 페이드) 이음매 없이 → 파일 전체를 그대로 반복 재생 (loopStart 0, loopEnd = 끝)
// 사용: node scripts/bgm.mjs [--drop v<n>]
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

const ROOT = resolve(import.meta.dirname, '..');
const FF = process.env.FFMPEG || 'C:/Users/User/AppData/Local/Microsoft/WinGet/Links/ffmpeg.exe';
const SRC = join(ROOT, 'audio', 'bgm-src'), OUT = join(ROOT, 'export', 'bgm');
const ff = a => execFileSync(FF, ['-hide_banner', '-loglevel', 'error', '-y', ...a], { stdio: ['ignore', 'pipe', 'pipe'] });
const dur = f => { const m = /Duration: (\d+):(\d+):([\d.]+)/.exec(spawnSync(FF, ['-hide_banner', '-i', f], { encoding: 'utf8' }).stderr); return +m[1] * 3600 + +m[2] * 60 + +m[3]; };

// ss/to: 원본에서 쓸 구간(초, to 음수 = 끝에서), xf: 겹침 초(0 = 원곡 그대로 반복), ch: 채널, ogg/m4a: 비트레이트
const TRACKS = [
  { id: 'bgm-part0', src: 'dungeon002.ogg', ss: 0.93, len: 104, xf: 4, ch: 1, ogg: '40k', m4a: '48k' },   // 거의 소리 없는 드론 → 모노, 100초 반복
  { id: 'bgm-part1', src: 'dark-shrine-loop.ogg', ss: 0, to: -1.5, xf: 3, ch: 2, ogg: '80k', m4a: '96k' },
  { id: 'bgm-boss', src: 'boss-battle-theme.mp3', ss: 0, xf: 0, ch: 2, ogg: '64k', m4a: '64k' },           // 원곡이 반복용 — 길이 그대로
];

mkdirSync(join(OUT, 'loop-check'), { recursive: true });
const rows = [];
for (const t of TRACKS) {
  const src = join(SRC, t.src);
  const total = dur(src);
  const T = t.len ?? (t.to != null ? total + t.to - t.ss : total - t.ss);
  const base = `atrim=${t.ss}:${t.ss + T},asetpts=PTS-STARTPTS,aformat=sample_rates=44100:channel_layouts=${t.ch === 1 ? 'mono' : 'stereo'}`;
  const graph = t.xf
    ? `[0:a]${base},asplit=3[a][b][c];` +
      `[a]atrim=0:${t.xf},asetpts=PTS-STARTPTS,afade=t=in:d=${t.xf}[h];` +
      `[b]atrim=${T - t.xf}:${T},asetpts=PTS-STARTPTS,afade=t=out:d=${t.xf}[e];` +
      `[h][e]amix=inputs=2:normalize=0[x];` +
      `[c]atrim=${t.xf}:${T - t.xf},asetpts=PTS-STARTPTS[m];[x][m]concat=n=2:v=0:a=1[out]`
    : `[0:a]${base}[out]`;
  const wav = join(OUT, `_tmp_${t.id}.wav`);
  ff(['-i', src, '-filter_complex', graph, '-map', '[out]', '-c:a', 'pcm_s16le', wav]);
  ff(['-i', wav, '-c:a', 'libvorbis', '-b:a', t.ogg, join(OUT, `${t.id}.ogg`)]);
  ff(['-i', wav, '-c:a', 'aac', '-b:a', t.m4a, '-movflags', '+faststart', join(OUT, `${t.id}.m4a`)]);
  const L = dur(wav);   // 이음매 확인: 끝 4초 + 처음 4초
  ff(['-i', wav, '-filter_complex', `[0:a]asplit[p][q];[p]atrim=${L - 4}:${L},asetpts=PTS-STARTPTS[e];[q]atrim=0:4,asetpts=PTS-STARTPTS[s];[e][s]concat=n=2:v=0:a=1[o]`, '-map', '[o]', '-c:a', 'libvorbis', '-b:a', t.ogg, join(OUT, 'loop-check', `${t.id}-seam.ogg`)]);
  execFileSync('node', ['-e', `require('fs').rmSync(${JSON.stringify(wav)})`]);
  rows.push({ id: t.id, sec: L.toFixed(1), ch: t.ch, ogg: statSync(join(OUT, `${t.id}.ogg`)).size, m4a: statSync(join(OUT, `${t.id}.m4a`)).size });
}
for (const r of rows) console.log(`${r.id}\t${r.sec}s\t${r.ch === 1 ? 'mono' : 'stereo'}\togg ${(r.ogg / 1024).toFixed(0)}KB\tm4a ${(r.m4a / 1024).toFixed(0)}KB`);

const di = process.argv.indexOf('--drop');
if (di > 0) {
  const dest = join('C:/github-clones/_asset-drop/bgm', process.argv[di + 1]);
  if (existsSync(dest)) { console.error('이미 있음: ' + dest); process.exit(1); }
  mkdirSync(dest, { recursive: true });
  for (const r of rows) for (const ext of ['ogg', 'm4a']) copyFileSync(join(OUT, `${r.id}.${ext}`), join(dest, `${r.id}.${ext}`));
  console.log('→ 전달: ' + dest);
}
