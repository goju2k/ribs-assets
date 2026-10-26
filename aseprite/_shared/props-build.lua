-- 길찾기 상호작용 물체 (D-034) 원본 생성. 계약 1 형식. 돌·철 = 던전 팔레트, 불 = 손불꽃 색, 봉인 = 봉인 빛. 사각형 효과 없음.
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로>.aseprite --script props-build.lua
--   prop-brazier        꺼진 화로 24×32: off / ignite / lit(loop)
--   prop-brazier-socket hub 봉인문 옆 빈 받침 16×24: empty / ignite / lit(loop)
--   prop-seal-door      봉인문 (폭 3칸) 48×40: closed(loop) / open / opened
--   prop-cracked-wall   금 간 벽 32×40: idle / collapse / rubble
--   prop-skill-pedestal 스킬 받침대 24×32: idle(loop, 작은 불꽃이 떠 있음) / taken / empty
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local K = { o=H"141018", d=H"241e2c", s=H"362e40", m=H"4a4058", l=H"5e536e", f0=H"2a2433", f1=H"3a3245" }   -- 돌
local I = { o=H"141018", m=H"3c3644", h=H"5c5468" }                                                      -- 철
local F = { W=H"fff7d6", Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018", a=H"5a4a44", A=H"7a6a62" } -- 불 + 재
local S = { b=H"2f4a66", B=H"306082", C=H"5fcde4", c=H"cbdbfc", W=H"ffffff" }                           -- 봉인 빛
local V = H"0b0910"
local WHICH = app.params.which
local FW, FH, ANCHOR = 24, 32, { 12, 31 }
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local function rect(i, x0, y0, x1, y1, c) for y = y0, y1 do for x = x0, x1 do px(i, x, y, c) end end end
local function stoneBox(i, x0, y0, x1, y1)  -- 외곽선 + 위·왼쪽 밝은 테 + 아래·오른쪽 그늘
  for y = y0, y1 do for x = x0, x1 do local c = K.m
    if x == x0 or x == x1 or y == y0 or y == y1 then c = K.o elseif y == y0 + 1 or x == x0 + 1 then c = K.l elseif y == y1 - 1 or x == x1 - 1 then c = K.s end
    px(i, x, y, c) end end
end
-- 위로 타오르는 불꽃 (cx, by = 불꽃 바닥, h 높이, w 반폭, k 흔들림 단계)
local function flame(i, cx, by, h, w, k, pal)
  pal = pal or { F.W, F.Y, F.y, F.r }
  for y = 0, h do local t = y / h; local half = w * (1 - t * t) + 0.3; local sway = math.sin(k * 1.7 + y * 0.6) * t * 1.4
    for x = -math.ceil(half), math.ceil(half) do if math.abs(x) <= half then
      local inner = math.abs(x) < half * 0.45
      px(i, cx + x + sway, by - y, t > 0.8 and pal[4] or (inner and t < 0.35) and pal[1] or (inner and t < 0.6) and pal[2] or pal[3]) end end end
end
local CL = {}

if WHICH == "prop-brazier" or WHICH == "prop-brazier-socket" then
  local socket = WHICH == "prop-brazier-socket"
  if socket then FW, FH, ANCHOR = 16, 24, { 8, 23 } end
  local cx = FW // 2
  local function body(i)
    if socket then   -- 벽 밑동에 붙은 작은 돌 받침 + 얕은 그릇
      stoneBox(i, 3, 15, 12, 23); rect(i, 4, 13, 11, 14, I.m); px(i, 3, 13, I.o); px(i, 12, 13, I.o); for x = 4, 11 do px(i, x, 12, I.h) end
    else             -- 세 다리 철 화로 + 돌 받침
      stoneBox(i, 6, 27, 17, 31)
      for _, x in ipairs({ 8, 12, 15 }) do for y = 21, 26 do px(i, x, y, I.m) end; px(i, x, 26, I.o) end
      for x = 5, 18 do px(i, x, 20, I.o) end; for x = 4, 19 do px(i, x, 17, I.h) end
      for y = 18, 19 do for x = 5, 18 do px(i, x, y, (x == 5 or x == 18) and I.o or I.m) end end
    end
  end
  local top = socket and 12 or 17   -- 그릇 윗면 y
  local function ash(i, lit) for x = cx - 4, cx + 3 do px(i, x, top, ((x + top) % 3 == 0) and (lit and F.r or F.A) or F.a) end end
  CL[#CL+1] = { socket and "empty" or "off", false, { { 200, nil, function(i) body(i); ash(i, false) end } } }
  CL[#CL+1] = { "ignite", false, {
    { 50, "ignite:start", function(i) body(i); ash(i, true); px(i, cx, top - 1, F.Y); px(i, cx - 1, top - 1, F.y) end },
    { 60, nil, function(i) body(i); ash(i, true); flame(i, cx, top - 1, socket and 3 or 4, 1.5, 0) end },
    { 60, nil, function(i) body(i); ash(i, true); flame(i, cx, top - 1, socket and 7 or 10, socket and 2.5 or 3.5, 1, { F.W, F.W, F.Y, F.y }) end },  -- "확" 크게
    { 70, nil, function(i) body(i); ash(i, true); flame(i, cx, top - 1, socket and 6 or 9, socket and 2 or 3, 2) end },
  } }
  local L = {}
  for k = 1, 4 do L[k] = { 110, nil, function(i) body(i); ash(i, true); flame(i, cx, top - 1, (socket and 5 or 8) + (k % 2), socket and 2 or 3, k); if k % 2 == 0 then px(i, cx + (k == 2 and 2 or -2), top - (socket and 8 or 11), F.y) end end } end
  CL[#CL+1] = { "lit", true, L }

elseif WHICH == "prop-seal-door" then
  FW, FH, ANCHOR = 48, 40, { 24, 39 }   -- 폭 3칸(48), 벽면 2줄(32) + 위 여유 8
  local function slab(i, ox, half)       -- 문짝 한쪽 (half = "l"|"r"), ox 밀린 거리
    local x0, x1 = half == "l" and 0 or 24, half == "l" and 23 or 47
    for y = 8, 39 do for x = x0, x1 do local xx = x + (half == "l" and -ox or ox)
      if xx >= 0 and xx < 48 then local c = K.m
        if y == 8 or y == 39 or x == x0 or x == x1 then c = K.o elseif y == 9 then c = K.l elseif (y - 8) % 8 == 0 then c = K.s elseif y == 38 then c = K.s end
        px(i, xx, y, c) end end end
  end
  local function glyph(i, lv, split)    -- 문 가운데 봉인 문양 (원 + 십자), split이면 가운데가 갈라짐
    local g = ({ { S.b, S.B }, { S.B, S.C }, { S.C, S.c }, { S.c, S.W } })[lv]
    for a = 0, 359, 8 do local t = math.rad(a); local x, y = 24 + math.cos(t) * 9, 23 + math.sin(t) * 9
      if not (split and math.abs(math.cos(t)) < 0.15) then px(i, x, y, g[1]) end end
    for k = -6, 6 do px(i, 24 + k, 23, g[1]); if not split then px(i, 24, 23 + k, g[1]) end end
    px(i, 24, 23, g[2]); px(i, 23, 23, g[2]); px(i, 25, 23, g[2])
    if split then for y = 9, 38 do px(i, 23 + (y % 3 == 0 and 1 or 0), y, lv >= 3 and S.c or S.C) end end
  end
  local function void(i, w) for y = 9, 38 do for x = 24 - w, 23 + w do px(i, x, y, V) end end end
  CL[#CL+1] = { "closed", true, {
    { 500, nil, function(i) slab(i, 0, "l"); slab(i, 0, "r"); glyph(i, 1) end },
    { 500, nil, function(i) slab(i, 0, "l"); slab(i, 0, "r"); glyph(i, 2) end },
  } }
  CL[#CL+1] = { "open", false, {
    { 120, "open:start", function(i) slab(i, 0, "l"); slab(i, 0, "r"); glyph(i, 3) end },
    { 120, nil, function(i) slab(i, 0, "l"); slab(i, 0, "r"); glyph(i, 4) end },
    { 120, nil, function(i) slab(i, 0, "l"); slab(i, 0, "r"); glyph(i, 4, true) end },      -- 갈라짐
    { 100, nil, function(i) void(i, 3); slab(i, 3, "l"); slab(i, 3, "r"); glyph(i, 3, true) end },
    { 110, nil, function(i) void(i, 9); slab(i, 9, "l"); slab(i, 9, "r") end },
    { 120, nil, function(i) void(i, 16); slab(i, 16, "l"); slab(i, 16, "r") end },
    { 140, "open:passable", function(i) void(i, 22); slab(i, 22, "l"); slab(i, 22, "r") end },
  } }
  CL[#CL+1] = { "opened", false, { { 200, nil, function(i) void(i, 22); slab(i, 23, "l"); slab(i, 23, "r") end } } }

elseif WHICH == "prop-cracked-wall" then
  FW, FH, ANCHOR = 32, 40, { 16, 39 }    -- 벽면 2×2(32) + 아래 잔해 여유 8
  local function bricks(i, drop)         -- drop[행] = 그 줄 벽돌이 떨어진 거리 (nil = 그대로, -1 = 없음)
    for y = 0, 31 do local row = y // 4
      local dy = drop and drop[row] or 0
      if dy ~= -1 then
        local off = (row % 2) * 4
        for x = 0, 31 do local bx = (x + off) % 8; local ry = y % 4
          local c = (ry == 3 or bx == 7) and H"241e2c" or ry == 0 and K.l or ry == 2 and K.s or K.m
          px(i, x, y + dy, c) end
      end
    end
  end
  local function cracks(i, glow)
    for _, p in ipairs({ {16,2},{15,4},{16,6},{17,8},{16,10},{14,12},{15,14},{17,16},{18,18},{16,20},{15,23},{16,26},{17,29},{12,13},{11,15},{10,16},{20,17},{22,18},{23,20},{13,22},{11,24} }) do
      px(i, p[1], p[2], glow and F.r or H"141018"); px(i, p[1] + 1, p[2], H"241e2c") end
  end
  local function rubble(i, n) local seed = 5; for k = 1, n do seed = (seed * 1103515245 + 12345) % 2147483648; local x = 2 + seed % 28; local y = 34 + (seed // 97) % 5
    px(i, x, y, K.l); px(i, x + 1, y, K.m); px(i, x, y + 1, K.s); px(i, x + 1, y + 1, K.o) end end
  CL[#CL+1] = { "idle", false, { { 200, nil, function(i) bricks(i); cracks(i) end } } }
  CL[#CL+1] = { "collapse", false, {
    { 60, "collapse:start", function(i) bricks(i); cracks(i, true) end },
    { 70, nil, function(i) bricks(i, { [3]=2, [4]=2, [5]=1 }); cracks(i, true) end },
    { 80, nil, function(i) bricks(i, { [0]=-1, [1]=4, [2]=5, [3]=6, [4]=5, [5]=4, [6]=2, [7]=1 }); rubble(i, 8) end },
    { 90, "collapse:passable", function(i) bricks(i, { [0]=-1, [1]=-1, [2]=10, [3]=12, [4]=-1, [5]=-1, [6]=7, [7]=4 }); rubble(i, 16) end },
    { 110, nil, function(i) rubble(i, 26) end },
  } }
  CL[#CL+1] = { "rubble", false, { { 200, nil, function(i) rubble(i, 26) end } } }

elseif WHICH == "prop-skill-pedestal" then
  FW, FH, ANCHOR = 24, 32, { 12, 31 }
  local function pedestal(i, glow)
    stoneBox(i, 7, 18, 16, 31); stoneBox(i, 5, 16, 18, 19)
    for x = 9, 14 do px(i, x, 25, glow and S.B or K.s) end; px(i, 11, 24, glow and S.C or K.s); px(i, 12, 26, glow and S.C or K.s)   -- 새긴 문양
  end
  local function orb(i, y, k, r)
    r = r or 1
    flame(i, 12, y, 3 + r + (k % 2), 1.4 + r * 0.4, k)
    px(i, 12, y + 1, F.r); if k % 2 == 1 then px(i, 10, y - 4, F.y) end
  end
  local BOB = { 0, -1, -1, 0 }
  local L = {}; for k = 1, 4 do L[k] = { 140, nil, function(i) pedestal(i, true); orb(i, 11 + BOB[k], k) end } end
  CL[#CL+1] = { "idle", true, L }
  CL[#CL+1] = { "taken", false, {
    { 60, "taken:start", function(i) pedestal(i, true); orb(i, 10, 1, 2) end },
    { 70, nil, function(i) pedestal(i, true); orb(i, 7, 2, 1); px(i, 12, 13, F.y) end },
    { 80, nil, function(i) pedestal(i, false); px(i, 12, 4, F.Y); px(i, 12, 5, F.y) end },
  } }
  CL[#CL+1] = { "empty", false, { { 200, nil, function(i) pedestal(i, false) end } } }
end
assert(#CL > 0, "which=" .. tostring(WHICH) .. " 모름")

local total = 0; for _, c in ipairs(CL) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "prop"
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
spr:saveAs(app.params.out)
