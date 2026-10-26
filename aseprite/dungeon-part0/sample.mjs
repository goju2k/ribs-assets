// dungeon-part0 견본 방: Part 0 봉인탑 통로 + 위로 열린 안전지대 + 북쪽 아치 문 + 동쪽 열린 출구 (30x13칸).
// export-tileset.mjs가 읽어 <id>-sample.tmj로 만든다. 레이어: floor → wall → props → collision → markers.
// 문자 지도: 공백 = 비움(허공), 벽 문자는 collision에도 칠해짐.
export const MAP = [
  '           CTTTTTTC           ',
  '           LUUUUUUR           ',
  '           LFFFFFFR           ',
  'TTTTTTTTTTTLqssssQRTTTTTTTTTTT',
  'UUUUDEUuUU]Ll....rR[UUUUUUUuUU',
  'FFFFGHKFFF}<l....r>{FFFFFKFFFF',
  'sssssssssssss====sssssssssssss',
  '..............................',
  '..............................',
  '..............................',
  '..............................',
  '..............................',
  'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
];
// 문자 → 타일 번호 (tileset.json의 names 참고). layer: 어느 레이어에 놓는지
export const LEGEND = {
  C: { tile: 11, layer: 'wall', solid: true },
  T: { tile: 12, layer: 'wall', solid: true },
  L: { tile: 13, layer: 'wall', solid: true },
  R: { tile: 14, layer: 'wall', solid: true },
  B: { tile: 15, layer: 'wall', solid: true },
  U: { tile: 20, layer: 'wall', solid: true },
  u: { tile: 21, layer: 'wall', solid: true },
  F: { tile: 22, layer: 'wall', solid: true },
  K: { tile: 24, layer: 'wall', solid: true },
  D: { tile: 25, layer: 'wall', solid: true },   // 아치 문 위 (벽면 위 줄)
  E: { tile: 26, layer: 'wall', solid: true },
  G: { tile: 27, layer: 'wall' },                // 아치 문 아래 = 열린 입구 (충돌 없음)
  H: { tile: 28, layer: 'wall' },
  ']': { tile: 54, layer: 'wall', solid: true },   // 벽 끝 마감 (D-040): 벽면 줄에서 오른쪽 이웃이 벽면이 아니면 54(위)/64(아래)
  '[': { tile: 55, layer: 'wall', solid: true },   //   왼쪽 이웃이 벽면이 아니면 55/65 (양쪽 다 아니면 57/67 한 칸 기둥)
  '}': { tile: 64, layer: 'wall', solid: true },
  '{': { tile: 65, layer: 'wall', solid: true },
  '<': { tile: 58, layer: 'wall', solid: true },   // 옆벽 끝: 왼쪽 벽(L) 줄이 아래로 끝나는 칸
  '>': { tile: 59, layer: 'wall', solid: true },   //   오른쪽 벽(R)
  '=': { tile: 56, layer: 'floor' },               // 문턱: 통로 입구 바닥 (벽면 아래 줄 바로 아래 행, 통로 폭만큼)
  s: { tile: 6, layer: 'floor' },
  l: { tile: 7, layer: 'floor' },
  r: { tile: 8, layer: 'floor' },
  q: { tile: 9, layer: 'floor' },
  Q: { tile: 10, layer: 'floor' },
  '.': { floor: true, layer: 'floor' },
};
// 맨바닥 변형: 칸 위치 해시로 고름 (이끼·금은 드물게)
export function floorTile(col, row) {
  const h = ((col * 73856093) ^ (row * 19349663)) >>> 0;
  const k = h % 100;
  return k < 5 ? 4 : k < 10 ? 5 : k < 19 ? 3 : k < 26 ? 2 : k < 32 ? 1 : 0;
}
// 소품: [타일, 열, 행]. 2x2는 네 칸 따로
export const PROPS = [
  [34, 14, 4], [35, 15, 4], [44, 14, 5], [45, 15, 5],   // 안전지대 봉인 문양 (맥동)
  [36, 20, 8], [37, 21, 8], [46, 20, 9], [47, 21, 9],   // 쓰러진 수호체 잔해 (가슴 문양 깜빡)
  [38, 3, 4], [40, 9, 4], [38, 21, 4], [40, 27, 4],     // 봉인등 (박자 둘)
  [30, 24, 5], [30, 7, 5],                              // 긁힌 자국
  [31, 6, 9], [31, 26, 10], [32, 18, 10], [33, 9, 7],   // 파편, 잔해, 해골
];
// 통로 서쪽 끝은 막고, 동쪽 끝은 열린 출구
export const EXTRA_SOLID = [[0, 7], [0, 8], [0, 9], [0, 10], [0, 11]];
// 출구 (Class "exit" 사각형): 들어서면 방이 바뀜. 연결할 방이 아직 없어 자기 자신(room-d)의 start로
export const EXITS = [
  { id: 'northDoor', x: 64, y: 80, width: 32, height: 16, targetRoomId: 'room-d', targetEntryId: 'start' }, // 아치 문 아래 칸 (4·5열, 5행)
  { id: 'eastEnd', x: 464, y: 112, width: 16, height: 80, targetRoomId: 'room-d', targetEntryId: 'start' }, // 통로 동쪽 끝 (29열, 7~11행)
];
export const MARKERS = [{ type: 'entryPoint', id: 'start', x: 216, y: 136 }];
