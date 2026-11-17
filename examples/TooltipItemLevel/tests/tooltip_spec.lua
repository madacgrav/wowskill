local wowmock = require("wowmock")

describe("TooltipItemLevel tooltip", function()
  local env
  before_each(function()
    env = wowmock.new_env({ items = { [19019] = { ilvl = 80, name = "Thunderfury" } } })
    env:load_addon(ADDON_DIR)
  end)

  it("adds the item level line for a known item", function()
    local lines = env:show_item_tooltip(19019)
    assert.equals("Item Level: 80", lines[1])
  end)

  it("adds nothing when the item level is unknown", function()
    local lines = env:show_item_tooltip(1)
    assert.equals(0, #lines)
  end)
end)
