-- .aseprite → <id>.png + <id>.anim.json (docs/asset-contract.md, contract 1). scripts/export-anim.sh가 부른다.
-- 원본 규칙:
--   태그 = clip (태그 User Data에 "loop"가 있으면 loop: true)
--   프레임 신호 = 그 프레임 셀들의 User Data (쉼표 구분, 예: "dash:travel")
--   스프라이트 User Data: "facing=left|right;anchor=x,y"  — left면 오른쪽 보도록 반전, anchor x도 반전
-- 시트: clip 하나당 한 줄, 프레임은 가로로.
local P = app.params
local spr = app.open(P["in"])
local FW, FH = spr.width, spr.height

local meta = {}
for kv in (spr.data or ""):gmatch("[^;]+") do local k, v = kv:match("^%s*(%w+)%s*=%s*(.-)%s*$"); if k then meta[k] = v end end
local flip = meta.facing == "left"
local ax, ay = (meta.anchor or ""):match("^(%d+),(%d+)$")
assert(ax, "스프라이트 User Data에 anchor=x,y 가 필요")
ax, ay = tonumber(ax), tonumber(ay)
if flip then ax = FW - ax end
assert(#spr.tags > 0, "태그(clip)가 없음")

local function frameImage(fn)
  local img = Image(FW, FH, ColorMode.RGB); img:drawSprite(spr, fn)
  if flip then
    local out = Image(FW, FH, ColorMode.RGB)
    for y = 0, FH - 1 do for x = 0, FW - 1 do out:drawPixel(FW - 1 - x, y, img:getPixel(x, y)) end end
    return out
  end
  return img
end
local function frameTags(fn)
  local t = {}
  for _, layer in ipairs(spr.layers) do local cel = layer:cel(fn)
    if cel and cel.data and cel.data ~= "" then for s in cel.data:gmatch("[^,%s]+") do t[#t+1] = s end end end
  return t
end
local function q(s) return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"' end

local maxF = 0; for _, tag in ipairs(spr.tags) do maxF = math.max(maxF, tag.frames) end
local sheet = Image(FW * maxF, FH * #spr.tags, ColorMode.RGB)
local clips = {}
for row, tag in ipairs(spr.tags) do
  local frames = {}
  for k = 0, tag.frames - 1 do
    local fn = tag.fromFrame.frameNumber + k
    sheet:drawImage(frameImage(fn), Point(k * FW, (row - 1) * FH))
    local f = string.format('{ "sx": %d, "sy": %d, "sWidth": %d, "sHeight": %d, "durationMs": %d',
      k * FW, (row - 1) * FH, FW, FH, math.floor(spr.frames[fn].duration * 1000 + 0.5))
    local tags = frameTags(fn)
    if #tags > 0 then local qs = {}; for _, s in ipairs(tags) do qs[#qs+1] = q(s) end; f = f .. ', "tags": [' .. table.concat(qs, ", ") .. ']' end
    frames[#frames+1] = "        " .. f .. " }"
  end
  local loop = (tag.data or ""):find("loop") ~= nil
  clips[#clips+1] = string.format('    %s: { "loop": %s, "frames": [\n%s\n    ] }', q(tag.name), loop and "true" or "false", table.concat(frames, ",\n"))
end

local id = P.id
local out = Sprite(sheet.width, sheet.height, ColorMode.RGB); out.cels[1].image = sheet
out:saveAs(P.out .. "/" .. id .. ".png")
local lines = {
  "{",
  '  "contract": 1,',
  '  "id": ' .. q(id) .. ',',
  '  "texture": ' .. q(id .. ".png") .. ',',
  '  "frameSize": [' .. FW .. ', ' .. FH .. '],',
  '  "anchor": [' .. ax .. ', ' .. ay .. '],',
}
if P.source and P.source ~= "" then lines[#lines+1] = '  "source": ' .. q(P.source) .. ',' end
lines[#lines+1] = '  "clips": {'
lines[#lines+1] = table.concat(clips, ",\n")
lines[#lines+1] = "  }"
lines[#lines+1] = "}"
-- "wb": LF 줄바꿈 (Windows에서 "w"는 CRLF)
local f = io.open(P.out .. "/" .. id .. ".anim.json", "wb"); f:write(table.concat(lines, "\n") .. "\n"); f:close()
