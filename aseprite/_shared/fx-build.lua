-- 전투 효과 원본 생성 (D-025). 계약 1 형식(.aseprite → export-anim.sh). 원칙: 각진 사각형 없이 둥글고 불규칙한 픽셀, 스타일 가이드 색만.
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로>.aseprite --script fx-build.lua
--   fx-fireball    불꽃탄: projectile(loop) / impact          — 손불꽃 3색, 오른쪽을 봄 (꼬리는 왼쪽)
--   fx-hit         수호체 피격 섬광: hit (2프레임 흰빛)       — 방어 계열 흰색·연청
--   fx-seal-shards 수호체 정지 소멸: shatter (봉인 빛 파편)   — 봉인 빛 3단계
--   fx-fire-pillar 불기둥: rise / burn(loop) / fade (반지름 20px) — 손불꽃 3색 + 어두운 빨강
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local F = { Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018" }            -- 손불꽃 + 어두운 빨강
local S = { W=H"ffffff", c=H"cbdbfc", C=H"5fcde4", B=H"306082", b=H"2f4a66" } -- 방어 계열 / 봉인 빛
local WHICH = app.params.which
local seed = 7
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local FW, FH

local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
-- 불규칙한 둥근 덩어리: 각도마다 반지름을 조금씩 흔듦. pal = { 가운데, 중간, 테 }, ry = 세로 비율
local function blob(i, cx, cy, r, pal, s, ry, jag)
  seed = s or 7; ry = ry or 1; jag = jag or 0.25
  local R = {}; for k = 0, 15 do R[k] = r * (1 - jag / 2 + rnd() * jag) end
  for y = math.floor(-r * ry) - 1, math.ceil(r * ry) + 1 do for x = -r - 1, r + 1 do
    local a = math.atan(y / ry, x); local k = math.floor(((a + math.pi) / (2 * math.pi)) * 16) % 16
    local d = math.sqrt(x * x + (y / ry) ^ 2) / R[k]
    if d <= 1 then px(i, cx + x, cy + y, d < 0.4 and pal[1] or d < 0.75 and pal[2] or pal[3]) end
  end end
end
local function dot(i, x, y, c) px(i, x, y, c) end

local CL = {}   -- { 이름, loop, { {ms, 태그, 그리기} } }
local ANCHOR, FACING

if WHICH == "fx-fireball" then
  FW, FH = 24, 12; ANCHOR = { 16, 6 }; FACING = "right"
  local cx, cy = 16, 6
  local function ball(i, k)
    for t = 1, 8 do local c = t < 3 and F.y or t < 6 and F.r or F.d   -- 꼬리 (뒤=왼쪽)
      if t % 3 ~= (k % 3) then dot(i, cx - 2 - t, cy + ((t + k) % 4 == 0 and 1 or (t + k) % 4 == 2 and -1 or 0), c) end end
    blob(i, cx, cy, 3, { F.Y, F.y, F.r }, 10 + k, 1, 0.35)
    dot(i, cx + 1 + (k % 2), cy - 3, F.y)
  end
  CL[#CL+1] = { "projectile", true, { {60, nil, function(i) ball(i, 0) end}, {60, nil, function(i) ball(i, 1) end}, {60, nil, function(i) ball(i, 2) end}, {60, nil, function(i) ball(i, 3) end} } }
  CL[#CL+1] = { "impact", false, {
    {40, "impact:start", function(i) blob(i, cx, cy, 4, { F.Y, F.Y, F.y }, 21, 1, 0.4) end},
    {40, nil, function(i) blob(i, cx, cy, 5, { F.Y, F.y, F.r }, 22, 1, 0.5); for k = 0, 5 do local a = k * 1.05 + 0.3; dot(i, cx + math.cos(a) * 7, cy + math.sin(a) * 5, F.y) end end},
    {50, nil, function(i) blob(i, cx, cy, 3, { F.y, F.r, F.d }, 23, 1, 0.6); for k = 0, 5 do local a = k * 1.05 + 0.6; dot(i, cx + math.cos(a) * 8, cy + math.sin(a) * 6 - 1, F.r) end end},
    {60, nil, function(i) for k = 0, 4 do local a = k * 1.25 + 0.2; dot(i, cx + math.cos(a) * 6, cy + math.sin(a) * 4 - 2, F.d) end; dot(i, cx, cy - 4, F.r) end},
  } }

elseif WHICH == "fx-hit" then
  FW, FH = 16, 16; ANCHOR = { 8, 8 }; FACING = "right"
  CL[#CL+1] = { "hit", false, {
    {33, "hit:start", function(i) blob(i, 8, 8, 4, { S.W, S.W, S.c }, 31, 1, 0.5); for k = 0, 3 do local a = k * 1.57 + 0.4; dot(i, 8 + math.cos(a) * 6, 8 + math.sin(a) * 6, S.W) end end},
    {33, nil, function(i) for k = 0, 7 do local a = k * 0.785 + 0.2; local r = 5 + (k % 2); dot(i, 8 + math.cos(a) * r, 8 + math.sin(a) * r, k % 2 == 0 and S.W or S.c) end; dot(i, 8, 8, S.c) end},
  } }

elseif WHICH == "fx-seal-shards" then
  FW, FH = 40, 32; ANCHOR = { 20, 26 }; FACING = "right"
  -- 가슴 문양 자리(앵커 위 약 13px)에서 봉인 빛 파편이 흩어지며 위로 떠 사라짐
  local ox, oy = 20, 13
  local P = {} ; seed = 41
  for k = 1, 10 do local a = rnd() * 2 * math.pi; P[k] = { math.cos(a) * (0.6 + rnd() * 0.6), math.sin(a) * 0.5 - 0.6 - rnd() * 0.4, rnd() < 0.3 } end
  local function shards(i, t, fade)
    for k, p in ipairs(P) do local x, y = ox + p[1] * t * 3, oy + p[2] * t * 3
      local c = fade == 0 and (p[3] and S.W or S.C) or fade == 1 and (p[3] and S.c or S.B) or S.b
      dot(i, x, y, c); if fade == 0 and p[3] then dot(i, x + 1, y, S.c) end end
  end
  CL[#CL+1] = { "shatter", false, {
    {50, "shatter:start", function(i) blob(i, ox, oy, 4, { S.W, S.c, S.C }, 51, 1, 0.5) end},
    {60, nil, function(i) blob(i, ox, oy, 2, { S.c, S.C, S.B }, 52); shards(i, 1, 0) end},
    {70, nil, function(i) shards(i, 2, 0) end},
    {80, nil, function(i) shards(i, 3, 1) end},
    {100, nil, function(i) shards(i, 4, 1) end},
    {120, nil, function(i) shards(i, 5, 2) end},
  } }

elseif WHICH == "fx-fire-pillar" then
  FW, FH = 48, 64; ANCHOR = { 24, 56 }; FACING = "right"
  local cx, by = 24, 56   -- 바닥 중심 (반지름 20px → 바닥 타원 40×16)
  local function base(i, r, s, pal) blob(i, cx, by, r, pal or { F.y, F.r, F.d }, s, 0.4, 0.3) end
  -- 기둥: 아래 넓고 위로 갈수록 좁아지는 불꽃 혀 여러 개
  local function column(i, h, s, w)
    seed = s; w = w or 14
    for t = 0, 4 do local x0 = cx + (t - 2) * (w / 5) + (rnd() - 0.5) * 3; local hh = h * (0.6 + rnd() * 0.4) * (t == 2 and 1 or 0.8)
      for y = 0, math.floor(hh) do local frac = y / hh; local half = math.max(0, (1 - frac) * (w / 5) * 0.9)
        local sway = math.sin((y + s) * 0.35) * 1.2
        for x = -math.floor(half), math.floor(half) do local inner = math.abs(x) < half * 0.45
          px(i, x0 + x + sway, by - 2 - y, frac > 0.8 and F.r or (inner and frac < 0.55) and F.Y or F.y) end end
    end
  end
  local function embers(i, s, n, h) seed = s; for k = 1, n do dot(i, cx + (rnd() - 0.5) * 30, by - 4 - rnd() * h, rnd() < 0.5 and F.y or F.r) end end
  CL[#CL+1] = { "rise", false, {
    {40, "pillar:start", function(i) base(i, 8, 61, { F.Y, F.y, F.r }) end},
    {40, nil, function(i) base(i, 14, 62); column(i, 18, 63, 10) end},
    {40, nil, function(i) base(i, 20, 64); column(i, 34, 64, 14) end},
  } }
  CL[#CL+1] = { "burn", true, {
    {70, nil, function(i) base(i, 20, 71); column(i, 40, 71); embers(i, 72, 5, 50) end},
    {70, nil, function(i) base(i, 20, 73); column(i, 44, 74); embers(i, 75, 5, 50) end},
    {70, nil, function(i) base(i, 20, 76); column(i, 38, 77); embers(i, 78, 5, 50) end},
    {70, nil, function(i) base(i, 20, 79); column(i, 42, 80); embers(i, 81, 5, 50) end},
  } }
  CL[#CL+1] = { "fade", false, {
    {60, "pillar:end", function(i) base(i, 18, 91, { F.r, F.d, F.d }); column(i, 22, 92, 10); embers(i, 93, 6, 40) end},
    {70, nil, function(i) base(i, 14, 94, { F.d, F.d, F.d }); embers(i, 95, 6, 30) end},
    {80, nil, function(i) embers(i, 96, 4, 20) end},
  } }
end
assert(FW, "which=" .. tostring(WHICH) .. " 모름")

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
spr.data = "facing=" .. FACING .. ";anchor=" .. ANCHOR[1] .. "," .. ANCHOR[2]
spr:saveAs(app.params.out)
