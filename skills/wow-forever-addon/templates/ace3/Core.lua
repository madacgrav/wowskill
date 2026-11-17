local addonName, ns = ...
local A = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
ns.addon = A

local defaults = { profile = { enabled = true, debug = false } }

function A:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("__NAME__DB", defaults, true)
  ns.SetupOptions(self)
  self:RegisterChatCommand("__SLASH__", "ChatCommand")
end

function A:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function A:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
  if self.db.profile.debug then self:Print(event, isLogin, isReload) end
end

function A:ChatCommand(input)
  input = strtrim(input or ""):lower()
  if input == "debug" then
    self.db.profile.debug = not self.db.profile.debug
    self:Print("debug", self.db.profile.debug and "on" or "off")
  else
    LibStub("AceConfigDialog-3.0"):Open(addonName)
  end
end
