-- 지인 공유판(Demo 0) M1 스프라이트 원본 생성 (D-028). 계약 1 형식(.aseprite → export-anim.sh).
-- 실행: aseprite -b --script-param which=<id> --script-param out=<경로>.aseprite --script m1-build.lua
--   companion                 동반자 "작은 빛": 8~10px, 창백한 금빛-흰색, 얼굴 없음, 봉인 문양 기하(마름모+십자+고리). idle / idle-dim / idle-bright / move
--   emote                     감정 말풍선 3종 12×9: ellipsis(…) / exclaim(!) / question(?)
--   vine                      덩굴 장애물 (16px 칸): idle / burn (타서 사라짐)
--   artifact-spark-of-being   존재의 불씨 (Part 0, 차가운 빛): idle / acquire
--   artifact-small-flame-core 작은 불꽃의 핵 (Part 1 끝, 따뜻한 빛): idle / acquire
local function H(h) return Color{r=tonumber(h:sub(1,2),16), g=tonumber(h:sub(3,4),16), b=tonumber(h:sub(5,6),16)} end
local G = { W=H"ffffff", g1=H"fff1c8", g2=H"f0d28c", g3=H"c9a45c", g4=H"8a6a3a" }          -- 동반자 금빛-흰색 (P-015)
local E = { W=H"ffffff", e1=H"bfeaff", e2=H"6fb8f2" }                                      -- 불씨 모습 색 (D-017)
local S = { c=H"cbdbfc", C=H"5fcde4", B=H"306082", b=H"2f4a66" }                            -- 봉인 빛
local F = { Y=H"fbf236", y=H"df7126", r=H"ac3232", d=H"7a2018" }                            -- 손불꽃
local K = { o=H"141018", d=H"241e2c", s=H"362e40", m=H"4a4058", l=H"5e536e" }                -- 돌·외곽
local V = { d=H"26301f", m=H"3d4a2c", l=H"56663f", h=H"74844e" }                            -- 덩굴 (이끼 계열)
local A = { a=H"7a5a3a", h=H"a07a4c" }                                                      -- 재
local U = { f=H"ece6dc", o=H"241e2c" }                                                      -- 말풍선 면·글자
local WHICH = app.params.which
local FW, FH, ANCHOR, FACING = 16, 16, { 8, 15 }, "right"
local function px(i, x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if c and x >= 0 and y >= 0 and x < FW and y < FH then i:drawPixel(x, y, c) end end
local function plot(i, ox, oy, rows, pal) for y, r in ipairs(rows) do for x = 1, #r do px(i, ox + x - 1, oy + y - 1, pal[r:sub(x, x)]) end end end
local CL = {}

if WHICH == "companion" then
  -- 9×9 문양: 가운데 흰 점, 십자 팔, 마름모 테, 네 귀 점 (봉인 문양과 같은 기하)
  local GLYPH = {
    "....a....",
    "...b.b...",
    "..b.c.b..",
    ".b..c..b.",
    "a.ccWcc.a",
    ".b..c..b.",
    "..b.c.b..",
    "...b.b...",
    "....a....",
  }
  local LV = {   -- 밝기 단계: a=귀 점, b=마름모 테, c=십자, W=가운데
    dim    = { a=G.g4, b=G.g3, c=G.g2, W=G.g1 },
    normal = { a=G.g3, b=G.g2, c=G.g1, W=G.W },
    bright = { a=G.g2, b=G.g1, c=G.W,  W=G.W },
  }
  local function body(i, lv, dy, spin)
    local rows = GLYPH
    if spin then rows = { "....a....", "...bcb...", "..b.c.b..", ".b..c..b.", "acccWccca", ".b..c..b.", "..b.c.b..", "...bcb...", "....a...." } end
    plot(i, 4, 2 + dy, rows, LV[lv])
    if lv == "bright" then for _, d in ipairs({ {8,0}, {8,12}, {2,6}, {14,6} }) do px(i, d[1], d[2] + dy, G.g1) end end
  end
  local BOB = { 0, 0, -1, -1, -1, 0 }
  local function idle(lv) local f = {}; for k = 1, 6 do f[k] = { 120, nil, function(i) body(i, lv, BOB[k], k == 3 or k == 4) end } end; return f end
  CL[#CL+1] = { "idle", true, idle("normal") }
  CL[#CL+1] = { "idle-dim", true, idle("dim") }
  CL[#CL+1] = { "idle-bright", true, idle("bright") }
  CL[#CL+1] = { "move", true, { -- 앞으로 기울며 뒤(왼쪽)에 금빛 잔광
    { 90, nil, function(i) body(i, "normal", 0); px(i, 2, 6, G.g2); px(i, 1, 7, G.g3) end },
    { 90, nil, function(i) body(i, "normal", -1, true); px(i, 2, 5, G.g3); px(i, 0, 6, G.g4) end },
    { 90, nil, function(i) body(i, "normal", -1); px(i, 2, 5, G.g2); px(i, 1, 4, G.g3) end },
    { 90, nil, function(i) body(i, "normal", 0, true); px(i, 2, 6, G.g3); px(i, 0, 7, G.g4) end },
  } }

elseif WHICH == "emote" then
  FW, FH, ANCHOR = 14, 12, { 6, 11 }   -- anchor = 말풍선 꼬리 끝 (머리 위 한 점에 맞춤)
  -- 12×9 둥근 말풍선 + 아래 꼬리
  local BUB = {
    "..oooooooo..",
    ".offffffffo.",
    "offffffffffo",
    "offffffffffo",
    "offffffffffo",
    "offffffffffo",
    "offffffffffo",
    ".offffffffo.",
    "..oooofooo..",
    "......oo....",
    "......o.....",
  }
  local P = { o=U.o, f=U.f }
  local function bubble(i, sy) plot(i, 1, sy, BUB, P) end
  local function small(i) plot(i, 3, 5, { ".oooooo.", "offffffo", "offffffo", "offffffo", ".ooffoo.", "...oo..." }, P) end
  local GL = {
    ellipsis = { { 4,4 }, { 6,4 }, { 8,4 } },
    exclaim  = { { 6,2 }, { 6,3 }, { 6,4 }, { 6,6 } },
    question = { { 5,2 }, { 6,2 }, { 7,2 }, { 7,3 }, { 6,4 }, { 6,6 } },
  }
  local function glyph(i, name, n) for k, p in ipairs(GL[name]) do if not n or k <= n then px(i, 1 + p[1], 1 + p[2], U.o) end end end
  CL[#CL+1] = { "ellipsis", false, {
    { 50, nil, function(i) small(i) end },
    { 180, nil, function(i) bubble(i, 0); glyph(i, "ellipsis", 1) end },
    { 180, nil, function(i) bubble(i, 0); glyph(i, "ellipsis", 2) end },
    { 400, nil, function(i) bubble(i, 0); glyph(i, "ellipsis", 3) end },
  } }
  CL[#CL+1] = { "exclaim", false, {
    { 40, nil, function(i) small(i) end },
    { 60, nil, function(i) bubble(i, -1); glyph(i, "exclaim") end },   -- 살짝 튀어 오름
    { 400, nil, function(i) bubble(i, 0); glyph(i, "exclaim") end },
  } }
  CL[#CL+1] = { "question", false, {
    { 50, nil, function(i) small(i) end },
    { 400, nil, function(i) bubble(i, 0); glyph(i, "question") end },
  } }

elseif WHICH == "vine" then
  FW, FH, ANCHOR = 16, 24, { 8, 23 }  -- 바닥 한 칸을 막고 위로 8px 더 자람
  local function vine(i, sway, burnt)
    -- 줄기 세 가닥 (아래 굵고 위로 가늘게), 잎 몇 장
    local stems = { { 3, 23, 5, 6 }, { 8, 23, 7, 2 }, { 12, 23, 11, 5 } }
    for k, s in ipairs(stems) do local x0, y0, x1, y1 = s[1], s[2], s[3] + (k == 2 and sway or 0), s[4]
      for t = 0, 1, 0.06 do local x = x0 + (x1 - x0) * t + math.sin(t * 6 + k) * 1.2; local y = y0 + (y1 - y0) * t
        if not (burnt and y < burnt) then px(i, x, y, t < 0.5 and V.m or V.l); px(i, x + 1, y, t < 0.3 and V.d or nil) end end end
    for _, l in ipairs({ { 4, 15 }, { 10, 11 }, { 6, 9 }, { 12, 16 }, { 7, 4 }, { 2, 19 }, { 13, 20 } }) do
      if not (burnt and l[2] < burnt) then px(i, l[1] + (l[2] < 10 and sway or 0), l[2], V.h); px(i, l[1] + 1 + (l[2] < 10 and sway or 0), l[2], V.l) end end
    for x = 1, 14 do px(i, x, 23, V.d) end
  end
  local function flames(i, top, n, seed)
    for k = 1, n do local x = 2 + ((k * 37 + seed * 11) % 12); local y = top + ((k * 13 + seed * 7) % 6)
      px(i, x, y, F.Y); px(i, x, y + 1, F.y); px(i, x - 1, y + 1, F.r); px(i, x, y - 1, (k + seed) % 2 == 0 and F.y or F.r) end
  end
  CL[#CL+1] = { "idle", true, { { 400, nil, function(i) vine(i, 0) end }, { 400, nil, function(i) vine(i, 1) end } } }
  CL[#CL+1] = { "burn", false, {
    { 60, "burn:start", function(i) vine(i, 0); flames(i, 16, 3, 1) end },
    { 70, nil, function(i) vine(i, 0); flames(i, 11, 5, 2) end },
    { 70, nil, function(i) vine(i, 1, 6); flames(i, 6, 7, 3) end },
    { 80, nil, function(i) vine(i, 0, 12); flames(i, 4, 6, 4) end },
    { 80, nil, function(i) vine(i, 0, 18); flames(i, 9, 4, 5); for x = 2, 13, 3 do px(i, x, 22, A.a) end end },
    { 90, "burn:clear", function(i) flames(i, 15, 2, 6); for x = 1, 14, 2 do px(i, x, 23, A.a); px(i, x + 1, 22, A.h) end end }, -- 이 프레임부터 통과 가능
    { 120, nil, function(i) for x = 2, 13, 3 do px(i, x, 23, A.a) end; px(i, 8, 18, F.r) end },
    { 150, nil, function(i) px(i, 5, 23, A.a); px(i, 10, 23, A.a) end },
  } }

elseif WHICH == "artifact-spark-of-being" or WHICH == "artifact-small-flame-core" then
  FW, FH, ANCHOR = 24, 24, { 12, 22 }  -- 바닥 받침 위에 떠 있는 결정
  local warm = WHICH == "artifact-small-flame-core"
  local C3 = warm and { F.Y, F.y, F.r } or { E.W, E.e1, E.e2 }        -- 속 불꽃
  local RIM = warm and { G.g2, G.g3, G.g4 } or { S.c, S.C, S.B }      -- 감싼 문양 테 (따뜻한 쪽은 금빛, 차가운 쪽은 봉인 빛)
  local function core(i, cx, cy, r)
    for y = -r, r do for x = -r, r do local d = math.sqrt(x * x + y * y)
      if d <= r + 0.3 then px(i, cx + x, cy + y, d < r * 0.45 and C3[1] or d < r * 0.8 and C3[2] or C3[3]) end end end
  end
  local function shell(i, cx, cy, lv) -- 마름모 껍질 (봉인 문양 기하)
    for k = 0, 6 do local c = (k % 2 == 0) and RIM[lv] or RIM[math.min(3, lv + 1)]
      px(i, cx - 7 + k, cy - k + (k > 0 and 0 or 0), nil)
      px(i, cx - 7 + k, cy + 0 - k, c); px(i, cx + 7 - k, cy - k, c); px(i, cx - 7 + k, cy + k, c); px(i, cx + 7 - k, cy + k, c) end
    px(i, cx, cy - 7, RIM[1]); px(i, cx, cy + 7, RIM[1])
  end
  local function pedestal(i) for x = 7, 16 do px(i, x, 22, K.s); px(i, x, 23, K.d) end; for x = 8, 15 do px(i, x, 21, K.m) end; px(i, 7, 21, K.o); px(i, 16, 21, K.o) end
  local BOB = { 0, -1, -1, 0 }
  local R = { 2, 3, 3, 2 }
  local F4 = {}
  for k = 1, 4 do F4[k] = { 160, nil, function(i) pedestal(i); shell(i, 12, 10 + BOB[k], k == 2 and 1 or 2); core(i, 12, 10 + BOB[k], R[k]) end } end
  CL[#CL+1] = { "idle", true, F4 }
  CL[#CL+1] = { "acquire", false, { -- 껍질이 열리고 빛이 터지며 사라짐 (주인공이 흡수)
    { 60, "acquire:start", function(i) pedestal(i); shell(i, 12, 10, 1); core(i, 12, 10, 4) end },
    { 60, nil, function(i) pedestal(i); core(i, 12, 10, 5); for k = 0, 7 do local a = k * 0.785; px(i, 12 + math.cos(a) * 9, 10 + math.sin(a) * 8, RIM[1]) end end },
    { 70, nil, function(i) pedestal(i); core(i, 12, 10, 3); for k = 0, 7 do local a = k * 0.785 + 0.4; px(i, 12 + math.cos(a) * 11, 10 + math.sin(a) * 9, C3[2]) end end },
    { 80, "acquire:absorb", function(i) pedestal(i); core(i, 12, 13, 2) end },
    { 90, nil, function(i) pedestal(i); px(i, 12, 17, C3[1]); px(i, 12, 18, C3[2]) end },
    { 120, nil, function(i) pedestal(i) end },
  } }
end
assert(#CL > 0, "which=" .. tostring(WHICH) .. " 모름")

local total = 0; for _, c in ipairs(CL) do total = total + #c[3] end
local spr = Sprite(FW, FH, ColorMode.RGB)
spr.layers[1].name = "art"
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
