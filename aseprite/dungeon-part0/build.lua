-- dungeon-part0.aseprite 생성 (이슈 #6): Act 1 / Part 0 봉인탑 통로 타일셋. 16x16, 10열 x 7행 (160x112).
-- 실행: aseprite -b --script-param out=<경로>/dungeon-part0.aseprite --script build.lua
-- 타일 번호와 애니메이션·이름은 tileset.json에 (export-tileset.mjs가 .tsj로 만든다). 번호를 바꾸면 tileset.json도 같이.
--  0 바닥        1 금         2 자갈        3 이음새       4 이끼 바닥     5 큰 금        6 벽 아래 그늘   7 왼벽 옆 그늘  8 오른벽 옆 그늘 9 왼위 모서리 그늘
-- 10 오른위 모서리 그늘 11 윗면    12 윗면(아래 테) 13 윗면(오른 테) 14 윗면(왼 테) 15 윗면(위 테) 16 윗면(아래+오른 테) 17 윗면(아래+왼 테) 18 허공   19 -
-- 20 벽면 위     21 벽면 위 금  22 벽면 아래   23 벽면 아래 금 24 벽면 아래 이끼 25,26 문 위 왼/오  27,28 문 아래 왼/오  29 -
-- 54,55 벽면 위 오른/왼 끝 · 64,65 벽면 아래 오른/왼 끝 · 57,67 한 칸 기둥 위/아래 · 58,59 옆벽 끝(왼쪽 벽/오른쪽 벽) · 56 문턱 (D-040)
-- 30 긁힌 자국   31 유물 파편   32 잔해       33 해골        34,35 문양 위   36,37 수호체 잔해 위  38,39 봉인등 프레임0,1
-- 40,41 봉인등 2,3  44,45 문양 아래  46,47 잔해 아래  48 잔해 아래(가슴 빛)
-- 50,51 / 60,61 문양 중간 밝기   52,53 / 62,63 문양 밝음
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local C = { f0=H"2a2433", f1=H"3a3245", f2=H"463d52", f3=H"584d66", cap=H"4a4058", mor=H"241e2c", br=H"4a4058", bh=H"5e536e", bs=H"362e40" }
-- 팔레트 바꿔 끼우기 (다른 층·분위기): --script-param pal="f0=2b2c38,f1=3b3d4c,..."
for k, v in (app.params.pal or ""):gmatch("(%w+)=(%x%x%x%x%x%x)") do C[k] = H(v) end
local IRON = { o=H"141018", m=H"3c3644", h=H"5c5468" }
local S1, S2, S3 = H"2f4a66", H"5fcde4", H"cbdbfc"   -- 봉인 빛 (어두움/중간/반짝) = 방어 계열
local CY = H"306082"                                -- 꺼져 가는 봉인 빛
local MOSS1, MOSS2 = H"3d4a2c", H"56663f"
local VOID = H"0b0910"
local BONE = { w=H"cfc6b8", s=H"8f8678" }
local COLS, ROWS = 10, 14  -- 7~8행: 흔적 (D-034), 9~13행: 벽 윗면 자동 연결 (D-041)

local img = Image(COLS * 16, ROWS * 16, ColorMode.RGB)
local function px(t, x, y, c) img:drawPixel((t % COLS) * 16 + x, (t // COLS) * 16 + y, c) end
local seed = 1
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local function floorBase(t, s)
  seed = s
  for y = 0, 15 do for x = 0, 15 do local r = rnd(); px(t, x, y, r < 0.05 and C.f0 or r < 0.085 and C.f2 or C.f1) end end
end
-- 32x32 덩어리: ids = {왼위, 오른위, 왼아래, 오른아래}
local function big(ids, x, y, c) if x >= 0 and y >= 0 and x < 32 and y < 32 then px(ids[1 + (x // 16) + (y // 16) * 2], x % 16, y % 16, c) end end
local function line(ids, x0, y0, x1, y1, c)
  local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, n do big(ids, math.floor(x0 + (x1 - x0) * i / n + 0.5), math.floor(y0 + (y1 - y0) * i / n + 0.5), c) end
end

-- ===== 바닥 =====
floorBase(0, 11)
floorBase(1, 23)
do local cy = 6
  for x = 2, 12 do cy = cy + (rnd() < 0.35 and 1 or (rnd() < 0.3 and -1 or 0)); cy = math.max(3, math.min(12, cy)); px(1, x, cy, C.f0); px(1, x, cy + 1, C.f2) end end
floorBase(2, 37)
for _, s in ipairs({ {3,4,2}, {10,9,3}, {5,12,2} }) do for x = s[1], s[1] + s[3] - 1 do px(2, x, s[2], C.f3); px(2, x, s[2] + 1, C.f2); px(2, x, s[2] + 2, C.f0) end end
floorBase(3, 51)
for x = 3, 9 do px(3, x, 5, C.f0); px(3, x, 6, C.f2) end
for y = 7, 10 do px(3, 9, y, C.f0) end
floorBase(4, 61)
for _, b in ipairs({ {3,4,3}, {10,10,2}, {5,12,2}, {12,3,1} }) do for y = -b[3], b[3] do for x = -b[3], b[3] do
  if x * x + y * y <= b[3] * b[3] then local r = rnd(); if r < 0.75 then px(4, (b[1] + x) % 16, (b[2] + y) % 16, r < 0.3 and MOSS2 or MOSS1) end end end end end
floorBase(5, 83)
do local cx, cy = 1, 3
  for i = 1, 16 do cx = cx + 1; cy = cy + ((i % 3 == 0) and 1 or 0); if cx < 16 then px(5, cx, cy, C.f0); px(5, cx, cy + 1, C.f2) end end
  for i = 0, 4 do px(5, 8 + i // 2, 7 + i, C.f0) end end
-- 그늘 (계단식): 6 위, 7 왼, 8 오른, 9 왼위, 10 오른위
local function shade(t, s, f) floorBase(t, s); for y = 0, 15 do for x = 0, 15 do if f(x, y) then px(t, x, y, C.f0) end end end end
local function edge(d, k) return d < 1 or (d == 1 and k % 2 == 0) or (d == 2 and k % 4 == 0) end
local function top(x, y) return y < 2 or (y == 2 and x % 2 == 0) or (y == 3 and x % 4 == 0) end
shade(6, 11, top)
shade(7, 13, function(x, y) return edge(x, y) end)
shade(8, 17, function(x, y) return edge(15 - x, y) end)
shade(9, 19, function(x, y) return top(x, y) or edge(x, y) end)
shade(10, 21, function(x, y) return top(x, y) or edge(15 - x, y) end)
for _, t in ipairs({ 6, 9, 10 }) do for x = 0, 15 do px(t, x, 0, C.bs) end end

-- ===== 벽 윗면 (테 = 바닥 쪽 가장자리 밝은 줄) — D-039: 바닥 점무늬 대신 매끈한 큰 판석(16px 줄눈) =====
local CAPS = { [11]="", [12]="b", [13]="r", [14]="l", [15]="t", [16]="br", [17]="bl" }
for t, lip in pairs(CAPS) do seed = 71 + t
  for y = 0, 15 do for x = 0, 15 do
    local c = C.cap
    if x == 0 or y == 0 then c = C.bs elseif (x == 1 or y == 1) and rnd() < 0.5 then c = C.br end   -- 판석 줄눈 + 살짝 깎인 모서리
    if (lip:find("b") and y == 15) or (lip:find("r") and x == 15) or (lip:find("l") and x == 0) or (lip:find("t") and y == 0) then c = C.bh end
    px(t, x, y, c) end end
end
for y = 0, 15 do for x = 0, 15 do px(18, x, y, VOID) end end

-- ===== 벽면 (2칸 높이: 위·아래) — D-039: 바닥과 확실히 다르게 =====
-- 큰 돌 블록(16×8, 줄마다 8px 엇갈림) · 가로 줄눈 · 블록 윗테 밝게 · 몸은 바닥보다 어둡게 + 세로 결 · 아래 그림자 띠
-- 위 칸 첫 줄 = 벽 윗면과 만나는 밝은 테. base = 아래 칸(줄 16~31로 이어 셈)
local function brickWall(t, gx0, base, hole)
  seed = 140 + t
  for y = 0, 15 do
    local gy = y + (base and 16 or 0)
    local ry = gy % 8; local row = gy // 8; local off = (row % 2) * 8
    for x = 0, 15 do
      local gx = gx0 + x
      local bx = (gx + off) % 16
      local blk = (gx + off) // 16 + row * 3          -- 블록마다 결 위치를 다르게
      local c
      if gy == 0 then c = C.bh                          -- 윗면과 만나는 밝은 테
      elseif ry == 7 then c = C.mor                     -- 가로 줄눈 (굵게 읽히게 아래 줄과 함께)
      elseif bx == 15 then c = C.mor                    -- 세로 줄눈
      elseif ry == 0 then c = (bx == 0) and C.bs or C.br  -- 블록 윗테
      elseif ry == 6 then c = C.f0                      -- 블록 아랫면 그늘
      elseif (bx + blk * 5) % 6 == 2 and ry >= 2 then c = C.f0                 -- 세로 결 (끊긴 홈)
      elseif (bx + blk * 5) % 6 == 3 and ry >= 2 and rnd() < 0.5 then c = C.f0
      else c = (rnd() < 0.06) and C.f0 or C.bs end      -- 몸: 바닥(f1)보다 어두운 bs
      if base and y >= 12 then                          -- 아래 그림자 띠
        if y >= 14 then c = (y == 15) and VOID or C.mor
        elseif (x + y) % 2 == 0 then c = C.mor end
      end
      local half = hole and hole(y) or -1
      local d = math.abs(gx - 15.5)
      if half > 0 and d < half then c = VOID elseif half > 0 and d < half + 1 then c = (gx < 16) and C.bh or C.bs end
      px(t, x, y, c)
    end
  end
end
local function crack(t) for _, p in ipairs({ {9,4}, {9,5}, {10,6}, {10,7}, {11,8}, {10,9}, {10,10} }) do px(t, p[1], p[2], C.mor) end end
brickWall(20, 0, false); brickWall(21, 0, false); crack(21)
brickWall(22, 0, true);  brickWall(23, 0, true); crack(23)
brickWall(24, 0, true); seed = 77
for x = 0, 15 do local h = 2 + math.floor(rnd() * 5); for y = 15 - h, 15 do if rnd() < 0.8 then px(24, x, y, rnd() < 0.3 and MOSS2 or MOSS1) end end end
local arch = function(y) return ({ [6]=5, [7]=7, [8]=8 })[y] or (y >= 9 and 9 or -1) end
brickWall(25, 0, false, arch); brickWall(26, 16, false, arch)
brickWall(27, 0, true, function() return 9 end); brickWall(28, 16, true, function() return 9 end)

-- ===== 벽 끝 마감 (D-040) — 새 벽면과 같은 질감 =====
-- 54/55 벽면 위 오른 끝/왼 끝, 64/65 벽면 아래 오른 끝/왼 끝: 벽면이 출입구·옆벽에서 끊기는 쪽에 4px 기둥 (밝은 앞테 + 그늘 옆면 + 바깥선)
-- 57/67 한 칸 기둥(위/아래), 58/59 옆벽 끝(왼쪽 벽/오른쪽 벽: 윗면 끝 + 짧은 앞면), 56 문턱(통로 입구 바닥의 돌 문턱)
local function pillarCol(t, x, k, gy, base, y)
  -- k: 0 = 벽과 기둥 사이 홈, 1 = 밝은 앞테, 2 = 앞면, 3 = 그늘 옆면, 4 = 바깥선
  local c = ({ C.mor, C.bh, C.br, C.bs, C.mor })[k + 1]
  if k >= 1 and k <= 3 and gy % 8 == 7 then c = C.mor end            -- 기둥 돌 줄눈 (벽 줄눈과 맞춤)
  if gy == 0 and k <= 3 then c = C.bh end
  if base and y >= 12 and k >= 1 then if y >= 14 then c = (y == 15) and VOID or C.mor elseif (x + y) % 2 == 0 then c = C.mor end end
  px(t, x, y, c)
end
local function wallEnd(t, base, side)
  brickWall(t, 0, base)
  for y = 0, 15 do local gy = y + (base and 16 or 0)
    for k = 0, 4 do local x = (side == "r") and (11 + k) or (4 - k); pillarCol(t, x, k, gy, base, y) end end
end
wallEnd(54, false, "r"); wallEnd(55, false, "l"); wallEnd(64, true, "r"); wallEnd(65, true, "l")
local function pillar(t, base)   -- 한 칸 폭 기둥: 왼쪽 바깥선·밝은 앞테 … 그늘 옆면·바깥선
  for y = 0, 15 do local gy = y + (base and 16 or 0)
    for x = 0, 15 do local k = (x == 0 or x == 15) and 4 or (x == 1) and 1 or (x == 14) and 3 or 2
      if k == 2 and (x + gy * 3) % 7 == 0 and gy % 8 >= 2 and gy % 8 <= 5 then px(t, x, y, C.f0)  -- 세로 결
      else pillarCol(t, x, k, gy, base, y) end end end
end
pillar(57, false); pillar(67, true)
-- 옆벽 끝: 윗면(테 포함) 위 10줄 + 아래 6줄은 짧은 앞면(밝은 테 → 몸 → 그림자). 58 = 왼쪽 벽(오른 테), 59 = 오른쪽 벽(왼 테)
local function sideEnd(t, rim)
  seed = 90 + t
  for y = 0, 15 do for x = 0, 15 do
    local c
    if y <= 9 then
      c = C.f0                                                          -- D-041: 윗면 = 어두운 단색 + 양옆 2px 테 (자동 연결 윗면과 같은 모양)
      if x == 1 or x == 14 or y == 8 then c = C.f3 end
      if x == 0 or x == 15 or y == 9 then c = C.bh end
    elseif y == 10 then c = C.br
    elseif y >= 14 then c = (y == 15) and VOID or C.mor
    else c = ((x + y) % 2 == 0 and y == 13) and C.mor or (x % 8 == 7 and C.mor or C.bs) end
    if x == 0 or x == 15 then if y >= 10 then c = C.mor end end
    px(t, x, y, c)
  end end
end
sideEnd(58, "r"); sideEnd(59, "l")
-- 문턱: 바닥 위쪽 4줄에 판석 문턱 (밝은 윗테 · 줄눈 · 아래 그늘)
floorBase(56, 97)
for x = 0, 15 do px(56, x, 0, C.bh); px(56, x, 1, (x % 8 == 7) and C.mor or C.br); px(56, x, 2, (x % 8 == 7) and C.mor or C.br); px(56, x, 3, C.f0) end

-- ===== 소품 (투명 배경, props 레이어) =====
for i = 0, 2 do for k = 0, 7 do px(30, 4 + i * 3 + k // 2, 3 + k, C.bh); px(30, 5 + i * 3 + k // 2, 3 + k, C.mor) end end
for _, s in ipairs({ {3,9,4,2}, {9,11,3,2}, {6,5,2,2}, {12,6,2,1} }) do
  for y = s[2], s[2] + s[4] - 1 do for x = s[1], s[1] + s[3] - 1 do px(31, x, y, y == s[2] and C.bh or C.br) end end
  for x = s[1], s[1] + s[3] - 1 do px(31, x, s[2] + s[4], C.f0) end
end
px(31, 4, 10, CY); px(31, 10, 12, CY)
for _, s in ipairs({ {2,10,3}, {6,12,2}, {11,9,2}, {9,13,1}, {4,6,1} }) do for x = s[1], s[1] + s[3] - 1 do px(32, x, s[2], C.f3); px(32, x, s[2] + 1, C.f0) end end
local SK = { ".ww.....", "wwww....", "wkwk..w.", ".ws..wws", "....ww..", "...ws...", "..sw...." }
for dy, r in ipairs(SK) do for dx = 1, #r do local ch = r:sub(dx, dx); local c = ch == "k" and C.f0 or BONE[ch]; if c then px(33, 4 + dx, 5 + dy, c) end end end

-- 봉인 문양 2x2, 밝기 단계 0(어두움)/1(중간)/2(밝음) — 맥동 애니메이션
local function sigil(ids, lv)
  local function L(c) if lv == 0 then return c end
    if c == S1 then return lv == 1 and S1 or S2 elseif c == S2 then return lv == 1 and S2 or S3 end; return c end
  for y = 0, 31 do for x = 0, 31 do
    local dx, dy = x - 15.5, (y - 15.5) * 1.15; local d = math.sqrt(dx * dx + dy * dy); local a = math.deg(math.atan(dy, dx)) % 360
    local gap = (a > 20 and a < 38) or (a > 150 and a < 163) or (a > 262 and a < 290)
    if math.abs(d - 13.6) < 0.55 and not gap then big(ids, x, y, L((math.floor(a) % 30 < 4 or (lv >= 1 and math.floor(a) % 15 < 3)) and S2 or S1)) end
    if math.abs(d - 8.6) < 0.5 and math.floor(a / 15) % 2 == 0 and not (a > 200 and a < 240) then big(ids, x, y, L(S1)) end
  end end
  for _, l in ipairs({ {15,4,15,27}, {6,15,25,15} }) do line(ids, l[1], l[2], l[3], l[4], L(S1)) end
  for _, p in ipairs({ {15,15}, {16,16}, {15,16}, {16,15} }) do big(ids, p[1], p[2], lv >= 1 and S3 or S2) end
  for _, p in ipairs({ {15,4}, {25,15}, {6,15}, {15,27}, {9,9}, {22,22} }) do big(ids, p[1], p[2], L(S2)) end
  for _, p in ipairs({ {15,4}, {24,8}, {8,23} }) do big(ids, p[1], p[2], S3) end
end
sigil({ 34, 35, 44, 45 }, 0); sigil({ 50, 51, 60, 61 }, 1); sigil({ 52, 53, 62, 63 }, 2)

-- 쓰러진 수호체 잔해 2x2 (가슴의 꺼져 가는 문양: 48은 빛나는 프레임)
local function debris(ids, glow)
  for y = 0, 31 do for x = 0, 31 do
    local dx, dy = x - 9, (y - 19) * 1.1; local d = math.sqrt(dx * dx + dy * dy)
    if d < 7.5 then local c = C.br; if d > 6.6 then c = C.mor elseif dx + dy < -5 then c = C.bh elseif dx + dy > 5 then c = C.bs end; big(ids, x, y, c) end
  end end
  for x = 5, 13 do big(ids, x, 19, C.mor) end; big(ids, 7, 19, CY); big(ids, 10, 19, CY)
  local tops = { 13, 12, 13, 14, 12, 13, 15, 14, 13, 12, 14, 13 }
  for i, ty in ipairs(tops) do local x = 15 + i
    for y = ty, 27 do local c = C.br; if y == ty then c = C.bh elseif y >= 26 then c = C.bs end; if i == 1 or i == #tops then c = C.mor end; big(ids, x, y, c) end
    big(ids, x, 28, C.mor)
  end
  for _, p in ipairs({ {18,18}, {19,19}, {20,19}, {21,20}, {24,16}, {24,17}, {25,18} }) do big(ids, p[1], p[2], C.mor) end
  big(ids, 22, 21, glow and S3 or CY)
  if glow then for _, p in ipairs({ {21,21}, {23,21}, {22,20}, {22,22} }) do big(ids, p[1], p[2], S2) end end
  for _, s in ipairs({ {3,27,2}, {14,29,3}, {28,27,2}, {1,13,2} }) do for x = s[1], s[1] + s[3] - 1 do big(ids, x, s[2], C.bh); big(ids, x, s[2] + 1, C.mor) end end
  for x = 3, 14 do big(ids, x, 27, C.f0) end
end
debris({ 36, 37, 46, 47 }, false)
debris({ 19, 19, 19, 48 }, true)  -- 빛나는 프레임은 오른아래(48)만 쓴다 (나머지는 빈 19에 그렸다가 지움)
for y = 0, 15 do for x = 0, 15 do px(19, x, y, Color{ r=0, g=0, b=0, a=0 }) end end

-- 봉인등: 벽면 위 칸에 겹침. 수정 밝기 4프레임
local LAMP = { { CY, S2 }, { S2, S3 }, { S2, S2 }, { CY, S3 } }
for f, ab in ipairs(LAMP) do local t = ({ 38, 39, 40, 41 })[f]
  px(t, 6, 12, IRON.o); px(t, 7, 12, IRON.h); px(t, 8, 12, IRON.m); px(t, 9, 12, IRON.o); px(t, 7, 13, IRON.m); px(t, 8, 13, IRON.o)
  local SH = { "..o.", ".oao", ".abo", "oaba", "oaao", ".oo." }
  for dy, r in ipairs(SH) do for dx = 1, 4 do local ch = r:sub(dx, dx)
    local c = ch == "o" and IRON.o or ch == "a" and ab[1] or ch == "b" and ab[2]; if c then px(t, 5 + dx, 5 + dy, c) end end end
end

-- ===== 흔적 (D-034, 행 7~8) — 길찾기용, 모두 투명 배경 겹침 =====
-- 70,71/80,81 긁힌 벽 (벽면 2×2 위에): 큰 손톱 같은 깊은 홈 네 줄
local CLAW = { 70, 71, 80, 81 }
for k = 0, 3 do
  local x0 = 5 + k * 6
  for t = 0, 22 do local x = x0 + t * 0.35 + math.sin(t * 0.4 + k) * 0.6; local y = 4 + t
    big(CLAW, math.floor(x), y, C.mor); big(CLAW, math.floor(x) + 1, y, C.o or H"141018"); big(CLAW, math.floor(x) - 1, y, C.bh) end
end
for _, p in ipairs({ {4,2},{11,3},{16,1},{22,4},{26,27},{9,28} }) do big(CLAW, p[1], p[2], C.bh) end   -- 튄 부스러기
-- 72/82 깨진 비석 (바닥에 선 돌판 16×32, 위가 부러짐)
local STELE = { 72, 72, 82, 82 }
local function st(x, y, c) if x >= 0 and x < 16 then px(y < 16 and 72 or 82, x, y % 16, c) end end
for y = 6, 30 do for x = 3, 12 do
  local top = 6 + ((x * 7) % 5)                     -- 부러진 윗면 (들쭉날쭉)
  if y >= top then local c = C.br
    if x == 3 or x == 12 or y == top then c = H"141018" elseif x == 4 then c = C.bh elseif x == 11 then c = C.bs end
    if y == 30 then c = C.f0 end
    st(x, y, c) end
end end
for _, p in ipairs({ {6,14},{7,14},{8,15},{6,17},{9,17},{7,20},{8,20},{6,23},{9,23} }) do st(p[1], p[2], C.mor) end   -- 닳은 새김 (읽을 수 없음)
for _, p in ipairs({ {1,29},{2,30},{13,30},{14,29},{14,30} }) do st(p[1], p[2], C.bs) end                           -- 부서진 조각
-- 벽화 (벽면 2×2 위에, 바랜 물감): a = 사람들이 큰 빛을 둘러쌈 (73,74/83,84), b = 작은 빛 하나 (75,76/85,86)
local PAINT = { o=H"8a6a3a", r=H"7a4a3a", l=H"c9b48a", w=H"e8dcb8", f=H"5e4e44" }
local function fade(ids, x, y, c, k) if (x * 3 + y * 5 + (k or 0)) % 7 ~= 0 then big(ids, x, y, c) end end   -- 군데군데 벗겨짐
local MA = { 73, 74, 83, 84 }
for y = 0, 31 do for x = 0, 31 do local d = math.sqrt((x - 16) ^ 2 + (y - 12) ^ 2)
  if d < 5 then fade(MA, x, y, d < 2.5 and PAINT.w or PAINT.l) elseif d < 7 and (x + y) % 2 == 0 then fade(MA, x, y, PAINT.o, 1) end end end
for k = 0, 6 do local a = math.pi * (0.15 + k * 0.7 / 6) ; local fx, fy = 16 + math.cos(a) * 12, 12 + math.sin(a) * 9 + 4   -- 둘러선 사람들 (작은 막대 형상)
  fade(MA, math.floor(fx), math.floor(fy), PAINT.r); fade(MA, math.floor(fx), math.floor(fy) + 1, PAINT.f); fade(MA, math.floor(fx), math.floor(fy) + 2, PAINT.f)
  fade(MA, math.floor(fx) - 1, math.floor(fy) + 1, PAINT.f, 2); fade(MA, math.floor(fx) + 1, math.floor(fy) + 1, PAINT.f, 3) end
for x = 3, 28 do fade(MA, x, 27, PAINT.f, 4) end
local MB = { 75, 76, 85, 86 }
local LIGHT = { "...l...", "..l.l..", ".l.w.l.", "l.wWw.l", ".l.w.l.", "..l.l..", "...l..." }   -- 작은 빛: 봉인 문양 같은 마름모
for dy, r in ipairs(LIGHT) do for dx = 1, #r do local ch = r:sub(dx, dx); local c = ch == "l" and PAINT.l or ch == "w" and PAINT.w or ch == "W" and H"fff1c8"
  if c then fade(MB, 12 + dx, 8 + dy, c) end end end
for k = 0, 9 do local a = k * 0.63; fade(MB, math.floor(16 + math.cos(a) * 10), math.floor(12 + math.sin(a) * 8), PAINT.o, k) end
for x = 6, 26 do fade(MB, x, 27, PAINT.f, 5) end

-- ===== 벽 윗면 자동 연결 (D-041, 행 9~13: 90~136) =====
-- 윗면 안쪽 = 어두운 단색(f0, 이음새 없음), 이웃이 윗면이 아닌 쪽에 2px 테(바깥 bh · 안쪽 f3)가 끊김 없이 돎.
-- 바깥 모서리는 1px 깎고, 안쪽 모서리(두 옆은 윗면인데 대각선만 아닐 때)는 테가 L자로 꺾여 이어짐.
-- 47칸 blob: 8방향 비트 N1 NE2 E4 SE8 S16 SW32 W64 NW128, 대각선 비트는 양옆 직교 비트가 둘 다 있을 때만 셈.
-- 줄인 값들을 오름차순으로 늘어놓은 순서 = 타일 90 + k (표는 tileset.json "autotile.walltop")
local BLOB = {}
do local seen = {}
  for m = 0, 255 do
    local r = m
    if (m & 1) == 0 or (m & 4) == 0 then r = r & ~2 end
    if (m & 4) == 0 or (m & 16) == 0 then r = r & ~8 end
    if (m & 16) == 0 or (m & 64) == 0 then r = r & ~32 end
    if (m & 64) == 0 or (m & 1) == 0 then r = r & ~128 end
    if not seen[r] then seen[r] = true; BLOB[#BLOB+1] = r end
  end
  table.sort(BLOB)
end
assert(#BLOB == 47, "blob " .. #BLOB)
for k, m in ipairs(BLOB) do
  local t = 89 + k
  local N, E, S, W = (m & 1) ~= 0, (m & 4) ~= 0, (m & 16) ~= 0, (m & 64) ~= 0
  for y = 0, 15 do for x = 0, 15 do
    local c = C.f0
    local inner = (not N and y == 1) or (not S and y == 14) or (not W and x == 1) or (not E and x == 14)
    local outer = (not N and y == 0) or (not S and y == 15) or (not W and x == 0) or (not E and x == 15)
    if inner then c = C.f3 end
    if outer then c = C.bh end
    -- 바깥 모서리 1px 깎기
    if (not N and not W and x == 0 and y == 0) or (not N and not E and x == 15 and y == 0)
      or (not S and not W and x == 0 and y == 15) or (not S and not E and x == 15 and y == 15) then c = C.mor end
    px(t, x, y, c)
  end end
  -- 안쪽 모서리: 테가 꺾여 들어오는 2×2
  local function notch(cx, cy, dx, dy) px(t, cx, cy, C.bh); px(t, cx + dx, cy, C.bh); px(t, cx, cy + dy, C.bh); px(t, cx + dx, cy + dy, C.f3) end
  if N and E and (m & 2) == 0 then notch(15, 0, -1, 1) end
  if S and E and (m & 8) == 0 then notch(15, 15, -1, -1) end
  if S and W and (m & 32) == 0 then notch(0, 15, 1, -1) end
  if N and W and (m & 128) == 0 then notch(0, 0, 1, 1) end
end

local spr = Sprite(COLS * 16, ROWS * 16, ColorMode.RGB)
spr.layers[1].name = "tiles"
spr.cels[1].image = img
spr.gridBounds = Rectangle(0, 0, 16, 16)
spr:saveAs(app.params.out)
