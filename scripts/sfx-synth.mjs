// 효과음 합성기 (sfxr 계열, 의존성 없음): audio/sfx-presets.mjs → export/sfx/<id>.wav + export/sfx/index.json
// 사용: node scripts/sfx-synth.mjs [--drop v<n>]
// 소리 하나 = 목소리(voice) 여러 겹. 목소리: 파형 + 음높이(시작→끝 미끄러짐) + 엔벨로프 + 비브라토 + 음 뛰기(arp) + 필터
import { mkdirSync, writeFileSync, existsSync, copyFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ROOT = resolve(import.meta.dirname, '..');
const RATE = 44100;
const OUT = join(ROOT, 'export', 'sfx');
const { SOUNDS } = await import(pathToFileURL(join(ROOT, 'audio', 'sfx-presets.mjs')).href);

function rng(seed) { let s = seed >>> 0 || 1; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

function renderVoice(v, buf) {
  const r = rng(v.seed ?? 1);
  const start = Math.floor((v.delay ?? 0) * RATE);
  const a = v.attack ?? 0.002, h = v.hold ?? 0, d = v.decay ?? 0.2, dur = a + h + d;
  const n = Math.floor(dur * RATE);
  let phase = 0, noiseVal = 0, lp = 0, hpIn = 0, hpOut = 0;
  const lpA = v.lp ? 1 - Math.exp(-2 * Math.PI * v.lp / RATE) : 1;
  const hpA = v.hp ? Math.exp(-2 * Math.PI * v.hp / RATE) : 0;
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const t = i / RATE, u = t / dur;
    // 음높이: 시작 → 끝 (지수 미끄러짐), 음 뛰기, 비브라토
    let f = v.freq * Math.pow((v.freqEnd ?? v.freq) / v.freq, Math.pow(u, v.curve ?? 1));
    if (v.arp && t >= v.arp.at) f *= v.arp.mult;
    if (v.vib) f *= 1 + v.vib.depth * Math.sin(2 * Math.PI * v.vib.rate * t);
    const prev = phase; phase = (phase + f / RATE) % 1;
    let s;
    switch (v.wave) {
      case 'square': s = phase < (v.duty ?? 0.5) ? 1 : -1; break;
      case 'saw': s = 2 * phase - 1; break;
      case 'tri': s = 1 - 4 * Math.abs(phase - 0.5); break;
      case 'sine': s = Math.sin(2 * Math.PI * phase); break;
      case 'noise': if (phase < prev) noiseVal = r() * 2 - 1; s = noiseVal; break; // 주기마다 새 값 (음높이 있는 잡음)
      default: throw new Error('파형 ' + v.wave);
    }
    // 엔벨로프 (공격 → 유지 → 감쇠, 감쇠는 지수형)
    let env = t < a ? t / a : t < a + h ? 1 : Math.pow(1 - (t - a - h) / d, v.decayPow ?? 2);
    if (v.tremolo) env *= 1 - v.tremolo.depth * (0.5 + 0.5 * Math.sin(2 * Math.PI * v.tremolo.rate * t));
    s *= env * (v.vol ?? 0.5);
    lp += lpA * (s - lp); s = v.lp ? lp : s;                       // 1극 저역 통과
    if (v.hp) { const o = hpA * (hpOut + s - hpIn); hpIn = s; hpOut = o; s = o; } // 1극 고역 통과
    if (v.crush) s = Math.round(s * v.crush) / v.crush;            // 비트 줄이기 (거친 맛)
    buf[start + i] += s;
  }
}

function render(sound) {
  const len = Math.max(...sound.voices.map(v => (v.delay ?? 0) + (v.attack ?? 0.002) + (v.hold ?? 0) + (v.decay ?? 0.2)));
  const buf = new Float32Array(Math.ceil((len + 0.02) * RATE));
  for (const v of sound.voices) renderVoice(v, buf);
  const gain = sound.gain ?? 1;
  let peak = 0;
  for (let i = 0; i < buf.length; i++) { buf[i] = Math.tanh(buf[i] * gain * 1.2); peak = Math.max(peak, Math.abs(buf[i])); } // 부드러운 자르기
  // 짧은 페이드아웃 (끝 딸깍 방지)
  for (let i = 0; i < 200 && i < buf.length; i++) buf[buf.length - 1 - i] *= i / 200;
  return { buf, peak, ms: Math.round(buf.length / RATE * 1000) };
}

function wav(buf) {
  const b = Buffer.alloc(44 + buf.length * 2);
  b.write('RIFF', 0); b.writeUInt32LE(36 + buf.length * 2, 4); b.write('WAVE', 8);
  b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(1, 22);
  b.writeUInt32LE(RATE, 24); b.writeUInt32LE(RATE * 2, 28); b.writeUInt16LE(2, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(buf.length * 2, 40);
  for (let i = 0; i < buf.length; i++) b.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(buf[i] * 32767))), 44 + i * 2);
  return b;
}

mkdirSync(OUT, { recursive: true });
const index = [];
for (const s of SOUNDS) {
  const { buf, peak, ms } = render(s);
  writeFileSync(join(OUT, `${s.id}.wav`), wav(buf));
  index.push({ id: s.id, group: s.group, label: s.label, note: s.note ?? '', candidate: s.candidate ?? null, ms, peak: +peak.toFixed(2) });
}
writeFileSync(join(OUT, 'index.json'), JSON.stringify(index, null, 1) + '\n');
console.log(`✓ export/sfx: ${index.length}개`);

const [flag, ver] = process.argv.slice(2);
if (flag === '--drop') {
  const dest = join('C:/github-clones/_asset-drop/sfx', ver);
  if (existsSync(dest)) { console.error('이미 있음: ' + dest); process.exit(1); }
  mkdirSync(dest, { recursive: true });
  for (const f of [...index.map(x => x.id + '.wav'), 'index.json']) copyFileSync(join(OUT, f), join(dest, f));
  console.log('→ 전달: ' + dest);
}
