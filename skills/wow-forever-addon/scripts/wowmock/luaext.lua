-- WoW's Lua extensions and small global helpers.
local M = {}

local function class(chars) return "[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]" end

local function strsplit(sep, s, n)
  local t, start, cls = {}, 1, class(sep)
  while true do
    if n and #t == n - 1 then t[#t + 1] = s:sub(start); break end
    local a, b = s:find(cls, start)
    if not a then t[#t + 1] = s:sub(start); break end
    t[#t + 1] = s:sub(start, a - 1)
    start = b + 1
  end
  return unpack(t)
end

local function strtrim(s, chars)
  local c = class(chars or " \t\r\n")
  return (s:gsub("^" .. c .. "+", ""):gsub(c .. "+$", ""))
end

local function deepcopy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = deepcopy(x) end
  return t
end

function M.install(env, api)
  api.strsplit, api.strtrim = strsplit, strtrim
  api.strjoin = function(sep, ...) return table.concat({ ... }, sep) end
  api.strlower, api.strupper, api.strlen, api.strsub = string.lower, string.upper, string.len, string.sub
  api.strfind, api.strmatch, api.strrep, api.strbyte, api.strchar = string.find, string.match, string.rep, string.byte, string.char
  api.gsub, api.format = string.gsub, string.format
  api.tinsert, api.tremove, api.sort = table.insert, table.remove, table.sort
  api.floor, api.ceil, api.abs, api.max, api.min, api.sqrt = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt
  api.random = math.random
  api.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  api.tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
  api.CopyTable = deepcopy
  api.Mixin = function(obj, ...)
    for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do obj[k] = v end end
    return obj
  end
  api.CreateFromMixins = function(...) return api.Mixin({}, ...) end
  api.hooksecurefunc = function(tbl, name, fn)
    if type(tbl) == "string" then tbl, name, fn = env.G, tbl, name end
    local orig = tbl[name]
    tbl[name] = function(...)
      local r = { orig(...) }
      fn(...)
      return unpack(r)
    end
  end
  api.securecall = function(fn, ...)
    if type(fn) == "string" then fn = env.G[fn] end
    return fn(...)
  end
  api.InCombatLockdown = function() return env.opts.in_combat == true end
  api.GetBuildInfo = function() return "1.60.1", "70532", "Oct 22 2026", 16001 end
  api.GetLocale = function() return "enUS" end
  api.debugstack = function() return debug.traceback() end
  api.geterrorhandler = function() return error end
end

return M
