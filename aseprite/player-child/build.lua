-- player-child.aseprite 생성 (이슈 #3). 모션 실험실에서 확정한 시안을 계약 형식(48x24 공통 프레임)으로.
-- 실행: aseprite -b --script-param out=<경로>/player-child.aseprite --script build.lua
-- 원본은 왼쪽을 봄 → sprite.data "facing=left" (내보낼 때 오른쪽으로 반전). anchor = 그림자 자리.
-- 태그(clip): float(loop) / dash / parry. 프레임 신호는 그 프레임 셀의 User Data에 쉼표로.
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local P = { K=H"0e0507", D=H"2e0a0d", M=H"4a1013", T=H"7a2018",
  r=H"ac3232", y=H"df7126", Y=H"fbf236", c=H"cbdbfc", C=H"5fcde4", B=H"306082", s=H"8f563b", W=H"ffffff" }
-- 손불꽃 불빛을 받는 곳(후드 얼굴 쪽 L, 몸 왼쪽 R, 손 h)의 밝기 3단계 — 빨강 안에서 한 톤씩
local GLOW = {
  { L=H"6e1c17", R=H"9a2b2a", h=H"5a1416" },
  { L=H"7a2018", R=H"ac3232", h=H"641816" },
  { L=H"862318", R=H"b8382f", h=H"6e1c17" },
}
local BODY = {
"..................",
"......KKKKK.......",
".....KMTTMDK..KK..",
"....KMLMMMMK.KcK..",
"....KLKKKMMMKCCK..",
"....KLKKKKMMKBK...",
"....KMKKKKMDKsK...",
".....KMKKDDDKsK...",
".....KDMDDDDKKK...",
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
local FLAME = {
 { "....", "..y.", ".rr.", "yry.", ".yYr", ".yyy" },
 { "..y.", ".ry.", "ryr.", "yYy.", ".yYr", "..y." },
 { "....", ".r..", ".yr.", "ryy.", "yYYr", ".yy." },
}
local FW, FH = 48, 24
local OX, OY = 15, 4          -- 18x18 몸의 왼쪽 위
local ANCHOR = { 24, 24 }     -- 그림자 자리 (몸 가운데, 밑단 아래)

local function px(img, x, y, c) if x >= 0 and y >= 0 and x < FW and y < FH then img:drawPixel(x, y, c) end end
-- o: dx, dy, lean(위쪽 몇 줄 앞으로), flame(0~3), glow(1~3), skip(행 거르기), color(단색/디더), fdx/fdy(손불꽃 위치), reach(손 내밀기 px)
local function body(img, o)
  o = o or {}
  local g = GLOW[o.glow or 2]
  local dx, dy = o.dx or 0, o.dy or 0
  local function put(x, y, c) px(img, x + OX + dx, y + OY + dy, c) end
  for y, r in ipairs(BODY) do
    local sh = (o.lean and y - 1 < o.lean) and -1 or 0
    if not (o.skip and o.skip(y - 1)) then
      for x = 1, #r do local ch = r:sub(x, x); local c = g[ch] or P[ch]
        if c then if o.color then c = o.color(x - 1, y - 1, ch) end; if c then put(x - 1 + sh, y - 1, c) end end end
    end
  end
  local fl = o.flame == nil and 1 or o.flame
  for k = 1, (o.reach or 0) do put(3 - k, 11, k == o.reach and g.h or g.R) end -- 손을 앞(왼쪽)으로 내밂
  if fl > 0 then for fy, r in ipairs(FLAME[fl]) do for x = 1, 4 do local c = P[r:sub(x, x)]; if c then put(x - 1 + (o.fdx or 0), 7 + fy + (o.fdy or 0), c) end end end end
end
local function ring(img, cx, cy, r, c, gaps)
  for a = 0, 359, 6 do if not (gaps and gaps(a)) then local t = math.rad(a); px(img, math.floor(cx + math.cos(t) * r + 0.5), math.floor(cy + math.sin(t) * r * 0.9 + 0.5), c) end end
end
local function silhouette(col) return function() return col end end
local function dither(col) return function(x, y) if (x + y) % 2 == 0 then return col end end end
-- 대시 중 불씨 = 불씨 모습 색 (D-015, 비교 시안 ① 하늘색→흰색). 손불꽃(FLAME)은 붉은색 그대로
local E = { Y=H"ffffff", y=H"bfeaff", r=H"6fb8f2" }
local function ember(i, cx, cy, tail)
  for k = 1, tail do local c = (k < 3) and E.Y or (k < 6) and E.y or E.r
    if k % 3 ~= 0 or k < 4 then px(i, cx + k, cy + ((k > 4 and k % 2 == 1) and 1 or 0), c) end end
  for _, d in ipairs({ {0,0,"Y"}, {-1,0,"y"}, {0,-1,"y"}, {0,1,"y"}, {1,0,"Y"}, {-1,-1,"r"}, {-1,1,"r"}, {-2,0,"r"} }) do px(i, cx + d[1], cy + d[2], E[d[3]]) end
end
local function core(i, cx, cy, r, k)
  for y = -r, r do for x = -r, r do local d = math.sqrt(x * x + y * y)
    if d <= r + 0.3 then px(i, cx + x, cy + y, d < r * 0.45 and E.Y or d < r * 0.8 and E.y or E.r) end end end
  if k % 2 == 0 then px(i, cx, cy - r - 1, E.y) else px(i, cx - 1, cy - r - 2, E.r) end
end

-- clip 정의: { 이름, loop, { {ms, "태그,태그" 또는 nil, 그리기} ... } }
local CLIPS = {}
-- float: 6프레임 110ms. 1px 상하, 밑단 고정, 손불꽃 3모양, 불빛 밝기 순서, 위로 튀는 불씨
local LIFT = { 0, 0, 1, 1, 1, 0 }
local LIGHT = { 2, 3, 1, 1, 3, 2 }
local SPARK = { {2,6,"y"}, {2,4,"r"}, {3,2,"r"}, false, {1,6,"y"}, {1,4,"r"} }
local F = {}
for i = 1, 6 do
  F[i] = { 110, nil, function(img)
    body(img, { dy = -LIFT[i], flame = (i - 1) % 3 + 1, glow = LIGHT[i] })
    local s = SPARK[i]; if s then px(img, OX + s[1], OY + s[2] - LIFT[i], P[s[3]]) end
  end }
end
CLIPS[#CLIPS+1] = { "float", true, F }
-- dash (D-021, 회복은 D-044로 100ms): 출발 멈춤 없음 — 누르는 즉시 흩어지며 튀어 나감. charge 83ms / travel 167ms(48px) / recover 233ms (전체 483ms)
-- recover가 어린이 폼의 무게: 불씨가 크게 퍼졌다가 몸이 아래부터 차오르고, 마지막에 1px 내려앉음
local function dots(i, list) for _, d in ipairs(list) do px(i, OX + d[1], OY + d[2], E[d[3]]) end end
CLIPS[#CLIPS+1] = { "dash", false, {
  { 42, "dash:charge", function(i) body(i, { skip = function(y) return y > 9 end, flame = 2 }); body(i, { skip = function(y) return y <= 9 end, color = dither(P.D), flame = 0 }); core(i, OX + 2, OY + 11, 2, 0) end },
  { 41, nil, function(i) body(i, { skip = function(y) return y > 5 end, color = dither(P.D), flame = 0 }); core(i, OX + 6, OY + 11, 3, 1); dots(i, { {11,7,"y"}, {12,13,"r"}, {3,6,"r"} }) end },
  { 56, "dash:travel", function(i) ember(i, OX + 6, OY + 11, 10); for y = 6, 12 do for x = 13, 15 do if (x + y) % 2 == 0 and (x * 7 + y * 3) % 5 ~= 0 then px(i, OX + x, OY + y, P.D) end end end end },
  { 56, nil, function(i) ember(i, OX + 6, OY + 10, 16) end },
  { 55, nil, function(i) ember(i, OX + 6, OY + 10, 13) end },
  -- D-044: 회복 2장 100ms — 털썩 내려앉음 없이 불씨가 몸으로 빠르게 모이고 바로 float 자세
  { 50, "dash:recover", function(i) body(i, { skip = function(y) return y < 8 end, color = dither(P.M), flame = 0 }); core(i, OX + 7, OY + 9, 3, 0); dots(i, { {7,4,"y"}, {12,8,"y"}, {2,11,"r"} }) end },
  { 50, nil, function(i) body(i, { flame = 2 }) end },
} }
-- parry: 패링 A (섬광 고리, 방어 계열 색), 1~2px 뒤로 밀림
CLIPS[#CLIPS+1] = { "parry", false, {
  { 60, "parry:flash", function(i) body(i, { dx = 1, flame = 2 }); ring(i, OX + 1, OY + 10, 4, P.W); px(i, OX + 1, OY + 10, P.W) end },
  { 60, nil, function(i) body(i, { dx = 2, flame = 3 }); ring(i, OX + 1, OY + 10, 7, P.c, function(a) return a % 36 < 12 end); ring(i, OX + 1, OY + 10, 3, P.W) end },
  { 80, nil, function(i) body(i, { dx = 2, flame = 1 }); ring(i, OX + 1, OY + 10, 9, P.C, function(a) return a % 48 < 30 end) end },
  { 120, nil, function(i) body(i, { dx = 1, flame = 2 }) end },
  { 160, nil, function(i) body(i, { flame = 1 }) end },
} }

-- fire (D-025): 준비 33ms → fire:release(투사체 생성) → 마무리 67ms. 몸 높이·밑단은 float 기본 자세 그대로 (연사로 반복돼도 튀지 않게)
CLIPS[#CLIPS+1] = { "fire", false, {
  { 33, nil, function(i) body(i, { flame = 3, glow = 3, fdx = 1 }) end },                                  -- 준비: 손불꽃을 살짝 당기며 밝아짐
  { 33, "fire:release", function(i) body(i, { lean = 6, flame = 1, glow = 3, fdx = -2, reach = 2 }) end }, -- 발사: 손을 앞으로 내밂, 불꽃이 손 끝에
  { 34, nil, function(i) body(i, { flame = 2, glow = 2, fdx = -1, reach = 1 }) end },                      -- 마무리: 돌아옴
} }

-- dash-quick (D-031 "전환"): 마무리 직후 자동 짧은 대시 24px. 출발 멈춤 없이 움직이면서 흩어지고 짧게 모임 (250ms)
CLIPS[#CLIPS+1] = { "dash-quick", false, {
  { 40, "dash:travel", function(i) body(i, { skip = function(y) return y > 7 end, color = dither(P.D), flame = 0 }); ember(i, OX + 6, OY + 11, 6) end },
  { 50, nil, function(i) ember(i, OX + 6, OY + 10, 10) end },
  { 50, "dash:recover", function(i) body(i, { skip = function(y) return y < 8 end, color = dither(P.M), flame = 0 }); core(i, OX + 7, OY + 9, 2, 1); dots(i, { {7,5,"y"}, {11,9,"r"} }) end },
  { 50, nil, function(i) body(i, { flame = 2 }) end },
} }

local total = 0; for _, c in ipairs(CLIPS) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "body"
for k = 2, total do spr:newEmptyFrame() end
local n = 0
for _, c in ipairs(CLIPS) do
  local from = n + 1
  for _, f in ipairs(c[3]) do
    n = n + 1
    local img = Image(FW, FH, ColorMode.RGB); f[3](img)
    local cel = spr:newCel(spr.layers[1], n, img)
    if f[2] then cel.data = f[2] end
    spr.frames[n].duration = f[1] / 1000
  end
  local tag = spr:newTag(from, n); tag.name = c[1]
  if c[2] then tag.data = "loop" end
end
spr.data = "facing=left;anchor=" .. ANCHOR[1] .. "," .. ANCHOR[2]
spr:saveAs(app.params.out)
