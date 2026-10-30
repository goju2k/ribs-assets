-- 진화 8종 효과 (D-076, 46번 26행 EVOLUTION_TUNING) — 시안. 원래 스킬보다 한 단계 화려하게. 손불꽃 색 + 흰 노랑 속, 각진 사각형 효과 없음.
-- 에임라의 기둥(fx-pillar-eternal)은 combo-build.lua(불기둥과 같은 불길 계산). 나머지는 여기서:
--   fx-phoenix        피닉스 불새 탄 40×28, 기준점 [28,14]: fly(날갯짓 반복) / impact — 오른쪽을 봄, 엔진이 진행 방향대로 돌림
--   fx-phoenix-trail  지나간 자리 불길 14×16, 기준점 [7,15]: burn(반복, 1초 동안) / out
--   fx-stormspark     파이어 스톰 탄 14×10, 기준점 [8,5]: 작은 탄 + 둘레를 도는 불티 2개 (나선으로 휘는 탄)
--   fx-sunlance-beam  선 랜스 빔 조각 16×20, 기준점 [0,10]: 랜스보다 굵고 흰 심 + 금빛 반짝임. start/body/end + -fade (랜스와 같은 쓰임)
--   fx-sunlance-burst 관통 줄 24px마다 작은 폭발(반지름 12) 28×28, 기준점 가운데: burst
--   fx-lava-pool      볼케이노 용암 웅덩이(반지름 20) 48×28, 기준점 가운데: form / loop(반복, 3초) / out
--   fx-peacock-flash  파이어 피콕 시전 섬광 64×64, 기준점 가운데: 12갈래 깃털이 원형으로 펼쳐짐
--   fx-hellfire-burst 헬파이어 폭발(반지름 20) 48×48, 기준점 가운데: burst
--   fx-bastion-link   포탑 사이 불 줄 조각 16×12, 기준점 [0,6]: loop(16px마다 이어 붙임) / node(줄 끝 포탑 쪽 매듭)
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local F = { W=H"fff7d6", Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018", a=H"3a1a14", A=H"5a4a44" }
local WHICH = app.params.which
local FW, FH, ANCHOR = 16, 16, { 8, 8 }
local TAU = 2 * math.pi
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local seed = 5
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local BAY = { { 0, 0.5 }, { 0.75, 0.25 } }
local function shade(v, x, y)
  v = v + (BAY[y % 2 + 1][x % 2 + 1] - 0.375) * 0.12
  if v > 0.80 then return F.W elseif v > 0.62 then return F.Y elseif v > 0.43 then return F.y elseif v > 0.27 then return F.r elseif v > 0.15 then return F.d end
end
local function blob(i, cx, cy, r, s, ry, boost)
  seed = s; ry = ry or 1; local R = {}; for k = 0, 15 do R[k] = r * (0.8 + rnd() * 0.4) end
  for y = math.floor(-r * ry) - 1, math.ceil(r * ry) + 1 do for x = -r - 1, r + 1 do
    local a = math.atan(y / ry, x); local k = math.floor(((a + math.pi) / TAU) * 16) % 16
    local d = math.sqrt(x * x + (y / ry) ^ 2) / R[k]
    if d <= 1 then px(i, cx + x, cy + y, shade((1 - d * 0.75) * (boost or 1), math.floor(cx + x), math.floor(cy + y))) end
  end end
end
-- 폭발: 반지름 R까지 불덩이가 퍼지며 고리 + 바깥 불티 (k = 0~1 진행)
local function burst(i, cx, cy, R, k, s)
  local r = R * (0.35 + 0.65 * math.min(1, k * 1.6))
  local core = math.max(0, 1.25 - k * 1.1)
  for y = math.floor(cy - r - 2), math.ceil(cy + r + 2) do for x = math.floor(cx - r - 2), math.ceil(cx + r + 2) do
    local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2) / r
    local ringv = math.max(0, 1 - math.abs(d - 0.85) * 5) * (1 - k * 0.6)
    local v = math.max((1 - d) * core, ringv)
    seed = s + x * 7 + y * 13; v = v * (0.8 + rnd() * 0.35)
    if d <= 1.05 and v > 0.15 then px(i, x, y, shade(v, x, y)) end
  end end
  seed = s
  for n = 1, 10 do local a = rnd() * TAU; local rr = r + 2 + rnd() * R * 0.5 * k; px(i, cx + math.cos(a) * rr, cy + math.sin(a) * rr, n % 3 == 0 and F.Y or (k > 0.6 and F.r or F.y)) end
end

local CL = {}
local function F_(ms, tag, fn) return { ms, tag, fn } end

if WHICH == "fx-phoenix" then
  FW, FH, ANCHOR = 40, 28, { 28, 14 }
  -- 불새: 불덩이 몸 + 머리·부리(앞) + 넓게 펼친 두 날개(뒤로 쓸림, 위아래로 퍼덕) + 긴 꼬리 깃 3줄
  local function wing(i, sd, flap)   -- 채운 세모: 어깨(26,14) · 날개 끝 · 뒤쪽 끝. 어깨에 가까울수록 밝게
    local ax, ay = 26, 14; local bx, by = 15 + flap, 14 + sd * (9 + flap * 2); local cx, cy = 21, 14 + sd * 2
    local function side(px1, py1, px2, py2, x, y) return (px2 - px1) * (y - py1) - (py2 - py1) * (x - px1) end
    for y = 0, FH - 1 do for x = 0, FW - 1 do
      local d1, d2, d3 = side(ax, ay, bx, by, x, y), side(bx, by, cx, cy, x, y), side(cx, cy, ax, ay, x, y)
      if (d1 >= 0 and d2 >= 0 and d3 >= 0) or (d1 <= 0 and d2 <= 0 and d3 <= 0) then
        local u = math.sqrt((x - ax) ^ 2 + (y - ay) ^ 2) / 12
        local feather = ((x + y * sd) % 3 == 0) and 0.12 or 0
        px(i, x, y, shade(1.0 - u * 0.75 - feather, x, y))
      end
    end end
  end
  local function bird(i, k)
    local flap = ({ 1, 0, -1, 0 })[k + 1]
    for t = 0, 18 do for strand = -1, 1 do         -- 꼬리 깃 (길게)
      local x = 23 - t; local y = 14 + strand * (1 + t * 0.2) + math.sin(t * 0.55 + k * 1.5 + strand) * 1.4
      if (t + strand + k) % 4 ~= 3 then px(i, x, y, t < 4 and F.Y or t < 9 and F.y or t < 14 and F.r or F.d) end
    end end
    wing(i, -1, flap); wing(i, 1, -flap)
    blob(i, 28, 14, 3, 200 + k, 0.85, 1.15)        -- 몸
    px(i, 32, 13, F.W); px(i, 33, 13, F.Y); px(i, 34, 14, F.y); px(i, 32, 14, F.W); px(i, 31, 12, F.Y)   -- 머리·부리
  end
  local L = {}; for k = 0, 3 do L[#L+1] = F_(60, k == 0 and "fly:start" or nil, function(i) bird(i, k) end) end
  CL[#CL+1] = { "fly", true, L }
  CL[#CL+1] = { "impact", false, { F_(50, "impact:start", function(i) burst(i, 28, 14, 10, 0.2, 31) end), F_(60, nil, function(i) burst(i, 28, 14, 10, 0.55, 32) end), F_(80, nil, function(i) burst(i, 28, 14, 10, 0.9, 33) end) } }

elseif WHICH == "fx-phoenix-trail" then
  FW, FH, ANCHOR = 14, 16, { 7, 15 }
  -- 작은 바닥 불길: 혓바닥 3갈래가 높이를 바꾸며 일렁 (주기 끊김 없음)
  local function flame(i, t, hs)
    for y = 0, FH - 1 do for x = 0, FW - 1 do
      local I = 0
      for g = -1, 1 do
        local h = (8 + 3 * (1 - math.abs(g))) * hs * (0.8 + 0.2 * math.sin(TAU * (t * (2 + g % 2) + g * 0.3)))
        local f = (15 - y) / h
        if f >= 0 and f <= 1 then local hw = 2.2 * (1 - f) ^ 0.6 + 0.4; local dx = math.abs(x - (7 + g * 3 + math.sin(TAU * (t + f * 0.8)) * f * 1.5))
          if dx < hw then I = math.max(I, (1 - dx / hw) ^ 0.6 * (1 - f) ^ 0.7 * 1.25) end end
      end
      if I > 0 then px(i, x, y, shade(I, x, y)) end
    end end
  end
  local L = {}; for k = 1, 8 do L[k] = F_(80, k == 1 and "burn:start" or nil, function(i) flame(i, (k - 1) / 8, 1) end) end
  CL[#CL+1] = { "burn", true, L }
  CL[#CL+1] = { "out", false, { F_(80, nil, function(i) flame(i, 0.1, 0.6) end), F_(90, nil, function(i) flame(i, 0.2, 0.3) end), F_(100, nil, function(i) px(i, 7, 14, F.r); px(i, 6, 13, F.d); px(i, 8, 12, F.A) end) } }

elseif WHICH == "fx-stormspark" then
  FW, FH, ANCHOR = 14, 10, { 8, 5 }
  local function spark(i, k)
    for t = 1, 4 do if (t + k) % 3 ~= 0 then px(i, 6 - t, 5 + ((t % 2 == 0) and 1 or 0), t < 2 and F.y or F.r) end end
    px(i, 8, 5, F.W); px(i, 7, 5, F.Y); px(i, 9, 5, F.Y); px(i, 8, 4, F.y); px(i, 8, 6, F.y)
    for s = 0, 1 do local a = TAU * (k / 4 + s * 0.5); px(i, 8 + math.cos(a) * 4, 5 + math.sin(a) * 3, s == 0 and F.Y or F.y); px(i, 8 + math.cos(a - 0.6) * 4, 5 + math.sin(a - 0.6) * 3, F.r) end
  end
  local L = {}; for k = 0, 3 do L[#L+1] = F_(50, nil, function(i) spark(i, k) end) end
  CL[#CL+1] = { "projectile", true, L }
  CL[#CL+1] = { "impact", false, { F_(40, "impact:start", function(i) burst(i, 8, 5, 4, 0.2, 51) end), F_(50, nil, function(i) burst(i, 8, 5, 4, 0.6, 52) end), F_(60, nil, function(i) burst(i, 8, 5, 4, 0.95, 53) end) } }

elseif WHICH == "fx-sunlance-beam" then
  FW, FH, ANCHOR = 16, 20, { 0, 10 }
  -- 랜스보다 굵은(바깥 6줄) 흰 심 + 위아래로 튀는 금빛 반짝임
  local function col(i, x, k, w)
    local prof = { [0] = 1.15, 1.05, 0.9, 0.7, 0.52, 0.36, 0.24 }
    for d = 0, 6 do local v = prof[d] * w + 0.07 * math.sin(TAU * (x / 16 * 2 + k / 3) + d)
      if d == 6 and (x + k) % 3 ~= 0 then v = 0 end
      px(i, x, 9 - d, shade(v, x, 9 - d)); px(i, x, 10 + d, shade(v, x, 10 + d)) end
  end
  local function glints(i, k) for n = 0, 2 do local x = (n * 5 + k * 6) % 16; px(i, x, 1 + (n % 2), F.W); px(i, (x + 7) % 16, 18 - (n % 2), F.Y) end end
  local function body(i, k, w) for x = 0, 15 do col(i, x, k, w) end; if w > 0.7 then glints(i, k) end end
  local function start(i, k, w) for x = 4, 15 do col(i, x, k, w * math.min(1, (x - 2) / 5)) end; blob(i, 3, 10, math.floor(3 + 3 * w), 160 + k, 1, 1.2) end
  local function tip(i, k, w) for x = 0, 7 do col(i, x, k, w) end; blob(i, 8, 10, math.floor(3 + 4 * w), 170 + k, 1, 1.2)
    for s = 0, 7 do local a = (s / 8 + k * 0.06) * TAU; local r = 6 + 2 * w + (s % 2); px(i, 8 + math.cos(a) * r, 10 + math.sin(a) * r, s % 2 == 0 and F.W or F.Y) end end
  for _, part in ipairs({ { "start", start }, { "body", body }, { "end", tip } }) do
    CL[#CL+1] = { part[1], true, { F_(50, part[1] == "start" and "beam:fire" or nil, function(i) part[2](i, 0, 1) end), F_(50, nil, function(i) part[2](i, 1, 1) end), F_(50, nil, function(i) part[2](i, 2, 1) end) } }
    CL[#CL+1] = { part[1] .. "-fade", false, { F_(60, nil, function(i) part[2](i, 0, 0.7) end), F_(60, nil, function(i) part[2](i, 1, 0.45) end), F_(70, nil, function(i) part[2](i, 2, 0.25) end) } }
  end

elseif WHICH == "fx-sunlance-burst" then
  FW, FH, ANCHOR = 28, 28, { 14, 14 }
  CL[#CL+1] = { "burst", false, { F_(40, "burst:start", function(i) burst(i, 14, 14, 12, 0.1, 61) end), F_(50, nil, function(i) burst(i, 14, 14, 12, 0.4, 62) end), F_(60, nil, function(i) burst(i, 14, 14, 12, 0.7, 63) end), F_(70, nil, function(i) burst(i, 14, 14, 12, 0.95, 64) end) } }

elseif WHICH == "fx-lava-pool" then
  FW, FH, ANCHOR = 48, 28, { 24, 14 }
  -- 용암 웅덩이(반지름 20, 위에서 본 타원 세로 0.55): 굳은 껍질(어둠) 사이로 빛나는 금이 흐르고 거품이 터짐
  local PTS = {}; seed = 77; for k = 1, 9 do PTS[k] = { 24 + (rnd() - 0.5) * 38, 14 + (rnd() - 0.5) * 20 } end
  local function pool(i, t, sc, glow)
    for y = 0, FH - 1 do for x = 0, FW - 1 do
      local dx, dy = (x - 24) / (20 * sc), (y - 14) / (11 * sc)
      local e = dx * dx + dy * dy
      if e <= 1 then
        local d1, d2 = 99, 99
        for _, q in ipairs(PTS) do local d = math.sqrt(((x - 24) / sc + 24 - q[1]) ^ 2 + (((y - 14) / sc + 14 - q[2]) * 1.6) ^ 2)
          if d < d1 then d2 = d1; d1 = d elseif d < d2 then d2 = d end end
        local edge = d2 - d1
        local pulse = 0.85 + 0.15 * math.sin(TAU * (t + x * 0.03 + y * 0.05))
        local v
        if edge < 1.3 then v = (0.85 - edge * 0.2) * pulse * glow       -- 금: 흰 노랑 → 노랑
        elseif edge < 2.6 then v = 0.42 * pulse * glow                   -- 금 가장자리: 주황
        else v = (0.1 + 0.08 * (1 - e)) * glow end                       -- 굳은 껍질
        if e > 0.82 then v = math.min(v, 0.32 * glow) end
        px(i, x, y, shade(v, x, y) or F.a)
      end
    end end
    seed = math.floor(t * 8) + 71   -- 거품
    for n = 1, 2 do local a, r = rnd() * TAU, rnd() * 0.6; local bx, by = 24 + math.cos(a) * 20 * r * sc, 14 + math.sin(a) * 11 * r * sc
      px(i, bx, by, F.Y); px(i, bx, by - 1, F.W) end
  end
  CL[#CL+1] = { "form", false, { F_(60, "form:start", function(i) pool(i, 0, 0.4, 1.2) end), F_(60, nil, function(i) pool(i, 0.05, 0.7, 1.15) end), F_(70, nil, function(i) pool(i, 0.1, 1, 1.1) end) } }
  local L = {}; for k = 1, 8 do L[k] = F_(110, nil, function(i) pool(i, (k - 1) / 8, 1, 1) end) end
  CL[#CL+1] = { "loop", true, L }
  CL[#CL+1] = { "out", false, { F_(100, nil, function(i) pool(i, 0.2, 1, 0.7) end), F_(110, nil, function(i) pool(i, 0.3, 0.9, 0.45) end), F_(120, nil, function(i) pool(i, 0.4, 0.8, 0.25) end) } }

elseif WHICH == "fx-peacock-flash" then
  FW, FH, ANCHOR = 64, 64, { 32, 32 }
  -- 공작 깃털: 12갈래 깃대가 원형으로 뻗고, 끝에 눈무늬(흰 심 · 노랑 · 빨강 고리)
  local function fan(i, k)
    local R = 8 + 22 * k
    for n = 0, 11 do local a = n / 12 * TAU - math.pi / 2
      for r = 4, R do local x, y = 32 + math.cos(a) * r, 32 + math.sin(a) * r
        px(i, x, y, shade((1 - r / (R + 4)) * 0.9 + 0.2, math.floor(x), math.floor(y)))
        if r % 3 == 0 and r > 8 then px(i, x + math.cos(a + 1.57) * 1.5, y + math.sin(a + 1.57) * 1.5, F.r); px(i, x - math.cos(a + 1.57) * 1.5, y - math.sin(a + 1.57) * 1.5, F.r) end
      end
      if k > 0.35 then local ex, ey = 32 + math.cos(a) * R, 32 + math.sin(a) * R; local er = 2 + math.floor(k * 1.5)
        for yy = -er, er do for xx = -er, er do local d = math.sqrt(xx * xx + yy * yy)
          if d <= er + 0.3 then px(i, ex + xx, ey + yy, d < er * 0.4 and F.W or d < er * 0.75 and F.Y or F.r) end end end end
    end
    blob(i, 32, 32, math.floor(4 + 3 * (1 - k)), 90, 1, 1.25)
  end
  CL[#CL+1] = { "flash", false, { F_(40, "flash:start", function(i) fan(i, 0.1) end), F_(50, nil, function(i) fan(i, 0.4) end), F_(60, nil, function(i) fan(i, 0.7) end), F_(80, nil, function(i) fan(i, 1) end),
    F_(80, nil, function(i) for n = 0, 11 do local a = n / 12 * TAU - math.pi / 2; px(i, 32 + math.cos(a) * 30, 32 + math.sin(a) * 30, F.y); px(i, 32 + math.cos(a) * 26, 32 + math.sin(a) * 26, F.r) end end) } }

elseif WHICH == "fx-hellfire-burst" then
  FW, FH, ANCHOR = 48, 48, { 24, 24 }
  -- 연소된 채 쓰러진 적이 터짐(반지름 20): 섬광 → 불덩이 + 고리 → 불티·재
  CL[#CL+1] = { "burst", false, {
    F_(40, "burst:start", function(i) blob(i, 24, 24, 6, 81, 1, 1.3) end),
    F_(50, nil, function(i) burst(i, 24, 24, 20, 0.25, 82) end),
    F_(60, nil, function(i) burst(i, 24, 24, 20, 0.5, 83) end),
    F_(70, nil, function(i) burst(i, 24, 24, 20, 0.75, 84) end),
    F_(90, nil, function(i) burst(i, 24, 24, 20, 0.95, 85); seed = 86; for n = 1, 8 do px(i, 24 + (rnd() - 0.5) * 36, 24 + (rnd() - 0.5) * 30 - 4, F.A) end end),
  } }

elseif WHICH == "fx-bastion-link" then
  FW, FH, ANCHOR = 16, 12, { 0, 6 }
  -- 포탑 사이 불 줄: 가운데 1~2줄 흰 노랑 심이 사인 곡선으로 꼬이고 바깥은 주황·빨강 불티. 16px마다 이어 붙여도 이음매 없음(x 주기 16)
  local function rope(i, k, w)
    for x = 0, 15 do
      for s = 0, 1 do local y = 6 + math.sin(TAU * (x / 16 + k / 4 + s * 0.5)) * 2.2
        px(i, x, y, shade(0.9 * w, x, math.floor(y))); px(i, x, y + (s == 0 and 1 or -1), shade(0.55 * w, x, math.floor(y) + 1)) end
      if (x + k * 3) % 5 == 0 then px(i, x, 6 + ((x + k) % 2 == 0 and -4 or 4), F.r) end
    end
  end
  local L = {}; for k = 0, 3 do L[#L+1] = F_(70, nil, function(i) rope(i, k, 1) end) end
  CL[#CL+1] = { "loop", true, L }
  local N = {}; for k = 0, 3 do N[#N+1] = F_(70, nil, function(i) blob(i, 4, 6, 4, 140 + k, 1, 1.15) end) end
  CL[#CL+1] = { "node", true, N }
end
assert(#CL > 0, "which=" .. tostring(WHICH) .. " 모름")

local total = 0; for _, c in ipairs(CL) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = WHICH
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
