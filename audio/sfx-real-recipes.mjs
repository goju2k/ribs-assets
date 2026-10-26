// Demo 0 효과음 v3 — 리얼 사운드 (D-030). scripts/sfx-real.mjs가 export/sfx/<id>.wav로 만든다.
// id = sounds.json의 28개 id 그대로. candidate가 있으면 같은 자리의 후보 (PICK에서 하나 고름).
// 질감 (스타일 가이드 10-b): 불씨·불 = 실제 불꽃(따뜻함) / 봉인·수호체 = 돌과 금속, 차가운 공명 / 동반자 = 작은 유리·종 / UI = 나무·돌·종
// 겹(layer): src(재료 키) ss(시작초) t(길이초) rate(음높이·속도 배율) rev(뒤집기) gain(dB) delay(ms) hp lp fi fo(페이드초) eq(ffmpeg 필터 배열)

export const SOURCES = {
  // Kenney (CC0) https://kenney.nl
  bell0: { file: 'kenney/impactBell_heavy_000.ogg', by: 'Kenney — Impact Sounds' },
  bell1: { file: 'kenney/impactBell_heavy_001.ogg', by: 'Kenney — Impact Sounds' },
  bell2: { file: 'kenney/impactBell_heavy_002.ogg', by: 'Kenney — Impact Sounds' },
  plateL0: { file: 'kenney/impactPlate_light_000.ogg', by: 'Kenney — Impact Sounds' },
  plateH0: { file: 'kenney/impactPlate_heavy_000.ogg', by: 'Kenney — Impact Sounds' },
  plateM0: { file: 'kenney/impactPlate_medium_000.ogg', by: 'Kenney — Impact Sounds' },
  metalL0: { file: 'kenney/impactMetal_light_000.ogg', by: 'Kenney — Impact Sounds' },
  glass0: { file: 'kenney/impactGlass_light_000.ogg', by: 'Kenney — Impact Sounds' },
  glass1: { file: 'kenney/impactGlass_light_001.ogg', by: 'Kenney — Impact Sounds' },
  glass2: { file: 'kenney/impactGlass_light_002.ogg', by: 'Kenney — Impact Sounds' },
  glass3: { file: 'kenney/impactGlass_light_003.ogg', by: 'Kenney — Impact Sounds' },
  mine0: { file: 'kenney/impactMining_000.ogg', by: 'Kenney — Impact Sounds' },
  mine1: { file: 'kenney/impactMining_001.ogg', by: 'Kenney — Impact Sounds' },
  mine3: { file: 'kenney/impactMining_003.ogg', by: 'Kenney — Impact Sounds' },
  softH: { file: 'kenney/impactSoft_heavy_000.ogg', by: 'Kenney — Impact Sounds' },
  softM: { file: 'kenney/impactSoft_medium_000.ogg', by: 'Kenney — Impact Sounds' },
  punchM: { file: 'kenney/impactPunch_medium_000.ogg', by: 'Kenney — Impact Sounds' },
  punchH: { file: 'kenney/impactPunch_heavy_000.ogg', by: 'Kenney — Impact Sounds' },
  woodL0: { file: 'kenney/impactWood_light_000.ogg', by: 'Kenney — Impact Sounds' },
  woodL1: { file: 'kenney/impactWood_light_001.ogg', by: 'Kenney — Impact Sounds' },
  woodM: { file: 'kenney/impactWood_medium_000.ogg', by: 'Kenney — Impact Sounds' },
  cloth1: { file: 'kenney/cloth1.ogg', by: 'Kenney — RPG Audio' },
  cloth2: { file: 'kenney/cloth2.ogg', by: 'Kenney — RPG Audio' },
  cloth3: { file: 'kenney/cloth3.ogg', by: 'Kenney — RPG Audio' },
  knife1: { file: 'kenney/drawKnife1.ogg', by: 'Kenney — RPG Audio' },
  knife2: { file: 'kenney/drawKnife2.ogg', by: 'Kenney — RPG Audio' },
  door1: { file: 'kenney/doorOpen_1.ogg', by: 'Kenney — RPG Audio' },
  // Freesound (CC0, 공개 미리듣기 파일)
  whoosh: { file: 'freesound/fs-244926.mp3', by: 'hnhnh — fire-whoosh.wav', url: 'https://freesound.org/people/hnhnh/sounds/244926/' },
  crackleA: { file: 'freesound/fs-414767.mp3', by: 'samarobryn — Crackling Fire', url: 'https://freesound.org/people/samarobryn/sounds/414767/' },
  crackleB: { file: 'freesound/fs-370938.mp3', by: 'jmehlferber — fire-crackling.wav', url: 'https://freesound.org/people/jmehlferber/sounds/370938/' },
  crackleC: { file: 'freesound/fs-563766.mp3', by: 'florianreichelt — fire crackles', url: 'https://freesound.org/people/florianreichelt/sounds/563766/' },
  torch: { file: 'freesound/fs-483692.mp3', by: 'LordStirling — torch ambience loop (30~50초 구간)', url: 'https://freesound.org/people/LordStirling/sounds/483692/' },
  scrapeV: { file: 'freesound/fs-802691.mp3', by: 'Vrymaa — Stone heavy - Scraping concrete', url: 'https://freesound.org/people/Vrymaa/sounds/802691/' },
  scrapeC: { file: 'freesound/fs-738784.mp3', by: 'CheatinSloth — Heavy Stone Scraping, Being Dragged', url: 'https://freesound.org/people/CheatinSloth/sounds/738784/' },
  scrapeAxe: { file: 'freesound/fs-321488.mp3', by: 'dslrguide — Scraping Stone', url: 'https://freesound.org/people/dslrguide/sounds/321488/' },
  bowl: { file: 'freesound/fs-439235.mp3', by: 'zambolino — singing bowl.wav', url: 'https://freesound.org/people/zambolino/sounds/439235/' },
  wine: { file: 'freesound/fs-193823.mp3', by: 'jhumbucker — Wine glass tinkles', url: 'https://freesound.org/people/jhumbucker/sounds/193823/' },
  ceramic: { file: 'freesound/fs-209014.mp3', by: 'OwlStorm — Ceramic Tink', url: 'https://freesound.org/people/OwlStorm/sounds/209014/' },
  clang: { file: 'freesound/fs-184343.mp3', by: 'jashstudios — Metal Clang', url: 'https://freesound.org/people/jashstudios/sounds/184343/' },
  tinkle: { file: 'freesound/fs-640717.mp3', by: 'soundofsong — bells tinkling end.wav', url: 'https://freesound.org/people/soundofsong/sounds/640717/' },
};

// 잔향 통일: room = 좁은 돌 통로, stone = 차가운 공명(봉인·수호체), hall = 넓은 공간(아티팩트·폼체인지)
export const REVERB = {
  none: null,
  room: 'aecho=0.8:0.6:38|67:0.16|0.09',
  stone: 'aecho=0.8:0.7:55|110|175:0.24|0.16|0.09',
  hall: 'aecho=0.8:0.8:90|190|310:0.30|0.20|0.12',
};

const S = [];
const add = (id, group, label, layers, o = {}) => S.push({ id, group, label, layers, ...o });

// ── 불씨·플레이어 (실제 불꽃, 따뜻함) ──
add('move-hum', '플레이어', '이동 — 작은 불꽃이 숨 쉬는 소리 (반복)', [
  { src: 'torch', ss: 2, t: 0.7, lp: 1800, hp: 120, fi: 0.15, fo: 0.15 },
], { reverb: 'none', peak: -14, note: '반복 재생용', tail: 0 });
add('dash-scatter', '플레이어', '대시 — 불씨로 흩어짐 (바람 + 불꽃)', [
  { src: 'whoosh', ss: 0.45, t: 0.5, rate: 1.4, hp: 300, fo: 0.12 },
  { src: 'cloth2', rate: 1.3, hp: 900, gain: -6 },
  { src: 'crackleB', ss: 3.1, t: 0.25, hp: 1500, gain: -8, fo: 0.1 },
], { reverb: 'room', peak: -4 });
add('dash-gather', '플레이어', '대시 — 다시 모임 (묵직하게)', [
  { src: 'whoosh', ss: 0.5, t: 0.45, rev: true, rate: 1.1, hp: 200, fi: 0.05 },
  { src: 'softH', rate: 0.75, lp: 900, delay: 230, gain: -2 },
], { reverb: 'room', peak: -4 });
add('fire-shoot', '플레이어', '불꽃탄 발사', [
  { src: 'whoosh', ss: 0.6, t: 0.35, rate: 1.8, hp: 500, fo: 0.08 },
  { src: 'crackleA', ss: 12.4, t: 0.18, hp: 1200, gain: -6, fo: 0.06 },
], { reverb: 'room', peak: -5 });
add('fire-impact', '플레이어', '불꽃탄 착탄', [
  { src: 'softM', rate: 0.9, lp: 2500 },
  { src: 'crackleC', ss: 8, t: 0.4, hp: 600, gain: -2, fo: 0.2 },
  { src: 'whoosh', ss: 1.0, t: 0.3, rate: 1.2, hp: 800, gain: -10, fo: 0.15 },
], { reverb: 'room', peak: -4 });
add('pillar-charge', '플레이어', '불기둥 — 시전 모음 (불이 빨려 들어감)', [
  { src: 'whoosh', ss: 0.4, t: 1.2, rev: true, rate: 0.85, hp: 150, fi: 0.2 },
  { src: 'crackleB', ss: 6, t: 0.6, hp: 1000, gain: -6, fi: 0.3 },
], { reverb: 'room', peak: -6 });
add('pillar-burst', '플레이어', '불기둥 — 발동 (불길이 솟음)', [
  { src: 'whoosh', ss: 0.45, t: 1.6, rate: 0.75, hp: 60, fo: 0.6 },
  { src: 'punchH', rate: 0.6, lp: 500, gain: -2 },
  { src: 'crackleA', ss: 20, t: 0.9, hp: 700, gain: -4, fo: 0.5, delay: 80 },
], { reverb: 'hall', peak: -2 });
add('ember-gain', '플레이어', '잔불 획득 (작은 불씨가 손에 붙음)', [
  { src: 'crackleB', ss: 9.3, t: 0.15, hp: 1500, fo: 0.08 },
  { src: 'glass1', rate: 1.3, gain: -6, delay: 30 },
], { reverb: 'room', peak: -8 });
add('player-hit', '플레이어', '피격', [
  { src: 'punchM', rate: 0.95 },
  { src: 'whoosh', ss: 1.2, t: 0.2, rate: 1.6, hp: 1500, gain: -10, fo: 0.1 },
], { reverb: 'room', peak: -4 });
add('player-down', '플레이어', '체력 0 (불이 사그라듦)', [
  { src: 'softH', rate: 0.6, lp: 600 },
  { src: 'crackleC', ss: 15, t: 1.2, hp: 400, lp: 2500, gain: -4, fo: 1.0 },
  { src: 'whoosh', ss: 0.8, t: 0.8, rev: true, rate: 0.6, gain: -8, fo: 0.4 },
], { reverb: 'hall', peak: -4 });

// ── 패링 (손맛의 핵심: 성공음 후보 4) ──
add('parry-try', '패링', '패링 시도 (휙)', [
  { src: 'cloth3', rate: 1.4, hp: 700 },
], { reverb: 'room', peak: -9 });
add('parry-success-a', '패링', '패링 성공 A — 칼날 "챙" + 판 울림', [
  { src: 'knife1', rate: 1.15, hp: 600 },
  { src: 'plateL0', rate: 1.2, gain: -3 },
  { src: 'bell1', rate: 1.6, hp: 800, gain: -10, fo: 0.25 },
], { reverb: 'stone', peak: -1, candidate: 'parry-success' });
add('parry-success-b', '패링', '패링 성공 B — 맑은 종 "챙"', [
  { src: 'metalL0', rate: 1.1 },
  { src: 'bell0', rate: 1.5, hp: 500, gain: -2 },
], { reverb: 'stone', peak: -1, candidate: 'parry-success' });
add('parry-success-c', '패링', '패링 성공 C — 냄비 깡 + 높은 울림 (거친 금속)', [
  { src: 'clang', rate: 1.05, hp: 300 },
  { src: 'bell2', rate: 2.0, hp: 1000, gain: -6, fo: 0.3 },
], { reverb: 'stone', peak: -1, candidate: 'parry-success' });
add('parry-success-d', '패링', '패링 성공 D — 묵직한 판 "쾅챙" (무게 있음)', [
  { src: 'plateH0', rate: 1.25 },
  { src: 'knife2', rate: 1.3, hp: 1500, gain: -4 },
  { src: 'punchH', rate: 0.7, lp: 400, gain: -6 },
], { reverb: 'stone', peak: -1, candidate: 'parry-success' });
add('parry-fail', '패링', '패링 실패 (둔탁)', [
  { src: 'woodM', rate: 0.8, lp: 1500 },
], { reverb: 'room', peak: -8 });

// ── 수호체·봉인 (돌과 금속, 차가운 공명) ──
add('sentinel-awaken', '수호체', '각성 (돌이 끌리며 봉인이 울림)', [
  { src: 'scrapeC', ss: 3, t: 0.7, rate: 0.9, lp: 2000, fi: 0.08, fo: 0.25 },
  { src: 'bowl', ss: 1.4, t: 1.0, rate: 0.7, gain: -6, fi: 0.2, fo: 0.4 },
], { reverb: 'stone', peak: -4 });
// D-036: 공격 소리 3단계 — 장전(낮게 차오름) → 신호 "팅"(가장 또렷, = 지금 패링) → 공격(휙/쿵).
// 장전은 2kHz 아래(lp)에만, 신호는 2kHz 위(hp)에만 둬서 겹쳐도 팅이 묻히지 않게. 장전은 len으로 정확히 자름(600/900ms).
const windup = (sfx, L, lab) => {
  add(`${sfx}-a`, '수호체', `장전${lab} A — 돌 긁힘 + 거꾸로 감기는 싱잉볼 (빨려 들어감)`, [
    { src: 'scrapeC', ss: 11.25, t: L * 0.85 + 0.05, rate: 0.85, lp: 1500, hp: 80, fi: L * 0.8, gain: -3 },
    { src: 'bowl', ss: 1.42, t: L * 0.9 * 0.7, rev: true, rate: 0.7, lp: 1800, delay: Math.round(L * 100) },
  ], { reverb: 'stone', peak: -6, len: L, candidate: sfx });
  const seg = L / 3 + 0.05;
  add(`${sfx}-b`, '수호체', `장전${lab} B — 돌 끌림 + 세 계단으로 높아지는 울림`, [
    { src: 'scrapeV', ss: 3.72, t: L * 0.9 + 0.05, rate: 0.9, lp: 1800, hp: 80, fi: L * 0.7, gain: -3 },
    ...[0.5, 0.63, 0.8].map((r, i) => ({ src: 'bowl', ss: 1.42, t: seg * r, rate: r, lp: 2000, fi: 0.06, fo: 0.08, gain: -6 + i * 2, delay: Math.round(i * L / 3 * 1000) })),
  ], { reverb: 'stone', peak: -6, len: L, candidate: sfx });
};
windup('sentinel-windup', 0.6, '');
windup('sentinel-windup-easy', 0.9, ' (쉬운 판 900ms)');
add('sentinel-cue-a', '수호체', '신호 "팅" A — 맑은 유리 + 높은 종 (짧게)', [
  { src: 'glass0', rate: 1.6, hp: 2500 },
  { src: 'bell2', t: 0.3, rate: 3.2, hp: 3000, gain: -8, fo: 0.15 },
], { reverb: 'room', peak: -1, candidate: 'sentinel-cue' });
add('sentinel-cue-b', '수호체', '신호 "팅" B — 도자기 팅 (가장 짧고 단단함)', [
  { src: 'ceramic', ss: 0.17, t: 0.35, rate: 1.3, hp: 2000, fo: 0.15 },
], { reverb: 'room', peak: -1, candidate: 'sentinel-cue' });
add('sentinel-cue-c', '수호체', '신호 "팅" C — 와인잔 팅 (맑게 울림)', [
  { src: 'wine', ss: 0.56, t: 0.45, rate: 1.5, hp: 2000, fo: 0.2 },
], { reverb: 'room', peak: -1, candidate: 'sentinel-cue' });
add('sentinel-attack-a', '수호체', '공격 A — 묵직한 휙 + 쿵', [
  { src: 'whoosh', ss: 2.2, t: 0.35, rate: 0.6, lp: 1500, hp: 60, fo: 0.15, gain: -4 },
  { src: 'punchH', rate: 0.55, lp: 600, delay: 60 },
  { src: 'mine0', rate: 0.6, delay: 70, gain: -5 },
], { reverb: 'stone', peak: -2, candidate: 'sentinel-attack' });
add('sentinel-attack-b', '수호체', '공격 B — 돌덩이 쿵 (휘두름 없이 충돌만)', [
  { src: 'softH', rate: 0.5, lp: 500 },
  { src: 'mine0', rate: 0.55, gain: -2 },
  { src: 'scrapeV', ss: 0.28, t: 0.3, rate: 1.2, hp: 300, gain: -10, fo: 0.2 },
], { reverb: 'stone', peak: -2, candidate: 'sentinel-attack' });
add('sentinel-hit', '수호체', '피격 (돌 딱 + 금속 판)', [
  { src: 'mine3', rate: 1.0 },
  { src: 'plateM0', rate: 0.85, gain: -6 },
], { reverb: 'stone', peak: -4 });
add('sentinel-shutdown', '수호체', '정지 (봉인 빛이 꺼지며 부서짐)', [
  { src: 'bowl', ss: 1.42, t: 1.4, rate: 0.85, gain: -2, fo: 0.9 },
  { src: 'scrapeV', ss: 5, t: 0.6, rate: 1.1, delay: 250, gain: -4, fo: 0.3 },
  { src: 'wine', ss: 7.3, t: 0.4, rate: 1.4, delay: 300, gain: -8, fo: 0.2 },
], { reverb: 'stone', peak: -4 });

// ── 이벤트 ──
add('artifact', '이벤트', '아티팩트 (맑은 울림 + 반짝)', [
  { src: 'bowl', ss: 1.42, t: 2.0, rate: 1.0, gain: -2, fo: 1.0 },
  { src: 'tinkle', ss: 0.2, t: 1.6, gain: -6, fo: 0.6 },
  { src: 'wine', ss: 11.9, t: 0.6, rate: 1.2, gain: -8, delay: 120, fo: 0.3 },
], { reverb: 'hall', peak: -3 });
add('form-change', '이벤트', '폼체인지 (처음으로 터지는 따뜻한 불)', [
  { src: 'whoosh', ss: 0.4, t: 1.6, rev: true, rate: 0.7, fi: 0.3 },
  { src: 'whoosh', ss: 0.45, t: 1.8, rate: 0.65, delay: 1100, fo: 0.8 },
  { src: 'crackleA', ss: 30, t: 1.5, hp: 300, gain: -4, delay: 1150, fo: 0.8 },
  { src: 'bowl', ss: 1.42, t: 2.0, rate: 0.8, gain: -6, delay: 1100, fo: 1.2 },
], { reverb: 'hall', peak: -2 });
add('door-open', '이벤트', '문 열림 (돌 문이 미끄러짐)', [
  { src: 'scrapeV', ss: 10, t: 1.0, rate: 0.8, lp: 1500, fi: 0.1, fo: 0.3 },
  { src: 'door1', rate: 0.7, lp: 1200, gain: -6 },
], { reverb: 'stone', peak: -5 });
add('vine-burn', '이벤트', '덩굴 탐 (탁탁 + 바스락)', [
  { src: 'crackleB', ss: 2, t: 0.7, hp: 800, fo: 0.3 },
  { src: 'cloth2', rate: 0.9, hp: 1500, gain: -6 },
  { src: 'whoosh', ss: 0.6, t: 0.4, rate: 1.3, hp: 600, gain: -8, fo: 0.2 },
], { reverb: 'room', peak: -5 });

// ── 동반자 · UI ──
add('companion-blip-a', '동반자·UI', '동반자 말소리 a (작은 유리 음절)', [ { src: 'glass0', rate: 1.6, t: 0.12, fo: 0.05 } ], { reverb: 'none', peak: -12, tail: 0 });
add('companion-blip-b', '동반자·UI', '동반자 말소리 b', [ { src: 'glass2', rate: 1.8, t: 0.12, fo: 0.05 } ], { reverb: 'none', peak: -12, tail: 0 });
add('companion-blip-c', '동반자·UI', '동반자 말소리 c', [ { src: 'glass3', rate: 1.45, t: 0.12, fo: 0.05 } ], { reverb: 'none', peak: -12, tail: 0 });
add('emote', '동반자·UI', '감정 표시 (작은 도자기 팅)', [ { src: 'ceramic', rate: 1.3, t: 0.4, fo: 0.15 } ], { reverb: 'room', peak: -10 });
add('ui-select', '동반자·UI', 'UI 선택 (나무 톡)', [ { src: 'woodL0', rate: 1.2, hp: 300 } ], { reverb: 'none', peak: -12, tail: 0 });
add('ui-confirm', '동반자·UI', 'UI 결정 (나무 + 작은 종)', [
  { src: 'woodL1', rate: 1.1, hp: 300 },
  { src: 'bell2', rate: 2.4, hp: 1500, gain: -8, delay: 25, fo: 0.2 },
], { reverb: 'room', peak: -10 });

// ── 스킬·콤보 v1 (D-031) ──
add('fire-fan', '콤보', '불꽃 3갈래 발사 (세 발이 겹쳐 퍼짐)', [
  { src: 'whoosh', ss: 0.6, t: 0.3, rate: 1.8, hp: 500, fo: 0.08 },
  { src: 'whoosh', ss: 0.7, t: 0.3, rate: 1.6, hp: 500, delay: 25, gain: -2, fo: 0.08 },
  { src: 'whoosh', ss: 0.8, t: 0.3, rate: 2.0, hp: 600, delay: 50, gain: -3, fo: 0.08 },
  { src: 'crackleA', ss: 12.4, t: 0.25, hp: 1200, gain: -6, fo: 0.08 },
], { reverb: 'room', peak: -4 });
add('pillar-big', '콤보', '큰 불기둥 (묵직하게 솟고 타오름)', [
  { src: 'whoosh', ss: 0.45, t: 2.0, rate: 0.62, hp: 40, fo: 0.8 },
  { src: 'punchH', rate: 0.5, lp: 400 },
  { src: 'softH', rate: 0.55, lp: 300, delay: 40, gain: -2 },
  { src: 'crackleA', ss: 20, t: 1.4, hp: 500, gain: -3, fo: 0.8, delay: 100 },
], { reverb: 'hall', peak: -1 });
add('pillar-quick', '콤보', '빠른 불기둥 (짧고 날렵)', [
  { src: 'whoosh', ss: 0.5, t: 0.45, rate: 1.4, hp: 200, fo: 0.15 },
  { src: 'crackleB', ss: 6.2, t: 0.25, hp: 900, gain: -5, fo: 0.1 },
], { reverb: 'room', peak: -5 });
add('combo-focus', '콤보', '집중 강화 (무게감 — 마무리에 겹침)', [
  { src: 'whoosh', ss: 0.5, t: 0.35, rev: true, rate: 1.0, hp: 150, fi: 0.05 },
  { src: 'punchH', rate: 0.55, lp: 350, delay: 120 },
  { src: 'crackleC', ss: 8, t: 0.35, hp: 700, gain: -6, delay: 130, fo: 0.2 },
], { reverb: 'hall', peak: -3 });
add('combo-switch', '콤보', '전환 자동 대시 (빠르게 빠짐)', [
  { src: 'whoosh', ss: 0.5, t: 0.3, rate: 1.9, hp: 600, fo: 0.08 },
  { src: 'cloth3', rate: 1.5, hp: 1000, gain: -5 },
], { reverb: 'room', peak: -6 });
add('combo-slot', '콤보', '콤보 칸 채움 (아주 작게)', [
  { src: 'crackleB', ss: 9.3, t: 0.08, hp: 2000, fo: 0.03 },
  { src: 'woodL1', rate: 1.6, hp: 600, gain: -6 },
], { reverb: 'none', peak: -16, tail: 0 });

// ── 길찾기 · 알 수 없는 기록 (D-034) ──
add('inspect', '길찾기', '살펴보기 (손끝으로 먼지를 쓸어냄)', [
  { src: 'cloth1', rate: 1.1, hp: 800, gain: -3 },
  { src: 'ceramic', rate: 0.8, t: 0.3, gain: -10, delay: 80, fo: 0.15 },
], { reverb: 'room', peak: -10 });
add('record-open', '길찾기', '기록창 열림 (돌판이 끌려 나옴)', [
  { src: 'scrapeV', ss: 3, t: 0.45, rate: 1.2, hp: 200, fi: 0.03, fo: 0.15 },
  { src: 'softM', rate: 0.7, lp: 600, delay: 300, gain: -4 },
], { reverb: 'stone', peak: -8 });
add('record-close', '길찾기', '기록창 닫힘 (돌판이 제자리로)', [
  { src: 'scrapeV', ss: 8, t: 0.3, rate: 1.3, hp: 200, fo: 0.1 },
  { src: 'mine0', rate: 0.75, lp: 1200, delay: 200, gain: -2 },
], { reverb: 'stone', peak: -8 });
add('brazier-ignite', '길찾기', '화로 점화 (불 붙는 "확")', [
  { src: 'whoosh', ss: 0.4, t: 0.9, rate: 1.0, hp: 100, fo: 0.4 },
  { src: 'crackleA', ss: 40, t: 1.0, hp: 400, gain: -4, delay: 150, fo: 0.6 },
  { src: 'softM', rate: 0.6, lp: 500, gain: -6 },
], { reverb: 'room', peak: -3 });
add('seal-door-open', '길찾기', '봉인문 열림 (봉인 울림 + 돌 갈림)', [
  { src: 'bowl', ss: 1.42, t: 1.4, rate: 0.9, gain: -2, fo: 0.8 },
  { src: 'scrapeC', ss: 8, t: 1.6, rate: 0.7, lp: 1500, delay: 350, fi: 0.1, fo: 0.4 },
  { src: 'softH', rate: 0.45, lp: 250, delay: 380, gain: -3 },
], { reverb: 'stone', peak: -2 });
add('wall-collapse', '길찾기', '벽 무너짐 (돌이 쏟아짐)', [
  { src: 'punchH', rate: 0.5, lp: 400 },
  { src: 'mine0', rate: 0.85, delay: 60 },
  { src: 'mine3', rate: 0.7, delay: 180, gain: -2 },
  { src: 'mine1', rate: 0.9, delay: 290, gain: -4 },
  { src: 'scrapeV', ss: 15, t: 0.9, rate: 1.4, hp: 300, delay: 120, gain: -6, fo: 0.5 },
], { reverb: 'stone', peak: -1 });

// ── 폼체인지 장면 D v2 (D-037) — 그림 시점에 맞춤 ──
add('form-merge', '폼체인지', '합쳐짐 — 차가운 울림과 따뜻한 불꽃이 겹치며 올라감 (1.1초)', [
  ...[0.55, 0.7, 0.85, 1.05].map((r, k) => ({ src: 'bowl', ss: 1.42, t: 0.45 * r, rate: r, lp: 3000, fi: 0.08, fo: 0.15, gain: -9 + k * 2, delay: k * 250 })),
  { src: 'crackleB', ss: 6, t: 1.1, hp: 900, fi: 0.6, fo: 0.2, gain: -8 },
  { src: 'tinkle', ss: 0.2, t: 0.5, rate: 1.3, hp: 2500, delay: 700, gain: -10, fo: 0.3 },
], { reverb: 'hall', peak: -5 });
add('form-flash', '폼체인지', '섬광 "휘잉" — 거꾸로 감긴 바람 + 높은 울림이 차오름', [
  { src: 'whoosh', ss: 0.4, t: 0.9, rev: true, rate: 1.2, hp: 400, fi: 0.1 },
  { src: 'bowl', ss: 1.42, t: 0.9, rev: true, rate: 1.8, hp: 1200, gain: -4 },
  { src: 'tinkle', ss: 0.2, t: 0.6, rate: 1.6, hp: 3000, delay: 520, gain: -6, fo: 0.4 },
], { reverb: 'hall', peak: -2 });
add('staff-drop', '폼체인지', '지팡이 떨어짐 "탁·탁" — 나무 + 수정 (drop:hit에서, 두 번째는 +230ms)', [
  { src: 'woodL0', rate: 1.1 },
  { src: 'glass1', rate: 1.4, gain: -5 },
  { src: 'woodL1', rate: 1.25, delay: 230, gain: -4 },
  { src: 'glass3', rate: 1.6, delay: 230, gain: -9 },
], { reverb: 'room', peak: -4 });
const SHAKE = [0, 200, 380, 540, 680, 800, 900, 990, 1070, 1140];   // prop-crystal-staff shake 프레임 시작 시점
add('staff-shake', '폼체인지', '지팡이 흔들림 — 달그락, 점점 빨라짐 (1.2초, shake:start에서)', SHAKE.map((d, k) => (
  { src: k % 2 ? 'woodL1' : 'woodL0', rate: 1.3 + k * 0.04, hp: 400, delay: d, gain: -10 + k * 0.7 })).concat(
  [{ src: 'glass2', rate: 1.5, delay: 1070, gain: -10 }]), { reverb: 'room', peak: -7 });
add('wind-gust', '폼체인지', '바람 "휘익" — 지나가는 바람 (1초)', [
  { src: 'whoosh', ss: 0.2, t: 0.75, rate: 0.6, lp: 2600, hp: 120, fi: 0.25, fo: 0.5 },
  { src: 'whoosh', ss: 1.0, t: 0.6, rate: 1.1, hp: 1500, delay: 200, gain: -10, fo: 0.3 },
], { reverb: 'room', peak: -4 });
add('robe-flutter', '폼체인지', '천 펄럭임 — 휘감기고 마지막에 "톡" (form-a 1.4초에 맞춤)', [
  { src: 'cloth1', rate: 1.1, hp: 300 },
  { src: 'cloth2', rate: 0.9, delay: 240, gain: -2 },
  { src: 'cloth3', rate: 1.0, delay: 500, gain: -3 },
  { src: 'cloth2', rate: 1.2, delay: 780, gain: -5 },
  { src: 'cloth1', rate: 1.3, delay: 1000, gain: -7 },
  { src: 'softM', rate: 1.4, lp: 2500, delay: 1250, gain: -6 },
], { reverb: 'room', peak: -5 });
add('handflame-ignite', '폼체인지', '손불꽃 점화 "화륵" — 처음으로 따뜻한 불', [
  { src: 'whoosh', ss: 0.5, t: 0.45, rate: 1.4, hp: 300, fo: 0.15 },
  { src: 'crackleA', ss: 12.4, t: 0.8, hp: 700, delay: 60, gain: -3, fo: 0.4 },
  { src: 'crackleC', ss: 8, t: 0.6, hp: 900, delay: 150, gain: -8, fo: 0.4 },
], { reverb: 'room', peak: -4 });

// 정식 이름 (게임이 쓰는 id): 사용자가 후보를 고르기 전까지 A
const PICK = { 'parry-success': 'a', 'sentinel-windup': 'a', 'sentinel-windup-easy': 'a', 'sentinel-cue': 'a', 'sentinel-attack': 'a' };
for (const [id, k] of Object.entries(PICK)) {
  const src = S.find(x => x.id === `${id}-${k}`);
  S.push({ ...src, id, candidate: null, label: src.label.replace(/ [A-D] — /, ' — ') + ` (선택: ${k.toUpperCase()})`, note: `후보 ${id}-${k}와 같은 소리` });
}
export const SOUNDS = S;
