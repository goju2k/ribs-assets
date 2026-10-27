-- 공유 미리보기·탭 아이콘 (D-050). 반전 원칙: 주인공 정체를 암시하는 것(사신·어두운 실루엣) 없음 — 불씨·봉인탑·제목만.
-- 실행: aseprite -b --script-param which=og|icon --script-param out=<png> [--script-param size=<픽셀>] --script og-build.lua
--   og    400×210 바탕(픽셀). title-bg(480×270)의 가운데를 잘라 쓰고, 가운데 푸른 불씨 + 별 입자 + "센티넬" 픽셀 로고(로고 픽셀 1칸 = 3×3)
--         → scripts/og.mjs가 정수 3배(1200×630)로 키우고 불씨 빛 번짐만 부드럽게 얹음. 핵심은 가운데 630×630(바탕 기준 x 95~305) 안
--   icon  size×size: 어두운 바탕(#0b0910)에 푸른 불씨만 또렷하게 (작은 크기에서도 형태가 읽히게 테두리 1px 어둡게)
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local E = { W=H"ffffff", y=H"bfeaff", r=H"6fb8f2", d=H"2f4a66" }
local VOID = H"0b0910"
local WHICH, OUT = app.params.which, app.params.out

local function ember(img, cx, cy, r)
  for y = -r - 1, r + 1 do for x = -r - 1, r + 1 do
    local d = math.sqrt(x * x + y * y)
    local c = d <= r * 0.42 and E.W or d <= r * 0.75 and E.y or d <= r + 0.3 and E.r or nil
    if c then img:drawPixel(cx + x, cy + y, c) end
  end end
end

if WHICH == "og" then
  local W, Hh = 400, 210
  local bg = Image{ fromFile = app.params.root .. "/export/title-bg/title-bg.png" }
  local img = Image(W, Hh, ColorMode.RGB)
  for y = 0, Hh - 1 do for x = 0, W - 1 do img:drawPixel(x, y, bg:getPixel(x + 40, y + 40)) end end   -- 첫 프레임의 가운데 (밑쪽 바닥 덜 보이게 조금 위로)
  -- 별 입자 (불씨 둘레에 드문드문)
  local seed = 17
  local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
  for k = 1, 22 do
    local x, y = 110 + math.floor(rnd() * 180), 20 + math.floor(rnd() * 120)
    if math.abs(x - 200) > 14 or math.abs(y - 83) > 14 then
      img:drawPixel(x, y, k % 4 == 0 and E.W or E.y)
      if k % 5 == 0 then img:drawPixel(x - 1, y, E.r); img:drawPixel(x + 1, y, E.r); img:drawPixel(x, y - 1, E.r); img:drawPixel(x, y + 1, E.r) end
    end
  end
  ember(img, 200, 83, 6)
  img:drawPixel(201, 74, E.y); img:drawPixel(199, 72, E.r)        -- 위로 오르는 작은 불티
  -- "센티넬" 픽셀 로고: 글자 16×15칸, 획 2칸. 로고 1칸 = 바탕 3×3 → 최종 9px
  local G = {
    { "...##.....##.##.", "...##.....##.##.", "..####....##.##.", ".##..##.####.##.", "##....##..##.##.", "#......#..##.##.", "..........##.##.", "..........##.##.",
      "................", "..##............", "..##............", "..##............", "..############..", "..############..", "................" },
    { "............##..", "............##..", "#########...##..", "#########...##..", "##..........##..", "########....##..", "########....##..", "##..........##..",
      "##..........##..", "#########...##..", "#########...##..", "............##..", "............##..", "............##..", "................" },
    { "##........##.##.", "##........##.##.", "##.......###.##.", "##........##.##.", "########..##.##.", "########..##.##.", "..........##.##.", "................",
      "..###########...", "...........##...", "..###########...", "..##............", "..###########....", "................", "................" },
  }
  local LW, GAP, S = 16, 3, 3
  local total = (#G * LW + (#G - 1) * GAP) * S
  local ox, oy = math.floor((W - total) / 2), 110
  local OL = H"0b0910"
  for g, rows in ipairs(G) do
    local gx = ox + (g - 1) * (LW + GAP) * S
    local on = function(x, y) return y >= 0 and y < #rows and x >= 0 and x < #rows[y + 1] and rows[y + 1]:sub(x + 1, x + 1) == "#" end
    for y = -1, #rows do for x = -1, LW do
      local fill = on(x, y)
      local edge = not fill and (on(x - 1, y) or on(x + 1, y) or on(x, y - 1) or on(x, y + 1))
      if fill or edge then
        local c = edge and OL or (y <= 1 and E.W or (y >= 11 and E.r or E.y))   -- 위 흰빛 → 가운데 하늘 → 아래 푸른 (불씨 색)
        for dy = 0, S - 1 do for dx = 0, S - 1 do img:drawPixel(gx + x * S + dx, oy + y * S + dy, c) end end
      end
    end end
  end
  local spr = Sprite(W, Hh, ColorMode.RGB); spr.cels[1].image = img
  spr:saveCopyAs(OUT)

elseif WHICH == "icon" then
  local N = tonumber(app.params.size)
  local img = Image(N, N, ColorMode.RGB)
  for y = 0, N - 1 do for x = 0, N - 1 do img:drawPixel(x, y, VOID) end end
  local c = N // 2
  local r = math.max(4, math.floor(N * 0.3))
  -- 바깥 1px 어두운 푸른 테 → 작은 크기에서도 동그라미가 바탕과 갈림
  for y = -r - 1, r + 1 do for x = -r - 1, r + 1 do local d = math.sqrt(x * x + y * y)
    if d <= r + 1.2 and d > r + 0.3 then img:drawPixel(c + x - (N % 2 == 0 and 1 or 0) + 1, c + y, E.d) end end end
  ember(img, c, c, r)
  if N >= 16 then img:drawPixel(c + 1, c - r - 2, E.y) end            -- 불티 하나
  local spr = Sprite(N, N, ColorMode.RGB); spr.cels[1].image = img
  spr:saveCopyAs(OUT)
end
