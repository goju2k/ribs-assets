-- player-ember.aseprite 생성 (D-039): 불씨 모습(Act 1) 대기 동작.
-- 실행: aseprite -b --script-param out=<경로>/player-ember.aseprite --script build.lua
-- 프레임 48×24, 기준점 [24,24] = player-child와 같은 그림자 자리 (엔진이 어린이 대시 프레임을 임시로 쓰던 자리 그대로 바꿔 끼울 수 있게).
-- 불씨 가운데 (24,15): 그림자 위 9px에 뜸. 색 = 스타일 가이드 1-1b (#ffffff / #bfeaff / #6fb8f2).
-- dash: 출발 83 → 이동 167 → 회복 100ms (D-044, 회복 2장)
-- idle: 심장박동처럼 "쿵-쿵" 두 박 + 쉼, 한 주기 1200ms. 아주 미세하게 — 흰 속만 1점 → 십자 → 3×3으로 커졌다 돌아옴, 몸 크기는 그대로.
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local E = { W=H"ffffff", y=H"bfeaff", r=H"6fb8f2" }
local FW, FH, CX, CY = 48, 24, 24, 15
local function px(i, x, y, c) if x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
-- beat 0 = 쉼(흰 속 1점) / 1 = 약(십자) / 2 = 강(3×3)
local function ember(i, beat, spark)
  for y = -3, 3 do for x = -3, 3 do local d = math.sqrt(x * x + y * y)
    if d <= 3.3 then px(i, CX + x, CY + y, d <= 1.6 and E.y or E.r) end end end
  px(i, CX, CY, E.W)
  if beat >= 1 then px(i, CX - 1, CY, E.W); px(i, CX + 1, CY, E.W); px(i, CX, CY - 1, E.W); px(i, CX, CY + 1, E.W) end
  if beat == 2 then px(i, CX - 1, CY - 1, E.W); px(i, CX + 1, CY - 1, E.W); px(i, CX - 1, CY + 1, E.W); px(i, CX + 1, CY + 1, E.W) end
  if spark then px(i, CX + spark[1], CY + spark[2], E.y) end
end
-- 쿵(강, 3×3) 90 → 풀림 100 → 쿵(약, 십자) 90 → 풀림 120 → 쉼 800 = 1200ms. 쉼 동안 작은 불티 하나가 위로
local FR = {
  { 90, 2 }, { 100, 0 }, { 90, 1 }, { 120, 0 },
  { 270, 0, { 1, -5 } }, { 270, 0, { 1, -6 } }, { 260, 0 },
}
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "ember"
for k = 2, #FR do spr:newEmptyFrame() end
for k, f in ipairs(FR) do
  local img = Image(FW, FH, ColorMode.RGB); ember(img, f[2], f[3])
  local cel = spr:newCel(spr.layers[1], k, img)
  if k == 1 then cel.data = "idle:beat" end
  spr.frames[k].duration = f[1] / 1000
end
local tag = spr:newTag(1, #FR); tag.name = "idle"; tag.data = "loop"
-- dash (D-044): 출발 83ms(2장) → 이동 167ms(3장, 꼬리) → 회복 100ms(2장, 바로 대기 모습). 오른쪽으로 감 → 꼬리는 왼쪽
local function core(i, r, pal) for y = -r, r do for x = -r, r do local d = math.sqrt(x * x + y * y)
  if d <= r + 0.3 then px(i, CX + x, CY + y, d < r * 0.45 and (pal or E).W or d < r * 0.8 and (pal or E).y or (pal or E).r) end end end end
local function tail(i, len) for k = 1, len do local c = (k < 3) and E.W or (k < 6) and E.y or E.r
  if k % 3 ~= 0 or k < 4 then px(i, CX - 2 - k, CY + ((k > 4 and k % 2 == 1) and 1 or 0), c) end end end
local DASH = {
  { 42, "dash:charge", function(i) core(i, 2) ; px(i, CX, CY - 4, E.y) end },
  { 41, nil, function(i) core(i, 3); px(i, CX - 4, CY, E.r); px(i, CX - 3, CY - 3, E.y) end },
  { 56, "dash:travel", function(i) tail(i, 10); core(i, 2) end },
  { 56, nil, function(i) tail(i, 16); core(i, 2) end },
  { 55, nil, function(i) tail(i, 12); core(i, 2) end },
  { 50, "dash:recover", function(i) tail(i, 3); core(i, 3); px(i, CX + 3, CY - 4, E.y); px(i, CX - 4, CY + 3, E.r) end },
  { 50, nil, function(i) ember(i, 0) end },
}
local base = #FR
for k = 1, #DASH do spr:newEmptyFrame() end
for k, f in ipairs(DASH) do
  local img = Image(FW, FH, ColorMode.RGB); f[3](img)
  local cel = spr:newCel(spr.layers[1], base + k, img)
  if f[2] then cel.data = f[2] end
  spr.frames[base + k].duration = f[1] / 1000
end
local dt = spr:newTag(base + 1, base + #DASH); dt.name = "dash"
spr.data = "facing=right;anchor=24,24"
spr:saveAs(app.params.out)
