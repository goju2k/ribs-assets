-- 전투 UI (D-044): 적 체력바 + 데미지 숫자 픽셀 글꼴. 쓸어버리는 전투에서 한눈에 읽히게.
-- 실행: aseprite -b --script-param which=ui-hpbar|ui-digits --script-param out=<폴더> --script ui-build.lua
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
