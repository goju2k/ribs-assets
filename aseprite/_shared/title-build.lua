-- 타이틀 배경 (Demo 0, 계획서 4절): 어둠 + 멀리 봉인등 몇 개. 아트 최소, 빛이 분위기.
-- 봉인탑 안 수직 공간을 아래에서 올려다봄: 양쪽 벽이 위로 갈수록 좁아지고 어둠에 묻힘, 층마다 턱(난간)과 봉인등.
-- 가운데는 비워 둠 (불씨·제목·메뉴 자리). 화면 480×270 (카메라 4배 기준 1920×1080). 봉인등 깜빡임 4프레임 반복.
-- 실행: aseprite -b --script-param out=<경로>.aseprite --script title-build.lua
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local W, Hh = 480, 270
local K = { void=H"0b0910", d1=H"110e16", d2=H"16121c", d3=H"1c1822", d4=H"241e2c", e=H"2e2838" }
local S = { W=H"cbdbfc", C=H"5fcde4", B=H"306082", b=H"2f4a66", h1=H"141c2a", h2=H"18243a" }
local seed = 5
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
local function px(i, x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < W and y < Hh then i:drawPixel(x, y, c) end end

-- 원근: 화면 아래(가까움) 벽 사이 폭이 넓고, 위(멂)로 갈수록 좁아짐. 소실점 (240, -120)
local VX, VY = 240, -140
local function wallX(y, side) local t = (y - VY) / (Hh - VY); return VX + side * (46 + 150 * t) end -- 벽 안쪽 가장자리
local LEDGES = { 248, 178, 124, 86, 60, 43 }    -- 아래(가까움) → 위(멂)
local LAMPS = {                                 -- {턱 번호, 왼(-1)/오른(1), 벽에서 안쪽 거리 비율}
  { 1, -1 }, { 1, 1 }, { 2, -1 }, { 3, 1 }, { 4, -1 }, { 5, 1 }, { 6, -1 },
}

local function scene(i, f)
  i:clear(K.void)
  -- 벽: 가장자리부터 바깥쪽으로 어둡게 (먼 위쪽일수록 더 어둡게), 성긴 벽돌 줄눈
  for y = 0, Hh - 1 do
    local depth = (y - VY) / (Hh - VY)         -- 0(멂)~1(가까움)
    for side = -1, 1, 2 do
      local edge = wallX(y, side)
      for k = 0, 140 do
        local x = edge + side * k
        local shade = depth > 0.75 and K.d4 or depth > 0.55 and K.d3 or depth > 0.4 and K.d2 or K.d1
        if k < 2 then shade = depth > 0.6 and K.e or K.d4 end   -- 벽 모서리 테
        local brick = ((math.floor(y / 6) % 2 == 0) and (math.floor(k / 9) * 9 == k)) or (y % 6 == 0)
        if brick and k >= 2 then shade = K.d1 end
        if depth < 0.35 and (x + y) % 2 == 0 then shade = K.void end   -- 먼 곳은 디더로 어둠에 녹임
        px(i, x, y, shade)
      end
    end
  end
  -- 층 턱 (벽에서 안쪽으로 살짝 나온 난간 줄)
  for n, ly in ipairs(LEDGES) do
    local depth = (ly - VY) / (Hh - VY); local len = math.floor(6 + 26 * depth)
    for side = -1, 1, 2 do local edge = wallX(ly, side)
      for k = 0, len do px(i, edge - side * k, ly, depth > 0.5 and K.e or K.d4); px(i, edge - side * k, ly + 1, K.d1) end end
  end
  -- 봉인등: 가까울수록 크고 밝음, 계단식 테두리 빛 (불투명 픽셀 디더)
  for n, L in ipairs(LAMPS) do
    local ly = LEDGES[L[1]]; local depth = (ly - VY) / (Hh - VY)
    local x = wallX(ly, L[2]) - L[2] * (4 + 10 * depth); local y = ly - 2 - math.floor(6 * depth)
    local flick = ((f + n) % 4 == 0) and 1 or 0
    local r = math.floor(4 + 22 * depth) + flick
    for dy = -r, r do for dx = -r, r do local d = math.sqrt(dx * dx + (dy / 0.75) ^ 2) / r
      if d < 1 and (dx + dy) % 2 == 0 then px(i, x + dx, y + dy, d < 0.5 and S.h2 or S.h1) end end end
    if depth > 0.45 then
      px(i, x, y - 2, S.b); px(i, x - 1, y - 1, S.B); px(i, x, y - 1, flick == 1 and S.W or S.C); px(i, x + 1, y - 1, S.B)
      px(i, x - 1, y, S.C); px(i, x, y, S.W); px(i, x + 1, y, S.C); px(i, x, y + 1, S.B); px(i, x, y + 2, K.d1)
    else
      px(i, x, y, flick == 1 and S.C or S.B); if depth > 0.3 then px(i, x, y - 1, S.b) end
    end
  end
  -- 떠다니는 별가루 몇 점 (프레임마다 조금 위로)
  seed = 77
  for k = 1, 18 do local x = 150 + rnd() * 180; local y = 40 + rnd() * 200 - f * 2; local bright = rnd() < 0.25
    px(i, x, y, bright and S.C or S.b) end
end

local spr = Sprite(W, Hh, ColorMode.RGB)
spr.layers[1].name = "bg"
for k = 2, 4 do spr:newEmptyFrame() end
for f = 1, 4 do local img = Image(W, Hh, ColorMode.RGB); scene(img, f - 1); spr:newCel(spr.layers[1], f, img); spr.frames[f].duration = 0.25 end
local tag = spr:newTag(1, 4); tag.name = "idle"; tag.data = "loop"
spr.data = "facing=right;anchor=240,135"
spr:saveAs(app.params.out)
