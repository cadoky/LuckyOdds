-- LuckyOdds: rarity odds per card from your luck. Weights are Common 60, Uncommon 25k,
-- Rare 10k^2, Epic 4k^3, Legendary k^4, with k = 1 + luck + level bonus (+1% per level,
-- 30% at most) + source bonus (+0.5 for amulets). A rough guide, not the game's exact roll.
-- Also marks the Battleground Caches on the minimap. WoW 1.12 / Lua 5.0.


local RARITY = {
  { key = "rare", r = 0.00, g = 0.44, b = 0.87 },
  { key = "epic", r = 0.64, g = 0.21, b = 0.93 },
  { key = "legend", r = 1.00, g = 0.50, b = 0.00 },
}
-- the two card groups: spells, rings and trinkets share one set of odds, amulets get +0.5
local GROUPS = {
  { keys = { "spells", "rings", "trinkets" }, bonus = 0 },
  { keys = { "amulets" }, bonus = 0.5 },
}

-- the panel's words, same languages as ASBuilder
local LANGS = { { "en", "English" }, { "zh", "Chinese" }, { "es", "Español" }, { "fr", "Français" }, { "pt", "Português" },
  { "ru", "Russian" }, { "de", "Deutsch" }, { "ja", "Japanese" }, { "tr", "Türkçe" }, { "ko", "Korean" } }
local L = {
  en = { luck = "Luck", level = "from your level", spells = "Spells", rings = "Rings", trinkets = "Trinkets", amulets = "Amulets",
    rare = "RARE", epic = "EPIC", legend = "LEGEND", settings = "Settings", sel = "Show on selection", on = "On", off = "Off", lang = "Language" },
  zh = { luck = "幸运", level = "来自等级", spells = "法术", rings = "戒指", trinkets = "饰品", amulets = "项链",
    rare = "稀有", epic = "史诗", legend = "传说", settings = "设置", sel = "选牌时显示", on = "开", off = "关", lang = "语言" },
  es = { luck = "Suerte", level = "de tu nivel", spells = "Hechizos", rings = "Anillos", trinkets = "Abalorios", amulets = "Amuletos",
    rare = "RARO", epic = "ÉPICO", legend = "LEGENDARIO", settings = "Ajustes", sel = "Mostrar al elegir", on = "Sí", off = "No", lang = "Idioma" },
  fr = { luck = "Chance", level = "de ton niveau", spells = "Sorts", rings = "Anneaux", trinkets = "Bijoux", amulets = "Amulettes",
    rare = "RARE", epic = "ÉPIQUE", legend = "LÉGENDAIRE", settings = "Réglages", sel = "Afficher au choix", on = "Oui", off = "Non", lang = "Langue" },
  pt = { luck = "Sorte", level = "do seu nível", spells = "Feitiços", rings = "Anéis", trinkets = "Berloques", amulets = "Amuletos",
    rare = "RARO", epic = "ÉPICO", legend = "LENDÁRIO", settings = "Opções", sel = "Mostrar ao escolher", on = "Sim", off = "Não", lang = "Idioma" },
  ru = { luck = "Удача", level = "от вашего уровня", spells = "Заклинания", rings = "Кольца", trinkets = "Аксессуары", amulets = "Амулеты",
    rare = "РЕДКАЯ", epic = "ЭПИК", legend = "ЛЕГЕНДА", settings = "Настройки", sel = "Показ при выборе", on = "Да", off = "Нет", lang = "Язык" },
  de = { luck = "Glück", level = "durch deine Stufe", spells = "Zauber", rings = "Ringe", trinkets = "Schmuck", amulets = "Amulette",
    rare = "SELTEN", epic = "EPISCH", legend = "LEGENDÄR", settings = "Optionen", sel = "Bei Auswahl zeigen", on = "An", off = "Aus", lang = "Sprache" },
  ja = { luck = "幸運", level = "レベル分", spells = "呪文", rings = "指輪", trinkets = "装飾品", amulets = "首飾り",
    rare = "レア", epic = "エピック", legend = "レジェンド", settings = "設定", sel = "選択時に表示", on = "オン", off = "オフ", lang = "言語" },
  tr = { luck = "Şans", level = "seviyenden", spells = "Büyüler", rings = "Yüzükler", trinkets = "Takılar", amulets = "Tılsımlar",
    rare = "NADİR", epic = "DESTANSI", legend = "EFSANEVİ", settings = "Ayarlar", sel = "Seçimde göster", on = "Açık", off = "Kapalı", lang = "Dil" },
  ko = { luck = "행운", level = "레벨 보너스", spells = "주문", rings = "반지", trinkets = "장신구", amulets = "목걸이",
    rare = "희귀", epic = "영웅", legend = "전설", settings = "설정", sel = "선택 시 표시", on = "켜짐", off = "꺼짐", lang = "언어" },
}

local db
local function Tr(k)
  local t = L[db and db.lang] or L.en
  return t[k] or L.en[k]
end


-- chances in percent for Rare, Epic and Legendary at a given k
local function Odds(k)
  local w = { 60, 25 * k, 10 * k * k, 4 * k * k * k, k * k * k * k }
  local total = w[1] + w[2] + w[3] + w[4] + w[5]
  return { w[3] * 100 / total, w[4] * 100 / total, w[5] * 100 / total }
end

local function Luck()
  local s = AZS_STATS
  return type(s) == "table" and tonumber(s.luck) or nil
end

local function LevelBonus()
  local lvl = UnitLevel("player") or 0
  return math.min(0.30, math.max(0, lvl) * 0.01)
end


local f = CreateFrame("Frame", "LuckyOddsFrame", UIParent)
f:SetWidth(252)
f:SetHeight(246)
f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
f:SetBackdropColor(0.04, 0.04, 0.06, 0.92)
f:SetBackdropBorderColor(0.62, 0.52, 0.32, 1)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() this:StartMoving() end)
f:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()
  local p, _, rp, x, y = this:GetPoint()
  db.point = { p, rp, x, y }
end)

local ui = {}   -- every piece of the panel; Layout() puts them in portrait or landscape

local function Text(font, justify)
  local t = f:CreateFontString(nil, "OVERLAY", font)
  t:SetJustifyH(justify or "LEFT")
  return t
end

local function Tex(layer, path)
  local t = f:CreateTexture(nil, layer)
  t:SetTexture(path)
  return t
end

-- Icons sit in small frames of their own: the game keeps a frame over the level-up cards, and
-- textures drawn straight on the panel stayed dark under the cards' veil.
local function IconFrame(size)
  local fr = CreateFrame("Frame", nil, f)
  fr:SetWidth(size)
  fr:SetHeight(size)
  fr.tex = fr:CreateTexture(nil, "ARTWORK")
  fr.tex:SetAllPoints(fr)
  fr.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  return fr
end

-- header: the luck amulet's icon, your luck, the level bonus
ui.icon = IconFrame(22)
ui.icon.tex:SetTexture("Interface\\Icons\\INV_Jewelry_Necklace_26")
ui.luckLabel = Text("GameFontNormalSmall")
ui.luck = Text("GameFontNormalLarge", "CENTER")   -- the percentage; Layout sets its size
ui.level = Text("GameFontDisableSmall", "CENTER")

ui.rule = { Tex("ARTWORK", "Interface\\Buttons\\WHITE8X8"), Tex("ARTWORK", "Interface\\Buttons\\WHITE8X8") }
ui.rule[1]:SetVertexColor(0.62, 0.52, 0.32, 0.5)
ui.rule[2]:SetVertexColor(0.62, 0.52, 0.32, 0.5)
ui.band = Tex("BACKGROUND", "Interface\\Buttons\\WHITE8X8")
ui.band:SetVertexColor(1, 1, 1, 0.04)

-- the two card groups' names
ui.group = {}
for g = 1, 2 do
  local grp = { text = Text("GameFontHighlightSmall", "CENTER") }
  grp.text:SetWidth(60)
  ui.group[g] = grp
end

-- the rarity names and the chances: ui.cell[group][rarity]
ui.name, ui.cell = {}, { {}, {} }
for i = 1, 3 do
  ui.name[i] = Text("GameFontNormalSmall", "CENTER")
  ui.name[i]:SetTextColor(RARITY[i].r, RARITY[i].g, RARITY[i].b)
  ui.cell[1][i] = Text("GameFontHighlightSmall", "CENTER")
  ui.cell[2][i] = Text("GameFontHighlightSmall", "CENTER")
end

-- settings: a label, three icon buttons (layout and the two minimap markers come later), the
-- show-on-selection switch and the language button with its list
ui.pop = CreateFrame("Frame", nil, f)   -- the settings window, tooltip sized
ui.pop:SetWidth(150)
ui.pop:SetHeight(58)
ui.pop:SetFrameLevel(f:GetFrameLevel() + 10)
ui.pop:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
ui.pop:SetBackdropColor(0.04, 0.04, 0.06, 1)
ui.pop:SetBackdropBorderColor(0.62, 0.52, 0.32, 1)
ui.pop:EnableMouse(true)
ui.pop:Hide()

local function TextButton(width)
  local b = CreateFrame("Button", nil, ui.pop)
  b:SetWidth(width)
  b:SetHeight(16)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  b.text:SetAllPoints(b)
  return b
end

local function IconButton(iconPath)
  local b = CreateFrame("Button", nil, f)
  b:SetWidth(20)
  b:SetHeight(20)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  b.tex = b:CreateTexture(nil, "ARTWORK")
  b.tex:SetAllPoints(b)
  b.tex:SetTexture(iconPath)
  b.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  return b
end

ui.sel = TextButton(138)
ui.sel:SetPoint("TOP", ui.pop, "TOP", 0, -9)
ui.lang = TextButton(138)
ui.lang:SetPoint("TOP", ui.pop, "TOP", 0, -31)

ui.gear = IconButton("Interface\\Icons\\INV_Misc_Gear_01")
ui.gear:SetScript("OnClick", function()
  if ui.pop:IsVisible() then ui.pop:Hide() else ui.pop:Show() end
end)
ui.gear:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:AddLine("Settings", 1, 0.82, 0)
  GameTooltip:Show()
end)
ui.gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
ui.pop:SetScript("OnHide", function() ui.menu:Hide() end)

ui.rot = IconButton("Interface\\AddOns\\LuckyOdds\\rotate")
ui.rot.tex:SetTexCoord(0, 1, 0, 1)
ui.rot:SetScript("OnClick", function()
  if not db then return end
  db.land = not db.land
  ui.Layout()
end)
ui.rot:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:AddLine("Layout", 1, 0.82, 0)
  GameTooltip:AddLine("Click: switch portrait / landscape", 1, 1, 1)
  GameTooltip:Show()
end)
ui.rot:SetScript("OnLeave", function() GameTooltip:Hide() end)

ui.menu = CreateFrame("Frame", nil, f)
ui.menu:SetWidth(108)
ui.menu:SetHeight(table.getn(LANGS) * 16 + 10)
ui.menu:SetFrameLevel(f:GetFrameLevel() + 12)
ui.menu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
ui.menu:SetBackdropColor(0.04, 0.04, 0.06, 1)
ui.menu:SetBackdropBorderColor(0.62, 0.52, 0.32, 1)
ui.menu:EnableMouse(true)
ui.menu:Hide()
ui.menuRows = {}
for i = 1, table.getn(LANGS) do
  local r = CreateFrame("Button", nil, ui.menu)
  r:SetWidth(98)
  r:SetHeight(16)
  r:SetFrameLevel(ui.menu:GetFrameLevel() + 1)
  r:SetPoint("TOPLEFT", ui.menu, "TOPLEFT", 5, -5 - (i - 1) * 16)
  r:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  r.key = LANGS[i][1]
  r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.text:SetPoint("LEFT", r, "LEFT", 6, 0)
  r.text:SetText(LANGS[i][2])
  ui.menuRows[i] = r
  r:SetScript("OnClick", function()
    db.lang = this.key
    ui.menu:Hide()
    ui.Layout()
  end)
end
ui.menu:SetScript("OnShow", function()
  for i = 1, table.getn(ui.menuRows) do
    local r = ui.menuRows[i]
    if r.key == db.lang then r.text:SetTextColor(0.35, 1, 0.35) else r.text:SetTextColor(1, 1, 1) end
  end
end)
ui.lang:SetScript("OnClick", function()
  if ui.menu:IsVisible() then ui.menu:Hide() else ui.menu:Show() end
end)
ui.menu:SetPoint("TOPLEFT", ui.lang, "BOTTOMLEFT", 0, -2)

-- the static words, in the chosen language
local function Relabel()
  if not db then return end
  for g = 1, 2 do
    local s = ""
    for i = 1, table.getn(GROUPS[g].keys) do s = s .. (i > 1 and " " or "") .. Tr(GROUPS[g].keys[i]) end
    ui.group[g].text:SetText(s)
  end
  for i = 1, 3 do ui.name[i]:SetText(Tr(RARITY[i].key)) end
  ui.luckLabel:SetText(Tr("luck"))
  ui.sel.text:SetText(Tr("sel") .. ": " .. (db.top and Tr("on") or Tr("off")))
  ui.lang.text:SetText(Tr("lang") .. ": " .. string.upper(db.lang))
end

-- puts every piece where the chosen layout wants it. Landscape is the portrait grid turned on
-- its side: rarities become columns, the two card groups become rows.
local function At(o, x, y, point)
  o:ClearAllPoints()
  o:SetPoint(point or "CENTER", f, "TOPLEFT", x, -y)
end

local luckFace = GameFontNormalLarge and GameFontNormalLarge:GetFont()

function ui.Layout()
  if not db then return end
  local land = db.land
  local w, h, hdr = 140, 210, 60
  local gx, gy, rx, ry, ny
  if land then
    w, h = 422, 84
    gx, gy = { 170, 170 }, { 20, 64 }      -- centre of each group's name (and its row of chances)
    rx, ny = { 222, 270, 318 }, 42         -- x of each rarity column; the names sit in the middle row
  else
    gx, gy = { 32, 108 }, { hdr + 20, hdr + 20 }
    rx, ry = { 70, 70, 70 }, { hdr + 56, hdr + 78, hdr + 100 }
  end
  f:SetWidth(w)
  f:SetHeight(h)
  ui.menu:Hide()
  ui.pop:Hide()

  for g = 1, 2 do
    At(ui.group[g].text, gx[g], gy[g] + (land and 4 or 0))
  end
  for i = 1, 3 do
    for g = 1, 2 do
      if land then At(ui.cell[g][i], rx[i], gy[g]) else At(ui.cell[g][i], gx[g], ry[i]) end
    end
    if land then At(ui.name[i], rx[i], ny) else At(ui.name[i], rx[i], ry[i]) end
  end

  ui.rule[1]:ClearAllPoints()
  ui.rule[2]:ClearAllPoints()
  ui.band:ClearAllPoints()
  local cx   -- the header's centre
  if land then
    ui.rule[1]:SetWidth(1) ui.rule[1]:SetHeight(h - 12) ui.rule[1]:SetPoint("TOPLEFT", f, "TOPLEFT", 136, -6)
    ui.rule[2]:SetWidth(1) ui.rule[2]:SetHeight(h - 12) ui.rule[2]:SetPoint("TOPLEFT", f, "TOPLEFT", 342, -6)
    ui.band:SetWidth(48) ui.band:SetHeight(h - 12) ui.band:SetPoint("TOPLEFT", f, "TOPLEFT", 246, -6)
    cx = 68
    At(ui.icon, 16, 17)
    At(ui.luckLabel, 28, 17, "LEFT")
    At(ui.luck, cx, 42)
    At(ui.level, cx, 67)
  else
    ui.rule[1]:SetWidth(w - 16) ui.rule[1]:SetHeight(1) ui.rule[1]:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -hdr)
    ui.rule[2]:SetWidth(w - 16) ui.rule[2]:SetHeight(1) ui.rule[2]:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -(hdr + 114))
    ui.band:SetWidth(w - 12) ui.band:SetHeight(22) ui.band:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -(hdr + 67))
    cx = w / 2
    At(ui.icon, 16, 15)
    At(ui.luckLabel, 28, 15, "LEFT")
    At(ui.luck, cx, 36)
    At(ui.level, cx, 51)
  end
  if luckFace then ui.luck:SetFont(luckFace, land and 26 or 20) end
  ui.level:SetWidth(land and 130 or 130)

  -- layout, chests, lairs and settings buttons: a row in portrait, two by two in landscape
  local btns = { ui.rot, ui.toggle[1], ui.toggle[2], ui.gear }
  local isz = land and 22 or 20
  for i = 1, 4 do
    local x, y = 70 + (i - 2.5) * 28, hdr + 130
    if land then x, y = 382 + (math.mod(i - 1, 2) - 0.5) * 30, 24 + math.floor((i - 1) / 2) * 36 end
    btns[i]:SetWidth(isz)
    btns[i]:SetHeight(isz)
    At(btns[i], x, y)
  end
  ui.pop:ClearAllPoints()
  ui.pop:SetPoint("TOPLEFT", ui.gear, "BOTTOMLEFT", 0, -2)
  Relabel()
end

local function Refresh()
  local luck = Luck()
  if not db.shown or not luck then f:Hide() return end
  f:Show()
  local lvl = LevelBonus()
  ui.luck:SetText("|cffffffff" .. math.floor(luck * 100 + 0.5) .. "%|r")
  ui.level:SetText("+" .. math.floor(lvl * 100 + 0.5) .. "% " .. Tr("level"))
  local k = 1 + luck + lvl
  for g = 1, 2 do
    local odds = Odds(k + GROUPS[g].bonus)
    for i = 1, 3 do
      local c = ui.cell[g][i]
      c:SetText(string.format("%.1f%%", odds[i]))
      -- a soft tint of the rarity colour, brighter the likelier it is
      local a = 0.55 + math.min(0.45, odds[i] / 40)
      c:SetTextColor(1 - (1 - RARITY[i].r) * 0.45 * a, 1 - (1 - RARITY[i].g) * 0.45 * a, 1 - (1 - RARITY[i].b) * 0.45 * a)
    end
  end
end

-- a hidden frame gets no OnUpdate, so the refresh runs on its own frame
local driver, wait = CreateFrame("Frame"), 0
driver:SetScript("OnUpdate", function()
  if not db then return end
  wait = wait + arg1
  if wait < 0.5 then return end
  wait = 0
  Refresh()
end)

-- game 0.126.0+: keep the panel over the level-up and new-item cards; /lucky top turns it off
local function ApplyTop()
  if AZS_SetOnTopOfScreens then AZS_SetOnTopOfScreens(f, db.top and true or false) end
  Relabel()
end
ui.sel:SetScript("OnClick", function()
  if not db then return end
  db.top = not db.top
  ApplyTop()
end)

driver:RegisterEvent("VARIABLES_LOADED")
driver:SetScript("OnEvent", function()
  if type(LuckyOddsDB) ~= "table" then LuckyOddsDB = { shown = true } end
  db = LuckyOddsDB
  if db.chests == nil then db.chests = true end
  if db.lairs == nil then db.lairs = true end
  if db.top == nil then db.top = true end
  if not L[db.lang] then db.lang = "en" end
  ApplyTop()
  f:ClearAllPoints()
  if db.point then
    f:SetPoint(db.point[1], UIParent, db.point[2], db.point[3], db.point[4])
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -230, -260)
  end
  ui.Layout()
end)
f:Hide()

-- ---------------------------------------------------------------- chests on the minimap
-- The game sends the hero's world position (AZS_RUN px/py) and every Battleground Cache's
-- (AZS_CHESTS x/y), both in yards: world x runs north, world y runs west. A pin sits on the
-- minimap for each chest in range; past the edge, an arrow points at the nearest one.
local PIN = 14
local ARROW = 24
-- outdoor minimap diameter in yards per zoom level (stock 1.12)
local ZOOM_YD = { [0] = 466.6667, 400, 333.3333, 266.6667, 200, 133.3333 }
local pins, lairPins, pinWait = {}, {}, 0
local LAIR_ICON = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

local function SquareMinimap()
  if type(GetMinimapShape) == "function" then
    local ok, shape = pcall(GetMinimapShape)
    if ok and shape then return shape == "SQUARE" end
  end
  return DFRL ~= nil   -- SurvivorsDragonUi's minimap is square
end

local function Tip(owner, title, dist)
  owner:EnableMouse(true)
  owner:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine(this.title or title, 1, 0.82, 0)
    if this.dist then GameTooltip:AddLine(math.floor(this.dist + 0.5) .. " yd away", 1, 1, 1) end
    GameTooltip:Show()
  end)
  owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function NewPin(i)
  local p = CreateFrame("Frame", nil, Minimap)
  p:SetWidth(PIN)
  p:SetHeight(PIN)
  p:SetFrameLevel(Minimap:GetFrameLevel() + 5)
  p.icon = p:CreateTexture(nil, "OVERLAY")
  p.icon:SetAllPoints(p)
  p.icon:SetTexture("Interface\\Icons\\INV_Box_02")
  p.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  Tip(p, "Battleground Cache")
  pins[i] = p
  return p
end

local arrow = CreateFrame("Frame", nil, Minimap)
arrow:SetWidth(ARROW)
arrow:SetHeight(ARROW)
arrow:SetFrameLevel(Minimap:GetFrameLevel() + 6)
arrow.tex = arrow:CreateTexture(nil, "OVERLAY")
arrow.tex:SetAllPoints(arrow)
arrow.tex:SetTexture("Interface\\Minimap\\MinimapArrow")
arrow.tex:SetVertexColor(1, 0.82, 0.2)
Tip(arrow, "Nearest Battleground Cache")
arrow:Hide()

-- turns the arrow clockwise by a radians (0 = north)
local function TurnArrow(a)
  local s, c = math.sin(-a), math.cos(-a)
  local function P(x, y)
    x, y = x - 0.5, y - 0.5
    return 0.5 + x * c - y * s, 0.5 + x * s + y * c
  end
  local ulx, uly = P(0, 0)
  local llx, lly = P(0, 1)
  local urx, ury = P(1, 0)
  local lrx, lry = P(1, 1)
  arrow.tex:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

-- a guardian's lair: a skull while the guardian is there (red while you fight it), the time
-- until it returns while the lair is empty
local function NewLair(i)
  local p = CreateFrame("Frame", nil, Minimap)
  p:SetWidth(PIN)
  p:SetHeight(PIN)
  p:SetFrameLevel(Minimap:GetFrameLevel() + 5)
  p.icon = p:CreateTexture(nil, "OVERLAY")
  p.icon:SetAllPoints(p)
  p.icon:SetTexture(LAIR_ICON)
  p.timer = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  p.timer:SetPoint("CENTER", p, "CENTER", 0, 0)
  Tip(p, "Guardian")
  lairPins[i] = p
  return p
end

-- the server sends a lair's countdown about once a second: count down in between
local function LairLeft(l)
  local left = tonumber(l.left) or -1
  if left > 0 and AZS_LAIRS_UPDATED then
    left = left - math.min(1.5, math.max(0, GetTime() - AZS_LAIRS_UPDATED))
    if left < 0 then left = 0 end
  end
  return left
end

local function Clock(sec)
  sec = math.ceil(sec)
  return math.floor(sec / 60) .. ":" .. string.format("%02d", math.mod(sec, 60))
end

local function HidePins()
  for i = 1, table.getn(pins) do pins[i]:Hide() end
  for i = 1, table.getn(lairPins) do lairPins[i]:Hide() end
  arrow:Hide()
end

-- places a minimap marker; false when it is past the minimap's edge
local function Place(frame, ox, oy, limit, square)
  local reach = square and math.max(math.abs(ox), math.abs(oy)) or math.sqrt(ox * ox + oy * oy)
  if reach > limit then return false end
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
  return true
end

local function UpdateLairs(hx, hy, scale, limit, square)
  local list = AZS_LAIRS
  local used = 0
  if db.lairs and type(list) == "table" then
    for i = 1, table.getn(list) do
      local l = list[i]
      local lx, ly = tonumber(l.x), tonumber(l.y)
      local up = (l.state == "asleep" or l.state == "awake")
      local left = LairLeft(l)
      if lx and ly and (up or left >= 0) then
        local north, east = lx - hx, hy - ly
        local p = lairPins[used + 1] or NewLair(used + 1)
        if Place(p, east * scale, north * scale, limit, square) then
          used = used + 1
          p.dist = math.sqrt(north * north + east * east)
          if up then
            p.icon:Show()
            p.timer:Hide()
            if l.state == "awake" then p.icon:SetVertexColor(1, 0.35, 0.35) else p.icon:SetVertexColor(1, 1, 1) end
            p.title = (l.name or "Guardian") .. (l.state == "awake" and " (fighting)" or " (asleep)")
          else
            p.icon:Hide()
            p.timer:SetText(left > 0 and Clock(left) or "due")
            if left > 0 then p.timer:SetTextColor(1, 0.55, 0.15) else p.timer:SetTextColor(1, 0.9, 0.2) end
            p.timer:Show()
            p.title = (l.name or "Guardian") .. (left > 0 and (" returns in " .. Clock(left)) or " is due")
          end
          p:Show()
        end
      end
    end
  end
  for i = used + 1, table.getn(lairPins) do lairPins[i]:Hide() end
end

local function UpdatePins()
  local run, list = AZS_RUN, AZS_CHESTS
  local hx = type(run) == "table" and tonumber(run.px)
  local hy = type(run) == "table" and tonumber(run.py)
  if not hx or not hy or not (AZS_GetPhase and AZS_GetPhase()) then
    HidePins()
    return
  end
  local width = Minimap:GetWidth() or 140
  local scale = width / (ZOOM_YD[Minimap:GetZoom() or 0] or 333.3333)   -- pixels per yard
  local limit = width / 2 - PIN / 2
  local square = SquareMinimap()
  UpdateLairs(hx, hy, scale, limit, square)
  local shown, nearest, nx, ny = 0, nil, 0, 0
  if not db.chests or type(list) ~= "table" then list = {} end
  for i = 1, table.getn(list) do
    local c = list[i]
    local cx, cy = tonumber(c.x), tonumber(c.y)
    if cx and cy then
      local north, east = cx - hx, hy - cy
      local dist = math.sqrt(north * north + east * east)
      local ox, oy = east * scale, north * scale
      local p = pins[shown + 1] or NewPin(shown + 1)
      if Place(p, ox, oy, limit, square) then
        shown = shown + 1
        p.dist = dist
        p:Show()
      elseif not nearest or dist < nearest then
        nearest, nx, ny = dist, ox, oy
      end
    end
  end
  for i = shown + 1, table.getn(pins) do pins[i]:Hide() end
  if shown == 0 and nearest then
    local a = math.atan2(nx, ny)   -- 0 = north, clockwise
    local dx, dy = math.sin(a), math.cos(a)
    local m = square and math.max(math.abs(dx), math.abs(dy)) or 1
    local edge = width / 2 - ARROW / 2
    TurnArrow(a)
    arrow.dist = nearest
    arrow:ClearAllPoints()
    arrow:SetPoint("CENTER", Minimap, "CENTER", dx / m * edge, dy / m * edge)
    arrow:Show()
  else
    arrow:Hide()
  end
end

local pinDriver = CreateFrame("Frame")
pinDriver:SetScript("OnUpdate", function()
  if not db then return end
  pinWait = pinWait + arg1
  if pinWait < 0.05 then return end
  pinWait = 0
  UpdatePins()
end)

-- ---------------------------------------------------------------- minimap button
-- click shows or hides the panel; drag moves the button around the minimap's rim
local function TogglePanel()
  db.shown = not db.shown
  local msg = db.shown and "panel shown." or "panel hidden."
  if db.shown and not Luck() then msg = "panel on; it shows once the game sends your luck (in a run)." end
  DEFAULT_CHAT_FRAME:AddMessage("|cffa335eeLuckyOdds|r: " .. msg)
  Refresh()
end

local btn = CreateFrame("Button", "LuckyOddsMinimapButton", Minimap)
btn:SetWidth(31)
btn:SetHeight(31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local btnIcon = btn:CreateTexture(nil, "BACKGROUND")
btnIcon:SetWidth(20)
btnIcon:SetHeight(20)
btnIcon:SetTexture("Interface\\Icons\\INV_Jewelry_Necklace_26")
btnIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
btnIcon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -5)
local btnRing = btn:CreateTexture(nil, "OVERLAY")
btnRing:SetWidth(53)
btnRing:SetHeight(53)
btnRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
btnRing:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

-- angle in degrees, 0 = east, counter-clockwise; on a square minimap it sits on the square's edge
local function PlaceButton()
  local a = math.rad(db.btnAngle or 255)
  local x, y = math.cos(a), math.sin(a)
  if SquareMinimap() then
    local m = math.max(math.abs(x), math.abs(y))
    x, y = x / m, y / m
  end
  local r = (Minimap:GetWidth() or 140) / 2 + 8
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", x * r, y * r)
end

btn:RegisterForClicks("LeftButtonUp")
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnClick", function() if db then TogglePanel() end end)
btn:SetScript("OnDragStart", function()
  this:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter()
    local s = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    db.btnAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
    PlaceButton()
  end)
end)
btn:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
btn:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:AddLine("LuckyOdds", 0.64, 0.21, 0.93)
  GameTooltip:AddLine("Click: show or hide the panel", 1, 1, 1)
  GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
  GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- registered after the driver, so db is set by the time this runs
btn:RegisterEvent("VARIABLES_LOADED")
btn:SetScript("OnEvent", PlaceButton)

-- ---------------------------------------------------------------- panel toggles
-- two small buttons in the panel's settings: chest and lair markers on or off
local say = "|cffa335eeLuckyOdds|r: "
local toggles = {}
ui.toggle = toggles

local function ToggleMarkers(key, what)
  db[key] = not db[key]
  DEFAULT_CHAT_FRAME:AddMessage(say .. what .. " on the minimap " .. (db[key] and "on." or "off."))
  UpdatePins()
  for i = 1, table.getn(toggles) do toggles[i].Style() end
end

local function NewToggle(key, what, iconPath)
  local b = IconButton(iconPath)
  local t = b.tex
  t:SetTexCoord(0, 1, 0, 1)
  b.Style = function()
    if not db then return end
    if db[key] then t:SetVertexColor(1, 1, 1) else t:SetVertexColor(0.35, 0.35, 0.35) end
  end
  b:SetScript("OnClick", function() if db then ToggleMarkers(key, what) end end)
  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine(what .. " on the minimap", 1, 0.82, 0)
    GameTooltip:AddLine(db and db[key] and "On. Click to hide." or "Off. Click to show.", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- registered after the driver, so db is set by the time this runs
  b:RegisterEvent("VARIABLES_LOADED")
  b:SetScript("OnEvent", b.Style)
  table.insert(toggles, b)
end
NewToggle("chests", "chests", "Interface\\AddOns\\LuckyOdds\\chest")
NewToggle("lairs", "guardian lairs", "Interface\\AddOns\\LuckyOdds\\skull")

-- ---------------------------------------------------------------- /lucky
SLASH_LUCKYODDS1 = "/lucky"
SlashCmdList["LUCKYODDS"] = function(msg)
  if not db then return end
  if string.lower(msg or "") == "lairs" then
    ToggleMarkers("lairs", "guardian lairs")
    return
  end
  if string.lower(msg or "") == "chests" then
    ToggleMarkers("chests", "chests")
    return
  end
  if string.lower(msg or "") == "top" then
    db.top = not db.top
    ApplyTop()
    DEFAULT_CHAT_FRAME:AddMessage(say .. "panel over the level-up cards " .. (db.top and "on." or "off (it stays under them)."))
    return
  end
  TogglePanel()
  DEFAULT_CHAT_FRAME:AddMessage(say .. "/lucky chests or /lucky lairs turn the minimap markers on or off, /lucky top keeps the panel over the level-up cards or not.")
end
