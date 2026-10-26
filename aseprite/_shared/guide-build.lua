-- 그림 안내 (D-035): 처음 기술이 필요한 순간 한 번 뜨는 글자 없는 안내.
-- 실행: aseprite -b --script-param which=<종류> --script-param root=<ribs-assets> --script-param out=<파일/폴더> --script guide-build.lua
--   ui-key       키캡 아이콘 32×16 (기준점 가운데). clip = space / shift / e / mouse-l / mouse-r, 각각 떠 있음 ↔ 눌림 반복
--   guide-dash   64×32 반복 그림 3장: 불씨가 수호체 앞 → 몸을 뚫고 지나감 → 뒤로 빠져나옴 (수호체는 멀쩡)
--   guide-parry  64×32 반복 그림 3장: 수호체 흰 테두리 신호 → 불씨 앞 패링 섬광 → 수호체 경직
--   guide-panel  안내 패널 테두리 24×24, 9-slice 가장자리 8px. 가운데는 비움(반투명 어둠은 엔진이 칠함)
-- 수호체 그림은 export/의 실제 스프라이트를 잘라 씀. 불씨는 스타일 가이드 1-1b 색(#ffffff/#bfeaff/#6fb8f2).
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local WHICH, ROOT, OUT = app.params.which, app.params.root, app.params.out
local U = { o=H"241e2c", d=H"2e2838", e=H"3a3245", f=H"584d66", l=H"6e6380", c=H"cbdbfc", W=H"ffffff", C=H"5fcde4", B=H"306082" }
local E = { W=H"ffffff", y=H"bfeaff", r=H"6fb8f2" }   -- 불씨 가운데 / 중간 / 테
local FW, FH, ANCHOR = 32, 16, { 16, 8 }
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < i.width and y < i.height then i:drawPixel(x, y, c) end end
local function rows(i, x0, y0, art, pal) for y, r in ipairs(art) do for x = 1, #r do local k = r:sub(x, x); if pal[k] then px(i, x0 + x - 1, y0 + y - 1, pal[k]) end end end end

-- 불씨: 둥근 심(반지름 r) + 뒤로 끌리는 꼬리(dir = 꼬리 방향 -1 왼쪽 / 1 오른쪽, len 길이)
local function ember(i, cx, cy, r, tail, dir)
  dir = dir or -1
  if tail and tail > 0 then
    for k = 1, tail do
      local x = cx + dir * (r + k - 1)
      if k <= tail * 0.5 or k % 2 == 1 then px(i, x, cy, k < tail * 0.4 and E.y or E.r) end
      if k < tail * 0.6 and k % 3 ~= 0 then px(i, x, cy - 1, E.r); px(i, x, cy + 1, E.r) end
    end
  end
  for y = -r, r do for x = -r, r do
    local d = math.sqrt(x * x + y * y)
    if d <= r + 0.3 then px(i, cx + x, cy + y, d <= r * 0.35 and E.W or (d <= r * 0.7 and E.y or E.r)) end
  end end
end
local function ring(i, cx, cy, r, c, gap)
  for a = 0, 359, 4 do if not gap or gap(a) then px(i, cx + math.cos(math.rad(a)) * r, cy + math.sin(math.rad(a)) * r, c) end end
end
-- export/ 스프라이트 한 칸 잘라 붙이기 (flip = 좌우 뒤집기: 수호체가 왼쪽 불씨를 보게)
local sheets = {}
local function sprite(i, id, sx, sy, w, h, dx, dy, flip)
  local s = sheets[id] or Image{ fromFile = ROOT .. "/export/" .. id .. "/" .. id .. ".png" }; sheets[id] = s
  for y = 0, h - 1 do for x = 0, w - 1 do
    local v = s:getPixel(sx + x, sy + y)
    if app.pixelColor.rgbaA(v) > 0 then i:drawPixel(dx + (flip and (w - 1 - x) or x), dy + y, v) end
  end end
end

local CL = {}
if WHICH == "ui-key" then
  -- 키캡: 바깥선 o, 윗면 f(첫 줄 l), 앞턱 e(떠 있음 3줄 / 눌림 1줄 — 윗면이 2px 내려감). 기호 c → 눌림 W
  local function cap(i, w, p, sym)
    local x0, y0, h = 16 - w // 2, 1, 13
    for y = y0 + p * 2, y0 + h - 1 do for x = x0, x0 + w - 1 do
      local top, bot, side = y == y0 + p * 2, y == y0 + h - 1, x == x0 or x == x0 + w - 1
      local corner = (x == x0 or x == x0 + w - 1) and (top or bot)
      if not corner then
        local c
        if top or bot or side then c = U.o
        elseif y <= y0 + 8 + p * 2 then c = (y == y0 + p * 2 + 1) and U.l or U.f
        else c = U.e end
        px(i, x, y, c)
      end
    end end
    sym(i, 16, y0 + 5 + p * 2, p == 1 and U.W or U.c)
  end
  local SYM = {
    e = { 5, function(i, cx, cy, c) rows(i, cx - 1, cy - 2, { "###", "#..", "##.", "#..", "###" }, { ["#"] = c }) end },
    shift = { 13, function(i, cx, cy, c) rows(i, cx - 3, cy - 3, { "...#...", "..#.#..", ".#...#.", "##...##", ".#...#.", ".#####." }, { ["#"] = c }) end },
    space = { 29, function(i, cx, cy, c) rows(i, cx - 7, cy - 1, { "#.............#", "#.............#", "###############" }, { ["#"] = c }) end },
  }
  for _, k in ipairs({ "space", "shift", "e" }) do
    local w = SYM[k][1] + 2
    if k == "e" then w = 13 elseif k == "shift" then w = 19 end
    CL[#CL+1] = { k, true, {
      { 450, nil, function(i) cap(i, w, 0, SYM[k][2]) end },
      { 220, nil, function(i) cap(i, w, 1, SYM[k][2]) end },
    } }
  end
  -- 마우스: 몸통 11×15, 위쪽 반이 두 버튼(가운데 줄로 나눔). 누를 버튼만 밝게 → 눌림 때 흰색 + 1px 내려앉음
  local function mouse(i, side, p)
    local x0, y0, w, h = 11, 0, 11, 15
    local function inside(x, y) local dx, dy = math.min(x - x0, x0 + w - 1 - x), math.min(y - y0, y0 + h - 1 - y); return not ((dx == 0 and dy <= 1) or (dx <= 1 and dy == 0)) end
    for y = y0, y0 + h - 1 do for x = x0, x0 + w - 1 do if inside(x, y) then
      local edge = not inside(x - 1, y) or not inside(x + 1, y) or not inside(x, y - 1) or not inside(x, y + 1) or x == x0 or x == x0 + w - 1 or y == y0 or y == y0 + h - 1
      local c = edge and U.o or (y <= y0 + 6 and U.f or U.e)
      if not edge and y == y0 + 6 then c = U.o end                       -- 버튼 아래 경계
      if not edge and y < y0 + 6 and x == x0 + 5 then c = U.o end         -- 두 버튼 사이
      local mine = (side == "l" and x < x0 + 5) or (side == "r" and x > x0 + 5)
      if not edge and y < y0 + 6 and mine then c = (y == y0 + 1 + p) and U.W or (p == 1 and U.c or U.C); if p == 1 and y == y0 + 1 then c = U.e end end
      px(i, x, y, c)
    end end end
  end
  CL[#CL+1] = { "mouse-l", true, { { 450, nil, function(i) mouse(i, "l", 0) end }, { 220, nil, function(i) mouse(i, "l", 1) end } } }
  CL[#CL+1] = { "mouse-r", true, { { 450, nil, function(i) mouse(i, "r", 0) end }, { 220, nil, function(i) mouse(i, "r", 1) end } } }

elseif WHICH == "guide-dash" then
  FW, FH, ANCHOR = 64, 32, { 32, 31 }
  -- 각성형(28×24, 기준점 14,20) chase 1번 칸을 가운데(x 32)에, 왼쪽을 보게
  local function foe(i) sprite(i, "sentinel-awakened", 0, 48, 28, 24, 18, 6, true) end
  CL[#CL+1] = { "loop", true, {
    { 450, nil, function(i) foe(i); ember(i, 9, 20, 3, 3, -1) end },                       -- 수호체 앞
    { 140, nil, function(i) foe(i); ember(i, 40, 20, 2, 28, -1) end },                     -- 몸을 뚫고 지나감 (꼬리가 수호체 위로)
    { 500, nil, function(i) foe(i); ember(i, 55, 20, 3, 4, -1) end },                      -- 뒤로 빠져나옴, 수호체는 그대로
  } }

elseif WHICH == "guide-parry" then
  FW, FH, ANCHOR = 64, 32, { 32, 31 }
  -- 근접형(36×32) 행: windup y64(4번째 칸 = 흰 테두리 신호), attack y128, stun y192. 오른쪽에서 왼쪽 불씨를 보게
  local function foe(i, sx, sy) sprite(i, "sentinel-melee", sx, sy, 36, 32, 24, 0, true) end
  CL[#CL+1] = { "loop", true, {
    { 500, nil, function(i) foe(i, 108, 64); ember(i, 12, 20, 3, 2, -1) end },                                  -- 흰 테두리 = 지금
    { 160, nil, function(i) foe(i, 0, 128); ember(i, 12, 20, 3, 0)                                               -- 패링 섬광 (방어 고리)
        ring(i, 15, 20, 6, U.W, function(a) return a < 90 or a > 270 end); ring(i, 15, 20, 8, U.c, function(a) return (a < 60 or a > 300) and a % 16 < 8 end)
        px(i, 23, 16, U.W); px(i, 24, 24, U.c); px(i, 22, 20, U.W) end },
    { 500, nil, function(i) foe(i, 36, 192); ember(i, 11, 20, 3, 0) end },                                      -- 수호체 경직 (튕겨남)
  } }

elseif WHICH == "guide-panel" then
  local S, Q = 24, 8
  local img = Image(S, S, ColorMode.RGB)
  for y = 0, S - 1 do for x = 0, S - 1 do
    local d = math.min(x, y, S - 1 - x, S - 1 - y)
    local corner = (x == 0 or x == S - 1) and (y == 0 or y == S - 1)
    if not corner then
      if d == 0 then img:drawPixel(x, y, U.o)
      elseif d == 1 then img:drawPixel(x, y, (x < S / 2 and y < S / 2) and U.l or U.f)
      elseif d == 2 then img:drawPixel(x, y, U.o) end
    end
  end end
  for _, c in ipairs({ {4,4}, {S - 5, 4}, {4, S - 5}, {S - 5, S - 5} }) do img:drawPixel(c[1], c[2], U.B) end   -- 귀퉁이 봉인 점
  local spr = Sprite(S, S, ColorMode.RGB); spr.cels[1].image = img
  spr:saveAs(OUT .. "/guide-panel.aseprite"); spr:saveCopyAs(OUT .. "/guide-panel.png")
  local f = io.open(OUT .. "/guide-panel.json", "wb")
  f:write('{\n  "size": [24, 24],\n  "slice": [8, 8, 8, 8],\n  "note": "테두리만 불투명(바깥 3px). 가운데는 투명 — 엔진이 반투명 어둠을 칠함. CSS: border-image: url(guide-panel.png) 8 / <8×배율>px round; image-rendering: pixelated"\n}\n')
  f:close()
  return
end
assert(#CL > 0, "which=" .. tostring(WHICH) .. " 모름")

local total = 0; for _, c in ipairs(CL) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "guide"
for k = 2, total do spr:newEmptyFrame() end
local n = 0
for _, c in ipairs(CL) do
  local from = n + 1
  for _, f in ipairs(c[3]) do
    n = n + 1
    local img = Image(FW, FH, ColorMode.RGB); f[3](img)
    local cel = spr:newCel(spr.layers[1], n, img)
    if f[2] then cel.data = f[2] end
    spr.frames[n].duration = f[1] / 1000
  end
  local tag = spr:newTag(from, n); tag.name = c[1]; if c[2] then tag.data = "loop" end
end
spr.data = "facing=right;anchor=" .. ANCHOR[1] .. "," .. ANCHOR[2]
spr:saveAs(OUT)
