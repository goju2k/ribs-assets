-- 샌드박스 방 에셋 (D-073, 47_sandbox-room-v0 7절) — 시안
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로> --script sandbox-build.lua
--   sentinel-mite / sentinel-archer / sentinel-brute  새 적 3종 (.aseprite → export-anim.sh). 원본은 왼쪽을 봄(facing=left)
--       clip: idle(반복) · move(반복) · windup(windup:start, windup:cue = 흰 1px 바깥 테두리) · attack(attack:active) · hit · down
--       수호체 규칙: 바닥·벽 팔레트 + 봉인 빛(P-014), 빨강 없음, 패링 신호는 흰색만(D-014)
--   fx-enemy-bolt   사수 탄 (보라·자홍 예약색, 37번 9절): loop(반복) · impact
--   fx-drop         바닥 드롭 표시: beam-normal / beam-rare / beam-epic(반복) · pickup
--   ui-items        png: 슬롯 아이콘 7 + 기타 아이콘 3 (16×16) + 등급 테두리 3 (20×20) → ui-items.png/json (out = 폴더)
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local C = { o=H"141018", d=H"241e2c", s=H"362e40", m=H"4a4058", l=H"5e536e", t=H"584d66" }
local GL = { [0]={ H"241e2c", H"306082" }, { H"306082", H"2f4a66" }, { H"5fcde4", H"306082" }, { H"cbdbfc", H"5fcde4" }, { H"ffffff", H"ffffff" } }
local MG = { W=H"ffd0f4", a=H"e050c8", b=H"9a2a8e", c=H"5a1a58" }        -- 적 탄 보라·자홍
local WHICH = app.params.which
local FW, FH, ANCHOR, FACING = 16, 16, { 8, 15 }, "left"
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local seed = 3
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local HIT = false   -- 피격 장면: 돌 색을 한 단 밝게
local function stone(c) if not HIT then return c end; return (c == C.s and C.m) or (c == C.m and C.l) or (c == C.l and GL[3][2]) or c end
local function block(i, x0, y0, x1, y1, fill, round)
  for y = y0, y1 do for x = x0, x1 do
    local corner = round and ((x == x0 or x == x1) and (y == y0 or y == y1))
    if not corner then
      local edge = x == x0 or x == x1 or y == y0 or y == y1
      local c = fill or C.m
      if edge then c = C.o elseif y == y0 + 1 or x == x0 + 1 then c = C.l elseif y == y1 - 1 or x == x1 - 1 then c = C.s end
      px(i, x, y, stone(c))
    end
  end end
end
local function glyph(i, cx, cy, lv, small)
  local g = GL[lv]
  if small then px(i, cx, cy, g[1]); px(i, cx - 1, cy, g[2]); px(i, cx + 1, cy, g[2]); px(i, cx, cy - 1, g[2]); px(i, cx, cy + 1, g[2]); return end
  for _, d in ipairs({ {0,-2}, {-1,-1}, {1,-1}, {-2,0}, {2,0}, {-1,1}, {1,1}, {0,2} }) do px(i, cx + d[1], cy + d[2], g[2]) end
  px(i, cx, cy, g[1]); if lv >= 2 then px(i, cx - 1, cy, g[1]); px(i, cx + 1, cy, g[1]); px(i, cx, cy - 1, g[1]); px(i, cx, cy + 1, g[1]) end
end
local function cueOutline(i)   -- 패링 신호: 몸 둘레 1px 바깥 테두리 흰색
  local edge = {}
  for yy = 0, FH - 1 do for xx = 0, FW - 1 do
    if app.pixelColor.rgbaA(i:getPixel(xx, yy)) == 0 then
      for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do local nx, ny = xx + d[1], yy + d[2]
        if nx >= 0 and ny >= 0 and nx < FW and ny < FH and app.pixelColor.rgbaA(i:getPixel(nx, ny)) > 0 then edge[#edge+1] = { xx, yy }; break end end
    end
  end end
  for _, p in ipairs(edge) do i:drawPixel(p[1], p[2], GL[4][1]) end
end
local function pebbles(i, cx, by, n, spread, up, s)   -- 쓰러짐: 돌 조각
  seed = s
  for k = 1, n do local x, y = cx + (rnd() - 0.5) * spread, by - rnd() * up
    px(i, x, y, C.l); px(i, x + 1, y, C.m); px(i, x, y + 1, C.s); px(i, x + 1, y + 1, C.o) end
end

local CL = {}
local function F(ms, tag, fn, hit) return { ms, tag, function(i) HIT = hit or false; fn(i); HIT = false end } end

if WHICH == "sentinel-mite" then
  -- 작은 수호체 떼: 12×8 몸, 프레임 16×16, 기준점 [8,15]. 빠르고 무리 지음 → 실루엣이 단순하고 작게
  FW, FH, ANCHOR = 16, 16, { 8, 15 }
  local function mite(i, o)
    o = o or {}
    local dx, dy, lv = o.dx or 0, (o.dy or 0) + (o.crouch and 1 or 0), o.lv or 1
    local L = o.legs or 0
    for k = 0, 3 do local lx = 4 + k * 3 + dx; local up = ((k + L) % 2 == 0) and 0 or 1   -- 다리 4개 (번갈아)
      px(i, lx, 14 - up + (o.crouch and 0 or 0), C.o); px(i, lx, 13 - up, stone(C.s)) end
    block(i, 4 + dx, 7 + dy, 13 + dx, 13 + dy, C.m, true)                                      -- 몸 (둥근 돌)
    block(i, 1 + dx + (o.lunge or 0), 8 + dy, 6 + dx + (o.lunge or 0), 12 + dy, C.m, true)   -- 머리 (앞, 왼쪽)
    local g = GL[math.min(lv, 3)]
    px(i, 2 + dx + (o.lunge or 0), 10 + dy, g[1]); px(i, 3 + dx + (o.lunge or 0), 10 + dy, g[2])  -- 눈구멍 빛
    glyph(i, 9 + dx, 10 + dy, lv, true)
    if o.jaw then px(i, (o.lunge or 0) + dx, 12 + dy, C.l); px(i, (o.lunge or 0) + dx - 1, 11 + dy, C.l) end
    if lv == 4 then cueOutline(i) end
  end
  CL[#CL+1] = { "idle", true, { F(150, nil, function(i) mite(i) end), F(150, nil, function(i) mite(i, { dy = 1 }) end), F(150, nil, function(i) mite(i, { lv = 2 }) end), F(150, nil, function(i) mite(i, { dy = 1 }) end) } }
  CL[#CL+1] = { "move", true, { F(70, nil, function(i) mite(i, { legs = 0 }) end), F(70, nil, function(i) mite(i, { legs = 1, dy = -1 }) end), F(70, nil, function(i) mite(i, { legs = 0 }) end), F(70, nil, function(i) mite(i, { legs = 1, dy = -1 }) end) } }
  CL[#CL+1] = { "windup", false, { F(120, "windup:start", function(i) mite(i, { crouch = true, lv = 2 }) end), F(120, nil, function(i) mite(i, { crouch = true, lv = 3, dx = 1 }) end), F(100, "windup:cue", function(i) mite(i, { crouch = true, lv = 4, dx = 1 }) end) } }
  CL[#CL+1] = { "attack", false, { F(60, "attack:active", function(i) mite(i, { lunge = -3, jaw = true, lv = 3 }) end), F(80, nil, function(i) mite(i, { lunge = -1, lv = 2 }) end), F(100, "attack:recover", function(i) mite(i) end) } }
  CL[#CL+1] = { "hit", false, { F(60, "hit:start", function(i) mite(i, { dx = 1, lv = 3 }) end, true), F(80, nil, function(i) mite(i, { dx = 1 }) end) } }
  CL[#CL+1] = { "down", false, { F(80, "down:start", function(i) mite(i, { dy = 1, lv = 0 }) end, true), F(100, nil, function(i) block(i, 3, 10, 12, 14, C.s, true); pebbles(i, 8, 14, 4, 12, 5, 21) end), F(300, nil, function(i) pebbles(i, 8, 15, 5, 14, 2, 23) end) } }

elseif WHICH == "sentinel-archer" then
  -- 원거리 사수: 가늘고 큰 키, 앞팔에 봉인 수정 활. 쏠 때 수정에 자홍 탄이 맺힘. 프레임 24×28, 기준점 [12,27]
  FW, FH, ANCHOR = 24, 28, { 12, 27 }
  local function archer(i, o)
    o = o or {}
    local lean, bob, lv = o.lean or 0, o.bob or 0, o.lv or 1
    local y = 2 + bob
    local la, lb = (o.legs == 1) and -1 or 0, (o.legs == 1) and 0 or -1
    block(i, 9, y + 18 + la, 11, y + 24, C.s); block(i, 13, y + 18 + lb, 15, y + 24, C.s)       -- 다리 (가늘게)
    block(i, 8 + lean, y + 7, 16 + lean, y + 19, C.m, true)                                     -- 몸
    glyph(i, 12 + lean, y + 13, lv, true)
    block(i, 9 + lean, y, 15 + lean, y + 7, C.m, true)                                          -- 머리 (세로 눈구멍)
    local g = GL[math.min(lv, 3)]; px(i, 10 + lean, y + 3, g[1]); px(i, 10 + lean, y + 4, g[1]); px(i, 10 + lean, y + 5, g[2])
    -- 앞팔 + 수정 활 (세로로 휜 봉인 빛)
    local ax = 4 + (o.draw or 0)
    block(i, ax + 1, y + 9, ax + 5, y + 13, C.m, true)
    for k = -5, 5 do local bx = ax - math.floor((25 - k * k) / 10); px(i, bx, y + 11 + k, (math.abs(k) < 2) and GL[3][1] or GL[2][1]) end
    if o.charge then   -- 맺히는 자홍 탄
      local r = o.charge; px(i, ax - 1, y + 11, MG.W)
      if r >= 1 then px(i, ax - 2, y + 11, MG.a); px(i, ax - 1, y + 10, MG.a); px(i, ax - 1, y + 12, MG.a) end
      if r >= 2 then px(i, ax - 3, y + 11, MG.b); px(i, ax - 2, y + 10, MG.b); px(i, ax - 2, y + 12, MG.b) end
    end
    if lv == 4 then cueOutline(i) end
  end
  CL[#CL+1] = { "idle", true, { F(160, nil, function(i) archer(i) end), F(160, nil, function(i) archer(i, { bob = 1 }) end), F(160, nil, function(i) archer(i, { lv = 2, bob = 1 }) end), F(160, nil, function(i) archer(i) end) } }
  CL[#CL+1] = { "move", true, { F(110, nil, function(i) archer(i, { legs = 0 }) end), F(110, nil, function(i) archer(i, { legs = 1, bob = 1 }) end), F(110, nil, function(i) archer(i, { legs = 0 }) end), F(110, nil, function(i) archer(i, { legs = 1, bob = 1 }) end) } }
  CL[#CL+1] = { "windup", false, {
    F(120, "windup:start", function(i) archer(i, { lean = 1, draw = 1, lv = 2, charge = 0 }) end),
    F(160, nil, function(i) archer(i, { lean = 1, draw = 2, lv = 2, charge = 1 }) end),
    F(200, nil, function(i) archer(i, { lean = 2, draw = 2, lv = 3, charge = 2 }) end),
    F(120, "windup:cue", function(i) archer(i, { lean = 2, draw = 2, lv = 4, charge = 2 }) end),
  } }
  CL[#CL+1] = { "attack", false, { F(60, "attack:active", function(i) archer(i, { lean = -1, draw = 0, lv = 3 }); px(i, 1, 13, MG.a); px(i, 0, 13, MG.W) end), F(100, nil, function(i) archer(i, { lean = 1, lv = 2 }) end), F(140, "attack:recover", function(i) archer(i) end) } }
  CL[#CL+1] = { "hit", false, { F(60, "hit:start", function(i) archer(i, { lean = 2, lv = 3 }) end, true), F(90, nil, function(i) archer(i, { lean = 1 }) end) } }
  CL[#CL+1] = { "down", false, { F(90, "down:start", function(i) archer(i, { lean = 2, bob = 2, lv = 0 }) end, true), F(110, nil, function(i) block(i, 7, 18, 17, 26, C.s, true); pebbles(i, 12, 26, 6, 16, 10, 31) end), F(300, nil, function(i) pebbles(i, 12, 27, 7, 18, 3, 33) end) } }

elseif WHICH == "sentinel-brute" then
  -- 돌진형 덩치: 근접형보다 넓고 낮은 몸, 머리는 어깨에 묻힘, 큰 앞주먹. 프레임 44×40, 기준점 [22,39]
  FW, FH, ANCHOR = 44, 40, { 22, 39 }
  local function brute(i, o)
    o = o or {}
    local lean, bob, lv = o.lean or 0, (o.bob or 0) + (o.slump or 0), o.lv or 1
    local x, y = 10, 8 + bob
    local la, lb = (o.legs == 1) and -1 or 0, (o.legs == 1) and 0 or -1
    block(i, x + 6, y + 22 + la, x + 12, y + 31, C.s); block(i, x + 16, y + 22 + lb, x + 22, y + 31, C.s)   -- 굵은 다리
    block(i, x + 22 + lean, y + 6, x + 29 + lean, y + 20, C.s, true)                                        -- 뒷팔
    block(i, x + 2 + lean, y + 4, x + 26 + lean, y + 24, C.m, true)                                         -- 몸 (넓게)
    glyph(i, x + 14 + lean, y + 14, lv)
    block(i, x + 7 + lean * 2, y - 1, x + 17 + lean * 2, y + 7, C.m, true)                                  -- 머리 (어깨에 묻힘)
    local g = GL[math.min(lv, 3)]; for ex = x + 8 + lean * 2, x + 12 + lean * 2 do px(i, ex, y + 3, g[1]) end
    local arm = o.arm or "rest"
    if arm == "rest" then block(i, x - 3 + lean, y + 8, x + 5 + lean, y + 22, C.m, true)
    elseif arm == "up" then block(i, x + lean, y - 7, x + 8 + lean, y + 8, C.m, true); if lv >= 2 then for k = 0, 4 do px(i, x + 2 + lean + k, y - 6, GL[lv][2]) end end
    elseif arm == "slam" then block(i, x - 9, y + 18, x + 4, y + 27, C.m, true); for k = 0, 9 do px(i, x - 10 + k, y + 29, GL[2][2]) end end
    if o.dust then for k = 0, 5 do px(i, x - 8 + k * 3, y + 29 - (k % 2), C.l) end end
    if lv == 4 then cueOutline(i) end
  end
  CL[#CL+1] = { "idle", true, { F(180, nil, function(i) brute(i) end), F(180, nil, function(i) brute(i, { bob = 1 }) end), F(180, nil, function(i) brute(i, { lv = 2, bob = 1 }) end), F(180, nil, function(i) brute(i) end) } }
  CL[#CL+1] = { "move", true, { F(100, nil, function(i) brute(i, { legs = 0, lean = -1 }) end), F(100, nil, function(i) brute(i, { legs = 1, bob = 1, lean = -1, dust = true }) end), F(100, nil, function(i) brute(i, { legs = 0, lean = -1 }) end), F(100, nil, function(i) brute(i, { legs = 1, bob = 1, lean = -1, dust = true }) end) } }
  CL[#CL+1] = { "windup", false, {
    F(140, "windup:start", function(i) brute(i, { lean = 1, arm = "up", lv = 2 }) end),
    F(160, nil, function(i) brute(i, { lean = 2, arm = "up", lv = 2 }) end),
    F(260, nil, function(i) brute(i, { lean = 2, arm = "up", lv = 3, bob = 1 }) end),
    F(67, "windup:cue", function(i) brute(i, { lean = 2, arm = "up", lv = 4, bob = 1 }) end),
    F(67, nil, function(i) brute(i, { lean = 2, arm = "up", lv = 3, bob = 1 }) end),
    F(66, nil, function(i) brute(i, { lean = 2, arm = "up", lv = 4, bob = 1 }) end),
  } }
  CL[#CL+1] = { "attack", false, { F(60, "attack:active", function(i) brute(i, { lean = -2, arm = "slam", lv = 3, dust = true }) end), F(80, nil, function(i) brute(i, { lean = -2, arm = "slam", lv = 2, slump = 1, dust = true }) end), F(300, "attack:recover", function(i) brute(i, { lean = -1, arm = "slam", lv = 1, slump = 1 }) end) } }
  CL[#CL+1] = { "hit", false, { F(60, "hit:start", function(i) brute(i, { lean = 1, lv = 3 }) end, true), F(90, nil, function(i) brute(i, { lean = 1 }) end) } }
  -- stun (D-073 후속): 패링당해 뒤로 밀리고 1초 경직. 봉인 빛이 꺼졌다 켜지며 깜빡, 몸 둘레에 봉인 빛 불티 (근접형 stun과 같은 박자 250×4)
  local function stunSparks(i, k) local P = { {6, 6}, {38, 10}, {8, 30}, {40, 26}, {22, 2}, {30, 34} }
    for n = 1, 3 do local p = P[(k + n * 2) % #P + 1]; px(i, p[1], p[2], GL[3][1]); if n == 1 then px(i, p[1] + 1, p[2], GL[2][2]) end end end
  CL[#CL+1] = { "stun", false, {
    F(250, "stun:start", function(i) brute(i, { lean = 3, slump = 1, lv = 0 }); stunSparks(i, 0) end, true),
    F(250, nil, function(i) brute(i, { lean = 3, slump = 2, lv = 2 }); stunSparks(i, 1) end),
    F(250, nil, function(i) brute(i, { lean = 2, slump = 2, lv = 0 }); stunSparks(i, 2) end),
    F(250, nil, function(i) brute(i, { lean = 2, slump = 1, lv = 1 }); stunSparks(i, 3) end),
  } }
  CL[#CL+1] = { "down", false, { F(100, "down:start", function(i) brute(i, { lean = 2, slump = 2, lv = 0 }) end, true), F(120, nil, function(i) brute(i, { lean = 3, slump = 5, lv = 0 }); pebbles(i, 22, 38, 6, 30, 10, 41) end), F(140, nil, function(i) block(i, 8, 28, 36, 38, C.s, true); pebbles(i, 22, 38, 8, 34, 8, 43) end), F(400, nil, function(i) block(i, 10, 32, 34, 38, C.s, true); pebbles(i, 22, 39, 9, 38, 3, 45) end) } }

elseif WHICH == "fx-enemy-bolt" then
  -- 사수 탄: 자홍 빛 화살촉 + 짧은 꼬리 (오른쪽으로 날아감, 엔진이 방향대로 돌림). 12×6, 기준점 [8,3]
  FW, FH, ANCHOR, FACING = 12, 7, { 8, 3 }, "right"
  local function bolt(i, k)
    for x = 0, 7 do local c = x >= 6 and MG.W or x >= 4 and MG.a or x >= 2 and MG.b or MG.c; if (x + k) % 3 ~= 0 or x >= 4 then px(i, x + 1, 3, c) end end
    px(i, 9, 3, MG.W); px(i, 8, 2, MG.a); px(i, 8, 4, MG.a); px(i, 10, 3, MG.a)
    if k == 1 then px(i, 5, 2, MG.b); px(i, 3, 4, MG.c) else px(i, 4, 2, MG.c); px(i, 6, 4, MG.b) end
  end
  CL[#CL+1] = { "loop", true, { F(60, nil, function(i) bolt(i, 0) end), F(60, nil, function(i) bolt(i, 1) end) } }
  CL[#CL+1] = { "impact", false, {
    F(50, "impact:start", function(i) px(i, 8, 3, MG.W); for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do px(i, 8 + d[1], 3 + d[2], MG.a) end end),
    F(60, nil, function(i) for _, d in ipairs({ {2,0}, {-2,0}, {0,2}, {0,-2}, {1,1}, {-1,-1}, {1,-1}, {-1,1} }) do px(i, 8 + d[1], 3 + d[2], MG.b) end; px(i, 8, 3, MG.a) end),
    F(70, nil, function(i) for _, d in ipairs({ {3,0}, {-3,0}, {0,3}, {0,-3} }) do px(i, 8 + d[1], 3 + d[2], MG.c) end end),
  } }

elseif WHICH == "fx-drop" then
  -- 바닥 드롭 표시: 등급 색 빛기둥(체커 디더로 위로 갈수록 성기게) + 반짝임 / 줍기: 빛이 안쪽으로 빨려 들며 위로 튐. 16×40, 기준점 [8,38]
  FW, FH, ANCHOR, FACING = 16, 40, { 8, 38 }, "right"
  local RAR = { normal = { H"ffffff", H"cbd0d8" }, rare = { H"c8f0a0", H"8fd46a" }, epic = { H"fff2a0", H"e8b84a" } }
  local function beam(i, pal, k)
    for y = 6, 37 do local t = (37 - y) / 31
      for x = 6, 9 do
        local core = x == 7 or x == 8
        local keep = (t < 0.35) or ((x + y + k) % 2 == 0 and t < 0.7) or ((x + y + k) % 4 == 0)
        if keep and (core or t < 0.6) then px(i, x, y, core and pal[1] or pal[2]) end
      end
    end
    for x = 4, 11 do px(i, x, 38, pal[2]) end; px(i, 3, 38, nil)                       -- 바닥 띠
    local sp = { { 4, 30 - k * 4 }, { 11, 22 - k * 3 }, { 6, 14 - k * 2 } }
    for _, s in ipairs(sp) do px(i, s[1], s[2], pal[1]) end
  end
  for name, pal in pairs({ ["beam-normal"] = RAR.normal, ["beam-rare"] = RAR.rare, ["beam-epic"] = RAR.epic }) do
    CL[#CL+1] = { name, true, { F(120, nil, function(i) beam(i, pal, 0) end), F(120, nil, function(i) beam(i, pal, 1) end), F(120, nil, function(i) beam(i, pal, 2) end), F(120, nil, function(i) beam(i, pal, 3) end) } }
  end
  table.sort(CL, function(a, b) return a[1] < b[1] end)
  CL[#CL+1] = { "pickup", false, {
    F(50, "pickup:start", function(i) for _, d in ipairs({ {-5,0}, {5,0}, {0,-5}, {-3,-3}, {3,-3} }) do px(i, 8 + d[1], 34 + d[2], H"ffffff") end end),
    F(50, nil, function(i) for _, d in ipairs({ {-3,0}, {3,0}, {0,-3}, {-2,-2}, {2,-2} }) do px(i, 8 + d[1], 34 + d[2], H"ffffff") end; px(i, 8, 34, H"ffffff") end),
    F(60, nil, function(i) px(i, 8, 30, H"ffffff"); px(i, 8, 31, H"cbd0d8"); px(i, 7, 32, H"cbd0d8"); px(i, 9, 32, H"cbd0d8") end),
    F(60, nil, function(i) px(i, 8, 24, H"ffffff"); px(i, 8, 26, H"cbd0d8") end),
  } }

elseif WHICH == "ui-items" then
  -- 아이콘 16×16 (줄 0: 슬롯 7 + 기타 3) · 등급 테두리 20×20 (줄 1: 보통·상급·최상급) — 아이콘 칸 안 (2,2)에 아이콘
  local P = {
    K=C.o, W=H"ffffff", y=H"bfeaff", r=H"6fb8f2", b=H"306082", d=H"2f4a66",                     -- 수정 (불씨 색)
    D=H"2e0a0d", M=H"4a1013", T=H"7a2018", L=H"862318",                                          -- 로브 천
    n=H"5e3a28", s=H"8f563b", h=H"b07048",                                                       -- 가죽
    g=H"8f8678", w=H"cfc6b8", m=C.m, l=C.l, C=H"5fcde4", c=H"cbdbfc",                            -- 뼈·돌·봉인 빛
    p=H"e8d8b0", f=H"c8b07c", q=H"9a7a4c",                                                       -- 두루마리 종이
  }
  local ICON = {
    crystal = { "................", "..........KK....", ".........KWyK...", "........KWyyrK..", ".......KWyyrrK..", "......KyyyrrK...", ".....KyyyrrK....", "....KyyrrrK.....",
                "...KyyrrbK......", "...KyrrbK.......", "..KyrbbK........", "..KrbbK.........", "..KbdK..........", "...KK...........", "................", "................" },
    head =    { "................", "......KKKKK.....", "....KKMTTTMKK...", "...KMTLLTMMMDK..", "..KMTLKKKKMMDK..", "..KMLKKKKKKMDK..", "..KMTKKKKKKMDK..", "..KMTKKKKKKMDK..",
                "..KMMKKKKKMMDK..", "...KMMKKKMMDDK..", "...KDMMMMMDDK...", "..KDDMMDDDDDDK..", "..KDDDDDDDDDDK..", "...KKKKKKKKKK...", "................", "................" },
    body =    { "................", "....KKK..KKK....", "...KMTMKKMTMK...", "..KMTLTMMTLTMK..", "..KMTTMMMMTTMK..", "..KMTMMDDMMTMK..", "...KMMMDDMMMK...", "...KMMMDDMMMK...",
                "...KMMDDDDMMK...", "..KMMMDDDDMMMK..", "..KMMDDDDDDMMK..", ".KMMDDDDDDDDMMK.", ".KMDDDDDDDDDDMK.", ".KKKKKKKKKKKKKK.", "................", "................" },
    hand =    { "................", "......KKKKK.....", ".....KhhhssK....", "....KhhssssnK...", "...KKhsssssnK...", "..KhhKsssssnK...", "..KhsKsssssnK...", "...KssssssnnK...",
                "....KssssnnK....", "....KnnnnnnK....", "....KgngngnK....", "....KngngngK....", "....KKKKKKKK....", "................", "................", "................" },
    foot =    { "................", ".......KKKKK....", ".......KhssK....", ".......KhssK....", ".......KhssK....", ".......KhsnK....", ".......KhsnK....", "......KKhsnK....",
                "....KKhhssnK....", "...KhhsssssnK...", "..KhhssssssnK...", "..KhssssssnnK...", "..KnnnnnnnnnK...", "...KKKKKKKKK....", "................", "................" },
    charm =   { "......gggg......", ".....g....g.....", "....g......g....", "....g......g....", ".....g....g.....", "......KKKK......", ".....KllllK.....", "....KllmmmmK....",
                "....KlmmCmmK....", "....KmmCCCmK....", "....KmmmCmmK....", ".....KmmmmK.....", "......KKKK......", "................", "................", "................" },
    relic =   { "................", "......KKKK......", ".....KwwwgK.....", "....KwKKKKgK....", "....KwKCcKgK....", "....KwKCCKgK....", "....KwKKKKgK....", ".....KwwggK.....",
                "......KwgK......", ".....KwwggK.....", "....KwwwgggK....", "....KKKKKKKK....", "................", "................", "................", "................" },
    scroll =  { "................", "...KKKKKKKKKK...", "..KpppppppppqK..", "..KfKKKKKKKKfK..", "...KppppppppK...", "...KpfqfqfqpK...", "...KppppppppK...", "...KpqfqfqfpK...",
                "...KppppCpppK...", "...KpppCCCppK...", "...KppppCpppK...", "..KKKKKKKKKKKK..", "..KfppppppppfK..", "...KKKKKKKKKK...", "................", "................" },
    stamp =   { "................", "......KKKK......", ".....KlllmK.....", "....KlmmmmmK....", "...KlmmCmmmsK...", "...KmmCCCmmsK...", "..KlmCCcCCmmsK..", "..KmmmCCCmmssK..",
                "..KmmCmmmCmssK..", "...KmmmmmmssK...", "...KmmmmmssK....", "....KmsssssK....", ".....KKKKKK.....", "................", "................", "................" },
    dust =    { "................", "..........W.....", "......K.....y...", ".....KlK........", "....KlmmK..W.....", "...KlmmmsK......", "...KmmmmsK..y...", "....KKKKK.......",
                "...y......W.....", ".....WKKKKK.....", "....KyyWyyrK....", "...KyWyyryrrK...", "..KyyyrWyrrbbK..", "..KKKKKKKKKKKK..", "................", "................" },
  }
  local ORDER = { "crystal", "head", "body", "hand", "foot", "charm", "relic", "scroll", "stamp", "dust" }
  local img = Image(10 * 16, 16 + 20, ColorMode.RGB)
  for k, name in ipairs(ORDER) do for y, r in ipairs(ICON[name]) do for x = 1, 16 do local c = P[r:sub(x, x)]; if c then img:drawPixel((k - 1) * 16 + x - 1, y - 1, c) end end end end
  -- 등급 테두리 (칸 바탕 + 테두리) 20×20
  local BG, BG2 = H"1a1622", H"241e2c"
  local function frame(ox, col, thick, ornament)
    for y = 0, 19 do for x = 0, 19 do
      local d = math.min(x, y, 19 - x, 19 - y)
      local corner = (x == 0 or x == 19) and (y == 0 or y == 19)
      local c = (d < thick) and col or ((d == thick) and H"0b0910" or ((x + y) % 2 == 0 and BG or BG2))
      if not (corner and thick == 1) then img:drawPixel(ox + x, 16 + y, c) end
    end end
    if ornament then for _, p in ipairs({ {0,0,1,1}, {19,0,-1,1}, {0,19,1,-1}, {19,19,-1,-1} }) do
      img:drawPixel(ox + p[1], 16 + p[2], H"fff2a0"); img:drawPixel(ox + p[1] + p[3] * 2, 16 + p[2], H"fff2a0"); img:drawPixel(ox + p[1], 16 + p[2] + p[4] * 2, H"fff2a0")
      img:drawPixel(ox + p[1] + p[3] * 3, 16 + p[2] + p[4] * 3, ornament) end end
  end
  frame(0, H"ffffff", 1); frame(20, H"8fd46a", 2); frame(40, H"e8b84a", 2, H"fff2a0")
  local spr = Sprite(img.width, img.height, ColorMode.RGB); spr.cels[1].image = img
  spr:saveCopyAs(app.params.out .. "/ui-items.png")
  local f = io.open(app.params.out .. "/ui-items.json", "wb")
  f:write('{\n  "icon": [16, 16],\n  "icons": ["' .. table.concat(ORDER, '", "') .. '"],\n  "iconRow": 0,\n  "frame": [20, 20],\n  "frames": ["normal", "rare", "epic"],\n  "frameOrigin": [0, 16],\n  "iconInFrame": [2, 2],\n' ..
    '  "note": "아이콘 k = (k×16, 0). 테두리 k = (k×20, 16): 보통 흰 1px · 상급 연두 #8fd46a 2px · 최상급 금 #e8b84a 2px + 모서리 장식. 아이콘은 테두리 칸 (2,2)에 얹음"\n}\n')
  f:close()
  return
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
spr.data = "facing=" .. FACING .. ";anchor=" .. ANCHOR[1] .. "," .. ANCHOR[2]
spr:saveAs(app.params.out)
