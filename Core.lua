local addonName = "Totemic"
Totemic = {}
local BOOKTYPE_SPELL = BOOKTYPE_SPELL or "spell"

local initQueue = {}
local isFullyLoaded = false

function Totemic_QueueInit(fn)
  if isFullyLoaded then
    fn()
  else
    table.insert(initQueue, fn)
  end
end

function Totemic_ProcessInitQueue()
  isFullyLoaded = true
  for i = 1, table.getn(initQueue) do
    initQueue[i]()
  end
  initQueue = {}
end

local S_SUB = (string and string.sub) or (strsub)
local S_LEN = (string and string.len) or (strlen)
local S_FIND = (string and string.find) or (strfind)
local S_GSUB = (string and string.gsub) or (gsub)
local S_LOWER = (string and string.lower) or (strlower)

local debugMode = false

local function safeCall(fn, ...)
  if not fn then return nil end
  local args = {...}
  local success, result = pcall(fn, unpack(args))
  if not success then
    if debugMode then
      DEFAULT_CHAT_FRAME:AddMessage("Totemic Error: " .. tostring(result), 1, 0.5, 0.5)
    end
    return nil
  end
  return result
end

local function safeCastSpell(name)
  if not name or type(name) ~= "string" then return false end
  local success = pcall(CastSpellByName, name)
  return success
end

local function safeFrameCall(frame, method, ...)
  if not frame or not frame[method] then return nil end
  local args = {...}
  local success, result = pcall(frame[method], frame, unpack(args))
  if not success then
    if debugMode then
      DEFAULT_CHAT_FRAME:AddMessage("Totemic Frame Error: " .. tostring(result), 1, 0.5, 0.5)
    end
    return nil
  end
  return result
end

BINDING_HEADER_TOTEMIC = "Totemic"
BINDING_NAME_TOTEMIC_TOGGLE = "Toggle Totemic Window"
TOTEMIC_TOGGLE_DESC = "Toggle the Totemic window"
BINDING_NAME_TOTEMIC_CAST_CURRENT = "Cast Current Totem Set"
TOTEMIC_CAST_DESC = "Cast the currently active totem set"

local elements = { "Earth", "Fire", "Water", "Air" }
local elementOrder = { Earth = 1, Fire = 2, Water = 3, Air = 4 }

local mapSpellToElement = {
  ["Strength of Earth Totem"] = "Earth",
  ["Stoneskin Totem"] = "Earth",
  ["Tremor Totem"] = "Earth",
  ["Earthbind Totem"] = "Earth",
  ["Stoneclaw Totem"] = "Earth",

  ["Searing Totem"] = "Fire",
  ["Magma Totem"] = "Fire",
  ["Fire Nova Totem"] = "Fire",
  ["Flametongue Totem"] = "Fire",
  ["Frost Resistance Totem"] = "Fire",

  ["Healing Stream Totem"] = "Water",
  ["Mana Spring Totem"] = "Water",
  ["Poison Cleansing Totem"] = "Water",
  ["Disease Cleansing Totem"] = "Water",
  ["Fire Resistance Totem"] = "Water",

  ["Windfury Totem"] = "Air",
  ["Grace of Air Totem"] = "Air",
  ["Tranquil Air Totem"] = "Air",
  ["Grounding Totem"] = "Air",
  ["Windwall Totem"] = "Air",
  ["Nature Resistance Totem"] = "Air",
  ["Sentry Totem"] = "Air",
}

local knownByElement = { Earth = {}, Fire = {}, Water = {}, Air = {} }
local currentSelection = { Earth = nil, Fire = nil, Water = nil, Air = nil }
local currentSetName = nil

local function normalizeSet(set)
  local s = { Earth = set.Earth or nil, Fire = set.Fire or nil, Water = set.Water or nil, Air = set.Air or nil }
  return s
end

local function unitKey()
  local name = UnitName("player") or ""
  local realm = GetCVar and GetCVar("realmName") or GetRealmName and GetRealmName() or ""
  return name .. "-" .. realm
end

local function ensureDB()
  if not TotemicDB or type(TotemicDB) ~= "table" then
    TotemicDB = {}
  end
  if not TotemicDB.sets or type(TotemicDB.sets) ~= "table" then
    TotemicDB.sets = {}
  end
  if not TotemicDB.options or type(TotemicDB.options) ~= "table" then
    TotemicDB.options = {}
  end
  if not TotemicDB.version then
    TotemicDB.version = 1
  end

  local key = unitKey()
  if not key or key == "-" then
    key = "default"
  end

  if not TotemicDB.sets[key] or type(TotemicDB.sets[key]) ~= "table" then
    TotemicDB.sets[key] = {}
  end

  if type(TotemicDB.options.alpha) ~= "number" or TotemicDB.options.alpha < 0.2 or TotemicDB.options.alpha > 1.0 then
    TotemicDB.options.alpha = 1.0
  end

  if not TotemicDB.options.frame or type(TotemicDB.options.frame) ~= "table" then
    TotemicDB.options.frame = {}
  end

  if not TotemicDB.options.minimap or type(TotemicDB.options.minimap) ~= "table" then
    TotemicDB.options.minimap = {}
  end
end

local spellScanCache = nil
local spellScanCacheTime = 0
local SPELL_CACHE_TTL = 30

local function isTotemSpell(name)
  if not name or type(name) ~= "string" then return false end
  if S_FIND(name, "Totem") then return true end
  return false
end

local function collectKnownTotems()
  local now = GetTime and GetTime() or 0
  if spellScanCache and (now - spellScanCacheTime) < SPELL_CACHE_TTL then
    knownByElement = spellScanCache
    return
  end

  knownByElement = { Earth = {}, Fire = {}, Water = {}, Air = {} }
  local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0

  for t = 1, tabs do
    local _, _, offset, numSpells = GetSpellTabInfo(t)
    if offset and numSpells then
      for i = offset + 1, offset + numSpells do
        local success, name = pcall(function()
          if GetSpellName then
            return GetSpellName(i, BOOKTYPE_SPELL)
          elseif GetSpellBookItemName then
            return GetSpellBookItemName(i, BOOKTYPE_SPELL)
          end
          return nil
        end)

        if success and name and isTotemSpell(name) then
          local el = mapSpellToElement[name]
          if el and knownByElement[el] then
            local found = false
            for j = 1, table.getn(knownByElement[el]) do
              if knownByElement[el][j] == name then
                found = true
                break
              end
            end
            if not found then
              table.insert(knownByElement[el], name)
            end
          end
        end
      end
    end
  end

  for i = 1, table.getn(elements) do
    local el = elements[i]
    table.sort(knownByElement[el])
  end

  spellScanCache = {
    Earth = {},
    Fire = {},
    Water = {},
    Air = {}
  }
  for i = 1, table.getn(elements) do
    local el = elements[i]
    for j = 1, table.getn(knownByElement[el]) do
      table.insert(spellScanCache[el], knownByElement[el][j])
    end
  end
  spellScanCacheTime = now
end

local function setCurrentSelectionFromSet(set)
  currentSelection.Earth = set and set.Earth or nil
  currentSelection.Fire = set and set.Fire or nil
  currentSelection.Water = set and set.Water or nil
  currentSelection.Air = set and set.Air or nil
end

local function castSpellByNameIfKnown(name)
  if not name or type(name) ~= "string" or name == "" then return false end
  return safeCastSpell(name)
end

function Totemic_CastCurrent()
  castSpellByNameIfKnown(currentSelection.Earth)
  castSpellByNameIfKnown(currentSelection.Fire)
  castSpellByNameIfKnown(currentSelection.Water)
  castSpellByNameIfKnown(currentSelection.Air)
end

local function getSetsTable()
  ensureDB()
  return TotemicDB.sets[unitKey()]
end

function Totemic_SaveSet()
  ensureDB()
  if not TotemicSetName then return end
  local name = TotemicSetName:GetText()
  if not name or name == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Please enter a set name", 1, 0.5, 0.5)
    return
  end
  local sets = getSetsTable()
  sets[name] = normalizeSet(currentSelection)
  currentSetName = name
  Totemic_UI_UpdateSets()
  DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set '" .. name .. "' saved", 0.5, 1, 0.5)
end

function Totemic_DeleteSet()
  ensureDB()
  if not TotemicSetName then return end
  local name = TotemicSetName:GetText()
  if not name or name == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Please enter a set name to delete", 1, 0.5, 0.5)
    return
  end
  local sets = getSetsTable()
  if not sets[name] then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set '" .. name .. "' not found", 1, 0.5, 0.5)
    return
  end

  sets[name] = nil
  if currentSetName == name then currentSetName = nil end

  local macroName = S_SUB(name, 1, 16)
  local macroIndex = GetMacroIndexByName(macroName)
  if macroIndex and macroIndex > 0 then
    DeleteMacro(macroIndex)
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set and macro '" .. name .. "' deleted", 0.5, 1, 0.5)
  else
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set '" .. name .. "' deleted", 0.5, 1, 0.5)
  end

  Totemic_UI_UpdateSets()
end

function Totemic_AutoCreateMacro()
  local name = currentSetName or (TotemicSetName and TotemicSetName:GetText())
  if not name or name == "" then return end

  local sets = getSetsTable()
  local set = sets[name]
  if not set then return end

  local macroBody = ""
  if set.Earth and set.Earth ~= "" then
    macroBody = macroBody .. "/cast " .. set.Earth .. "\n"
  end
  if set.Fire and set.Fire ~= "" then
    macroBody = macroBody .. "/cast " .. set.Fire .. "\n"
  end
  if set.Water and set.Water ~= "" then
    macroBody = macroBody .. "/cast " .. set.Water .. "\n"
  end
  if set.Air and set.Air ~= "" then
    macroBody = macroBody .. "/cast " .. set.Air .. "\n"
  end

  if macroBody == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: No totems selected for macro", 1, 0.5, 0.5)
    return
  end

  local macroName = S_SUB(name, 1, 16)
  local numGlobalMacros, numCharMacros = GetNumMacros()
  local maxMacros = 18

  local macroIndex = GetMacroIndexByName(macroName)

  if macroIndex and macroIndex > 0 then
    EditMacro(macroIndex, macroName, 1, macroBody)
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Macro '" .. macroName .. "' updated - bind in ESC > Keybindings", 0.5, 1, 0.5)
  else
    if numCharMacros >= maxMacros then
      DEFAULT_CHAT_FRAME:AddMessage("Totemic: Macro slots full (18/18) - delete unused macros", 1, 0.5, 0.5)
      return
    end

    CreateMacro(macroName, 1, macroBody, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Macro '" .. macroName .. "' created - bind in ESC > Keybindings > General", 0.5, 1, 0.5)
  end
end

function Totemic_CreateMacro()
  Totemic_AutoCreateMacro()
end

function Totemic_OnShow()
  if Totemic_UI_Init then Totemic_UI_Init() end
  if TotemicFrame then
    TotemicFrame:SetAlpha(TotemicDB and TotemicDB.options and TotemicDB.options.alpha or 1)
  end
  Totemic_ApplyFramePosition()
  Totemic_UI_BuildDropdowns(knownByElement, currentSelection)
  Totemic_UI_UpdateSets()
  if TotemicSetName then
    if currentSetName then TotemicSetName:SetText(currentSetName) else TotemicSetName:SetText("") end
  end
  if Totemic_UI_UpdateAlphaLabel then Totemic_UI_UpdateAlphaLabel() end
end

function Totemic_Toggle()
  if Totemic_UI_Init then Totemic_UI_Init() end
  if TotemicFrame then
    if TotemicFrame:IsShown() then TotemicFrame:Hide() else TotemicFrame:Show() end
  end
end

local function printHelp()
  DEFAULT_CHAT_FRAME:AddMessage("Totemic Commands:", 1, 1, 0.5)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic - Toggle UI", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic show - Show UI", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic hide - Hide UI", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic cast [setname] - Cast totems", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic reset - Reset window position", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic debug [on|off] - Toggle debug mode", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic reload - Reload spell cache", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic list - List saved sets", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic export [setname] - Export set data", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic import <name> <data> - Import set", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic test - Run self-tests", 0.8, 0.8, 0.8)
  DEFAULT_CHAT_FRAME:AddMessage("  /totemic help - Show this help", 0.8, 0.8, 0.8)
end

SLASH_TOTEMIC1 = "/totemic"
SlashCmdList = SlashCmdList or {}
SlashCmdList["TOTEMIC"] = function(msg)
  local m = msg
  if type(m) ~= "string" then m = "" end
  m = S_GSUB and S_GSUB(m, "^%s+", "") or m
  local sp = S_FIND and S_FIND(m, "%s")
  local cmd, rest
  if sp then
    cmd = S_SUB and S_SUB(m, 1, sp - 1) or m
    rest = S_SUB and S_SUB(m, sp + 1) or ""
  else
    cmd = m
    rest = ""
  end
  cmd = S_LOWER and S_LOWER(cmd) or cmd

  if cmd == nil or cmd == "" then
    Totemic_Toggle()
    return
  end

  if cmd == "cast" then
    local name = rest and (S_GSUB and S_GSUB(rest, "^%s*(.-)%s*$", "%1") or rest) or nil
    if name and name ~= "" then
      local set = getSetsTable()[name]
      if set then
        setCurrentSelectionFromSet(set)
        Totemic_CastCurrent()
        currentSetName = name
        if TotemicSetName then TotemicSetName:SetText(name) end
        Totemic_UI_UpdateActiveSet()
      else
        DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set '" .. name .. "' not found", 1, 0.5, 0.5)
      end
    else
      Totemic_CastCurrent()
    end
  elseif cmd == "show" then
    if Totemic_UI_Init then Totemic_UI_Init() end
    if TotemicFrame then TotemicFrame:Show() end
  elseif cmd == "hide" then
    if TotemicFrame then TotemicFrame:Hide() end
  elseif cmd == "resetpos" or cmd == "reset" then
    Totemic_ResetFramePosition()
    if TotemicFrame then TotemicFrame:Show() end
  elseif cmd == "debug" then
    local arg = rest and S_LOWER(S_GSUB(rest, "^%s*(.-)%s*$", "%1")) or ""
    if arg == "on" or arg == "true" or arg == "1" then
      Totemic_SetDebugMode(true)
    elseif arg == "off" or arg == "false" or arg == "0" then
      Totemic_SetDebugMode(false)
    else
      Totemic_SetDebugMode(not debugMode)
    end
  elseif cmd == "reload" or cmd == "refresh" then
    Totemic_InvalidateCache()
  elseif cmd == "list" then
    local sets = getSetsTable()
    local count = 0
    DEFAULT_CHAT_FRAME:AddMessage("Totemic Saved Sets:", 1, 1, 0.5)
    for name, _ in pairs(sets) do
      count = count + 1
      DEFAULT_CHAT_FRAME:AddMessage("  " .. name, 0.8, 0.8, 0.8)
    end
    if count == 0 then
      DEFAULT_CHAT_FRAME:AddMessage("  (none)", 0.6, 0.6, 0.6)
    end
  elseif cmd == "export" then
    local setName = rest and S_GSUB(rest, "^%s*(.-)%s*$", "%1") or ""
    Totemic_ExportSet(setName)
  elseif cmd == "import" then
    local importRest = rest and S_GSUB(rest, "^%s+", "") or ""
    local firstSpace = S_FIND(importRest, "%s")
    if firstSpace then
      local importName = S_SUB(importRest, 1, firstSpace - 1)
      local importData = S_SUB(importRest, firstSpace + 1)
      importData = S_GSUB(importData, "^%s*(.-)%s*$", "%1")
      Totemic_ImportSet(importName, importData)
    else
      DEFAULT_CHAT_FRAME:AddMessage("Totemic: Usage: /totemic import <name> <data>", 1, 0.5, 0.5)
    end
  elseif cmd == "test" or cmd == "selftest" then
    Totemic_SelfTest()
  elseif cmd == "help" or cmd == "?" then
    printHelp()
  else
    Totemic_Toggle()
  end
end

local eventFrame = nil
local registeredEvents = {}

local function registerEvent(event)
  if not eventFrame then return end
  if not registeredEvents[event] then
    eventFrame:RegisterEvent(event)
    registeredEvents[event] = true
  end
end

local function unregisterEvent(event)
  if not eventFrame then return end
  if registeredEvents[event] then
    eventFrame:UnregisterEvent(event)
    registeredEvents[event] = nil
  end
end

local function handleEvent(event)
  if event == "PLAYER_LOGIN" then
    ensureDB()
    safeCall(Totemic_UI_Init)
    safeCall(Totemic_OnLoad)
    collectKnownTotems()

    DEFAULT_CHAT_FRAME:AddMessage("Totemic 0.1.0 Loaded!", 0.5, 1, 0.5)

    if TotemicDB.options.wasShown and TotemicFrame then
      safeFrameCall(TotemicFrame, "Show")
    end

    Totemic_ProcessInitQueue()
  elseif event == "LEARNED_SPELL_IN_TAB" then
    spellScanCache = nil
    collectKnownTotems()
    if TotemicFrame and TotemicFrame:IsShown() then
      safeCall(Totemic_UI_BuildDropdowns, knownByElement, currentSelection)
    end
  elseif event == "PLAYER_LOGOUT" then
    ensureDB()
    if TotemicFrame then
      TotemicDB.options.wasShown = TotemicFrame:IsShown() and true or false
    end
  end
end

eventFrame = CreateFrame("Frame", "TotemicEventFrame")
eventFrame:SetScript("OnEvent", function(self, eventName, ...)
  if eventName then
    handleEvent(eventName)
  end
end)

registerEvent("PLAYER_LOGIN")
registerEvent("LEARNED_SPELL_IN_TAB")
registerEvent("PLAYER_LOGOUT")

function Totemic_Select(element, spellName)
  currentSelection[element] = spellName
  currentSetName = nil
  Totemic_UI_UpdateActiveSet()
end

function Totemic_GetKnownByElement()
  return knownByElement
end

function Totemic_GetCurrentSelection()
  return currentSelection
end

function Totemic_GetSets()
  return getSetsTable()
end

function Totemic_UI_SetAlpha(v)
  ensureDB()
  if Totemic_UI_Init then Totemic_UI_Init() end
  TotemicDB.options.alpha = v
  if TotemicFrame then TotemicFrame:SetAlpha(v) end
  if Totemic_UI_UpdateAlphaLabel then Totemic_UI_UpdateAlphaLabel() end
end

function Totemic_GetCurrentSetName()
  return currentSetName
end

function Totemic_SaveFramePosition()
  ensureDB()
  if not TotemicFrame then return end
  local p, rel, rp, x, y = TotemicFrame:GetPoint()
  TotemicDB.options.frame.point = p
  TotemicDB.options.frame.relPoint = rp
  TotemicDB.options.frame.x = x
  TotemicDB.options.frame.y = y
  TotemicDB.options.frame.width = TotemicFrame:GetWidth()
  TotemicDB.options.frame.height = TotemicFrame:GetHeight()
end

function Totemic_ApplyFramePosition()
  ensureDB()
  if not TotemicFrame then return end
  local o = TotemicDB.options.frame
  if o and o.point and o.relPoint and o.x and o.y then
    TotemicFrame:ClearAllPoints()
    TotemicFrame:SetPoint(o.point, UIParent, o.relPoint, o.x, o.y)
  else
    TotemicFrame:ClearAllPoints()
    TotemicFrame:SetPoint("CENTER")
  end

  if o and o.width and o.height then
    TotemicFrame:SetWidth(o.width)
    TotemicFrame:SetHeight(o.height)
  end
end

function Totemic_ResetFramePosition()
  ensureDB()
  TotemicDB.options.frame = {}
  Totemic_ApplyFramePosition()
end

function Totemic_LoadSetByName(name, doCast)
  local sets = getSetsTable()
  local set = sets[name]
  if not set then return end
  currentSetName = name
  setCurrentSelectionFromSet(set)
  Totemic_UI_RefreshDropdowns()
  if TotemicSetName then TotemicSetName:SetText(name) end
  Totemic_UI_UpdateActiveSet()
  if doCast then Totemic_CastCurrent() end
end

function Totemic_SetDebugMode(enabled)
  debugMode = enabled and true or false
end

function Totemic_GetDebugMode()
  return debugMode
end

function Totemic_InvalidateCache()
  spellScanCache = nil
  spellScanCacheTime = 0
  collectKnownTotems()
  if TotemicFrame and TotemicFrame:IsShown() then
    Totemic_UI_BuildDropdowns(knownByElement, currentSelection)
  end
end

local function serializeSet(set)
  if not set or type(set) ~= "table" then return "" end
  local parts = {}
  for i = 1, table.getn(elements) do
    local el = elements[i]
    local spell = set[el]
    if spell and type(spell) == "string" then
      table.insert(parts, el .. ":" .. spell)
    end
  end
  return table.concat(parts, "|")
end

local function deserializeSet(str)
  if not str or type(str) ~= "string" or str == "" then return nil end
  local set = {}
  local pos = 1
  while pos <= S_LEN(str) do
    local pipePos = S_FIND(str, "|", pos, true)
    local segment
    if pipePos then
      segment = S_SUB(str, pos, pipePos - 1)
      pos = pipePos + 1
    else
      segment = S_SUB(str, pos)
      pos = S_LEN(str) + 1
    end

    if segment and segment ~= "" then
      local colonPos = S_FIND(segment, ":", 1, true)
      if colonPos then
        local el = S_SUB(segment, 1, colonPos - 1)
        local spell = S_SUB(segment, colonPos + 1)
        if el and spell and (el == "Earth" or el == "Fire" or el == "Water" or el == "Air") then
          set[el] = spell
        end
      end
    end
  end
  return set
end

function Totemic_ExportSet(name)
  if not name or name == "" then
    name = currentSetName
  end
  if not name or name == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: No set specified for export", 1, 0.5, 0.5)
    return
  end

  local sets = getSetsTable()
  local set = sets[name]
  if not set then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set '" .. name .. "' not found", 1, 0.5, 0.5)
    return
  end

  local encoded = serializeSet(set)
  if encoded and encoded ~= "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic Export: " .. name, 0.5, 1, 0.5)
    DEFAULT_CHAT_FRAME:AddMessage(encoded, 1, 1, 0.5)
    return encoded
  end
end

function Totemic_ImportSet(name, data)
  if not name or name == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Set name required for import", 1, 0.5, 0.5)
    return false
  end
  if not data or data == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Import data required", 1, 0.5, 0.5)
    return false
  end

  local set = deserializeSet(data)
  if not set then
    DEFAULT_CHAT_FRAME:AddMessage("Totemic: Invalid import data", 1, 0.5, 0.5)
    return false
  end

  ensureDB()
  local sets = getSetsTable()
  sets[name] = normalizeSet(set)

  if Totemic_UI_UpdateSets then
    Totemic_UI_UpdateSets()
  end
  return true
end

function Totemic_SelfTest()
  local passed = 0
  local failed = 0
  local total = 0

  local function test(name, fn)
    total = total + 1
    local success, result = pcall(fn)
    if success and result then
      passed = passed + 1
      if debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("  [PASS] " .. name, 0.5, 1, 0.5)
      end
      return true
    else
      failed = failed + 1
      DEFAULT_CHAT_FRAME:AddMessage("  [FAIL] " .. name, 1, 0.5, 0.5)
      return false
    end
  end

  DEFAULT_CHAT_FRAME:AddMessage("Totemic Self-Test Starting...", 1, 1, 0.5)

  test("DB initialization", function()
    ensureDB()
    return TotemicDB and TotemicDB.sets and TotemicDB.options
  end)

  test("Unit key generation", function()
    local key = unitKey()
    return key and type(key) == "string" and key ~= ""
  end)

  test("Set normalization", function()
    local testSet = { Earth = "Test", Fire = nil, Water = "Test2", Air = nil }
    local normalized = normalizeSet(testSet)
    return normalized and normalized.Earth == "Test" and normalized.Water == "Test2"
  end)

  test("Serialization roundtrip", function()
    local original = { Earth = "Strength of Earth Totem", Fire = "Searing Totem", Water = nil, Air = "Windfury Totem" }
    local serialized = serializeSet(original)
    local deserialized = deserializeSet(serialized)
    return deserialized and deserialized.Earth == original.Earth and deserialized.Fire == original.Fire and deserialized.Air == original.Air
  end)

  test("Totem spell detection", function()
    return isTotemSpell("Searing Totem") and isTotemSpell("Strength of Earth Totem") and not isTotemSpell("Lightning Bolt")
  end)

  test("Element mapping", function()
    return mapSpellToElement["Searing Totem"] == "Fire" and mapSpellToElement["Strength of Earth Totem"] == "Earth"
  end)

  test("Safe spell cast", function()
    return safeCastSpell("Invalid Spell Name") ~= nil
  end)

  test("Compat layer exists", function()
    return Totemic_Compat and Totemic_Compat.TableLength and Totemic_Compat.StringSub
  end)

  test("Event registration", function()
    return eventFrame and registeredEvents["PLAYER_LOGIN"]
  end)

  test("Global functions exist", function()
    return Totemic_Toggle and Totemic_CastCurrent and Totemic_SaveSet and Totemic_DeleteSet and Totemic_ExportSet and Totemic_ImportSet
  end)

  DEFAULT_CHAT_FRAME:AddMessage("Totemic Self-Test Complete:", 1, 1, 0.5)
  DEFAULT_CHAT_FRAME:AddMessage("  Passed: " .. passed .. "/" .. total, 0.5, 1, 0.5)
  if failed > 0 then
    DEFAULT_CHAT_FRAME:AddMessage("  Failed: " .. failed .. "/" .. total, 1, 0.5, 0.5)
  end

  return failed == 0
end

function Totemic_ValidateAPI()
  local required = {
    "Totemic_Toggle",
    "Totemic_CastCurrent",
    "Totemic_SaveSet",
    "Totemic_DeleteSet",
    "Totemic_UI_Init",
    "Totemic_GetKnownByElement",
    "Totemic_GetCurrentSelection"
  }

  for i = 1, table.getn(required) do
    if not _G[required[i]] then
      DEFAULT_CHAT_FRAME:AddMessage("Totemic Error: Missing function " .. required[i], 1, 0, 0)
      return false
    end
  end
  return true
end
