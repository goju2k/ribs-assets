-- 성장 v1 2b 불 스킬 이펙트 (시안). 손불꽃 색(스타일 가이드 1-1) + 흰 노랑 속, 각진 사각형 효과 없음. 모두 오른쪽을 봄(엔진이 방향대로 돌림).
-- 실행: aseprite -b --script-param which=<id> --script-param out=<id>.aseprite --script skills-build.lua
--   fx-lance-charge  플레임 랜스 시전 36f(600ms): 불티가 손끝으로 모이며 심이 커짐. 24×24, 기준점 가운데
--   fx-lance-beam    플레임 랜스 빔 조각 16×16, 기준점 [0,8](왼쪽 가운데). start(손끝) · body(16px마다 이어 붙임) · end(첫 벽, 가운데가 맞은 점)
--                    각 조각 = 쏨(반복) / -fade(사라짐). 엔진: start 1개 + body를 길이만큼 + end를 맞은 점에
--   fx-fireshot      파이어 샷 원뿔(반각 30°, 사거리 56) 한 번 터짐 310ms. 64×60, 기준점 [2,30] = 손끝
--   fx-breath        파이어 브레스 원뿔(반각 25°, 사거리 48) start / loop(반복) / end. 56×40, 기준점 [2,20]
--   fx-burn-spread   연소가 옮겨 붙을 때 이웃으로 튀는 작은 불씨 10×8 (엔진이 포물선으로 옮김)
--   fx-firespark     파이어 스트림 탄 (빠른 연사용 작은 탄) 12×6, 기준점 [8,3]
--   prop-fire-turret 파이어 터렛: summon(200ms) / idle(반복) / fire(fire:release) / expire. 16×28, 기준점 [8,27]
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local F = { W=H"fff7d6", Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018", a=H"5a4a44" }
local WOOD = { o=H"0e0507", s=H"5e3a28", m=H"8f563b", l=H"b07048" }
local WHICH = app.params.which
local FW, FH, ANCHOR = 16, 16, { 0, 8 }
local TAU = 2 * math.pi
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local seed = 5
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local BAY = { { 0, 0.5 }, { 0.75, 0.25 } }
local function shade(v, x, y)   -- 불 세기 → 색 층 (D-043 불기둥과 같은 문턱)
  v = v + (BAY[y % 2 + 1][x % 2 + 1] - 0.375) * 0.12
  if v > 0.80 then return F.W elseif v > 0.62 then return F.Y elseif v > 0.43 then return F.y elseif v > 0.27 then return F.r elseif v > 0.15 then return F.d end
end
local function blob(i, cx, cy, r, s)
  seed = s; local R = {}; for k = 0, 15 do R[k] = r * (0.8 + rnd() * 0.4) end
  for y = -r - 1, r + 1 do for x = -r - 1, r + 1 do
    local a = math.atan(y, x); local k = math.floor(((a + math.pi) / TAU) * 16) % 16
    local d = math.sqrt(x * x + y * y) / R[k]
    if d <= 1 then px(i, cx + x, cy + y, shade(1 - d * 0.75, math.floor(cx + x), math.floor(cy + y))) end
  end end
end

local CL = {}
local function F_(ms, tag, fn) return { ms, tag, fn } end

if WHICH == "fx-lance-charge" then
  FW, FH, ANCHOR = 24, 24, { 12, 12 }
  -- 불티 8개가 바깥에서 가운데로 모이고(나선), 심이 r1 → r3로 커짐. 마지막 장은 흰 섬광 = 곧 발사
  local N = 6
  local L = {}
  for k = 1, N do local t = (k - 1) / (N - 1)
    L[k] = F_(100, k == 1 and "charge:start" or (k == N and "charge:full" or nil), function(i)
      for s = 0, 7 do local a = s / 8 * TAU + t * 1.6; local r = 11 * (1 - t) + 2
        px(i, 12 + math.cos(a) * r, 12 + math.sin(a) * r, s % 2 == 0 and F.Y or F.y)
        if t < 0.7 then px(i, 12 + math.cos(a - 0.25) * (r + 2), 12 + math.sin(a - 0.25) * (r + 2), F.r) end end
      blob(i, 12, 12, math.floor(1 + t * 2.5), 40 + k)
      if k == N then for _, d in ipairs({ {0,-5}, {0,5}, {-5,0}, {5,0} }) do px(i, 12 + d[1], 12 + d[2], F.W) end end
    end)
  end
  CL[#CL+1] = { "charge", false, L }

elseif WHICH == "fx-lance-beam" then
  FW, FH, ANCHOR = 16, 16, { 0, 8 }
  -- 빔 단면: 가운데 2줄 흰 노랑 → 노랑 → 주황 → 빨강(바깥 1줄은 띄엄띄엄 깜빡). 굵기 w(1 = 가득, 작을수록 가늘게 사라짐)
  local function beamCol(i, x, k, w)
    local prof = { [0] = 1.0, 0.85, 0.66, 0.48, 0.30 }      -- 가운데에서 거리별 세기
    for d = 0, 4 do
      local v = prof[d] * w + 0.06 * math.sin(TAU * (x / 16 * 2 + k / 3) + d)
      if d == 4 and (x + k) % 3 ~= 0 then v = 0 end
      px(i, x, 7 - d, shade(v, x, 7 - d)); px(i, x, 8 + d, shade(v, x, 8 + d))
    end
  end
  local function wisps(i, k) for n = 0, 2 do local x = (n * 6 + k * 5) % 16; px(i, x, 2 + (n % 2), F.r); px(i, (x + 3) % 16, 13 - (n % 2), F.y) end end
  local function body(i, k, w) for x = 0, 15 do beamCol(i, x, k, w) end; if w > 0.7 then wisps(i, k) end end
  local function start(i, k, w) for x = 4, 15 do beamCol(i, x, k, w * math.min(1, (x - 2) / 5)) end; blob(i, 3, 8, math.floor(2 + 3 * w), 60 + k) end
  local function tip(i, k, w)   -- 맞은 점(가운데 8,8)에서 튀는 불꽃
    for x = 0, 7 do beamCol(i, x, k, w) end
    blob(i, 8, 8, math.floor(2 + 4 * w), 70 + k)
    for s = 0, 5 do local a = (s / 6 + k * 0.08) * TAU; local r = 5 + 2 * w + (s % 2); px(i, 8 + math.cos(a) * r, 8 + math.sin(a) * r, s % 2 == 0 and F.Y or F.y) end
  end
  for _, part in ipairs({ { "start", start }, { "body", body }, { "end", tip } }) do
    CL[#CL+1] = { part[1], true, { F_(50, part[1] == "start" and "beam:fire" or nil, function(i) part[2](i, 0, 1) end), F_(50, nil, function(i) part[2](i, 1, 1) end), F_(50, nil, function(i) part[2](i, 2, 1) end) } }
    CL[#CL+1] = { part[1] .. "-fade", false, { F_(60, nil, function(i) part[2](i, 0, 0.7) end), F_(60, nil, function(i) part[2](i, 1, 0.45) end), F_(70, nil, function(i) part[2](i, 2, 0.25) end) } }
  end

elseif WHICH == "fx-fireshot" then
  FW, FH, ANCHOR = 64, 60, { 2, 30 }   -- 반각 30°·사거리 56 → 끝이 위아래 28px, 높이 60에 들어감
  -- 근접 산탄: 손끝 섬광 → 불꽃 알갱이(짧은 줄)가 원뿔로 퍼짐(가까울수록 굵고 밝게) → 끝에서 불티로 흩어짐
  local HALF, RANGE = math.rad(30), 56
  local PEL = {}; seed = 81
  for k = 1, 14 do PEL[k] = { a = (rnd() * 2 - 1) * HALF, sp = 0.75 + rnd() * 0.25 } end
  local function pellets(i, r0, len, w)
    for _, p in ipairs(PEL) do local r = r0 * p.sp
      for d = 0, len do local rr = r - d; if rr > 3 and rr <= RANGE then
        local x, y = 2 + math.cos(p.a) * rr, 30 + math.sin(p.a) * rr
        local v = (1 - rr / RANGE) * 0.9 + 0.35 - d / (len + 1) * 0.4
        px(i, x, y, shade(v * w, math.floor(x), math.floor(y)))
        if rr < 24 and d == 0 then px(i, x, y + 1, shade(v * w - 0.2, math.floor(x), math.floor(y) + 1)) end
      end end
    end
  end
  local function wedge(i, rmax, w)   -- 손끝 쪽 불 부채 (가까울수록 진함)
    for y = 0, FH - 1 do for x = 2, FW - 1 do
      local dx, dy = x - 2, y - 30; local r = math.sqrt(dx * dx + dy * dy); local a = math.abs(math.atan(dy, dx))
      if r <= rmax and a <= HALF then local v = (1 - r / rmax) * w * (1 - a / HALF * 0.5); if v > 0.15 then px(i, x, y, shade(v, x, y)) end end
    end end
  end
  CL[#CL+1] = { "burst", false, {
    F_(50, "shot:fire", function(i) wedge(i, 14, 1.1); blob(i, 4, 30, 4, 91) end),
    F_(50, nil, function(i) wedge(i, 22, 0.9); pellets(i, 26, 5, 1) end),
    F_(60, nil, function(i) wedge(i, 18, 0.55); pellets(i, 42, 4, 0.9) end),
    F_(70, nil, function(i) pellets(i, 54, 3, 0.7) end),
    F_(80, nil, function(i) seed = 93; for k = 1, 9 do local a = (rnd() * 2 - 1) * HALF; local r = 30 + rnd() * 26; px(i, 2 + math.cos(a) * r, 30 + math.sin(a) * r - 2, k % 2 == 0 and F.y or F.r) end end),
  } }

elseif WHICH == "fx-breath" then
  FW, FH, ANCHOR = 56, 40, { 2, 20 }
  -- 화염 숨결: 원뿔 안 불 세기를 계산 — 밖으로 흐르는 띠(위상 t)로 이글거림, 끝은 혓바닥 모양으로 너울. 반복 주기 끊김 없음
  local HALF, RANGE = math.rad(25), 48
  local function field(i, t, reach, w)
    for y = 0, FH - 1 do for x = 2, FW - 1 do
      local dx, dy = x - 2, y - 20; local r = math.sqrt(dx * dx + dy * dy); local a = math.atan(dy, dx)
      local edge = HALF * (0.85 + 0.15 * math.sin(TAU * (r / 14 - t * 2)))
      local lim = RANGE * reach * (0.88 + 0.12 * math.sin(TAU * (a * 2.2 + t * 3)))
      if r <= lim and math.abs(a) <= edge then
        local core = 1 - math.abs(a) / edge
        local flow = 0.78 + 0.22 * math.sin(TAU * (r / 10 - t * 3) + a * 5)
        local v = (core ^ 0.6) * (1 - r / lim) ^ 0.5 * flow * 1.25 * w
        if r < 6 then v = v + 0.25 end
        local c = shade(v, x, y); if c then px(i, x, y, c) end
      end
    end end
  end
  local LOOP = {}; for k = 1, 8 do LOOP[k] = F_(60, k == 1 and "breath:loop" or nil, function(i) field(i, (k - 1) / 8, 1, 1) end) end
  CL[#CL+1] = { "start", false, { F_(50, "breath:start", function(i) field(i, 0, 0.35, 1.1) end), F_(50, nil, function(i) field(i, 0.06, 0.7, 1.05) end) } }
  CL[#CL+1] = { "loop", true, LOOP }
  CL[#CL+1] = { "end", false, { F_(60, nil, function(i) field(i, 0.2, 0.75, 0.75) end), F_(60, nil, function(i) field(i, 0.3, 0.5, 0.55) end), F_(70, nil, function(i) field(i, 0.4, 0.3, 0.4) end) } }

elseif WHICH == "fx-burn-spread" then
  FW, FH, ANCHOR = 10, 8, { 5, 4 }
  CL[#CL+1] = { "loop", true, {
    F_(60, nil, function(i) px(i, 5, 4, F.Y); px(i, 4, 4, F.y); px(i, 5, 3, F.y); px(i, 6, 5, F.r); px(i, 3, 5, F.r) end),
    F_(60, nil, function(i) px(i, 5, 4, F.Y); px(i, 6, 4, F.y); px(i, 5, 5, F.y); px(i, 4, 3, F.r); px(i, 7, 3, F.d) end),
    F_(60, nil, function(i) px(i, 5, 4, F.W); px(i, 5, 3, F.Y); px(i, 4, 4, F.y); px(i, 6, 4, F.y); px(i, 5, 2, F.r) end),
  } }

elseif WHICH == "fx-firespark" then
  FW, FH, ANCHOR = 12, 6, { 8, 3 }
  -- 빠른 연사용 작은 탄: 불꽃탄(24×12)의 절반 크기, 꼬리 짧게 — 30발이 날아도 화면이 덜 덮임
  local function spark(i, k)
    for t = 1, 5 do if (t + k) % 3 ~= 0 then px(i, 6 - t, 3 + ((t + k) % 3 == 1 and 0 or (t % 2 == 0 and 1 or 0)), t < 2 and F.y or t < 4 and F.r or F.d) end end
    px(i, 8, 3, F.W); px(i, 7, 3, F.Y); px(i, 9, 3, F.Y); px(i, 8, 2, F.y); px(i, 8, 4, F.y); px(i, 10, 3, F.y)
  end
  CL[#CL+1] = { "projectile", true, { F_(50, nil, function(i) spark(i, 0) end), F_(50, nil, function(i) spark(i, 1) end), F_(50, nil, function(i) spark(i, 2) end) } }
  CL[#CL+1] = { "impact", false, {
    F_(40, "impact:start", function(i) px(i, 8, 3, F.W); for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do px(i, 8 + d[1], 3 + d[2], F.Y) end end),
    F_(50, nil, function(i) for _, d in ipairs({ {2,0}, {-2,0}, {0,2}, {0,-2}, {1,1}, {-1,-1} }) do px(i, 8 + d[1], 3 + d[2], F.y) end end),
    F_(60, nil, function(i) for _, d in ipairs({ {3,0}, {-3,1}, {1,-2} }) do px(i, 8 + d[1], 3 + d[2], F.r) end end),
  } }

elseif WHICH == "prop-fire-turret" then
  FW, FH, ANCHOR = 16, 28, { 8, 27 }
  -- 파이어 터렛: 땅에 꽂힌 그을린 나무 말뚝 + 그 위에 떠서 일렁이는 불씨 덩어리, 둘레를 도는 불티 3개.
  -- 플레이어 쪽 불의 물건: 돌·봉인 빛(수호체)이 아니라 나무·손불꽃 색. 화로(배경 소품)와도 달리 그릇 없이 불만 뜸
  local function stake(i, h, burnt)
    for y = 27 - h, 27 do px(i, 7, y, WOOD.o); px(i, 10, y, WOOD.o); px(i, 8, y, burnt and WOOD.s or WOOD.m); px(i, 9, y, burnt and WOOD.o or WOOD.s) end
    px(i, 8, 27 - h, WOOD.l); px(i, 9, 27 - h, WOOD.m)
    if not burnt then for y = 27 - h + 2, 27, 4 do px(i, 8, y, WOOD.l) end end
    for x = 5, 12 do if (x % 3) ~= 0 then px(i, x, 27, WOOD.s) end end         -- 땅에 박힌 자리 흙
  end
  local function orb(i, r, k, cy)
    blob(i, 8, cy, r, 110 + k)
    if r >= 3 then for s = 0, 2 do local a = (s / 3 + k * 0.09) * TAU; px(i, 8 + math.cos(a) * (r + 3), cy + math.sin(a) * (r + 2) * 0.7, s == 0 and F.Y or F.y) end end
    px(i, 8 + (k % 2), cy - r - 2, F.y)
  end
  -- summon 200ms: 엔진이 설치 12f(200ms) 뒤 첫 발을 쏨 (deployF와 맞춤)
  CL[#CL+1] = { "summon", false, {
    F_(40, "summon:start", function(i) stake(i, 4) end),
    F_(40, nil, function(i) stake(i, 9) end),
    F_(40, nil, function(i) stake(i, 12); orb(i, 1, 0, 11) end),
    F_(40, nil, function(i) stake(i, 12); orb(i, 3, 1, 10) end),
    F_(40, nil, function(i) stake(i, 12); orb(i, 4, 2, 9) end),
  } }
  local IDLE = {}; for k = 1, 4 do IDLE[k] = F_(110, nil, function(i) stake(i, 12); orb(i, (k % 2 == 0) and 4 or 3, k, 9 - ((k == 2 or k == 3) and 1 or 0)) end) end
  CL[#CL+1] = { "idle", true, IDLE }
  CL[#CL+1] = { "fire", false, {
    F_(50, "fire:release", function(i) stake(i, 12); orb(i, 5, 5, 9); px(i, 15, 9, F.W); px(i, 14, 9, F.Y) end),
    F_(60, nil, function(i) stake(i, 12); orb(i, 3, 6, 10) end),
    F_(80, nil, function(i) stake(i, 12); orb(i, 4, 7, 9) end),
  } }
  CL[#CL+1] = { "expire", false, {
    F_(80, "expire:start", function(i) stake(i, 12); orb(i, 3, 8, 10) end),
    F_(90, nil, function(i) stake(i, 12, true); orb(i, 2, 9, 11) end),
    F_(100, nil, function(i) stake(i, 9, true); px(i, 8, 16, F.r); px(i, 9, 15, F.d) end),
    F_(120, nil, function(i) stake(i, 3, true); px(i, 7, 22, F.a); px(i, 10, 20, F.a) end),
  } }
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
