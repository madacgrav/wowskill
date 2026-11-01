local wowmock = require("wowmock")

describe("__NAME__", function()
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
    env:slash("/__SLASH__ debug")
    assert.equals(true, ns.db.debug)
    local _, ns2 = env:reload()
    assert.equals(true, ns2.db.debug)
  end)
--@pattern:timer@

  it("ticker fires on interval", function()
    env:advance(ns.db.interval * 3 + 0.1)
    assert.equals(3, ns.ticks)
  end)
--@end-pattern@
--@pattern:ui@

  it("window toggles", function()
    assert.equals(true, ns.window:IsShown())
    env:slash("/__SLASH__ show")
    assert.equals(false, ns.window:IsShown())
  end)
--@end-pattern@
end)
