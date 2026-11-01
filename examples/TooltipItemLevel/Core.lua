local addonName, ns = ...
local DB_VERSION = 1
local defaults = { version = DB_VERSION, debug = false,
}
local charDefaults = {
}

local f = CreateFrame("Frame")
ns.frame = f
f:SetScript("OnEvent", function(self, event, ...) local h = self[event]; if h then h(self, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

function ns.Print(...) print("|cff33ff99" .. addonName .. "|r:", ...) end
function ns.Debug(...) if ns.db and ns.db.debug then ns.Print("[debug]", ...) end end

local function mergeDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      mergeDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end
ns.mergeDefaults = mergeDefaults

-- Migrations: add `if from < N then ... end` steps here and bump DB_VERSION.
function ns.Migrate(db, from)
  db.version = DB_VERSION
end

function f:ADDON_LOADED(name)
  if name ~= addonName then return end
  TooltipItemLevelDB = mergeDefaults(TooltipItemLevelDB or {}, defaults)
  TooltipItemLevelCharDB = mergeDefaults(TooltipItemLevelCharDB or {}, charDefaults)
  ns.db, ns.char = TooltipItemLevelDB, TooltipItemLevelCharDB
  ns.Migrate(ns.db, ns.db.version or 0)
  self:UnregisterEvent("ADDON_LOADED")
end

function f:PLAYER_LOGIN()
  ns.Debug("loaded")
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
  if tooltip ~= GameTooltip or not data or not data.id then return end
  local ilvl = C_Item.GetDetailedItemLevelInfo(data.id)
  if ilvl then tooltip:AddLine(("Item Level: %d"):format(ilvl), 1, 1, 1) end
  ns.Debug("item tooltip", data.id, ilvl)
end)

local help = "commands: debug"
SLASH_TOOLTIPITEMLEVEL1 = "/tooltipitemlevel"
SlashCmdList.TOOLTIPITEMLEVEL = function(msg)
  local cmd = strtrim(msg or ""):lower()
  if cmd == "debug" then
    ns.db.debug = not ns.db.debug
    ns.Print("debug", ns.db.debug and "on" or "off")
  else
    ns.Print(help)
  end
end
