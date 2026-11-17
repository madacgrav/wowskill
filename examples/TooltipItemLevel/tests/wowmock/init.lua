-- wowmock: a minimal offline WoW API environment for testing addons under LuaJIT / Lua 5.1.
-- Covers frames, events, C_Timer, units, slash commands, SavedVariables, tooltips and LibStub.
-- Does NOT cover taint, secure frames, rendering, secret values or real library behaviour.
local M = {}
local Env = {}
Env.__index = Env
M.Env = Env

local STD = { "assert", "error", "ipairs", "next", "pairs", "pcall", "xpcall", "select", "tonumber", "tostring",
  "type", "unpack", "rawget", "rawset", "rawequal", "setmetatable", "getmetatable", "string", "table", "math",
  "bit", "date", "time", "coroutine" }

local function deepcopy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = deepcopy(x) end
  return t
end
M.deepcopy = deepcopy

-- opts: saved (SV name -> table), login (false to skip PLAYER_LOGIN), player_name, units, items, in_combat
function M.new_env(opts)
  opts = opts or {}
  local self = setmetatable({ opts = opts, output = {}, saved_in = deepcopy(opts.saved or {}), sv_names = {} }, Env)
  local api = {}
  for _, k in ipairs(STD) do api[k] = _G[k] end
  api.print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
    self.output[#self.output + 1] = table.concat(t, " ")
  end
  self.api = api
  self.G = setmetatable({}, { __index = api })
  rawset(self.G, "_G", self.G)
  for _, m in ipairs({ "luaext", "frames", "events", "timer", "unit", "slash", "tooltip", "ace" }) do
    require("wowmock." .. m).install(self, api)
  end
  return self
end

-- Load <dir>/<name>.toc: run each file with (addonName, ns), then SavedVariables, then ADDON_LOADED
-- (and PLAYER_LOGIN + PLAYER_ENTERING_WORLD unless opts.login == false). Returns the addon namespace.
function Env:load_addon(dir)
  local toc = require("wowmock.toc").parse(dir)
  local ns = {}
  for _, path in ipairs(toc.files) do
    local chunk, err = loadfile(path)
    if not chunk then error("wowmock: " .. err, 2) end
    setfenv(chunk, self.G)
    chunk(toc.name, ns)
  end
  for _, field in ipairs({ "SavedVariables", "SavedVariablesPerCharacter" }) do
    for sv in (toc.fields[field] or ""):gmatch("[%w_]+") do
      self.sv_names[#self.sv_names + 1] = sv
      rawset(self.G, sv, deepcopy(self.saved_in[sv]))
    end
  end
  self.addon_dir, self.ns, self.toc = dir, ns, toc
  self:fire("ADDON_LOADED", toc.name)
  if self.opts.login ~= false then
    self:fire("PLAYER_LOGIN")
    self:fire("PLAYER_ENTERING_WORLD", true, false)
  end
  return ns
end

-- Snapshot of the addon's SavedVariables as they would be written on logout.
function Env:saved()
  local t = {}
  for _, n in ipairs(self.sv_names) do t[n] = deepcopy(rawget(self.G, n)) end
  return t
end

-- Simulate /reload: a fresh env with the current SavedVariables, addon loaded again. Returns env, ns.
function Env:reload()
  local o = {}
  for k, v in pairs(self.opts) do o[k] = v end
  o.saved = self:saved()
  local e = M.new_env(o)
  return e, e:load_addon(self.addon_dir)
end

return M
