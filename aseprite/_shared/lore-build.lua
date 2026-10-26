-- "알 수 없는 기록" (D-034) UI 원본: 고대 문자 기호 시트 + 기록창 돌판 테두리(9-slice).
-- 실행: aseprite -b --script-param which=glyphs|record-frame --script-param out=<폴더> --script lore-build.lua
--   glyphs        9×9 기호 40개 (10×10 칸, 8열×5행 = 80×50). 봉인 문양 기하(P-017): 고리·마름모·십자·대각·눈금·점 조합.
--                 서로 최소 8픽셀 이상 다른 것만 골라 구분이 잘 되게. 한 가지 색(흰색) — 화면에서 색을 입혀 씀.
--                 출력: glyphs.png + glyphs.json { cell, glyph, columns, count }
--   record-frame  기록창 돌판 테두리 48×48, 9-slice 가장자리 16px. 가운데는 고른 돌색(늘려도 줄무늬 없음).
--                 출력: record-frame.png + record-frame.json { slice: [위,오른,아래,왼] }
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local WHICH, OUT = app.params.which, app.params.out

if WHICH == "glyphs" then
  local N = 9
  -- 부품 (9×9 좌표 0~8, 가운데 4)
  local function on(set, x, y) if x >= 0 and y >= 0 and x < N and y < N then set[y * N + x] = true end end
  local P = {}
  P.diamond = function(s) for k = 0, 4 do on(s, 4 - k, k); on(s, 4 + k, k); on(s, 4 - k, 8 - k); on(s, 4 + k, 8 - k) end end
  P.ring = function(s) for _, p in ipairs({ {3,0},{4,0},{5,0},{2,1},{6,1},{1,2},{7,2},{0,3},{8,3},{0,4},{8,4},{0,5},{8,5},{1,6},{7,6},{2,7},{6,7},{3,8},{4,8},{5,8} }) do on(s, p[1], p[2]) end end
  P.vee = function(s) for k = 0, 4 do on(s, k, k * 2 / 1 // 1 > 8 and 8 or k * 2); on(s, 8 - k, k * 2) end end
  P.arcTop = function(s) for _, p in ipairs({ {2,1},{3,0},{4,0},{5,0},{6,1},{1,2},{7,2} }) do on(s, p[1], p[2]) end end
  P.arcBot = function(s) for _, p in ipairs({ {2,7},{3,8},{4,8},{5,8},{6,7},{1,6},{7,6} }) do on(s, p[1], p[2]) end end
  P.arcLeft = function(s) for _, p in ipairs({ {1,2},{0,3},{0,4},{0,5},{1,6},{2,1},{2,7} }) do on(s, p[1], p[2]) end end
  P.arcRight = function(s) for _, p in ipairs({ {7,2},{8,3},{8,4},{8,5},{7,6},{6,1},{6,7} }) do on(s, p[1], p[2]) end end
  P.bars = function(s) for y = 2, 6 do on(s, 0, y); on(s, 8, y) end end
  P.vfull = function(s) for y = 0, 8 do on(s, 4, y) end end
  P.vtop = function(s) for y = 0, 4 do on(s, 4, y) end end
  P.vbot = function(s) for y = 4, 8 do on(s, 4, y) end end
  P.hfull = function(s) for x = 0, 8 do on(s, x, 4) end end
  P.hhalf = function(s) for x = 2, 6 do on(s, x, 4) end end
  P.diagA = function(s) for k = 1, 7 do on(s, k, k) end end
  P.diagB = function(s) for k = 1, 7 do on(s, 8 - k, k) end end
  P.dot = function(s) on(s, 4, 4) end
  P.small = function(s) for _, p in ipairs({ {4,2},{3,3},{5,3},{2,4},{6,4},{3,5},{5,5},{4,6} }) do on(s, p[1], p[2]) end end
  P.ticks = function(s) on(s, 4, 0); on(s, 4, 1); on(s, 0, 4); on(s, 1, 4); on(s, 8, 4); on(s, 7, 4); on(s, 4, 8); on(s, 4, 7) end
  P.corners = function(s) for _, p in ipairs({ {1,1},{7,1},{1,7},{7,7} }) do on(s, p[1], p[2]) end end
  P.dots2 = function(s) on(s, 2, 4); on(s, 6, 4) end
  P.dots3 = function(s) on(s, 4, 2); on(s, 2, 6); on(s, 6, 6) end
  local FRAMES = { "none", "diamond", "ring", "arcTop", "arcBot", "bars", "arcLeft", "arcRight" }
  local INNER = { "vfull", "hfull", "dot", "small", "diagA", "diagB", "vtop", "vbot", "hhalf", "ticks", "corners", "dots2", "dots3",
    "vfull+hfull", "diagA+diagB", "small+dot", "vtop+hhalf", "vbot+hhalf", "dots2+vfull", "corners+dot", "dots3+vbot", "diagA+vfull", "ticks+dot", "diagB+hhalf", "small+vfull", "dots3+hhalf", "corners+hfull", "ticks+diagA", "dots2+vtop" }
  local function build(frame, inner)
    local s = {}
    if frame ~= "none" then P[frame](s) end
    for part in inner:gmatch("[^+]+") do P[part](s) end
    return s
  end
  local function count(s) local n = 0; for _ in pairs(s) do n = n + 1 end; return n end
  local function diff(a, b) local d = 0; for k in pairs(a) do if not b[k] then d = d + 1 end end; for k in pairs(b) do if not a[k] then d = d + 1 end end; return d end
  -- 후보를 틀 순서·속 순서로 섞어 늘어놓고, 앞에서부터 기존 것들과 모두 8픽셀 이상 다르면 채택
  local cand = {}
  for i = 1, #INNER do for f = 1, #FRAMES do cand[#cand+1] = { FRAMES[(f + i) % #FRAMES + 1], INNER[i] } end end
  local picked = {}
  for _, c in ipairs(cand) do
    local s = build(c[1], c[2])
    local n = count(s)
    if n >= 6 and n <= 34 then
      local ok = true
      for _, p in ipairs(picked) do if diff(s, p.s) < 8 then ok = false; break end end
      if ok then picked[#picked+1] = { s = s, name = c[1] .. "|" .. c[2] } end
    end
    if #picked == 40 then break end
  end
  assert(#picked == 40, "기호가 40개 안 됨: " .. #picked)
  local CELL, COLS, ROWS = 10, 8, 5
  local img = Image(CELL * COLS, CELL * ROWS, ColorMode.RGB)
  local W = H"ffffff"
  local names = {}
  for k, p in ipairs(picked) do
    local cx, cy = ((k - 1) % COLS) * CELL, ((k - 1) // COLS) * CELL
    for key in pairs(p.s) do img:drawPixel(cx + key % N, cy + key // N, W) end
    names[#names+1] = '"' .. p.name .. '"'
  end
  local spr = Sprite(img.width, img.height, ColorMode.RGB); spr.cels[1].image = img
  spr:saveAs(OUT .. "/glyphs.aseprite"); spr:saveCopyAs(OUT .. "/glyphs.png")
  local f = io.open(OUT .. "/glyphs.json", "wb")
  f:write('{\n  "cell": [10, 10],\n  "glyph": [9, 9],\n  "columns": 8,\n  "count": 40,\n  "note": "기호 k(0부터)는 (k % 8 * 10, floor(k / 8) * 10)의 9x9. 흰색 한 가지 — 화면에서 색을 입힘. 이름은 만든 부품(틀|속)",\n  "parts": [' .. table.concat(names, ", ") .. ']\n}\n')
  f:close()

elseif WHICH == "record-frame" then
  local S, E = 48, 16
  local C = { o=H"141018", d=H"241e2c", s=H"2e2838", m=H"3a3245", f=H"4a4058", l=H"5e536e", g=H"306082", G=H"5fcde4" }
  local img = Image(S, S, ColorMode.RGB)
  local seed = 9
  local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
  for y = 0, S - 1 do for x = 0, S - 1 do
    local d = math.min(x, y, S - 1 - x, S - 1 - y)      -- 가장자리까지 거리
    local c
    if d == 0 then c = C.o
    elseif d == 1 then c = (x < S / 2 and y < S / 2) and C.l or C.f   -- 바깥 테 (위·왼쪽 밝게)
    elseif d <= 9 then c = (rnd() < 0.12) and C.s or C.f               -- 돌판 테두리 띠 (거친 질감)
    elseif d == 10 then c = C.d                                         -- 안쪽 홈 (새긴 선)
    elseif d == 11 then c = C.l
    else c = C.m end                                                    -- 안쪽 면: 고른 색 (늘려도 무늬 없음)
    if d >= 3 and d <= 7 and (rnd() < 0.05) then c = C.l end
    img:drawPixel(x, y, c)
  end end
  -- 네 귀퉁이 봉인 문양 장식 (마름모 + 가운데 점) — 9-slice 귀퉁이 안에만
  for _, c0 in ipairs({ {5,5}, {S - 6, 5}, {5, S - 6}, {S - 6, S - 6} }) do
    for k = 0, 2 do for _, s in ipairs({ {1,1}, {1,-1}, {-1,1}, {-1,-1} }) do
      img:drawPixel(c0[1] + s[1] * k, c0[2] + s[2] * (2 - k), C.g) end end
    img:drawPixel(c0[1], c0[2], C.G)
  end
  local spr = Sprite(S, S, ColorMode.RGB); spr.cels[1].image = img
  spr:saveAs(OUT .. "/record-frame.aseprite"); spr:saveCopyAs(OUT .. "/record-frame.png")
  local f = io.open(OUT .. "/record-frame.json", "wb")
  f:write('{\n  "size": [48, 48],\n  "slice": [16, 16, 16, 16],\n  "note": "CSS: border-image: url(record-frame.png) 16 fill / <16×배율>px round; image-rendering: pixelated. 가운데(16~32)는 고른 돌색이라 늘려도 됨. 귀퉁이 16px 안에 봉인 문양 장식"\n}\n')
  f:close()
end
