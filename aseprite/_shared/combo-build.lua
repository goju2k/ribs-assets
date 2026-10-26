-- 스킬·콤보 v1 (D-031) 효과·UI 원본 생성. 계약 1 형식(.aseprite → export-anim.sh). 불 원소, 스타일 가이드 색, 사각형 없음.
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로>.aseprite --script combo-build.lua
--   fx-fire-fan          불꽃 3갈래 (L 마무리): muzzle(손끝 부채꼴 섬광) / blast(착탄 작은 폭발). 날아가는 탄은 fx-fireball projectile을 3발로
--   fx-fire-pillar-big   큰 불기둥 (R 마무리, 반지름 26): rise / burn(loop) / fade / smolder(loop, 남는 연소)
--   fx-fire-pillar-quick 빠른 불기둥 (R 연결타, 반지름 12): burst (짧고 날렵)
--   fx-focus             "집중" 강화: ring (마무리에 덧입히는 불꽃 고리, 1회)
--   ui-combo             콤보 UI 7×7: slot-empty / slot-l / slot-r (칸 5×5) / gain-focus / gain-switch / gain-rhythm (떠오름 3프레임)
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local F = { W=H"fff7d6", Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018", a=H"3a1a14", A=H"5a4a44" }   -- 손불꽃 (+ 거의 흰 심, 재)
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

elseif WHICH == "fx-fire-pillar-big" or WHICH == "fx-fire-pillar-quick" then
  -- D-043: 이글거리는 불길 (파이어월 감각). 한 덩어리 기둥이 아니라 높이·위상이 다른 혓바닥 여러 겹이 계속 위로 핥아 오름.
  -- 장면마다 손으로 그리지 않고 불길 세기(0~1)를 계산해 색 층으로 칠함: 흰 노랑 → 노랑 → 주황 → 빨강 → 어둠(디더로 흩어짐).
  -- 반복 구간은 시간 t(0~1)의 정수배 주기만 써서 끊김 없이 이어짐. 바닥 = 타는 고리(이글거리는 테), 불티·재가 위로.
  local big = WHICH == "fx-fire-pillar-big"
  local R = big and 26 or 12
  if big then FW, FH, ANCHOR = 64, 80, { 32, 70 } else FW, FH, ANCHOR = 32, 48, { 16, 42 } end
  local cx, by = ANCHOR[1], ANCHOR[2]
  local TAU = 2 * math.pi
  local BAYER = { { 0, 0.5 }, { 0.75, 0.25 } }
  local function shade(v, x, y)
    v = v + (BAYER[y % 2 + 1][x % 2 + 1] - 0.375) * 0.12
    if v > 0.80 then return F.W elseif v > 0.62 then return F.Y elseif v > 0.43 then return F.y
    elseif v > 0.27 then return F.r elseif v > 0.15 then return F.d end
  end
  -- 혓바닥 목록 (고정): 바닥 타원 안에 앞·뒤 두 줄로 흩어 둠. n = 주기 안에서 핥는 횟수(정수)
  local TONGUES = {}
  do seed = big and 401 or 431
    local N = big and 11 or 5
    for k = 1, N do
      local rel = (k - (N + 1) / 2) / ((N - 1) / 2)
      TONGUES[k] = { x = cx + rel * R * 0.78 + (rnd() - 0.5) * 2, b = by + math.floor(((k * 5) % 7 / 6 - 0.5) * R * 0.6),   -- 바닥 타원 깊이 안에 앞·뒤로 흩어 둠
        h = (1 - 0.45 * math.abs(rel)) * (0.8 + rnd() * 0.3), w = (big and 4.2 or 3.2) * (0.85 + rnd() * 0.3),
        n = 1 + (k % 3), ph = rnd(), sw = 1 + (k % 2) }
    end
  end
  local SPARKS = {}
  do seed = big and 451 or 461
    for k = 1, (big and 26 or 10) do SPARKS[k] = { x = cx + (rnd() - 0.5) * R * 1.6, n = 1 + (k % 2), ph = rnd(), drift = (rnd() - 0.5) * 6 } end
  end
  -- o: t(0~1) · hs 높이 비율 · is 세기 비율 · ring 고리 세기(0~1) · sp 불티 비율 · low(잔불: 낮은 혓바닥만)
  local function fire(i, o)
    local t, hs, is = o.t, o.hs or 1, o.is or 1
    local H = (big and 60 or 30) * hs
    -- 고리 (뒤 반쪽 먼저)
    local function ring(front)
      if (o.ring or 0) <= 0 then return end
      for a = 0, 359, 3 do
        local ra = math.rad(a); local s = math.sin(ra)
        if (s >= 0) == front then
          local x, y = cx + math.cos(ra) * R, by + s * R * 0.38
          local fl = 0.5 + 0.5 * math.sin(TAU * (t * 2 + a / 360 * 5))
          local v = (0.35 + 0.45 * fl) * o.ring
          px(i, x, y, shade(v + 0.1, math.floor(x), math.floor(y))); px(i, x, y + 1, shade(v - 0.12, math.floor(x), math.floor(y) + 1))
          local h = math.floor((1 + 3 * fl) * o.ring)              -- 테 위 작은 불꽃
          for d = 1, h do px(i, x, y - d, shade(v - d * 0.1, math.floor(x), math.floor(y) - d)) end
        end
      end
    end
    ring(false)
    -- 불길 세기 계산
    local x0, x1 = math.max(0, cx - R - 4), math.min(FW - 1, cx + R + 4)
    for y = math.max(0, math.floor(by - H - 6)), math.min(FH - 1, math.floor(by + R * 0.4)) do for x = x0, x1 do
      local I = 0
      local e = ((x - cx) / R) ^ 2 + ((y - by) / (R * 0.38)) ^ 2           -- 바닥 타원 안 = 타는 숯 바닥
      if e < 1 then I = (o.low and 0.3 or 0.38) + 0.16 * math.sin(TAU * (t * 2 + x * 0.11)) * math.sin(TAU * (t + y * 0.17 + x * 0.04)) - e * 0.12 + (((x * 73 + y * 151) % 17) / 17 - 0.5) * 0.22 end   -- 숯 알갱이 (체크 무늬 방지)
      for _, g in ipairs(TONGUES) do
        local hk = H * g.h * (o.low and 0.18 or 1) * (0.72 + 0.28 * (0.5 + 0.5 * math.sin(TAU * (t * g.n + g.ph))))
        local f = (g.b - y) / hk
        if f >= -0.05 and f <= 1 then
          local sway = math.sin(TAU * (t * g.sw + f * 0.9 + g.ph)) * (1 + f * 2.2)
          local hw = g.w * (1 - f) ^ 0.55 + 0.6
          local dx = math.abs(x - (g.x + sway))
          if dx < hw then
            local core = (1 - dx / hw) ^ 0.6
            local lick = 0.78 + 0.22 * math.sin(TAU * (f * 2.4 - t * (g.n + 1)) + x * 0.6)   -- 위로 올라가는 띠
            local v = core * (1 - math.max(0, f)) ^ 0.75 * lick * 1.25
            if v > I then I = v end
          end
        end
      end
      if I > 0 then px(i, x, y, shade(I * is, x, y)) end
    end end
    -- 혓바닥 끝에서 떨어져 나가는 불꽃 조각
    if not o.low then for k, g in ipairs(TONGUES) do
      local u = (t * g.n + g.ph * 1.7) % 1
      local tip = g.b - H * g.h * 0.9 - u * 10
      local x = g.x + math.sin(TAU * (u + g.ph)) * 2
      px(i, x, tip, shade((0.62 - u * 0.5) * is, math.floor(x), math.floor(tip)))
      if u < 0.4 then px(i, x, tip + 1, shade((0.5 - u * 0.5) * is, math.floor(x), math.floor(tip) + 1)) end
    end end
    ring(true)
    -- 불티·재
    local sp = o.sp or 1
    for k, s in ipairs(SPARKS) do if k <= #SPARKS * sp then
      local u = (t * s.n + s.ph) % 1
      local y = by - 3 - u * (H + 12) * (o.low and 0.4 or 1)
      local x = s.x + math.sin(TAU * (u * 1.5 + s.ph)) * 2 + s.drift * u
      px(i, x, y, u < 0.3 and F.Y or u < 0.6 and F.y or u < 0.85 and F.r or F.A)
    end end
  end
  local function seq(n, ms, from, to, opt)   -- n장, 각 ms: 매 장 t를 from → to로
    local L = {}
    for k = 1, n do local u = (k - 1) / n
      L[k] = { ms, nil, function(i) local o = opt(u, k); o.t = from + (to - from) * u; fire(i, o) end } end
    return L
  end
  if big then
    -- 오름 0.2초 → 이글거림 0.9초(반복 12장) → 잦아듦 0.5초 → 잔불 1초(반복 8장)
    local rise = seq(4, 50, 0, 0.2, function(u) return { hs = 0.25 + 0.75 * (u + 0.25), is = 1.15 - u * 0.15, ring = 0.4 + u * 0.6, sp = u } end)
    rise[1][2] = "pillar:start"
    CL[#CL+1] = { "rise", false, rise }
    CL[#CL+1] = { "burn", true, seq(12, 75, 0, 1, function() return { ring = 1 } end) }
    local fade = seq(6, 83, 0, 0.45, function(u) return { hs = 1 - u * 0.85, is = 1 - u * 0.55, ring = 1 - u * 0.6, sp = 1 - u * 0.5 } end)
    fade[1][2] = "pillar:end"
    CL[#CL+1] = { "fade", false, fade }
    local low = function() return { low = true, is = 0.72, ring = 0.45, sp = 0.25 } end
    CL[#CL+1] = { "embers", true, seq(8, 125, 0, 1, low) }    -- 잦아든 뒤 바닥 잔불 (엔진이 1000ms로 자름)
    CL[#CL+1] = { "smolder", true, seq(8, 125, 0, 1, low) }   -- 대상이 불탈 때 (같은 그림)
  else
    -- 빠른 불기둥 0.6초: 오름 0.1(2장) → 이글 0.3(4장) → 잦아듦 0.2(3장)
    local L = {}
    for _, f in ipairs(seq(2, 50, 0, 0.1, function(u) return { hs = 0.35 + u * 0.65, is = 1.15, ring = 0.6 + u * 0.4, sp = 0.3 } end)) do L[#L+1] = f end
    for _, f in ipairs(seq(4, 75, 0.1, 0.5, function() return { ring = 1 } end)) do L[#L+1] = f end
    for _, f in ipairs(seq(3, 67, 0.5, 0.7, function(u) return { hs = 0.8 - u * 0.6, is = 0.9 - u * 0.45, ring = 0.8 - u * 0.5, sp = 0.8 } end)) do L[#L+1] = f end
    L[1][2] = "pillar:start"; L[7][2] = "pillar:end"
    CL[#CL+1] = { "burst", false, L }
  end

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
