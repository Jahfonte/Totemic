local ELEMENTS = { "Earth", "Fire", "Water", "Air" }
local DROPDOWN_WIDTH = 200
local FRAME_MIN_WIDTH = 400
local FRAME_MAX_WIDTH = 800
local FRAME_MIN_HEIGHT = 400
local FRAME_MAX_HEIGHT = 600
local FRAME_DEFAULT_WIDTH = 500
local FRAME_DEFAULT_HEIGHT = 450

local dropdownByElement = {}
local frameInitialized = false
local savedSetRows = {}
local scrollFrame = nil
local scrollChild = nil

-- Helper functions
local function setSize(frame, width, height)
  if not frame then return false end
  local success = pcall(function()
    frame:SetWidth(width)
    frame:SetHeight(height)
  end)
  return success
end

local function safeCreateFrame(frameType, name, parent, template)
  if not frameType then return nil end
  local success, frame = pcall(CreateFrame, frameType, name, parent, template)
  if not success or not frame then
    return nil
  end
  return frame
end

local function safeCreateFontString(parent, name, layer, template)
  if not parent then return nil end
  local success, fontString = pcall(function()
    return parent:CreateFontString(name, layer, template)
  end)
  if not success or not fontString then
    return nil
  end
  return fontString
end

local function safeCreateTexture(parent, name, layer)
  if not parent then return nil end
  local success, texture = pcall(function()
    return parent:CreateTexture(name, layer)
  end)
  if not success or not texture then
    return nil
  end
  return texture
end

local function assignDropdownText(frame, text)
  if not frame then return end
  local success, label = pcall(getglobal, frame:GetName() .. "Text")
  if success and label and label.SetText then
    pcall(function() label:SetText(text or "") end)
  end
end

local function setBackdrop(frame, bg, edge)
  if not frame or not frame.SetBackdrop then return end
  pcall(function()
    frame:SetBackdrop({
      bgFile = bg or "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = edge or "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
  end)
end

local function createButton(name, parent, width, height, text, onClick)
  local btn = safeCreateFrame("Button", name, parent, "UIPanelButtonTemplate")
  if not btn then return nil end

  setSize(btn, width, height)
  if text and btn.SetText then
    pcall(function() btn:SetText(text) end)
  end
  if onClick and btn.SetScript then
    pcall(function() btn:SetScript("OnClick", onClick) end)
  end

  if btn.SetScript then
    pcall(function()
      btn:SetScript("OnEnter", function()
        if this.tooltipText then
          GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
          GameTooltip:SetText(this.tooltipText, 1, 1, 1)
          GameTooltip:Show()
        end
      end)
      btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    end)
  end

  return btn
end

local function createDropdown(name, parent, width)
  local dropdown = safeCreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  if not dropdown then return nil end

  if UIDropDownMenu_SetWidth then
    pcall(UIDropDownMenu_SetWidth, width or DROPDOWN_WIDTH, dropdown)
  end

  assignDropdownText(dropdown, "Select Totem")
  return dropdown
end

local function setButtonTooltip(btn, text)
  if not btn or not text then return end
  btn.tooltipText = text
end

-- Create totem selection row
local function createElementRow(parent, index, element, yOffset)
  if not parent then return end

  local label = safeCreateFontString(parent, nil, "OVERLAY", "GameFontNormal")
  if label then
    pcall(function()
      label:SetPoint("TOPLEFT", 20, yOffset - (index - 1) * 40)
      label:SetText(element .. ":")
      label:SetWidth(50)
      label:SetJustifyH("LEFT")
    end)
  end

  local drop = createDropdown("Totemic" .. element .. "Drop", parent, DROPDOWN_WIDTH)
  if drop and label then
    pcall(function()
      drop:SetPoint("LEFT", label, "RIGHT", 10, 2)
    end)
    assignDropdownText(drop, "Select Totem")
    dropdownByElement[element] = drop
  end
end

-- Create saved set row
local function createSavedSetRow(parent, index)
  local row = safeCreateFrame("Frame", "TotemicSetRow" .. index, parent)
  if not row then return nil end

  setSize(row, 440, 28)
  row:Hide()

  -- Set name label
  local nameLabel = safeCreateFontString(row, nil, "OVERLAY", "GameFontNormal")
  if nameLabel then
    pcall(function()
      nameLabel:SetPoint("LEFT", 10, 0)
      nameLabel:SetWidth(250)
      nameLabel:SetJustifyH("LEFT")
      nameLabel:SetText("")
    end)
    row.nameLabel = nameLabel
  end

  -- Load button
  local loadBtn = createButton(nil, row, 60, 22, "Load", function()
    local setName = this:GetParent().setName
    if setName and Totemic_LoadSetByName then
      Totemic_LoadSetByName(setName, false)
    end
  end)
  if loadBtn then
    pcall(function()
      loadBtn:SetPoint("RIGHT", -75, 0)
    end)
    setButtonTooltip(loadBtn, "Load this totem set")
  end
  row.loadBtn = loadBtn

  -- Delete button
  local deleteBtn = createButton(nil, row, 60, 22, "Delete", function()
    local setName = this:GetParent().setName
    if setName and TotemicSetName then
      TotemicSetName:SetText(setName)
      if Totemic_DeleteSet then
        Totemic_DeleteSet()
      end
    end
  end)
  if deleteBtn then
    pcall(function()
      deleteBtn:SetPoint("RIGHT", -10, 0)
    end)
    setButtonTooltip(deleteBtn, "Delete this totem set")
  end
  row.deleteBtn = deleteBtn

  return row
end

-- Update saved sets list
local function updateSavedSetsList()
  local sets = Totemic_GetSets and Totemic_GetSets() or {}
  local names = {}
  for name, _ in pairs(sets) do
    table.insert(names, name)
  end
  table.sort(names)

  -- Hide all rows first
  for i = 1, 20 do
    if savedSetRows[i] then
      savedSetRows[i]:Hide()
    end
  end

  -- Show and update visible rows
  local yPos = -5
  for i = 1, table.getn(names) do
    if i > 20 then break end -- Max 20 sets

    local row = savedSetRows[i]
    if row then
      row.setName = names[i]
      if row.nameLabel then
        row.nameLabel:SetText(names[i])
      end
      pcall(function()
        row:SetPoint("TOPLEFT", 0, yPos)
      end)
      row:Show()
      yPos = yPos - 30
    end
  end

  -- Update scroll frame height
  if scrollChild then
    local height = math.max(150, table.getn(names) * 30 + 10)
    scrollChild:SetHeight(height)
  end
end

-- Main UI initialization
function Totemic_UI_Init()
  if TotemicFrame then return end
  if frameInitialized then return end

  local frame = safeCreateFrame("Frame", "TotemicFrame", UIParent)
  if not frame then return end

  frameInitialized = true

  -- Set frame properties
  setSize(frame, FRAME_DEFAULT_WIDTH, FRAME_DEFAULT_HEIGHT)
  pcall(function()
    frame:SetPoint("CENTER")
    frame:SetMinResize(FRAME_MIN_WIDTH, FRAME_MIN_HEIGHT)
    frame:SetMaxResize(FRAME_MAX_WIDTH, FRAME_MAX_HEIGHT)
  end)
  setBackdrop(frame)

  -- Make frame movable
  pcall(function()
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
      if not this.isResizing then
        this:StartMoving()
      end
    end)
    frame:SetScript("OnDragStop", function()
      this:StopMovingOrSizing()
      Totemic_SaveFramePosition()
    end)
    frame:SetScript("OnShow", Totemic_OnShow)
    frame:Hide()
  end)

  -- Create resize grip
  local resizeGrip = safeCreateFrame("Button", "TotemicResizeGrip", frame)
  if resizeGrip then
    setSize(resizeGrip, 16, 16)
    pcall(function()
      resizeGrip:SetPoint("BOTTOMRIGHT", -4, 4)
      resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
      resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
      resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
      resizeGrip:SetScript("OnMouseDown", function()
        frame.isResizing = true
        frame:StartSizing("BOTTOMRIGHT")
      end)
      resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        frame.isResizing = false
        Totemic_SaveFramePosition()
      end)
    end)
  end

  -- Cast button (top right)
  local castBtn = createButton("TotemicCastNowButton", frame, 80, 28, "Cast", Totemic_CastCurrent)
  if castBtn then
    pcall(function()
      castBtn:SetPoint("TOPRIGHT", -50, -10)
    end)
    setButtonTooltip(castBtn, "Cast currently selected totems")
  end

  -- Close button
  local close = createButton("TotemicCloseButton", frame, 32, 32, nil, Totemic_Toggle)
  if close then
    pcall(function()
      close:SetPoint("TOPRIGHT", -8, -8)
      close:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
      close:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
      close:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    end)
  end

  -- Title
  local title = safeCreateFontString(frame, "TotemicTitle", "OVERLAY", "GameFontHighlightLarge")
  if title then
    pcall(function()
      title:SetPoint("TOPLEFT", 20, -20)
      title:SetText("Totemic")
    end)
  end

  -- Subtitle
  local subtitle = safeCreateFontString(frame, "TotemicSubtitle", "OVERLAY", "GameFontNormalSmall")
  if subtitle and title then
    pcall(function()
      subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
      subtitle:SetText("Configure totem sets - macros update automatically")
    end)
  end

  -- Horizontal divider
  local divider1 = safeCreateTexture(frame, nil, "ARTWORK")
  if divider1 then
    pcall(function()
      divider1:SetTexture(0.3, 0.3, 0.3, 1)
      divider1:SetPoint("TOPLEFT", 15, -55)
      divider1:SetPoint("TOPRIGHT", -15, -55)
      divider1:SetHeight(1)
    end)
  end

  -- Totem selection area
  for i = 1, table.getn(ELEMENTS) do
    createElementRow(frame, i, ELEMENTS[i], -75)
  end

  -- Horizontal divider 2
  local divider2 = safeCreateTexture(frame, nil, "ARTWORK")
  if divider2 then
    pcall(function()
      divider2:SetTexture(0.3, 0.3, 0.3, 1)
      divider2:SetPoint("TOPLEFT", 15, -240)
      divider2:SetPoint("TOPRIGHT", -15, -240)
      divider2:SetHeight(1)
    end)
  end

  -- Save controls section
  local nameLabel = safeCreateFontString(frame, nil, "OVERLAY", "GameFontNormal")
  if nameLabel then
    pcall(function()
      nameLabel:SetPoint("TOPLEFT", 20, -255)
      nameLabel:SetText("Set Name:")
    end)
  end

  local nameBox = safeCreateFrame("EditBox", "TotemicSetName", frame, "InputBoxTemplate")
  if nameBox and nameLabel then
    pcall(function()
      nameBox:SetAutoFocus(false)
    end)
    setSize(nameBox, 200, 20)
    pcall(function()
      nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    end)
  end

  local saveBtn = createButton("TotemicSaveButton", frame, 80, 24, "Save Set", function()
    if Totemic_SaveSet then
      Totemic_SaveSet()
    end
    if Totemic_AutoCreateMacro then
      Totemic_AutoCreateMacro()
    end
    updateSavedSetsList()
  end)
  if saveBtn and nameBox then
    pcall(function()
      saveBtn:SetPoint("LEFT", nameBox, "RIGHT", 10, 1)
    end)
    setButtonTooltip(saveBtn, "Save current selection and create/update macro")
  end

  -- Horizontal divider 3
  local divider3 = safeCreateTexture(frame, nil, "ARTWORK")
  if divider3 then
    pcall(function()
      divider3:SetTexture(0.3, 0.3, 0.3, 1)
      divider3:SetPoint("TOPLEFT", 15, -285)
      divider3:SetPoint("TOPRIGHT", -15, -285)
      divider3:SetHeight(1)
    end)
  end

  -- Saved Sets section label
  local setsLabel = safeCreateFontString(frame, nil, "OVERLAY", "GameFontHighlight")
  if setsLabel then
    pcall(function()
      setsLabel:SetPoint("TOPLEFT", 20, -295)
      setsLabel:SetText("Saved Sets:")
    end)
  end

  -- Create scroll frame for saved sets
  scrollFrame = safeCreateFrame("ScrollFrame", "TotemicScrollFrame", frame, "UIPanelScrollFrameTemplate")
  if scrollFrame then
    setSize(scrollFrame, 460, 150)
    pcall(function()
      scrollFrame:SetPoint("TOPLEFT", 20, -315)
    end)

    -- Create scroll child
    scrollChild = safeCreateFrame("Frame", "TotemicScrollChild", scrollFrame)
    if scrollChild then
      setSize(scrollChild, 440, 150)
      scrollFrame:SetScrollChild(scrollChild)

      -- Create saved set rows
      for i = 1, 20 do
        savedSetRows[i] = createSavedSetRow(scrollChild, i)
      end
    end
  end

  -- Opacity slider
  local slider = safeCreateFrame("Slider", "TotemicAlphaSlider", frame, "OptionsSliderTemplate")
  if slider then
    pcall(function()
      slider:SetPoint("BOTTOM", 0, 55)
      slider:SetWidth(180)
      slider:SetMinMaxValues(0.2, 1.0)
      slider:SetValueStep(0.05)
      slider:SetScript("OnValueChanged", function()
        Totemic_AlphaSlider_OnValueChanged()
      end)
    end)
  end

  local alphaLabel = safeCreateFontString(frame, "TotemicAlphaValue", "OVERLAY", "GameFontNormalSmall")
  if alphaLabel and slider then
    pcall(function()
      alphaLabel:SetPoint("TOP", slider, "BOTTOM", 0, -2)
      alphaLabel:SetText("Opacity: 100%")
    end)
  end

  -- Help text at bottom
  local helpText = safeCreateFontString(frame, nil, "OVERLAY", "GameFontNormalSmall")
  if helpText then
    pcall(function()
      helpText:SetPoint("BOTTOM", 0, 20)
      helpText:SetText("Saving creates a macro you can bind in WoW keybindings")
      helpText:SetTextColor(0.7, 0.7, 0.7)
    end)
  end

  TotemicFrame = frame
  if Totemic_AlphaSlider_OnLoad then
    pcall(Totemic_AlphaSlider_OnLoad)
  end
end

local function ensureUI()
  if not TotemicFrame then Totemic_UI_Init() end
end

-- Build dropdown menus with totem options
function Totemic_UI_BuildDropdowns(known, current)
  ensureUI()
  if not known or type(known) ~= "table" then return end
  if not current or type(current) ~= "table" then return end

  for i = 1, table.getn(ELEMENTS) do
    local element = ELEMENTS[i]
    local frame = dropdownByElement[element]

    if frame and UIDropDownMenu_Initialize then
      pcall(function()
        UIDropDownMenu_Initialize(frame, function()
          local list = known[element]
          if not list or type(list) ~= "table" then
            list = {}
          end

          local noneInfo = {}
          noneInfo.text = "None"
          noneInfo.func = function()
            if Totemic_Select then
              Totemic_Select(element, nil)
            end
            assignDropdownText(frame, "None")
          end
          if UIDropDownMenu_AddButton then
            UIDropDownMenu_AddButton(noneInfo)
          end

          for j = 1, table.getn(list) do
            local spellName = list[j]
            if spellName and type(spellName) == "string" then
              local info = {}
              info.text = spellName
              info.func = function()
                if Totemic_Select then
                  Totemic_Select(element, spellName)
                end
                assignDropdownText(frame, spellName)
              end
              if UIDropDownMenu_AddButton then
                UIDropDownMenu_AddButton(info)
              end
            end
          end
        end)

        if UIDropDownMenu_SetWidth then
          UIDropDownMenu_SetWidth(DROPDOWN_WIDTH, frame)
        end

        local currentSpell = current[element]
        if currentSpell and type(currentSpell) == "string" and currentSpell ~= "" then
          assignDropdownText(frame, currentSpell)
        elseif currentSpell == nil or currentSpell == "" then
          assignDropdownText(frame, "None")
        else
          assignDropdownText(frame, "None")
        end
      end)
    end
  end
end

function Totemic_UI_RefreshDropdowns()
  Totemic_UI_BuildDropdowns(Totemic_GetKnownByElement(), Totemic_GetCurrentSelection())
end

function Totemic_UI_UpdateSets()
  ensureUI()
  updateSavedSetsList()
end

function Totemic_AlphaSlider_OnLoad()
  ensureUI()
  local slider = TotemicAlphaSlider
  if not slider then return end
  local low = getglobal(slider:GetName() .. "Low")
  local high = getglobal(slider:GetName() .. "High")
  local text = getglobal(slider:GetName() .. "Text")
  if low then low:SetText("20%") end
  if high then high:SetText("100%") end
  if text then text:SetText("Window Opacity") end
  slider:SetValueStep(0.05)
  local v = (TotemicDB and TotemicDB.options and TotemicDB.options.alpha) or 1
  slider:SetValue(v)
  Totemic_UI_UpdateAlphaLabel()
end

function Totemic_AlphaSlider_OnValueChanged()
  ensureUI()
  if not TotemicAlphaSlider then return end
  Totemic_UI_SetAlpha(TotemicAlphaSlider:GetValue())
end

function Totemic_OnLoad()
  ensureUI()
  local alpha = (TotemicDB and TotemicDB.options and TotemicDB.options.alpha) or 1
  TotemicFrame:SetAlpha(alpha)
  Totemic_UI_UpdateAlphaLabel()
end

function Totemic_UI_UpdateAlphaLabel()
  ensureUI()
  local alpha = (TotemicDB and TotemicDB.options and TotemicDB.options.alpha) or 1
  if TotemicAlphaValue then
    local pct = math.floor(alpha * 100 + 0.5)
    TotemicAlphaValue:SetText("Opacity: " .. pct .. "%")
  end
end

function Totemic_UI_UpdateActiveSet()
  ensureUI()
end