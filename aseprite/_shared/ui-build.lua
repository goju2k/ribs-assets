-- 전투 UI (D-044): 적 체력바 + 데미지 숫자 픽셀 글꼴. 쓸어버리는 전투에서 한눈에 읽히게.
-- 실행: aseprite -b --script-param which=ui-hpbar|ui-digits|ui-digits-crit --script-param out=<폴더> --script ui-build.lua
--   ui-hpbar   18×4 틀(1px 바깥선 + 안쪽 16×2 빈 바탕) + 채움 16×2 + 잔상 16×2. 엔진이 안쪽 칸에 비율만큼 잘라 그림
--              채움 = 연한 하늘색(위 밝은 줄 / 아래 줄): 붉은색(주인공) · 봉인 청록 #5fcde4와 구분. 잔상 = 흰색. 반투명 없음
--   ui-digits  0~9, 두 크기: 작은 숫자(글자 4×6) / 큰 숫자(글자 6×8, 집중 마무리). 흰 글자 + 1px 어두운 외곽선(8방향)
--              엔진이 곱하기로 색을 입힘(일반 흰색 · 집중 노랑 · 연소 주황) — 외곽선은 어두워서 그대로 남음
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local WHICH, OUT = app.params.which, app.params.out
local OL = H"0e0b12"

if WHICH == "ui-hpbar" then
  local C = { border=OL, empty=H"241e2c", fillT=H"cde9f8", fill=H"8fc6e6", ghost=H"ffffff" }
  local img = Image(18, 8, ColorMode.RGB)
  for y = 0, 3 do for x = 0, 17 do
    local edge = x == 0 or x == 17 or y == 0 or y == 3
    local corner = (x == 0 or x == 17) and (y == 0 or y == 3)
    if not corner then img:drawPixel(x, y, edge and C.border or C.empty) end
  end end
  for x = 0, 15 do img:drawPixel(x, 4, C.fillT); img:drawPixel(x, 5, C.fill); img:drawPixel(x, 6, C.ghost); img:drawPixel(x, 7, C.ghost) end
  local spr = Sprite(18, 8, ColorMode.RGB); spr.cels[1].image = img
  spr:saveAs(OUT .. "/ui-hpbar.aseprite"); spr:saveCopyAs(OUT .. "/ui-hpbar.png")
  local f = io.open(OUT .. "/ui-hpbar.json", "wb")
  f:write('{\n  "frame": { "rect": [0, 0, 18, 4], "inner": [1, 1, 16, 2] },\n  "fill": { "rect": [0, 4, 16, 2] },\n  "ghost": { "rect": [0, 6, 16, 2] },\n' ..
    '  "colors": { "border": "#0e0b12", "empty": "#241e2c", "fillTop": "#cde9f8", "fill": "#8fc6e6", "ghost": "#ffffff" },\n' ..
    '  "note": "틀(18×4)을 그리고, 안쪽 [1,1,16,2]에 잔상 → 채움 순서로 왼쪽부터 비율만큼 잘라 그림. 잔상은 줄어들기 직전 값에서 천천히 따라 내려옴. 기준점 = 틀 아래 가운데(9,4), 머리 위 2px. 근접형 몸(24px) 위 폭 16"\n}\n')
  f:close()

elseif WHICH == "ui-digits-crit" then
  -- 치명타 데미지 숫자 (D-071·D-072 확정): 글자 8×10(일반 4×6의 약 1.7배), 획 2칸. 색을 미리 입힌 판(여러 색이라 곱하기로는 안 됨)
  -- 피할 색: 상급 연두 #8fd46a · 최상급 금 · 적 탄 보라/자홍 · 방어 청록. 줄 0 = Y1 레몬 / 줄 1 = Y2 노랑 / 줄 2 = Y3 진노랑 (D-072, 연출은 A)
  local D = {
    ["0"] = { "########", "########", "##....##", "##....##", "##....##", "##....##", "##....##", "##....##", "########", "########" },
    ["1"] = { "...##...", "..###...", ".####...", "...##...", "...##...", "...##...", "...##...", "...##...", "########", "########" },
    ["2"] = { "########", "########", "......##", "......##", "########", "########", "##......", "##......", "########", "########" },
    ["3"] = { "########", "########", "......##", "......##", "..######", "..######", "......##", "......##", "########", "########" },
    ["4"] = { "##....##", "##....##", "##....##", "##....##", "########", "########", "......##", "......##", "......##", "......##" },
    ["5"] = { "########", "########", "##......", "##......", "########", "########", "......##", "......##", "########", "########" },
    ["6"] = { "########", "########", "##......", "##......", "########", "########", "##....##", "##....##", "########", "########" },
    ["7"] = { "########", "########", "......##", "......##", ".....##.", "....##..", "...##...", "...##...", "...##...", "...##..." },
    ["8"] = { "########", "########", "##....##", "##....##", "########", "########", "##....##", "##....##", "########", "########" },
    ["9"] = { "########", "########", "##....##", "##....##", "########", "########", "......##", "......##", "########", "########" },
  }
  -- D-072 확정: Y3 진노랑(연한 금 → #ffd23a → 호박 노랑) + A 연출(2배 "펑" → 1배로 내려앉으며 오름). 아래쪽도 노랑에 머물러 연소 주황(#df7126)과 갈림
  -- 시안 때 비교한 것: Y1 레몬(ffffff/fffbb0/fbf236), Y2 노랑(fff7d6/fbf236/e8c81e)
  local OL = H"2a1e08"
  local V = {
    { fill = function(y) return y <= 1 and H"fff2a0" or y <= 6 and H"ffd23a" or H"f0b41e" end, ol = { OL }, shadow = OL },
  }
  local CW, CH = 8 + 6, 10 + 6   -- 칸: 글자 + 테 2겹 + 그림자 여유
  local img = Image(10 * CW, #V * CH, ColorMode.RGB)
  for vi, v in ipairs(V) do for d = 0, 9 do
    local rows = D[tostring(d)]
    local on = function(x, y) return x >= 0 and y >= 0 and x < 8 and y < 10 and rows[y + 1]:sub(x + 1, x + 1) == "#" end
    local ox, oy = d * CW + 3, (vi - 1) * CH + 3
    local function ring(k) -- 글자에서 k칸 떨어진 테두리
      for y = -k, 9 + k do for x = -k, 7 + k do
        if not on(x, y) then local near = false
          for dy = -k, k do for dx = -k, k do if on(x + dx, y + dy) then near = true end end end
          if near then img:drawPixel(ox + x, oy + y, v.ol[k]) end end
      end end
    end
    if v.shadow then for y = 0, 9 do for x = 0, 7 do if on(x, y) then img:drawPixel(ox + x, oy + y + 2, v.shadow); img:drawPixel(ox + x + 1, oy + y + 2, v.shadow) end end end end
    for k = #v.ol, 1, -1 do ring(k) end
    for y = 0, 9 do for x = 0, 7 do if on(x, y) then img:drawPixel(ox + x, oy + y, v.fill(y)) end end end
  end end
  local spr = Sprite(img.width, img.height, ColorMode.RGB); spr.cels[1].image = img
  spr:saveCopyAs(OUT .. "/ui-digits-crit.png")
  local f = io.open(OUT .. "/ui-digits-crit.json", "wb")
  f:write('{\n  "glyphs": "0123456789",\n  "cell": [14, 16],\n  "glyphOrigin": [3, 3],\n  "glyph": [8, 10],\n  "advance": 10,\n' ..
    '  "colors": "미리 입힌 색(곱하기 색 입히기 안 함): #fff2a0 → #ffd23a → #f0b41e, 외곽선·그림자 #2a1e08",\n' ..
    '  "motion": { "popScale": 2, "popMs": 60, "risePx": 10, "riseMs": 700, "lifeMs": 900 },\n' ..
    '  "note": "숫자 d의 칸 = (d × 14, 0), 글자는 칸 안 (3,3)부터 8×10. advance 10(외곽선·그림자 겹침). 처음 popMs 동안 popScale배(정수)로 그렸다가 1배로 내려앉으며 riseMs 동안 risePx 올라가고 lifeMs에 사라짐. 직접 맞힌 피해의 치명타에만 씀"\n}\n')
  f:close()

elseif WHICH == "ui-digits" then
  local SMALL = {
    ["0"] = { "####", "#..#", "#..#", "#..#", "#..#", "####" },
    ["1"] = { ".##.", "###.", ".##.", ".##.", ".##.", "####" },
    ["2"] = { "####", "...#", "####", "#...", "#...", "####" },
    ["3"] = { "####", "...#", ".###", "...#", "...#", "####" },
    ["4"] = { "#..#", "#..#", "####", "...#", "...#", "...#" },
    ["5"] = { "####", "#...", "####", "...#", "...#", "####" },
    ["6"] = { "####", "#...", "####", "#..#", "#..#", "####" },
    ["7"] = { "####", "...#", "...#", "..#.", "..#.", "..#." },
    ["8"] = { "####", "#..#", "####", "#..#", "#..#", "####" },
    ["9"] = { "####", "#..#", "####", "...#", "...#", "####" },
  }
  local BIG = {
    ["0"] = { "######", "######", "##..##", "##..##", "##..##", "##..##", "######", "######" },
    ["1"] = { "..##..", ".###..", "####..", "..##..", "..##..", "..##..", "######", "######" },
    ["2"] = { "######", "######", "....##", "######", "######", "##....", "######", "######" },
    ["3"] = { "######", "######", "....##", "..####", "..####", "....##", "######", "######" },
    ["4"] = { "##..##", "##..##", "##..##", "######", "######", "....##", "....##", "....##" },
    ["5"] = { "######", "######", "##....", "######", "######", "....##", "######", "######" },
    ["6"] = { "######", "######", "##....", "######", "######", "##..##", "######", "######" },
    ["7"] = { "######", "######", "....##", "...##.", "..##..", "..##..", "..##..", "..##.." },
    ["8"] = { "######", "######", "##..##", "######", "######", "##..##", "######", "######" },
    ["9"] = { "######", "######", "##..##", "######", "######", "....##", "######", "######" },
  }
  -- 칸 = 글자 + 외곽선 2. 작은 칸 6×8, 큰 칸 8×10. 줄 0 = 작은 숫자, 줄 1(y 8) = 큰 숫자
  local img = Image(10 * 8, 8 + 10, ColorMode.RGB)
  local W = H"ffffff"
  local function glyph(rows, ox, oy)
    local gw, gh = #rows[1], #rows
    local on = function(x, y) return x >= 0 and y >= 0 and x < gw and y < gh and rows[y + 1]:sub(x + 1, x + 1) == "#" end
    for y = -1, gh do for x = -1, gw do
      if on(x, y) then img:drawPixel(ox + 1 + x, oy + 1 + y, W)
      else local near = false
        for dy = -1, 1 do for dx = -1, 1 do if on(x + dx, y + dy) then near = true end end end
        if near then img:drawPixel(ox + 1 + x, oy + 1 + y, OL) end end
    end end
  end
  for d = 0, 9 do glyph(SMALL[tostring(d)], d * 6, 0); glyph(BIG[tostring(d)], d * 8, 8) end
  local spr = Sprite(img.width, img.height, ColorMode.RGB); spr.cels[1].image = img
  spr:saveAs(OUT .. "/ui-digits.aseprite"); spr:saveCopyAs(OUT .. "/ui-digits.png")
  local f = io.open(OUT .. "/ui-digits.json", "wb")
  f:write('{\n  "glyphs": "0123456789",\n' ..
    '  "small": { "origin": [0, 0], "cell": [6, 8], "glyph": [4, 6], "advance": 5 },\n' ..
    '  "big": { "origin": [0, 8], "cell": [8, 10], "glyph": [6, 8], "advance": 7 },\n' ..
    '  "colors": { "normal": "#ffffff", "focus": "#fbf236", "burn": "#df7126" },\n' ..
    '  "note": "숫자 k의 칸 = origin + (k × cell[0], 0). 칸끼리 외곽선 1px을 겹쳐 advance만큼 띄움. 흰 글자에 곱하기로 색을 입힘(외곽선은 어두워 그대로). 반투명 없음"\n}\n')
  f:close()
end
