// dungeon-part0 견본 방: Part 0 봉인탑 통로 + 위로 열린 안전지대 (30x13칸).
// export-tileset.mjs가 읽어 <id>-sample.tmj로 만든다. 레이어: floor → wall → props → collision → markers.
// 문자 지도: 공백 = 비움(허공), 벽 문자는 collision에도 칠해짐.
export const MAP = [
  '           CTTTTTTC           ',
  '           LUUUUUUR           ',
  '           LFFFFFFR           ',
  'TTTTTTTTTTTLqssssQRTTTTTTTTTTT',
  'UUUUUUUuUUULl....rRUUUUUUUUuUU',
  'FFFFFFKFFFFLl....rRFFFFFFKFFFF',
  'sssssssssssss....sssssssssssss',
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
  [34, 14, 4], [35, 15, 4], [44, 14, 5], [45, 15, 5],   // 안전지대 봉인 인장 (맥동)
  [36, 20, 8], [37, 21, 8], [46, 20, 9], [47, 21, 9],   // 쓰러진 수호자 잔해 (가슴 인장 깜빡)
  [38, 3, 4], [40, 9, 4], [38, 21, 4], [40, 27, 4],     // 봉인등 (박자 둘)
  [30, 24, 5], [30, 7, 5],                              // 긁힌 자국
  [31, 6, 9], [31, 26, 10], [32, 18, 10], [33, 9, 7],   // 파편, 잔해, 해골
];
// 통로 양 끝은 이 견본에선 막아 둠 (다른 방과 잇는 출구는 게임 쪽에서)
export const EXTRA_SOLID = [[0, 7], [0, 8], [0, 9], [0, 10], [0, 11], [29, 7], [29, 8], [29, 9], [29, 10], [29, 11]];
export const MARKERS = [{ type: 'entryPoint', id: 'start', x: 216, y: 136 }];
