-- 스킬·콤보 v1 (D-031) 효과·UI 원본 생성. 계약 1 형식(.aseprite → export-anim.sh). 불 원소, 스타일 가이드 색, 사각형 없음.
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로>.aseprite --script combo-build.lua
--   fx-fire-fan          불꽃 3갈래 (L 마무리): muzzle(손끝 부채꼴 섬광) / blast(착탄 작은 폭발). 날아가는 탄은 fx-fireball projectile을 3발로
--   fx-fire-pillar-big   큰 불기둥 (R 마무리, 반지름 26): rise / burn(loop) / fade / smolder(loop, 남는 연소)
--   fx-fire-pillar-quick 빠른 불기둥 (R 연결타, 반지름 12): burst (짧고 날렵)
--   fx-focus             "집중" 강화: ring (마무리에 덧입히는 불꽃 고리, 1회)
--   ui-combo             콤보 UI 7×7: slot-empty / slot-l / slot-r (칸 5×5) / gain-focus / gain-switch / gain-rhythm (떠오름 3프레임)
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local F = { W=H"fff7d6", Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018", a=H"3a1a14" }   -- 손불꽃 (+ 거의 흰 심, 재)
local U = { o=H"241e2c", e=H"3a3245", f=H"584d66", W=H"ffffff", c=H"cbdbfc" }               -- UI 테·빈 칸 (돌 팔레트) + 방어 계열
local WHICH = app.params.which
local seed = 3
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local FW, FH, ANCHOR = 16, 16, { 8, 8 }
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local function blob(i, cx, cy, r, pal, s, ry, jag)
  seed = s or 7; ry = ry or 1; jag = jag or 0.3
  local R = {}; for k = 0, 15 do R[k] = r * (1 - jag / 2 + rnd() * jag) end
  for y = math.floor(-r * ry) - 1, math.ceil(r * ry) + 1 do for x = -r - 1, r + 1 do
    local a = math.atan(y / ry, x); local k = math.floor(((a + math.pi) / (2 * math.pi)) * 16) % 16
    local d = math.sqrt(x * x + (y / ry) ^ 2) / R[k]
    if d <= 1 then px(i, cx + x, cy + y, d < 0.35 and pal[1] or d < 0.7 and pal[2] or pal[3]) end
  end end
end
-- 불기둥 몸통: 여러 갈래 불꽃 혀 (w 폭, h 높이)
local function column(i, cx, by, h, w, s)
  seed = s
  local n = math.max(3, math.floor(w / 3))
  for t = 0, n - 1 do
    local x0 = cx + (t - (n - 1) / 2) * (w / n) + (rnd() - 0.5) * 2
    local hh = h * (0.55 + rnd() * 0.45) * (1 - math.abs(t - (n - 1) / 2) / n * 0.6)
    local half0 = (w / n) * 0.8
    for y = 0, math.floor(hh) do local frac = y / hh; local half = math.max(0, (1 - frac) * half0)
      local sway = math.sin((y + s) * 0.33) * 1.3
      for x = -math.floor(half), math.floor(half) do local inner = math.abs(x) < half * 0.45
        px(i, x0 + x + sway, by - 2 - y, frac > 0.82 and F.r or (inner and frac < 0.5) and (frac < 0.2 and F.W or F.Y) or F.y) end end
  end
end
local function embers(i, cx, by, n, wspread, h, s) seed = s; for k = 1, n do px(i, cx + (rnd() - 0.5) * wspread, by - 3 - rnd() * h, rnd() < 0.5 and F.y or F.r) end end

local CL = {}
if WHICH == "fx-fire-fan" then
  FW, FH, ANCHOR = 24, 24, { 4, 12 }   -- anchor = 손끝 (오른쪽으로 부채꼴, 각 ±20°)
  local ox, oy = 4, 12
  local function tongue(i, ang, len, w, s)
    seed = s
    for k = 0, len do local t = k / len; local x = ox + math.cos(ang) * k; local y = oy + math.sin(ang) * k
      local half = (1 - t) * w
      for d = -math.floor(half), math.floor(half) do px(i, x - math.sin(ang) * d, y + math.cos(ang) * d, t < 0.3 and F.W or t < 0.6 and F.Y or t < 0.85 and F.y or F.r) end end
  end
  CL[#CL+1] = { "muzzle", false, {
    { 33, "fan:release", function(i) blob(i, ox, oy, 3, { F.W, F.Y, F.y }, 11); for _, a in ipairs({ -0.35, 0, 0.35 }) do tongue(i, a, 9, 1.5, 12) end end },
    { 40, nil, function(i) blob(i, ox + 1, oy, 2, { F.Y, F.y, F.r }, 13); for _, a in ipairs({ -0.35, 0, 0.35 }) do tongue(i, a, 13, 1, 14) end end },
    { 50, nil, function(i) for _, a in ipairs({ -0.38, 0, 0.38 }) do for k = 10, 16, 3 do px(i, ox + math.cos(a) * k, oy + math.sin(a) * k, F.r) end end end },
  } }
  CL[#CL+1] = { "blast", false, {   -- 착탄 작은 폭발 (fx-fireball impact보다 둥글고 큼)
    { 40, "blast:start", function(i) blob(i, 12, 12, 5, { F.W, F.Y, F.y }, 21, 1, 0.4) end },
    { 40, nil, function(i) blob(i, 12, 12, 7, { F.Y, F.y, F.r }, 22, 1, 0.5); for k = 0, 7 do local a = k * 0.785 + 0.2; px(i, 12 + math.cos(a) * 10, 12 + math.sin(a) * 9, F.y) end end },
    { 50, nil, function(i) blob(i, 12, 12, 6, { F.y, F.r, F.d }, 23, 1, 0.6); for k = 0, 7 do local a = k * 0.785 + 0.5; px(i, 12 + math.cos(a) * 11, 12 + math.sin(a) * 10 - 1, F.r) end end },
    { 60, nil, function(i) blob(i, 12, 13, 3, { F.r, F.d, F.a }, 24, 1, 0.7); for k = 0, 5 do local a = k * 1.05; px(i, 12 + math.cos(a) * 9, 11 + math.sin(a) * 7 - 2, F.d) end end },
  } }

elseif WHICH == "fx-fire-pillar-big" then
  FW, FH, ANCHOR = 64, 80, { 32, 70 }   -- 바닥 중심, 반지름 26 → 바닥 타원 52×20
  local cx, by = 32, 70
  local function base(i, r, s, pal) blob(i, cx, by, r, pal or { F.y, F.r, F.d }, s, 0.4, 0.3) end
  CL[#CL+1] = { "rise", false, {
    { 50, "pillar:start", function(i) base(i, 10, 61, { F.W, F.Y, F.y }) end },
    { 50, nil, function(i) base(i, 18, 62, { F.Y, F.y, F.r }); column(i, cx, by, 22, 14, 63) end },
    { 50, nil, function(i) base(i, 26, 64); column(i, cx, by, 46, 22, 64) end },
    { 60, nil, function(i) base(i, 26, 65); column(i, cx, by, 62, 26, 65); embers(i, cx, by, 8, 46, 66, 66) end },
  } }
  CL[#CL+1] = { "burn", true, {
    { 70, nil, function(i) base(i, 26, 71); column(i, cx, by, 56, 24, 71); embers(i, cx, by, 7, 46, 64, 72) end },
    { 70, nil, function(i) base(i, 26, 73); column(i, cx, by, 60, 26, 74); embers(i, cx, by, 7, 46, 64, 75) end },
    { 70, nil, function(i) base(i, 26, 76); column(i, cx, by, 52, 24, 77); embers(i, cx, by, 7, 46, 64, 78) end },
    { 70, nil, function(i) base(i, 26, 79); column(i, cx, by, 58, 26, 80); embers(i, cx, by, 7, 46, 64, 81) end },
  } }
  CL[#CL+1] = { "fade", false, {
    { 70, "pillar:end", function(i) base(i, 24, 91, { F.r, F.d, F.d }); column(i, cx, by, 28, 16, 92); embers(i, cx, by, 8, 46, 48, 93) end },
    { 80, nil, function(i) base(i, 20, 94, { F.d, F.d, F.a }); embers(i, cx, by, 7, 40, 36, 95) end },
    { 90, nil, function(i) embers(i, cx, by, 5, 36, 24, 96) end },
  } }
  CL[#CL+1] = { "smolder", true, {   -- 연소: 바닥에 남는 낮은 불꽃 (지속 시간만큼 반복)
    { 120, nil, function(i) base(i, 22, 101, { F.r, F.d, F.a }); for k = 0, 6 do local x = cx - 18 + k * 6; column(i, x, by + 1, 5 + (k % 3), 3, 102 + k) end end },
    { 120, nil, function(i) base(i, 22, 103, { F.r, F.d, F.a }); for k = 0, 6 do local x = cx - 16 + k * 6; column(i, x, by + 1, 4 + ((k + 1) % 3), 3, 110 + k) end end },
    { 120, nil, function(i) base(i, 22, 105, { F.r, F.d, F.a }); for k = 0, 6 do local x = cx - 18 + k * 6; column(i, x, by + 1, 6 - (k % 3), 3, 118 + k) end; embers(i, cx, by, 3, 40, 14, 125) end },
  } }

elseif WHICH == "fx-fire-pillar-quick" then
  FW, FH, ANCHOR = 32, 40, { 16, 34 }   -- 바닥 중심, 반지름 12
  local cx, by = 16, 34
  CL[#CL+1] = { "burst", false, {
    { 30, "pillar:start", function(i) blob(i, cx, by, 6, { F.W, F.Y, F.y }, 131, 0.4) end },
    { 35, nil, function(i) blob(i, cx, by, 12, { F.Y, F.y, F.r }, 132, 0.4); column(i, cx, by, 20, 9, 133) end },
    { 40, nil, function(i) blob(i, cx, by, 12, { F.y, F.r, F.d }, 134, 0.4); column(i, cx, by, 28, 10, 135) end },
    { 45, nil, function(i) blob(i, cx, by, 10, { F.r, F.d, F.d }, 136, 0.4); column(i, cx, by, 14, 7, 137); embers(i, cx, by, 4, 20, 26, 138) end },
    { 50, "pillar:end", function(i) embers(i, cx, by, 4, 18, 16, 139) end },
  } }

elseif WHICH == "fx-focus" then
  FW, FH, ANCHOR = 48, 48, { 24, 24 }   -- 마무리 효과 중심에 덧입힘
  local function ring(i, r, pal, s, gaps)
    seed = s
    for a = 0, 359, 4 do if not (gaps and (a % gaps) < gaps / 3) then local t = math.rad(a); local rr = r + (rnd() - 0.5) * 1.6
      local x, y = 24 + math.cos(t) * rr, 24 + math.sin(t) * rr * 0.8
      px(i, x, y, pal[1]); px(i, x, y - 1, pal[2]); if rnd() < 0.4 then px(i, x, y - 2, pal[3]) end end end
  end
  CL[#CL+1] = { "ring", false, {
    { 35, "focus:start", function(i) ring(i, 8, { F.W, F.Y, F.y }, 141) end },
    { 40, nil, function(i) ring(i, 13, { F.Y, F.y, F.r }, 142); ring(i, 7, { F.Y, F.y, F.y }, 143, 45) end },
    { 45, nil, function(i) ring(i, 17, { F.y, F.r, F.d }, 144, 30) end },
    { 55, nil, function(i) ring(i, 20, { F.r, F.d, F.d }, 145, 20) end },
  } }

elseif WHICH == "ui-combo" then
  FW, FH, ANCHOR = 7, 7, { 3, 3 }
  local function slot(i, fill)
    for y = 1, 5 do for x = 1, 5 do local edge = x == 1 or x == 5 or y == 1 or y == 5; local corner = (x == 1 or x == 5) and (y == 1 or y == 5)
      if not corner then px(i, x, y, edge and U.o or U.e) end end end
    if fill == "l" then px(i, 3, 3, F.Y); px(i, 2, 3, F.y); px(i, 4, 3, F.y); px(i, 3, 2, F.y); px(i, 3, 4, F.r)          -- 불꽃 점 (둥근 불씨)
    elseif fill == "r" then px(i, 3, 2, F.Y); px(i, 3, 3, F.y); px(i, 3, 4, F.y); px(i, 2, 4, F.r); px(i, 4, 4, F.r) end  -- 기둥 점 (세로 불기둥)
  end
  local ICON = {
    focus  = { "..Y..", ".YyY.", "YyWyY", ".YyY.", "..r.." },   -- 집중: 겹친 불꽃 (안쪽이 흰 심)
    switch = { "y.y..", ".Y.Y.", "..Y.Y", ".Y.Y.", "y.y.." },   -- 전환: 겹 화살표(») — 옆으로 빠짐
    rhythm = { "Y...Y", ".y.y.", "..Y..", ".y.y.", "Y...Y" },   -- 리듬: 번갈음 (교차)
  }
  local P = { Y=F.Y, y=F.y, r=F.r, W=F.W }
  local function icon(i, name, dy, glow)
    for y, r in ipairs(ICON[name]) do for x = 1, 5 do px(i, x, y + dy, P[r:sub(x, x)]) end end
    if glow then for _, d in ipairs({ {0,3}, {6,3}, {3,0}, {3,6} }) do px(i, d[1], d[2] + dy, F.d) end end
  end
  CL[#CL+1] = { "slot-empty", false, { { 100, nil, function(i) slot(i) end } } }
  CL[#CL+1] = { "slot-l", false, { { 100, nil, function(i) slot(i, "l") end } } }
  CL[#CL+1] = { "slot-r", false, { { 100, nil, function(i) slot(i, "r") end } } }
  for _, n in ipairs({ "focus", "switch", "rhythm" }) do
    CL[#CL+1] = { "gain-" .. n, false, {   -- 짧게 떠오름: 아래에서 1px 올라오며 번쩍 → 유지
      { 60, nil, function(i) icon(i, n, 1, true) end },
      { 60, nil, function(i) icon(i, n, 0, true) end },
      { 300, nil, function(i) icon(i, n, 0) end },
    } }
  end
end
assert(#CL > 0, "which=" .. tostring(WHICH) .. " 모름")

local total = 0; for _, c in ipairs(CL) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "fx"
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
