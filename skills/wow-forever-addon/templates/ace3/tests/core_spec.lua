local wowmock = require("wowmock")

describe("__NAME__ (Ace3)", function()
  local env, ns
  before_each(function()
    env = wowmock.new_env()
    ns = env:load_addon(ADDON_DIR)
  end)

  it("runs OnInitialize with AceDB defaults", function()
    assert.truthy(ns.addon.db)
    assert.equals(true, env:saved().__NAME__DB.profiles.Default.enabled)
  end)

  it("slash debug toggles and persists across reload", function()
    env:slash("/__SLASH__ debug")
    assert.equals(true, ns.addon.db.profile.debug)
    local _, ns2 = env:reload()
    assert.equals(true, ns2.addon.db.profile.debug)
  end)

  it("registers events in OnEnable", function()
    assert.truthy(ns.addon._aceframe:IsEventRegistered("PLAYER_ENTERING_WORLD"))
  end)

  it("bare slash command opens the options panel", function()
    env:slash("/__SLASH__")
    assert.equals("__NAME__", env.ace_opened)
  end)
end)
