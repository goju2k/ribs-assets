-- 패링 방어막 fx-parry-shield (D-083, 사용자 선택: B 구슬막). 우클릭(패링 시전) 때마다 몸을 감싸는 막. 성공 여부와 관계없이 나옴.
-- 실행: aseprite -b --script-param out=<경로>/fx-parry-shield.aseprite --script parry-build.lua
-- 40×40, 기준점 [20,20] = 몸 중심. 반지름 12(combat.json parry.radiusPx). 색: 방어 계열 흰 → 연청 → 청록(D-012). 반투명 없음(옅은 막 = 디더).
--   open    66ms: 입력 즉시 펼쳐짐 (첫 장 parry:on)
--   hold    반복(45ms × 3): 판정 창이 끝날 때까지 돌림. 기본 200ms = open 66 + hold 134 (시동 2f + 판정 10f). 창 길이가 바뀌어도 맥동 속도는 그대로
--   fizzle  헛방 280ms ≈ whiffRecoveryF 17: 막이 끊어져 흩어짐
--   pop     성공 150ms: 막이 바깥으로 퍼지며 가늘어져, 안쪽 패링 섬광(player-child parry 고리)과 겹쳐도 읽힘
-- 반지름이 조금 바뀌면 엔진이 최근접 확대, 많이 바뀌면 다시 뽑음. 시안 비교는 scratch/parry-lab(커밋 안 함).
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local S = { W=H"ffffff", c=H"cbdbfc", C=H"5fcde4", B=H"306082" }
local FW, FH, CX, CY = 40, 40, 20, 20
local TAU = 2 * math.pi
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local function ring(i, r, col)
  local n = math.ceil(TAU * r * 1.5)
  for k = 0, n - 1 do local u = k / n; px(i, CX + math.cos(u * TAU) * r, CY + math.sin(u * TAU) * r, col(u)) end
end
-- 구슬막: 옅은 디더 막(4칸에 1점, 가운데는 비움) + 고리 + 왼쪽 위 빛
local function shell(i, r, k)
  for y = -r, r do for x = -r, r do local d = math.sqrt(x * x + y * y)
    if d < r - 1 and d > 5 and (x + y * 2 + k) % 4 == 0 then px(i, CX + x, CY + y, d > r - 4 and S.C or S.B) end end end
  ring(i, r, function() return S.C end)
  ring(i, r, function(u) return (u > 0.55 and u < 0.8) and S.W or ((u > 0.48 and u < 0.88) and S.c or nil) end)
  px(i, CX + r * 0.5, CY + r * 0.55, S.c)
end
local CL = {
  { "open", false, "parry:on", { { 33, function(i) shell(i, 9, 0) end }, { 33, function(i) shell(i, 12, 1) end } } },
  { "hold", true, nil, { { 45, function(i) shell(i, 12, 2) end }, { 45, function(i) shell(i, 12, 3) end }, { 45, function(i) shell(i, 12, 0) end } } },
  { "fizzle", false, "parry:fizzle", {
    { 70, function(i) ring(i, 12, function(u) return (u * 10) % 2 < 1.3 and S.C or nil end); for y = -9, 9, 3 do for x = -9, 9, 3 do if x * x + y * y < 90 and x * x + y * y > 25 then px(i, CX + x, CY + y, S.B) end end end end },
    { 70, function(i) ring(i, 12, function(u) return (u * 10) % 2 < 0.8 and S.C or nil end); ring(i, 8, function(u) return (u * 8) % 2 < 0.4 and S.B or nil end) end },
    { 70, function(i) ring(i, 13, function(u) return (u * 10) % 2 < 0.4 and S.B or nil end) end },
    { 70, function(i) ring(i, 14, function(u) return (u * 20) % 4 < 0.3 and S.B or nil end) end },
  } },
  { "pop", false, "parry:pop", {
    { 40, function(i) ring(i, 14, function() return S.W end); ring(i, 15, function(u) return (u * 16) % 2 < 1 and S.c or nil end) end },
    { 50, function(i) ring(i, 16, function(u) return (u * 16) % 2 < 1.3 and S.c or nil end) end },
    { 60, function(i) ring(i, 18, function(u) return (u * 16) % 2 < 0.6 and S.C or nil end) end },
  } },
}
local total = 0; for _, c in ipairs(CL) do total = total + #c[4] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "fx-parry-shield"
for k = 2, total do spr:newEmptyFrame() end
local n = 0
for _, c in ipairs(CL) do
  local from = n + 1
  for idx, f in ipairs(c[4]) do
    n = n + 1
    local img = Image(FW, FH, ColorMode.RGB); f[2](img)
    local cel = spr:newCel(spr.layers[1], n, img)
    if idx == 1 and c[3] then cel.data = c[3] end
    spr.frames[n].duration = f[1] / 1000
  end
  local tag = spr:newTag(from, n); tag.name = c[1]; if c[2] then tag.data = "loop" end
end
spr.data = "facing=right;anchor=20,20"
spr:saveAs(app.params.out)
