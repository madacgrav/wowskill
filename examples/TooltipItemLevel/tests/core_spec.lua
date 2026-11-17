local wowmock = require("wowmock")

describe("TooltipItemLevel", function()
  local env, ns
  before_each(function()
    env = wowmock.new_env()
    ns = env:load_addon(ADDON_DIR)
  end)

  it("loads and applies defaults", function()
    assert.truthy(ns.db)
    assert.equals(false, ns.db.debug)
    assert.equals(1, ns.db.version)
  end)

  it("slash debug toggles and persists across reload", function()
    env:slash("/tooltipitemlevel debug")
    assert.equals(true, ns.db.debug)
    local _, ns2 = env:reload()
    assert.equals(true, ns2.db.debug)
  end)
end)
