// 타일셋 내보내기 (docs/asset-contract.md, contract 2): aseprite/<id>/ → export/<id>/<id>.png + <id>.tsj + <id>-sample.tmj (+ collision.tsj/png)
// 사용: node scripts/export-tileset.mjs <id> [--drop v<n>]
// 입력: aseprite/<id>/<id>.aseprite (그림), tileset.json (이름·종류·애니메이션), sample.mjs (견본 방, 있으면)
import { execFileSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const ROOT = resolve(import.meta.dirname, '..');
const ASEPRITE = process.env.ASEPRITE || 'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe';
const DROP_ROOT = process.env.DROP_ROOT || 'C:/github-clones/_asset-drop';
const [id, flag, drop] = process.argv.slice(2);
if (!id) { console.error('사용: node scripts/export-tileset.mjs <id> [--drop v<n>]'); process.exit(2); }
const SRC = join(ROOT, 'aseprite', id), OUT = join(ROOT, 'export', id);
mkdirSync(OUT, { recursive: true });
const meta = JSON.parse(readFileSync(join(SRC, 'tileset.json'), 'utf8'));
const T = meta.tileSize, COLS = meta.columns, ROWS = meta.rows, COUNT = COLS * ROWS;
const fail = m => { console.error('✗ ' + m); process.exit(1); };

// 1) png
execFileSync(ASEPRITE, ['-b', join(SRC, `${id}.aseprite`), '--save-as', join(OUT, `${id}.png`)], { stdio: 'inherit' });
const png = readFileSync(join(OUT, `${id}.png`));
const [pw, ph] = [png.readUInt32BE(16), png.readUInt32BE(20)];
if (pw !== COLS * T || ph !== ROWS * T) fail(`png ${pw}x${ph} ≠ ${COLS}x${ROWS}칸`);

// 2) .tsj (Tiled 외부 타일셋)
const tiles = new Map();
const tile = n => { if (!tiles.has(n)) tiles.set(n, { id: n }); return tiles.get(n); };
for (const [type, list] of Object.entries(meta.types || {})) for (const n of list) tile(n).type = type;
for (const [n, name] of Object.entries(meta.names || {})) (tile(+n).properties ??= []).push({ name: 'name', type: 'string', value: name });
for (const [n, frames] of Object.entries(meta.animations || {})) {
  for (const [f, ms] of frames) {
    if (!(Number.isInteger(f) && f >= 0 && f < COUNT)) fail(`애니메이션 ${n}: 프레임 ${f}가 범위 밖`);
    if (!(Number.isInteger(ms) && ms > 0)) fail(`애니메이션 ${n}: duration ${ms}`);
  }
  if (frames[0][0] !== +n) fail(`애니메이션 ${n}: 첫 프레임은 자기 자신이어야 함`);
  tile(+n).animation = frames.map(([tileid, duration]) => ({ tileid, duration }));
}
const tsj = {
  columns: COLS, image: `${id}.png`, imageheight: ph, imagewidth: pw, margin: 0, name: id, spacing: 0,
  tilecount: COUNT, tiledversion: '1.12.2', tileheight: T, tilewidth: T, type: 'tileset', version: '1.10',
  tiles: [...tiles.values()].sort((a, b) => a.id - b.id),
};
writeFileSync(join(OUT, `${id}.tsj`), JSON.stringify(tsj, null, 1) + '\n');

// 3) 견본 방 .tmj
const samplePath = join(SRC, 'sample.mjs');
if (existsSync(samplePath)) {
  const S = await import(pathToFileURL(samplePath).href);
  const W = S.MAP[0].length, H = S.MAP.length;
  if (S.MAP.some(r => r.length !== W)) fail('견본 지도 줄 길이가 다름');
  const COL_FIRST = COUNT + 1; // collision 타일셋 firstgid
  const L = { floor: new Array(W * H).fill(0), wall: new Array(W * H).fill(0), props: new Array(W * H).fill(0), collision: new Array(W * H).fill(0) };
  const autos = [];
  S.MAP.forEach((line, row) => [...line].forEach((ch, col) => {
    if (ch === ' ') return;
    const g = S.LEGEND[ch]; if (!g) fail(`견본 지도 (${col},${row}) 모르는 문자 '${ch}'`);
    if (g.autotile) autos.push([col, row, g]);
    else L[g.layer][row * W + col] = 1 + (g.floor ? S.floorTile(col, row) : g.tile);
    if (g.solid) L.collision[row * W + col] = COL_FIRST;
  }));
  // 자동 연결 (D-041): 47칸 blob. 이웃이 같은 autotile(또는 joins에 그 이름)이면 이어짐, 지도 밖은 이어진 것으로 봄
  const same = (c, r, name) => { if (c < 0 || r < 0 || c >= W || r >= H) return true; const g2 = S.LEGEND[S.MAP[r][c]]; return !!g2 && (g2.autotile === name || (g2.joins || []).includes(name)); };
  for (const [col, row, g] of autos) {
    const A = meta.autotile?.[g.autotile]; if (!A) fail('autotile 없음: ' + g.autotile);
    const n = (dc, dr) => same(col + dc, row + dr, g.autotile);
    const N = n(0, -1), E = n(1, 0), So = n(0, 1), We = n(-1, 0);
    const m = (N ? 1 : 0) | (N && E && n(1, -1) ? 2 : 0) | (E ? 4 : 0) | (E && So && n(1, 1) ? 8 : 0) | (So ? 16 : 0) | (So && We && n(-1, 1) ? 32 : 0) | (We ? 64 : 0) | (We && N && n(-1, -1) ? 128 : 0);
    L[g.layer][row * W + col] = 1 + A.base + A.masks.indexOf(m);
  }
  for (const [t, col, row] of S.PROPS) L.props[row * W + col] = 1 + t;
  for (const [col, row] of S.EXTRA_SOLID || []) L.collision[row * W + col] = COL_FIRST;
  let lid = 0, oid = 0;
  const layer = (name, data, opacity = 1) => ({ data, height: H, id: ++lid, name, opacity, type: 'tilelayer', visible: true, width: W, x: 0, y: 0 });
  const tmj = {
    compressionlevel: -1, height: H, infinite: false,
    layers: [
      layer('floor', L.floor), layer('wall', L.wall), layer('props', L.props), layer('collision', L.collision, 0.5),
      { draworder: 'topdown', id: ++lid, name: 'markers', opacity: 1, type: 'objectgroup', visible: true, x: 0, y: 0,
        objects: [
          ...S.MARKERS.map(m => ({ height: 0, id: ++oid, name: m.id, point: true, properties: [{ name: 'id', type: 'string', value: m.id }], rotation: 0, type: m.type, visible: true, width: 0, x: m.x, y: m.y })),
          ...(S.EXITS || []).map(x => ({ height: x.height, id: ++oid, name: x.id, properties: ['id', 'targetRoomId', 'targetEntryId'].map(k => ({ name: k, type: 'string', value: x[k] })), rotation: 0, type: 'exit', visible: true, width: x.width, x: x.x, y: x.y })),
        ] },
    ],
    nextlayerid: lid + 1, nextobjectid: oid + 1, orientation: 'orthogonal', renderorder: 'right-down', tiledversion: '1.12.2',
    tileheight: T, tilesets: [{ firstgid: 1, source: `${id}.tsj` }, { firstgid: COL_FIRST, source: 'collision.tsj' }],
    tilewidth: T, type: 'map', version: '1.10', width: W,
  };
  writeFileSync(join(OUT, `${id}-sample.tmj`), JSON.stringify(tmj, null, 1) + '\n');
  for (const f of ['collision.tsj', 'collision.png']) copyFileSync(join(ROOT, 'aseprite', '_shared', f), join(OUT, f));
}
console.log(`✓ export/${id}: ${COLS}x${ROWS}칸, 애니메이션 ${Object.keys(meta.animations || {}).length}개${existsSync(samplePath) ? ', 견본 방' : ''}`);

// 4) 전달
if (flag === '--drop') {
  const dest = join(DROP_ROOT, id, drop);
  if (existsSync(dest)) fail(`이미 있음: ${dest} (판 번호를 올리세요)`);
  mkdirSync(dest, { recursive: true });
  for (const f of [`${id}.png`, `${id}.tsj`, `${id}-sample.tmj`, 'collision.tsj', 'collision.png']) if (existsSync(join(OUT, f))) copyFileSync(join(OUT, f), join(dest, f));
  console.log(`→ 전달: ${dest}`);
}
