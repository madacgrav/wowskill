-- Lint fixture: valid Forever code. Must pass scripts/lint.sh.
local addonName, ns = ...

local f = CreateFrame("Frame", nil, UIParent)
f:RegisterEvent("BAG_UPDATE")
f:SetScript("OnEvent", function(_, _, bag)
  local info = C_Container.GetContainerItemInfo(bag, 1)
  if info then ns.lastStack = info.stackCount end
end)

C_Timer.After(1, function() print(addonName, "ready") end)
