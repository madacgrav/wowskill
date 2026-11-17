-- Expected to FAIL against the seeded faults in Core.lua (check.sh asserts the failures).
local wowmock = require("wowmock")

describe("Buggy", function()
  it("loads without reading SavedVariables at file scope", function()
    local env = wowmock.new_env()
    env:load_addon(ADDON_DIR)
  end)

  it("does not create frames per event", function()
    local env = wowmock.new_env({ saved = { BuggyDB = { scale = 1 } } })
    -- the file-scope SV read only succeeds when BuggyDB is pre-seeded as a global
    rawset(env.G, "BuggyDB", { scale = 1 })
    env:load_addon(ADDON_DIR)
    local before = #env.frames
    for _ = 1, 50 do env:fire("BAG_UPDATE", 0) end
    assert(#env.frames - before <= 1, ("frame count grew by %d over 50 events"):format(#env.frames - before))
  end)
end)
