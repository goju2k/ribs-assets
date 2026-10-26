-- 수호체 원본 생성 (전투 명세 v1 8절, D-014, 신호 = 흰색만 + 1px 바깥 테두리).
-- 실행: aseprite -b --script-param which=melee|awakened --script-param out=<경로>.aseprite --script sentinel-build.lua
-- 색: 바닥·벽 팔레트 + 봉인 빛 (P-014). 빨강 없음. 원본은 왼쪽을 봄 (facing=left). 태그 = clip, 셀 User Data = 프레임 신호, 태그 User Data "loop" = 반복.
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local C = { o=H"141018", d=H"241e2c", s=H"362e40", m=H"4a4058", l=H"5e536e", t=H"584d66" }
local GL = { [0]={ H"241e2c", H"306082" }, { H"306082", H"2f4a66" }, { H"5fcde4", H"306082" }, { H"cbdbfc", H"5fcde4" }, { H"ffffff", H"ffffff" } } -- 4 = 패링 신호: 흰색만 (불씨 중간색 #bfeaff와 구분) -- 봉인 빛 단계: {가운데, 둘레}
local WHICH = app.params.which
local FW, FH = (WHICH == "melee") and 36 or 28, (WHICH == "melee") and 32 or 24

local function newImg() return Image(FW, FH) end
local function px(i, x, y, c) if x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
-- 돌 덩어리: 외곽선 + 위·왼쪽 밝은 테 + 아래·오른쪽 그늘
local function block(i, x0, y0, x1, y1, fill, round)
  for y = y0, y1 do for x = x0, x1 do
    local corner = round and ((x == x0 or x == x1) and (y == y0 or y == y1))
    if not corner then
      local edge = x == x0 or x == x1 or y == y0 or y == y1
      local c = fill or C.m
      if edge then c = C.o elseif y == y0 + 1 or x == x0 + 1 then c = C.l elseif y == y1 - 1 or x == x1 - 1 then c = C.s end
      px(i, x, y, c)
    end
  end end
end
local function glyph(i, cx, cy, lv)  -- 가슴 봉인 문양 (마름모 + 가운데)
  local g = GL[lv]
  for _, d in ipairs({ {0,-2}, {-1,-1}, {1,-1}, {-2,0}, {2,0}, {-1,1}, {1,1}, {0,2} }) do px(i, cx + d[1], cy + d[2], g[2]) end
  px(i, cx, cy, g[1]); if lv >= 2 then px(i, cx - 1, cy, g[1]); px(i, cx + 1, cy, g[1]); px(i, cx, cy - 1, g[1]); px(i, cx, cy + 1, g[1]) end
end

-- ===== 근접 수호체 (몸 상자 24x24를 (10,4)에, 프레임 36x32 — 공격 팔·신호 테두리 여유) =====
local MX, MY = 10, 4
-- o: lean(윗몸 뒤로 +px), bob, arm('rest'|'up'|'forward'|'down'), lv(빛 0~4), legs(0/1), slump, tilt
local function melee(i, o)
  o = o or {}
  local lean, bob, lv = o.lean or 0, o.bob or 0, o.lv or 1
  local x, y = MX, MY + bob + (o.slump or 0)
  -- 다리 (짧고 굵게)
  local la, lb = (o.legs == 1) and -1 or 0, (o.legs == 1) and 0 or -1
  block(i, x + 7, y + 18 + la, x + 10, y + 23, C.s); block(i, x + 13, y + 18 + lb, x + 16, y + 23, C.s)
  -- 뒷팔 (어둡게)
  block(i, x + 17 + lean, y + 9, x + 21 + lean, y + 17, C.s, true)
  -- 몸통
  block(i, x + 5 + lean // 2, y + 7, x + 18 + lean // 2, y + 19, C.m, true)
  glyph(i, x + 11 + lean // 2, y + 13, lv)
  -- 머리 (투구, 가로 눈구멍)
  local hx = x + 7 + lean
  block(i, hx, y + 1, hx + 8, y + 8, C.m, true)
  local g = GL[math.max(0, lv - (lv == 4 and 0 or 1))]
  for ex = hx + 1, hx + 4 do px(i, ex, y + 4, g[1]) end; px(i, hx + 5, y + 4, g[2])
  -- 앞팔 (공격 팔)
  local arm = o.arm or "rest"
  if arm == "rest" then block(i, x + 1 + lean // 2, y + 9, x + 6 + lean // 2, y + 18, C.m, true)
  elseif arm == "up" then block(i, x + 3 + lean, y - 3, x + 8 + lean, y + 9, C.m, true); if lv >= 2 then px(i, x + 4 + lean, y - 2, GL[lv][2]); px(i, x + 5 + lean, y - 2, GL[lv][2]) end
  elseif arm == "forward" then block(i, x - 8, y + 10, x + 6, y + 15, C.m, true); for k = 0, 4 do px(i, x - 7 + k, y + 16, GL[3][1]) end
  elseif arm == "down" then block(i, x - 4, y + 14, x + 6, y + 19, C.m, true) end
  if lv == 4 then -- 패링 신호: 몸 둘레 1px 바깥 테두리를 흰색으로 (크게, 흰색만)
    local W, edge = GL[4][1], {}
    for yy = 0, FH - 1 do for xx = 0, FW - 1 do
      if app.pixelColor.rgbaA(i:getPixel(xx, yy)) == 0 then
        for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do local nx, ny = xx + d[1], yy + d[2]
          if nx >= 0 and ny >= 0 and nx < FW and ny < FH and app.pixelColor.rgbaA(i:getPixel(nx, ny)) > 0 then edge[#edge+1] = { xx, yy }; break end end
      end
    end end
    for _, p in ipairs(edge) do px(i, p[1], p[2], W) end
  end
end
local function smear(i)  -- 공격 휘두름 자국 (방어 계열 아님: 봉인 빛 청록)
  for k = 0, 9 do px(i, MX - 8 + k, MY + 8 + (k % 3 == 0 and 1 or 0), GL[2][2]) end
  for k = 0, 6 do px(i, MX - 9 + k, MY + 17, GL[3][2]) end
end
local function sparks(i, n) local P = { {MX + 2, MY + 2}, {MX + 20, MY + 4}, {MX + 6, MY + 20}, {MX + 22, MY + 14} }; for k = 1, n do px(i, P[k][1], P[k][2], GL[3][1]) end end

local M = {}
M[#M+1] = { "idle", "대기", { {150,0,function(i) melee(i,{lv=1}) end}, {150,0,function(i) melee(i,{lv=1,bob=1}) end}, {150,0,function(i) melee(i,{lv=2,bob=1}) end}, {150,0,function(i) melee(i,{lv=1}) end} } }
M[#M+1] = { "approach", "접근 (40px/s)", { {120,-5,function(i) melee(i,{legs=0,lean=-1}) end}, {120,-5,function(i) melee(i,{legs=1,bob=1,lean=-1}) end}, {120,-5,function(i) melee(i,{legs=0,lean=-1}) end}, {120,-5,function(i) melee(i,{legs=1,bob=1,lean=-1}) end} } }
-- 예비동작: ① 젖힘·빛 강해짐 → ② 정지(힘 모음) → ③ 흰 반짝임(신호)
local function windup(hold, cueFrames)
  local F = { {100,0,function(i) melee(i,{lean=1,arm="up",lv=2}) end, "windup:start"}, {100,0,function(i) melee(i,{lean=2,arm="up",lv=2}) end} }
  F[#F+1] = { hold, 0, function(i) melee(i,{lean=2,arm="up",lv=3,bob=1}) end }
  for k = 1, cueFrames do F[#F+1] = { k == cueFrames and 66 or 67, 0, function(i) melee(i,{lean=2,arm="up",lv=(k % 2 == 1) and 4 or 3,bob=1}) end, k == 1 and "windup:cue" or nil } end
  return F
end
M[#M+1] = { "windup", "예비동작 (600ms, 신호 8f)", windup(267, 2) }       -- 200 + 267 + 133
M[#M+1] = { "windup-easy", "예비동작 쉬움 (900ms, 신호 12f)", windup(500, 3) } -- 200 + 500 + 200
M[#M+1] = { "attack", "공격 (100ms)", { {50,0,function(i) melee(i,{lean=-1,arm="forward",lv=3}); smear(i) end, "attack:active"}, {50,0,function(i) melee(i,{lean=-2,arm="forward",lv=2}) end} } }
M[#M+1] = { "recover", "공격 후 빈틈 (500ms)", { {200,0,function(i) melee(i,{lean=-2,arm="down",lv=1,bob=1}) end, "attack:recover"}, {150,0,function(i) melee(i,{lean=-1,arm="down",lv=1,bob=1}) end}, {150,0,function(i) melee(i,{arm="rest",lv=1}) end} } }
M[#M+1] = { "stun", "패링 경직 (1s)", { {250,0,function(i) melee(i,{lean=3,arm="up",lv=0}); sparks(i,4) end, "stun:start"}, {250,0,function(i) melee(i,{lean=3,arm="rest",lv=1,bob=1}); sparks(i,2) end}, {250,0,function(i) melee(i,{lean=2,arm="rest",lv=0,bob=1}) end}, {250,0,function(i) melee(i,{lean=1,arm="rest",lv=1}) end} } }
M[#M+1] = { "shutdown", "정지 (영구 비활성)", { {150,0,function(i) melee(i,{lean=2,lv=2}) end, "shutdown:start"}, {150,0,function(i) melee(i,{lean=1,lv=1,slump=1}) end}, {200,0,function(i) melee(i,{lv=1,slump=2,arm="down"}) end}, {400,0,function(i) melee(i,{lv=0,slump=3,arm="down"}) end} } }

-- ===== 각성형 수호체 (몸 상자 16x16을 (6,4)에, 프레임 28x24) =====
local AX, AY = 6, 4
local function awake(i, o)
  o = o or {}
  local lv, up, hop = o.lv or 2, o.up or 4, o.hop or 0
  local x, y = AX, AY - hop
  if up == 0 then -- 잔해: 투구가 옆으로 누움 + 가슴판 조각
    block(i, x + 1, y + 9, x + 7, y + 15, C.m, true); for ex = x + 2, x + 5 do px(i, ex, y + 12, GL[0][2]) end
    block(i, x + 9, y + 10, x + 14, y + 15, C.m)
    for k = 0, 13 do px(i, x + 1 + k, y + 16, C.d) end
    return
  end
  local by = y + 16 - up * 2  -- 몸이 솟는 높이
  block(i, x + 4, by + 2, x + 11, math.min(y + 15, by + 9), C.m, true)            -- 몸
  glyph(i, x + 8, math.min(y + 12, by + 5), lv >= 2 and 2 or lv)
  block(i, x + 3, by - 5, x + 10, by + 2, C.m, true)                              -- 투구
  local g = GL[lv]; for ex = x + 4, x + 6 do px(i, ex, by - 2, g[1]) end; px(i, x + 7, by - 2, g[2])
  if o.legs then px(i, x + 5, y + 15, C.o); px(i, x + 10, y + 15 - (o.legs == 1 and 1 or 0), C.o) end
end
local A = {}
A[#A+1] = { "dormant", "대기 (잔해처럼)", { {400,0,function(i) awake(i,{up=0}) end}, {400,0,function(i) awake(i,{up=0}) end} } }
A[#A+1] = { "awaken", "각성 (400ms)", { {100,0,function(i) awake(i,{up=1,lv=1}) end}, {100,0,function(i) awake(i,{up=2,lv=1}) end}, {100,0,function(i) awake(i,{up=3,lv=2}) end}, {100,0,function(i) awake(i,{up=4,lv=3}) end} } }
A[#A+1] = { "chase", "추격 (48px/s)", { {100,-5,function(i) awake(i,{hop=0,legs=0}) end}, {100,-5,function(i) awake(i,{hop=1,legs=1}) end}, {100,-5,function(i) awake(i,{hop=2,legs=1}) end}, {100,-5,function(i) awake(i,{hop=1,legs=0}) end} } }

local LOOP = { idle = true, approach = true, dormant = true, chase = true }
local function build(V, anchor)
  local total = 0; for _, v in ipairs(V) do total = total + #v[3] end
  local spr = Sprite(FW, FH, ColorMode.RGB)
  spr.layers[1].name = "body"
  for k = 2, total do spr:newEmptyFrame() end
  local n = 0
  for _, v in ipairs(V) do
    local from = n + 1
    for _, d in ipairs(v[3]) do
      n = n + 1
      local img = newImg(); d[3](img)
      local cel = spr:newCel(spr.layers[1], n, img)
      if d[4] then cel.data = d[4] end
      spr.frames[n].duration = d[1] / 1000
    end
    local tag = spr:newTag(from, n); tag.name = v[1]
    if LOOP[v[1]] then tag.data = "loop" end
  end
  spr.data = "facing=left;anchor=" .. anchor[1] .. "," .. anchor[2]
  spr:saveAs(app.params.out)
end
if WHICH == "melee" then build(M, { MX + 12, MY + 24 }) else build(A, { AX + 8, AY + 16 }) end
