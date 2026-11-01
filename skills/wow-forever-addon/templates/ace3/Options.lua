local addonName, ns = ...

function ns.SetupOptions(addon)
  local options = {
    name = addonName,
    type = "group",
    args = {
      enabled = {
        type = "toggle", name = "Enabled", order = 1,
        get = function() return addon.db.profile.enabled end,
        set = function(_, v) addon.db.profile.enabled = v end,
      },
      debug = {
        type = "toggle", name = "Debug output", order = 2,
        get = function() return addon.db.profile.debug end,
        set = function(_, v) addon.db.profile.debug = v end,
      },
    },
  }
  options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
  addon.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end
