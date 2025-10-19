local function ensureOpts()
  if not TotemicDB or type(TotemicDB) ~= "table" then
    TotemicDB = {}
  end
  if not TotemicDB.options or type(TotemicDB.options) ~= "table" then
    TotemicDB.options = {}
  end
  if not TotemicDB.options.minimap or type(TotemicDB.options.minimap) ~= "table" then
    TotemicDB.options.minimap = {}
  end
  if type(TotemicDB.options.minimap.angle) ~= "number" then
    TotemicDB.options.minimap.angle = 45
  end
end

local btn = CreateFrame("Button", "TotemicMinimapButton", Minimap)
btn:SetWidth(31)
btn:SetHeight(31)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)
btn:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
btn:RegisterForClicks("AnyUp")
btn:RegisterForDrag("LeftButton")

local overlay = btn:CreateTexture(nil, "OVERLAY")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

local icon = btn:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Spell_Nature_StoneClawTotem")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", btn, "CENTER", 0, 0)

local function updatePos()
  ensureOpts()
  local a = TotemicDB.options.minimap.angle
  local radius = 80
  local x = math.cos(math.rad(a)) * radius
  local y = math.sin(math.rad(a)) * radius
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

btn:SetScript("OnDragStart", function()
  btn.wasDragging = nil
  btn.isDragging = true
  btn:SetScript("OnUpdate", function()
    ensureOpts()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale
    local dx = cx - mx
    local dy = cy - my
    local ang
    if math.atan2 then
      ang = math.deg(math.atan2(dy, dx))
    else
      if dx == 0 and dy == 0 then
        ang = TotemicDB.options.minimap.angle or 45
      else
        local a
        if dx == 0 then
          if dy > 0 then a = math.pi/2 elseif dy < 0 then a = -math.pi/2 else a = 0 end
        else
          a = math.atan(dy/dx)
          if dx < 0 then if dy >= 0 then a = a + math.pi else a = a - math.pi end end
        end
        ang = math.deg(a)
      end
    end
    local angle = ang
    if angle < 0 then angle = angle + 360 end
    TotemicDB.options.minimap.angle = angle
    updatePos()
  end)
end)

btn:SetScript("OnDragStop", function()
  btn:SetScript("OnUpdate", nil)
  btn.isDragging = nil
  btn.wasDragging = true
  updatePos()
end)

btn:SetScript("OnMouseUp", function()
  if this.isDragging then return end
  if this.wasDragging then this.wasDragging = nil return end
  local button = arg1 or "LeftButton"
  if button == "LeftButton" then
    if Totemic_Toggle then
      Totemic_Toggle()
    else
      if TotemicFrame then
        if TotemicFrame:IsShown() then
          TotemicFrame:Hide()
        else
          TotemicFrame:Show()
        end
      end
    end
  end
end)

btn:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:SetText("Totemic", 1, 1, 1)
  GameTooltip:AddLine("Left-click: Toggle", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end)

btn:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  ensureOpts()
  updatePos()
end)
