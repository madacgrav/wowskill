-- LibStub registry plus minimal Ace3 stubs (AceAddon, AceEvent, AceConsole, AceDB, AceDBOptions, AceConfig,
-- AceConfigDialog). Enough for lifecycle, profile defaults, events and chat commands; not real Ace behaviour.
-- Known divergence: real AceDB strips defaults on logout; this stub keeps them in the saved tables.
local M = {}

local function fill(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      fill(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

function M.install(env, api)
  env.libs = {}
  local LibStub = setmetatable({}, { __call = function(_, major, silent)
    local l = env.libs[major]
    if not l and not silent then error("Cannot find a library instance of " .. tostring(major), 2) end
    return l
  end })
  function LibStub:NewLibrary() return nil end -- real libs never load offline; stubs are pre-registered
  function LibStub:GetLibrary(major, silent) return self(major, silent) end
  function LibStub:IterateLibraries() return pairs(env.libs) end
  api.LibStub = LibStub

  -- AceEvent-3.0 mixin: one hidden frame per object; handler = method name, function, or self[event]
  local AceEvent = {}
  function AceEvent:RegisterEvent(event, handler)
    local f = self._aceframe
    if not f then
      f = env.new_frame("Frame")
      f._handlers = {}
      f:SetScript("OnEvent", function(fr, e, ...) local h = fr._handlers[e]; if h then h(e, ...) end end)
      self._aceframe = f
    end
    local obj = self
    if type(handler) == "function" then
      f._handlers[event] = handler
    else
      local m = handler or event
      f._handlers[event] = function(...) obj[m](obj, ...) end
    end
    f:RegisterEvent(event)
  end
  function AceEvent:UnregisterEvent(event)
    local f = self._aceframe
    if f then f._handlers[event] = nil; f:UnregisterEvent(event) end
  end

  -- AceConsole-3.0 mixin
  local AceConsole = {}
  function AceConsole:RegisterChatCommand(cmd, handler)
    local key = "ACECONSOLE_" .. cmd:upper()
    rawset(env.G, "SLASH_" .. key .. "1", "/" .. cmd:lower())
    local obj = self
    api.SlashCmdList[key] = function(msg)
      if type(handler) == "string" then obj[handler](obj, msg) else handler(msg) end
    end
  end
  function AceConsole:Print(...) api.print(tostring(self.name or "") .. ":", ...) end

  -- AceAddon-3.0: OnInitialize on the next ADDON_LOADED, OnEnable on PLAYER_LOGIN
  local addons, initq, enableq = {}, {}, {}
  local AceAddon = {}
  function AceAddon:NewAddon(name, ...)
    local obj = { name = name }
    for i = 1, select("#", ...) do
      local lib = env.libs[(select(i, ...))]
      if lib and lib._mixin then for k, v in pairs(lib._mixin) do obj[k] = v end end
    end
    addons[name] = obj
    initq[#initq + 1] = obj
    return obj
  end
  function AceAddon:GetAddon(name, silent)
    if not addons[name] and not silent then error("Cannot find an AceAddon '" .. tostring(name) .. "'", 2) end
    return addons[name]
  end
  local lifecycle = env.new_frame("Frame")
  lifecycle:RegisterEvent("ADDON_LOADED")
  lifecycle:RegisterEvent("PLAYER_LOGIN")
  lifecycle:SetScript("OnEvent", function(_, e)
    if e == "ADDON_LOADED" then
      while #initq > 0 do
        local a = table.remove(initq, 1)
        if a.OnInitialize then a:OnInitialize() end
        enableq[#enableq + 1] = a
      end
    elseif e == "PLAYER_LOGIN" then
      for _, a in ipairs(enableq) do if a.OnEnable then a:OnEnable() end end
      enableq = {}
    end
  end)

  -- AceDB-3.0: profiles keyed by "<player> - <realm>", defaults filled into the active profile and global
  local AceDB = {}
  function AceDB:New(svname, defaults, defaultProfile)
    defaults = defaults or {}
    local sv = rawget(env.G, svname)
    if type(sv) ~= "table" then sv = {}; rawset(env.G, svname, sv) end
    sv.profileKeys = sv.profileKeys or {}
    sv.profiles = sv.profiles or {}
    local charKey = (api.UnitName("player")) .. " - " .. api.GetRealmName()
    local pname = sv.profileKeys[charKey]
      or (defaultProfile == true and "Default")
      or (type(defaultProfile) == "string" and defaultProfile)
      or charKey
    local db = { sv = sv }
    local function use(name)
      sv.profiles[name] = sv.profiles[name] or {}
      fill(sv.profiles[name], defaults.profile or {})
      sv.profileKeys[charKey] = name
      db.profile, db._pname = sv.profiles[name], name
    end
    use(pname)
    sv.global = sv.global or {}
    fill(sv.global, defaults.global or {})
    db.global = sv.global
    function db:SetProfile(name) use(name) end
    function db:GetCurrentProfile() return self._pname end
    function db:GetProfiles()
      local t = {}
      for k in pairs(sv.profiles) do t[#t + 1] = k end
      table.sort(t)
      return t, #t
    end
    function db:RegisterCallback() end
    return db
  end

  env.ace_options = {}
  env.libs["CallbackHandler-1.0"] = {}
  env.libs["AceGUI-3.0"] = {}
  env.libs["AceAddon-3.0"] = AceAddon
  env.libs["AceEvent-3.0"] = { _mixin = AceEvent }
  env.libs["AceConsole-3.0"] = { _mixin = AceConsole }
  env.libs["AceDB-3.0"] = AceDB
  env.libs["AceDBOptions-3.0"] = {
    GetOptionsTable = function() return { type = "group", name = "Profiles", args = {} } end,
  }
  env.libs["AceConfig-3.0"] = {
    RegisterOptionsTable = function(_, name, t) env.ace_options[name] = t end,
  }
  env.libs["AceConfigDialog-3.0"] = {
    AddToBlizOptions = function() return env.new_frame("Frame") end,
    Open = function(_, name) env.ace_opened = name end,
  }
end

return M
