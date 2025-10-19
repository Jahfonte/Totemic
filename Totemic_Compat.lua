Totemic_Compat = {}

local S_SUB = (string and string.sub) or strsub
local S_LEN = (string and string.len) or strlen
local S_FIND = (string and string.find) or strfind
local S_GSUB = (string and string.gsub) or gsub
local S_LOWER = (string and string.lower) or strlower
local S_UPPER = (string and string.upper) or strupper

function Totemic_Compat.TableLength(t)
  if not t then return 0 end
  return table.getn(t)
end

function Totemic_Compat.SafeGetGlobal(name)
  if not name then return nil end
  return getglobal(name)
end

function Totemic_Compat.SafeSetGlobal(name, value)
  if not name then return end
  setglobal(name, value)
end

function Totemic_Compat.StringSub(s, i, j)
  if not s then return "" end
  return S_SUB(s, i, j)
end

function Totemic_Compat.StringLen(s)
  if not s then return 0 end
  return S_LEN(s)
end

function Totemic_Compat.StringFind(s, pattern, init, plain)
  if not s or not pattern then return nil end
  return S_FIND(s, pattern, init, plain)
end

function Totemic_Compat.StringGsub(s, pattern, repl)
  if not s then return "" end
  return S_GSUB(s, pattern, repl)
end

function Totemic_Compat.StringLower(s)
  if not s then return "" end
  return S_LOWER(s)
end

function Totemic_Compat.StringUpper(s)
  if not s then return "" end
  return S_UPPER(s)
end

function Totemic_Compat.Trim(s)
  if not s then return "" end
  local trimmed = S_GSUB(s, "^%s*(.-)%s*$", "%1")
  return trimmed
end

function Totemic_Compat.TableContains(t, value)
  if not t then return false end
  for i = 1, table.getn(t) do
    if t[i] == value then return true end
  end
  return false
end

function Totemic_Compat.TableCopy(t)
  if not t then return {} end
  local copy = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      copy[k] = Totemic_Compat.TableCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

function Totemic_Compat.SafePairs(t)
  if not t or type(t) ~= "table" then
    return function() return nil end
  end
  return pairs(t)
end

function Totemic_Compat.SafeNext(t, k)
  if not t or type(t) ~= "table" then
    return nil
  end
  return next(t, k)
end

function Totemic_Compat.TryCatch(fn, errHandler)
  local success, result = pcall(fn)
  if not success then
    if errHandler then
      errHandler(result)
    end
    return nil, result
  end
  return result, nil
end
