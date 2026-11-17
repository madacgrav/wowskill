-- Unit and realm queries. opts.player_name overrides the player; opts.units[unit] = name adds others.
local M = {}

function M.install(env, api)
  local function units() return env.opts.units or {} end
  api.UnitName = function(u)
    if u == "player" then return env.opts.player_name or "Tester", nil end
    return units()[u], nil
  end
  api.UnitClass = function(u)
    if u == "player" then return "Warlock", "WARLOCK", 9 end
  end
  api.UnitLevel = function(u) if u == "player" or units()[u] then return 60 end end
  api.UnitGUID = function(u) if u == "player" then return "Player-0-00000001" end end
  api.UnitExists = function(u) return u == "player" or units()[u] ~= nil end
  api.GetRealmName = function() return "Mockrealm" end
end

return M
