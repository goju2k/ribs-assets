// Demo 0 효과음 프리셋 (D-028, 계획서 3절). scripts/sfx-synth.mjs가 export/sfx/<id>.wav로 만든다.
// id = 이벤트 명령 `sfx <id>`에 쓰는 이름. candidate가 있으면 같은 자리의 후보 (사용자가 고르면 하나만 남김).
// 목소리 매개변수: wave(square|saw|tri|sine|noise) freq freqEnd curve duty attack hold decay decayPow vol delay vib{rate,depth} arp{at,mult} lp hp crush tremolo{rate,depth} seed
const S = [];
const add = (id, group, label, voices, extra = {}) => S.push({ id, group, label, voices, ...extra });

// ── 플레이어 ──
add('move-hum', '플레이어', '이동 (부유 웅웅) — 이동 중 반복', [
  { wave: 'sine', freq: 110, attack: 0.15, hold: 0.3, decay: 0.15, decayPow: 1, vol: 0.35, tremolo: { rate: 6, depth: 0.3 } },
  { wave: 'sine', freq: 166, attack: 0.15, hold: 0.3, decay: 0.15, decayPow: 1, vol: 0.15 },
], { note: '반복 재생용 (600ms)' });
add('dash-scatter', '플레이어', '대시 — 흩어짐 (출발)', [
  { wave: 'noise', freq: 800, freqEnd: 3200, decay: 0.18, hp: 400, vol: 0.35, seed: 3 },
  { wave: 'square', freq: 300, freqEnd: 900, duty: 0.25, decay: 0.14, vol: 0.15 },
]);
add('dash-gather', '플레이어', '대시 — 모임 (회복, 묵직하게)', [
  { wave: 'noise', freq: 3000, freqEnd: 600, decay: 0.2, lp: 3000, vol: 0.3, seed: 5 },
  { wave: 'sine', freq: 900, freqEnd: 300, decay: 0.2, vol: 0.2 },
  { wave: 'sine', freq: 120, freqEnd: 60, delay: 0.12, decay: 0.15, vol: 0.45 },
]);
add('fire-shoot', '플레이어', '불꽃탄 발사', [
  { wave: 'square', freq: 620, freqEnd: 300, duty: 0.25, decay: 0.12, vol: 0.22 },
  { wave: 'noise', freq: 2000, freqEnd: 800, decay: 0.1, lp: 4000, vol: 0.25, seed: 7 },
]);
add('fire-impact', '플레이어', '불꽃탄 착탄', [
  { wave: 'noise', freq: 1200, freqEnd: 300, decay: 0.22, lp: 2500, vol: 0.4, seed: 9 },
  { wave: 'sine', freq: 160, freqEnd: 60, decay: 0.15, vol: 0.3 },
]);
add('pillar-charge', '플레이어', '불기둥 — 시전 모음', [
  { wave: 'saw', freq: 120, freqEnd: 360, attack: 0.05, hold: 0.3, decay: 0.1, lp: 900, vol: 0.25, vib: { rate: 7, depth: 0.02 } },
  { wave: 'noise', freq: 500, freqEnd: 1500, attack: 0.3, decay: 0.1, lp: 2000, vol: 0.12, seed: 11 },
]);
add('pillar-burst', '플레이어', '불기둥 — 발동', [
  { wave: 'noise', freq: 300, freqEnd: 80, decay: 0.6, lp: 1500, vol: 0.5, seed: 13 },
  { wave: 'sine', freq: 80, freqEnd: 40, decay: 0.5, vol: 0.45 },
  { wave: 'noise', freq: 3000, decay: 0.15, hp: 2000, vol: 0.2, seed: 14 },
]);
add('ember-gain', '플레이어', '잔불 획득', [
  { wave: 'tri', freq: 880, arp: { at: 0.06, mult: 1.5 }, decay: 0.18, vol: 0.3 },
  { wave: 'sine', freq: 1760, delay: 0.06, decay: 0.12, vol: 0.15 },
]);
add('player-hit', '플레이어', '피격', [
  { wave: 'square', freq: 300, freqEnd: 120, decay: 0.15, crush: 8, vol: 0.35 },
  { wave: 'noise', freq: 1500, decay: 0.08, vol: 0.25, seed: 15 },
]);
add('player-down', '플레이어', '체력 0', [
  { wave: 'square', freq: 440, freqEnd: 55, curve: 0.5, decay: 0.8, lp: 2000, vol: 0.3 },
  { wave: 'noise', freq: 600, freqEnd: 100, decay: 0.6, lp: 800, vol: 0.2, seed: 17 },
]);

// ── 패링 (손맛의 절반: 성공음 후보 3) ──
add('parry-try', '패링', '패링 시도 (휙)', [
  { wave: 'noise', freq: 1500, freqEnd: 2600, attack: 0.01, decay: 0.09, hp: 1000, vol: 0.28, seed: 19 },
]);
add('parry-success-a', '패링', '패링 성공 A — 금속 "챙" (배음 여러 개)', [
  { wave: 'noise', freq: 6000, decay: 0.03, hp: 2000, vol: 0.6, seed: 21 },
  { wave: 'square', freq: 740, duty: 0.3, decay: 0.06, vol: 0.2 },
  { wave: 'sine', freq: 1480, decay: 0.5, vol: 0.38 },
  { wave: 'sine', freq: 2350, decay: 0.35, vol: 0.25 },
  { wave: 'sine', freq: 3720, decay: 0.2, vol: 0.15 },
], { candidate: 'parry-success' });
add('parry-success-b', '패링', '패링 성공 B — 밝은 종 + 위로 튐', [
  { wave: 'noise', freq: 8000, decay: 0.02, hp: 3000, vol: 0.45, seed: 23 },
  { wave: 'sine', freq: 1760, arp: { at: 0.05, mult: 1.5 }, decay: 0.45, vol: 0.38 },
  { wave: 'tri', freq: 2640, decay: 0.3, vol: 0.2 },
], { candidate: 'parry-success' });
add('parry-success-c', '패링', '패링 성공 C — 묵직한 "챙" (쿵 + 울림)', [
  { wave: 'noise', freq: 4000, decay: 0.05, vol: 0.45, seed: 25 },
  { wave: 'square', freq: 520, duty: 0.3, decay: 0.12, crush: 10, vol: 0.32 },
  { wave: 'sine', freq: 1046, decay: 0.5, vol: 0.35 },
  { wave: 'sine', freq: 1568, decay: 0.4, vol: 0.22 },
  { wave: 'sine', freq: 130, freqEnd: 65, decay: 0.2, vol: 0.45 },
], { candidate: 'parry-success' });
add('parry-fail', '패링', '패링 실패 (둔탁)', [
  { wave: 'sine', freq: 200, freqEnd: 90, decay: 0.15, vol: 0.4 },
  { wave: 'noise', freq: 400, decay: 0.1, lp: 800, vol: 0.25, seed: 27 },
]);

// ── 수호체 (예비동작 신호음 후보 3) ──
add('sentinel-awaken', '수호체', '각성 (돌이 깨어남)', [
  { wave: 'noise', freq: 200, freqEnd: 400, attack: 0.1, decay: 0.35, lp: 600, vol: 0.4, seed: 29 },
  { wave: 'sine', freq: 220, freqEnd: 440, attack: 0.2, hold: 0.1, decay: 0.2, vol: 0.2 },
  { wave: 'sine', freq: 660, delay: 0.3, decay: 0.2, vol: 0.15 },
]);
add('sentinel-cue-a', '수호체', '예비동작 신호 A — 높은 종 "핑"', [
  { wave: 'sine', freq: 2093, decay: 0.25, vol: 0.45 },
  { wave: 'sine', freq: 3136, decay: 0.18, vol: 0.2 },
], { candidate: 'sentinel-cue' });
add('sentinel-cue-b', '수호체', '예비동작 신호 B — 올라가는 두 음 "띠링"', [
  { wave: 'square', freq: 988, duty: 0.25, decay: 0.06, vol: 0.3 },
  { wave: 'square', freq: 1480, duty: 0.25, delay: 0.07, decay: 0.12, vol: 0.3 },
], { candidate: 'sentinel-cue' });
add('sentinel-cue-c', '수호체', '예비동작 신호 C — 반짝 + 위로 휨', [
  { wave: 'noise', freq: 8000, decay: 0.03, hp: 4000, vol: 0.2, seed: 31 },
  { wave: 'tri', freq: 1318, freqEnd: 1760, attack: 0.01, decay: 0.2, vol: 0.35 },
  { wave: 'sine', freq: 2637, delay: 0.03, decay: 0.15, vol: 0.15 },
], { candidate: 'sentinel-cue' });
add('sentinel-attack', '수호체', '근접 공격 (휘두름)', [
  { wave: 'noise', freq: 600, freqEnd: 200, attack: 0.02, decay: 0.18, lp: 1500, vol: 0.45, seed: 33 },
  { wave: 'sine', freq: 140, freqEnd: 70, decay: 0.15, vol: 0.35 },
]);
add('sentinel-hit', '수호체', '피격 (돌 딱)', [
  { wave: 'noise', freq: 3000, decay: 0.05, hp: 800, vol: 0.4, seed: 35 },
  { wave: 'square', freq: 220, freqEnd: 180, decay: 0.06, crush: 6, vol: 0.25 },
]);
add('sentinel-shutdown', '수호체', '정지 (빛이 꺼지며 부서짐)', [
  { wave: 'sine', freq: 880, freqEnd: 110, curve: 0.7, decay: 0.6, vol: 0.3 },
  { wave: 'noise', freq: 500, freqEnd: 150, delay: 0.2, decay: 0.4, lp: 900, vol: 0.3, seed: 37 },
  { wave: 'noise', freq: 4000, delay: 0.1, decay: 0.2, hp: 3000, vol: 0.12, seed: 38 },
]);

// ── 이벤트 ──
add('artifact', '이벤트', '아티팩트 (맥동 화음)', [
  { wave: 'sine', freq: 523, attack: 0.05, hold: 0.3, decay: 0.8, vol: 0.18 },
  { wave: 'sine', freq: 659, attack: 0.05, hold: 0.3, decay: 0.8, vol: 0.18 },
  { wave: 'sine', freq: 784, attack: 0.05, hold: 0.3, decay: 0.8, vol: 0.18 },
  { wave: 'tri', freq: 1046, attack: 0.1, hold: 0.2, decay: 0.8, vib: { rate: 6, depth: 0.01 }, vol: 0.12 },
]);
add('form-change', '이벤트', '폼체인지 (처음으로 따뜻한 소리)', [
  { wave: 'saw', freq: 110, freqEnd: 440, attack: 0.4, hold: 0.2, decay: 0.6, lp: 1800, vol: 0.22 },
  { wave: 'sine', freq: 220, freqEnd: 880, attack: 0.4, hold: 0.2, decay: 0.6, vol: 0.2 },
  { wave: 'noise', freq: 200, freqEnd: 2000, attack: 0.5, decay: 0.5, lp: 3000, vol: 0.12, seed: 39 },
  { wave: 'sine', freq: 523, delay: 0.7, attack: 0.02, decay: 0.8, vol: 0.2 },
  { wave: 'sine', freq: 784, delay: 0.7, attack: 0.02, decay: 0.8, vol: 0.15 },
]);
add('door-open', '이벤트', '문 열림 (돌 미끄러짐)', [
  { wave: 'noise', freq: 150, freqEnd: 250, attack: 0.05, hold: 0.3, decay: 0.2, lp: 500, vol: 0.45, seed: 41 },
  { wave: 'sine', freq: 60, hold: 0.3, decay: 0.2, vol: 0.2 },
]);
add('vine-burn', '이벤트', '덩굴 탐 (탁탁)', [
  { wave: 'noise', freq: 2500, decay: 0.35, hp: 1500, vol: 0.25, tremolo: { rate: 30, depth: 0.8 }, seed: 43 },
  { wave: 'noise', freq: 600, freqEnd: 200, decay: 0.4, lp: 1200, vol: 0.25, seed: 44 },
]);

// ── 동반자 · UI ──
add('companion-blip-a', '동반자·UI', '동반자 말소리 a (대사 글자마다, a·b·c를 번갈아)', [ { wave: 'tri', freq: 1200, freqEnd: 1260, attack: 0.003, decay: 0.04, vol: 0.3 } ]);
add('companion-blip-b', '동반자·UI', '동반자 말소리 b', [ { wave: 'tri', freq: 1400, freqEnd: 1470, attack: 0.003, decay: 0.04, vol: 0.3 } ]);
add('companion-blip-c', '동반자·UI', '동반자 말소리 c', [ { wave: 'tri', freq: 1050, freqEnd: 1100, attack: 0.003, decay: 0.04, vol: 0.3 } ]);
add('emote', '동반자·UI', '감정 표시 (뿅)', [ { wave: 'sine', freq: 600, freqEnd: 1200, decay: 0.08, vol: 0.3 } ]);
add('ui-select', '동반자·UI', 'UI 선택', [ { wave: 'square', freq: 880, decay: 0.04, vol: 0.18 } ]);
add('ui-confirm', '동반자·UI', 'UI 결정', [ { wave: 'square', freq: 880, arp: { at: 0.05, mult: 1.5 }, decay: 0.12, vol: 0.2 } ]);

export const SOUNDS = S;
