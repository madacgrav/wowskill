-- Seeded-fault fixture: every numbered fault must be caught by lint.sh or test.sh.
local _, ns = ...

-- Fault 1: global leak (missing `local`), caught as W111
count = 0

-- Fault 2: never-emit Classic Era API, caught as NEVER-EMIT: UnitAura
function ns.HasBuff() return UnitAura("player", 1) ~= nil end

-- Fault 3: SavedVariables read at file scope (nil until ADDON_LOADED), caught at load in test.sh
local scale = BuggyDB.scale

-- Fault 4: OnUpdate doing work every frame with no time accumulator, caught as PERF: unthrottled OnUpdate
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function() ns.ticks = (ns.ticks or 0) + 1 end)

-- Fault 5: frame recreated on every event (frames are never freed), caught by the frame-count spec
local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE")
f:SetScript("OnEvent", function()
  ns.badge = CreateFrame("Frame", nil, UIParent)
  ns.scale = scale
end)
