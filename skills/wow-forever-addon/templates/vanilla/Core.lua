local addonName, ns = ...
local DB_VERSION = 1
local defaults = { version = DB_VERSION, debug = false,
--@pattern:timer@
  interval = 5,
--@end-pattern@
}
local charDefaults = {
--@pattern:ui@
  point = { "CENTER", "UIParent", "CENTER", 0, 0 }, shown = true,
--@end-pattern@
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
  __NAME__DB = mergeDefaults(__NAME__DB or {}, defaults)
  __NAME__CharDB = mergeDefaults(__NAME__CharDB or {}, charDefaults)
  ns.db, ns.char = __NAME__DB, __NAME__CharDB
  ns.Migrate(ns.db, ns.db.version or 0)
  self:UnregisterEvent("ADDON_LOADED")
end

function f:PLAYER_LOGIN()
  ns.Debug("loaded")
--@pattern:timer@
  ns.ticker = C_Timer.NewTicker(ns.db.interval, function() ns.ticks = (ns.ticks or 0) + 1 end)
--@end-pattern@
--@pattern:ui@
  ns.CreateWindow()
--@end-pattern@
--@pattern:ldb@
  ns.CreateLauncher()
--@end-pattern@
end
--@pattern:event@

f:RegisterEvent("PLAYER_TARGET_CHANGED")
function f:PLAYER_TARGET_CHANGED()
  ns.Debug("target", UnitName("target") or "none")
end
--@end-pattern@
--@pattern:ui@

function ns.CreateWindow()
  if ns.window then return ns.window end
  local w = CreateFrame("Frame", addonName .. "Window", UIParent, "BackdropTemplate")
  w:SetSize(200, 80)
  local p = ns.char.point
  w:SetPoint(p[1], p[2], p[3], p[4], p[5])
  w:SetMovable(true)
  w:EnableMouse(true)
  w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart", w.StartMoving)
  w:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local a, _, r, x, y = self:GetPoint()
    ns.char.point = { a, "UIParent", r, x, y }
  end)
  w.text = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  w.text:SetPoint("CENTER")
  w.text:SetText(addonName)
  w:SetShown(ns.char.shown)
  ns.window = w
  return w
end
--@end-pattern@
--@pattern:ldb@

function ns.CreateLauncher()
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb then return end
  ns.launcher = ldb:NewDataObject(addonName, {
    type = "launcher",
    icon = 134400,
    OnClick = function() ns.Print("clicked") end,
  })
end
--@end-pattern@
--@pattern:tooltip@

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
  if tooltip ~= GameTooltip or not data or not data.id then return end
  ns.Debug("item tooltip", data.id)
end)
--@end-pattern@

local help = "commands: debug"
--@pattern:ui@
help = help .. ", show"
--@end-pattern@
SLASH___KEY__1 = "/__SLASH__"
SlashCmdList.__KEY__ = function(msg)
  local cmd = strtrim(msg or ""):lower()
  if cmd == "debug" then
    ns.db.debug = not ns.db.debug
    ns.Print("debug", ns.db.debug and "on" or "off")
--@pattern:ui@
  elseif cmd == "show" then
    ns.char.shown = not ns.char.shown
    ns.CreateWindow():SetShown(ns.char.shown)
--@end-pattern@
  else
    ns.Print(help)
  end
end
