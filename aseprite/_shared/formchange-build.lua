-- 폼체인지 장면 D v2 (D-037): 불씨 → 어린이. 대본 _design/docs/24_opening-script-v1.md "장면 D v2".
-- 실행: aseprite -b --script-param which=<id> --script-param out=<id>.aseprite --script formchange-build.lua
--   prop-robe           48×32, 기준점 [24,32] = player-child [24,24]와 같은 바닥 자리(몸 그림이 같음). 원본은 왼쪽을 봄
--                       lie(널브러짐) / flutter(바람에 펄럭, 반복) / form-a(바람이 채움 1400ms — D-038 확정)
--                       form 끝 프레임 = player-child 몸 (지팡이·손불꽃 없음 — 장면 9·10에서 생김)
--   prop-crystal-staff  24×32, 기준점 [12,31]. drop(떨어져 두 번 튕김 1000ms) / lie(수정 맥동, 반복) / shake(느림→빠름 1200ms) / rise(떠올라 곧게 섬 450ms) / fly(손까지 날아가는 동안 반복)
--   fx-merge            32×32, 기준점 가운데. loop: 푸른 불씨와 작은 불꽃이 두 바퀴 돌며 가까워지고 밝아짐 (1100ms)
--   fx-wind             64×24, 기준점 가운데. loop: 오른쪽으로 날아가는 바람 줄기·먼지 (엔진이 소품을 왼→오로 옮김)
-- 수정 = 불씨 색(#ffffff/#bfeaff/#6fb8f2): 불씨가 수정이 된 것 (D-037). 모션은 실험실 시안(scratch/motion-lab/robe.lua)과 같음.
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local P = { K=H"0e0507", D=H"2e0a0d", M=H"4a1013", T=H"7a2018", r=H"ac3232", y=H"df7126", Y=H"fbf236", s=H"8f563b", S=H"5e3a28" }
local E = { W=H"ffffff", y=H"bfeaff", r=H"6fb8f2" }
local DUST, GUST = H"6a6078", H"a99fb8"
local WHICH = app.params.which
local FW, FH, ANCHOR, FACING = 48, 32, { 24, 32 }, "right"
local OX, OY = 0, 0
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local function put(i, x, y, c) px(i, OX + x, OY + y, c) end
local function art(i, rows, x0, y0, pal, recolor)
  for y, r in ipairs(rows) do for x = 1, #r do local ch = r:sub(x, x); local c = (pal or P)[ch]; if recolor and c then c = recolor(x - 1 + x0, y - 1 + y0, ch, c) end; put(i, x0 + x - 1, y0 + y - 1, c) end end
end
local seed = 7
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local CL = {}

if WHICH == "prop-robe" then
  FACING, OX, OY = "left", 15, 12
  local DARK = { L=P.M, R=P.D, h=P.D }   -- 손불꽃이 켜지기 전: 불빛 받는 곳도 그냥 천 색
  local BODY = {   -- player-child 몸 (aseprite/player-child/build.lua BODY와 같음, 지팡이 칸 제외)
  "..................",
  "......KKKKK.......",
  ".....KMTTMDK......",
  "....KMLMMMMK......",
  "....KLKKKMMMK.....",
  "....KLKKKKMMK.....",
  "....KMKKKKMDK.....",
  ".....KMKKDDDK.....",
  ".....KDMDDDDK.....",
  "....KRDDDDMDK.....",
  "....KRDDDDMMK.....",
  "...hRDDMMDKMMK....",
  "....RDDMMDKMMK....",
  "....KRDDMDKDMDK...",
  ".....KDDMMMMDMK...",
  "......KKDDMMKK....",
  "........KKKK......",
  "..................",
  }
  local SLUMP = {
  "..KKKK............",
  ".KMTTMKK...KKK....",
  "KMKKKMDDKKKDMDK...",
  "KDMMDDMMDDMDDMMKK.",
  ".KKKKKKKKKKKKKKKK.",
  }
  local PUFF = {
  "..KKKK..KKK.......",
  ".KMTTMKKDMDKKK....",
  "KMKKKMDDMMDDMDKK..",
  "KDMMDDMMDDMDDMMDK.",
  "KDDMMDDDMMDDMMDDK.",
  ".KKKKKKKKKKKKKKKK.",
  }
  local function body(i, o)
    o = o or {}
    for y, r in ipairs(BODY) do local yy = y - 1
      if yy >= (o.from or 0) then for x = 1, #r do local ch = r:sub(x, x); local c = DARK[ch] or P[ch]
        if c and o.recolor then c = o.recolor(x - 1, yy, ch, c) end
        put(i, x - 1, yy + ((yy <= 4 and o.hood) or 0) + (o.dy or 0), c) end end
    end
  end
  local function swirl(i, cx, yt, yb, rx, phase, turns)
    for k = 0, 60 do
      local t = k / 60; local a = phase + t * turns * 2 * math.pi
      local x, y = cx + math.cos(a) * rx * (0.6 + 0.4 * t), yb - (yb - yt) * t
      local front = math.sin(a) > 0
      local col = front and { P.T, P.M, P.M, P.D } or { P.D, P.D, P.K }
      for d = 1, #col do put(i, math.floor(x + 0.5), math.floor(y + 0.5) + d - 1, (front and d == 1 and k % 3 ~= 0) and P.M or col[d]) end
    end
  end
  local FLAP = { { "...KKK.", "KKDMMK.", "MMDDMMK" }, { "....KK.", "..KKMMK", "KKDDMDK" }, { "...KKK.", "KKDMMK.", "MMDDMMK" }, { ".......", "...KKKK", "KKDMMDK" } }
  CL[#CL+1] = { "lie", true, { { 1000, nil, function(i) art(i, SLUMP, 0, 12) end } } }
  local F = {}
  for k = 1, 4 do F[k] = { 90, nil, function(i) art(i, SLUMP, 0, 12, nil, function(x, y, ch, c) if x >= 10 and y <= 13 then return nil end; return c end); art(i, FLAP[k], 10, 11) end } end
  CL[#CL+1] = { "flutter", true, F }
  -- rise-slow (D-039): 바람 없이 스스로 천천히 일어섬 2800ms. 아랫단 → 몸 → 후드 순서로 형체. 손불꽃·지팡이 없음
  -- (지팡이는 소품이 이미 손 자리에 떠서 기다림 → 끝 프레임에서 player-child idle로 바꿔치기)
  local function cap(i, top, wide) art(i, wide and { "..KKKKKKKK...", ".KMTTMDDMDK..", "KDMDDMMDDMMK." } or { "...KKKKKK....", "..KMTTMDDK..." }, 2, top - (wide and 3 or 2)) end
  local SLOW = 250
  CL[#CL+1] = { "rise-slow", false, {
    { 300, "rise-slow:start", function(i) art(i, SLUMP, 0, 12) end },
    { SLOW, nil, function(i) art(i, SLUMP, 0, 12, nil, function(x, y, ch, c) if x >= 10 and y <= 13 then return nil end; return c end); art(i, FLAP[4], 10, 11) end }, -- 자락이 스스로 살짝 들썩
    { SLOW, nil, function(i) art(i, PUFF, 0, 11) end },                               -- 천 아래로 숨이 들어간 듯 부풂
    { SLOW, nil, function(i) art(i, PUFF, 0, 10) end },                                -- 땅에서 1px 들림 (밑단 자리가 비어 뜸)
    { SLOW, nil, function(i) body(i, { from = 14 }); cap(i, 14, true) end },          -- 아랫단이 먼저 형체
    { SLOW, nil, function(i) body(i, { from = 10 }); cap(i, 10, true) end },          -- 몸이 차오름 (위는 처진 천)
    { SLOW, nil, function(i) body(i, { from = 8 }); cap(i, 8) end },
    { SLOW, nil, function(i) body(i, { hood = 3 }) end }, -- 후드는 아직 몸 위에 내려앉음
    { SLOW, nil, function(i) body(i, { hood = 2 }) end },                             -- 후드가 솟음
    { SLOW, nil, function(i) body(i, { hood = 1 }) end },
    { SLOW, "rise-slow:done", function(i) body(i) end },                              -- 다 일어섬 = 손이 지팡이에 닿음
  } }
  CL[#CL+1] = { "form-a", false, {
    { 120, "form-a:lift", function(i) art(i, SLUMP, 0, 12); art(i, FLAP[1], 10, 11) end },
    { 120, nil, function(i) art(i, { "....KKKKKK....", "..KKMTTMDDKK..", ".KDMKKKDMMDDK.", "KDDDMMDDDMMDDK", ".KK..KKKK..KK." }, 2, 8) end },
    { 130, nil, function(i) swirl(i, 8, 4, 15, 7, 0, 1.2) end },
    { 130, nil, function(i) swirl(i, 8, 3, 15, 6, 1.7, 1.2) end },
    { 140, nil, function(i) body(i, { from = 13 }); swirl(i, 8, 3, 12, 5, 3.4, 1.0) end },
    { 140, nil, function(i) body(i, { from = 9 }); swirl(i, 8, 2, 9, 4, 5.1, 0.8) end },
    { 150, nil, function(i) body(i, { from = 5 }); art(i, { "......KKKKK.", ".....KMDDMDK" }, 0, 4) end },
    { 150, "form-a:hood", function(i) body(i, { hood = 2 }) end },
    { 170, nil, function(i) body(i, { dy = -1 }) end },
    { 150, "form-a:settle", function(i) body(i) end },
  } }

elseif WHICH == "prop-crystal-staff" then
  FW, FH, ANCHOR = 24, 32, { 12, 31 }
  -- 크기는 player-child가 손에 든 지팡이(7px)와 같음 → 날아가 손에 안착할 때 player-child idle로 바꿔치기해도 이어짐
  -- 지팡이 선: (x0,y0) 자루 끝 → (x1,y1) 수정 끝. 바깥선 K → 자루 s → 수정(맥동 0~2)
  local function staff(i, x0, y0, x1, y1, pulse)
    local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0), 1)
    local pts = {}
    for k = 0, n do pts[#pts+1] = { math.floor(x0 + (x1 - x0) * k / n + 0.5), math.floor(y0 + (y1 - y0) * k / n + 0.5) } end
    local cx, cy = pts[#pts][1], pts[#pts][2]
    for _, p in ipairs(pts) do for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do px(i, p[1] + d[1], p[2] + d[2], P.K) end end
    for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1}, {1,1}, {-1,-1}, {1,-1}, {-1,1} }) do px(i, cx + d[1], cy + d[2], P.K) end
    for k, p in ipairs(pts) do px(i, p[1], p[2], P.s) end
    px(i, cx, cy, pulse == 2 and E.W or E.y); px(i, pts[#pts - 1][1], pts[#pts - 1][2], E.r)
    if pulse == 2 then px(i, cx + 2, cy - 2, E.y) end
  end
  local function lying(i, pulse, lift, rock) staff(i, 9, 29 - (lift or 0) - (rock == -1 and 1 or 0), 15, 29 - (lift or 0) - (rock == 1 and 1 or 0), pulse) end
  -- 곧게 선 모습 = player-child 손 지팡이 그림(오른쪽을 보는 내보낸 그림 기준으로 좌우 반전해 둠)
  local UP = { "KK..", "KcK.", "KCCK", ".KBK", ".KsK", ".KsK", ".KKK" }
  local function upright(i, pulse, sway, dy)
    local pal = { K=P.K, s=P.s, c=pulse == 2 and E.W or E.y, C=pulse >= 1 and E.y or E.r, B=E.r }
    for y, r in ipairs(UP) do
      local sh = (sway ~= 0 and y <= 3) and sway or 0   -- 위쪽(수정)만 1px 기울어 흔들림
      for x = 1, 4 do px(i, 9 + x + sh, 24 + y + (dy or 0), pal[r:sub(x, x)]) end
    end
  end
  CL[#CL+1] = { "drop", false, {
    { 60, nil, function(i) staff(i, 10, 9, 14, 3, 1) end },          -- 떨어짐 (비스듬히)
    { 60, nil, function(i) staff(i, 10, 17, 14, 11, 1) end },
    { 60, nil, function(i) staff(i, 10, 25, 14, 19, 1) end },
    { 70, "drop:hit", function(i) staff(i, 9, 30, 14, 25, 2) end },  -- "탁" 자루가 먼저 닿음
    { 80, nil, function(i) staff(i, 8, 25, 15, 23, 1) end },          -- 튀어 오름
    { 80, nil, function(i) staff(i, 8, 26, 15, 28, 1) end },
    { 70, "drop:bounce", function(i) lying(i, 2, 0, 1) end },         -- "탁" 두 번째
    { 90, nil, function(i) lying(i, 1, 0, 1) end },
    { 100, nil, function(i) lying(i, 1) end },
    { 330, nil, function(i) lying(i, 0) end },
  } }
  CL[#CL+1] = { "lie", true, {
    { 220, nil, function(i) lying(i, 0) end }, { 220, nil, function(i) lying(i, 1) end },
    { 220, nil, function(i) lying(i, 2) end }, { 220, nil, function(i) lying(i, 1) end },
  } }
  local SH = { 200, 180, 160, 140, 120, 100, 90, 80, 70, 60 }   -- 흔들흔들: 처음엔 느리게 → 점점 빠르게 (합 1200)
  local F = {}
  for k, ms in ipairs(SH) do F[k] = { ms, k == 1 and "shake:start" or nil, function(i) lying(i, k > 6 and 2 or 1, 0, k % 2 == 1 and 1 or -1) end } end
  CL[#CL+1] = { "shake", false, F }
  -- rise: 누운 채 떠올라 곧게 섬 (엔진이 10px 올리는 동안, 450ms) → fly: 손까지 느리게 날아가는 동안 반복 (살짝 흔들림 + 수정 은은한 맥동)
  CL[#CL+1] = { "rise", false, {
    { 150, "rise:start", function(i) lying(i, 1, 1) end },
    { 150, nil, function(i) staff(i, 10, 27, 14, 22, 1) end },
    { 150, nil, function(i) upright(i, 1, 0) end },
  } }
  CL[#CL+1] = { "rise-slow", false, {   -- D-039: 느린 판 900ms (rise를 0.5배속으로 늘리는 대신 중간 각도를 더 넣음)
    { 150, "rise-slow:start", function(i) lying(i, 1, 1) end },
    { 150, nil, function(i) lying(i, 1, 2) end },
    { 150, nil, function(i) staff(i, 9, 27, 15, 24, 1) end },
    { 150, nil, function(i) staff(i, 10, 27, 14, 22, 2) end },
    { 150, nil, function(i) staff(i, 11, 27, 13, 20, 1) end },
    { 150, nil, function(i) upright(i, 1, 0) end },
  } }
  local SW = { 0, 1, 1, 0, -1, -1 }
  local PU = { 1, 1, 2, 1, 0, 0 }
  local G = {}
  for k = 1, 6 do G[k] = { 150, nil, function(i) upright(i, PU[k], SW[k], (k == 2 or k == 3) and -1 or 0) end } end
  CL[#CL+1] = { "fly", true, G }

elseif WHICH == "fx-merge" then
  FW, FH, ANCHOR = 32, 32, { 16, 16 }
  local function emb(i, x, y, r) for dy = -r, r do for dx = -r, r do local d = math.sqrt(dx * dx + dy * dy); if d <= r + 0.3 then px(i, x + dx, y + dy, d < r * 0.45 and E.W or (d < r * 0.8 and E.y or E.r)) end end end end
  local function flame(i, x, y, big)   -- 작은 불꽃 (따뜻한 색, 위로 혀)
    px(i, x, y, P.Y); px(i, x - 1, y, P.y); px(i, x + 1, y, P.y); px(i, x, y + 1, P.r); px(i, x, y - 1, P.y); px(i, x, y - 2, P.r)
    if big then px(i, x - 1, y + 1, P.r); px(i, x + 1, y + 1, P.r); px(i, x + 1, y - 1, P.r) end
  end
  local N = 12
  local F = {}
  for k = 1, N do
    local t = (k - 1) / (N - 1)
    F[k] = { k == N and 100 or 91, nil, function(i)
      local r = 9 - 7 * t
      for tr = 3, 1, -1 do   -- 꼬리 (지난 자리 흐리게)
        local a = (t - tr * 0.03) * 4 * math.pi
        px(i, 16 + math.cos(a) * (r + tr * 0.5), 16 + math.sin(a) * (r + tr * 0.5) * 0.6, E.r)
        px(i, 16 - math.cos(a) * (r + tr * 0.5), 16 - math.sin(a) * (r + tr * 0.5) * 0.6, P.r)
      end
      local a = t * 4 * math.pi
      if k < N then
        emb(i, 16 + math.cos(a) * r, 16 + math.sin(a) * r * 0.6, t > 0.6 and 2 or 1)
        flame(i, 16 - math.cos(a) * r, 16 - math.sin(a) * r * 0.6, t > 0.5)
      else emb(i, 16, 16, 3) end
      if t > 0.55 then local g = math.floor((t - 0.55) * 12); for q = 0, g do px(i, 16 + (q % 2 == 0 and q or -q), 16 - (q % 3), E.y) end end   -- 밝아짐
      if t > 0.8 then for a2 = 0, 359, 30 do px(i, 16 + math.cos(math.rad(a2)) * (4 + t * 3), 16 + math.sin(math.rad(a2)) * (4 + t * 3) * 0.8, E.y) end end
    end }
  end
  CL[#CL+1] = { "loop", true, F }

elseif WHICH == "fx-radiance" then
  -- D-041: 일어서는 어린이 둘레 방사형 빛줄기 (노출이 터진 느낌). 128×128, 기준점 [64,64] = 빛의 가운데
  -- loop: 로브 rise-slow 2.8초 동안 반복(8장 880ms) / fade: 줄기가 줄어들며 사라짐(4장 480ms, 마지막은 빈 칸)
  -- 가운데 반지름 12 안은 비워 둠 → 어린이 실루엣이 그대로 보임(엔진은 로브 뒤에 그려도, 앞에 그려도 됨)
  FW, FH, ANCHOR = 128, 128, { 64, 64 }
  local CXr, CYr = 64, 64
  local NR = 20
  local BASE = {}
  seed = 31
  for k = 1, NR do BASE[k] = { a = (k - 1) * (360 / NR) + rnd() * 9, len = (k % 5 == 1) and 58 + rnd() * 6 or 30 + rnd() * 18, w = (k % 5 == 1) and 2 or 1 } end
  local function ray(i, a, len, w)
    local ca, sa = math.cos(math.rad(a)), math.sin(math.rad(a))
    for r = 13, len do
      local t = (r - 13) / math.max(1, len - 13)
      local x, y = CXr + ca * r, CYr + sa * r * 0.92
      if t < 0.45 then px(i, x, y, E.W); if w > 1 or t < 0.2 then px(i, x - sa, y + ca, E.W); px(i, x + sa, y - ca, t < 0.25 and E.W or E.y) end
      elseif t < 0.75 then px(i, x, y, E.y); if w > 1 and r % 2 == 0 then px(i, x - sa, y + ca, E.y) end
      elseif r % 2 == 0 then px(i, x, y, E.y) end
    end
  end
  local function halo(i, f)   -- 실루엣 둘레 고리 (깜빡이는 점선)
    for a = 0, 359, 6 do local r = 12 + ((a // 6 + f) % 3 == 0 and 1 or 0)
      px(i, CXr + math.cos(math.rad(a)) * r, CYr + math.sin(math.rad(a)) * r * 0.92, ((a // 6 + f) % 2 == 0) and E.W or E.y) end
  end
  local function sparks(i, f, n, out)
    seed = 77
    for k = 1, n do
      local a, r0, sp = rnd() * 360, 14 + rnd() * 40, 2 + rnd() * 3
      local r = 14 + (r0 - 14 + f * sp * (out or 1)) % 48
      local x, y = CXr + math.cos(math.rad(a)) * r, CYr + math.sin(math.rad(a)) * r * 0.92
      if k % 7 == 0 then px(i, x, y, P.Y); px(i, x, y + 1, P.y)                      -- 불꽃 조각 (따뜻함은 주인공 몫)
      elseif k % 3 == 0 then px(i, x, y, E.W); px(i, x - 1, y, E.y); px(i, x + 1, y, E.y); px(i, x, y - 1, E.y); px(i, x, y + 1, E.y)  -- 반짝임
      else px(i, x, y, (k + f) % 2 == 0 and E.W or E.y) end
    end
  end
  local function frame(i, f, scale, nsp)
    for k, b in ipairs(BASE) do
      local len = 13 + (b.len * (0.85 + 0.15 * math.sin(f * 0.9 + k * 1.7)) - 13) * scale
      if len > 15 then ray(i, b.a + f * 1.5, len, b.w) end
    end
    if scale > 0.3 then halo(i, f) end
    sparks(i, f, nsp)
  end
  local F = {}
  for f = 1, 8 do F[f] = { 110, f == 1 and "loop:start" or nil, function(i) frame(i, f, 1, 26) end } end
  CL[#CL+1] = { "loop", true, F }
  CL[#CL+1] = { "fade", false, {
    { 120, nil, function(i) frame(i, 9, 0.7, 20) end },
    { 120, nil, function(i) frame(i, 10, 0.45, 12) end },
    { 120, nil, function(i) frame(i, 11, 0.2, 6) end },
    { 120, nil, function(i) sparks(i, 12, 3) end },
  } }

elseif WHICH == "fx-wind" then
  FW, FH, ANCHOR = 64, 24, { 32, 12 }
  local LINES = { {3,14,0}, {7,20,13}, {11,10,30}, {15,16,45}, {19,12,22}, {9,8,52} }   -- y, 길이, 시작 x
  local F = {}
  for k = 1, 4 do F[k] = { 70, nil, function(i)
    for n, l in ipairs(LINES) do
      local x0 = (l[3] + k * 7) % (FW + l[2]) - l[2]
      for d = 0, l[2] - 1 do local x = x0 + d
        if d > l[2] * 0.3 or d % 2 == 0 then px(i, x, l[1] + ((d > l[2] - 4 and n % 2 == 0) and -1 or 0), d > l[2] * 0.6 and GUST or DUST) end end
    end
    seed = 5
    for q = 1, 10 do local x0, y0 = rnd() * FW, 2 + rnd() * 20; px(i, (x0 + k * 5) % FW, y0 + ((k + q) % 3 - 1), q % 3 == 0 and GUST or DUST) end
  end } end
  CL[#CL+1] = { "loop", true, F }
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
