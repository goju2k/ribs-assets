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
-- o: dx, dy, lean(위쪽 몇 줄 앞으로), flame(0~3), glow(1~3), skip(행 거르기), color(단색/디더)
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
  if fl > 0 then for fy, r in ipairs(FLAME[fl]) do for x = 1, 4 do local c = P[r:sub(x, x)]; if c then put(x - 1, 7 + fy, c) end end end end
end
local function ring(img, cx, cy, r, c, gaps)
  for a = 0, 359, 6 do if not (gaps and gaps(a)) then local t = math.rad(a); px(img, math.floor(cx + math.cos(t) * r + 0.5), math.floor(cy + math.sin(t) * r * 0.9 + 0.5), c) end end
end
local function silhouette(col) return function() return col end end
local function dither(col) return function(x, y) if (x + y) % 2 == 0 then return col end end end
local function ember(i, cx, cy, tail)
  for k = 1, tail do local c = (k < 3) and P.Y or (k < 6) and P.y or P.r
    if k % 3 ~= 0 or k < 4 then px(i, cx + k, cy + ((k > 4 and k % 2 == 1) and 1 or 0), c) end end
  for _, d in ipairs({ {0,0,"Y"}, {-1,0,"y"}, {0,-1,"y"}, {0,1,"y"}, {1,0,"Y"}, {-1,-1,"r"}, {-1,1,"r"}, {-2,0,"r"} }) do px(i, cx + d[1], cy + d[2], P[d[3]]) end
end
local function core(i, cx, cy, r, k)
  for y = -r, r do for x = -r, r do local d = math.sqrt(x * x + y * y)
    if d <= r + 0.3 then px(i, cx + x, cy + y, d < r * 0.45 and P.Y or d < r * 0.8 and P.y or P.r) end end end
  if k % 2 == 0 then px(i, cx, cy - r - 1, P.y) else px(i, cx - 1, cy - r - 2, P.r) end
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
-- dash: 대시 B (불씨 꼬리), 멈춤 중간 — 출발 전 330ms, 전체 735ms, 이동은 스킬 데이터(48px 기준)
CLIPS[#CLIPS+1] = { "dash", false, {
  { 70, "dash:charge", function(i) body(i, { dy = 1, flame = 2 }) end },
  { 70, nil, function(i) body(i, { skip = function(y) return y > 11 end, flame = 3 }); body(i, { skip = function(y) return y <= 11 end, color = dither(P.M), flame = 0 }); core(i, OX + 2, OY + 11, 2, 0) end },
  { 70, nil, function(i) body(i, { skip = function(y) return y > 8 end, color = dither(P.D), flame = 0 }); core(i, OX + 6, OY + 11, 3, 1) end },
  { 60, nil, function(i) core(i, OX + 7, OY + 11, 3, 1) end },
  { 60, nil, function(i) core(i, OX + 7, OY + 11, 2, 2) end },
  { 45, "dash:travel", function(i) ember(i, OX + 6, OY + 11, 10) end },
  { 45, nil, function(i) ember(i, OX + 6, OY + 10, 16) end },
  { 45, nil, function(i) ember(i, OX + 6, OY + 10, 13) end },
  { 60, "dash:recover", function(i) body(i, { skip = function(y) return y < 8 end, color = dither(P.M), flame = 0 }); ember(i, OX + 6, OY + 11, 5) end },
  { 70, nil, function(i) body(i, { skip = function(y) return y < 4 end, flame = 2 }); body(i, { skip = function(y) return y >= 4 end, color = dither(P.M), flame = 0 }) end },
  { 140, nil, function(i) body(i, { flame = 3 }) end },
} }
-- parry: 패링 A (섬광 고리, 방어 계열 색), 1~2px 뒤로 밀림
CLIPS[#CLIPS+1] = { "parry", false, {
  { 60, "parry:flash", function(i) body(i, { dx = 1, flame = 2 }); ring(i, OX + 1, OY + 10, 4, P.W); px(i, OX + 1, OY + 10, P.W) end },
  { 60, nil, function(i) body(i, { dx = 2, flame = 3 }); ring(i, OX + 1, OY + 10, 7, P.c, function(a) return a % 36 < 12 end); ring(i, OX + 1, OY + 10, 3, P.W) end },
  { 80, nil, function(i) body(i, { dx = 2, flame = 1 }); ring(i, OX + 1, OY + 10, 9, P.C, function(a) return a % 48 < 30 end) end },
  { 120, nil, function(i) body(i, { dx = 1, flame = 2 }) end },
  { 160, nil, function(i) body(i, { flame = 1 }) end },
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
