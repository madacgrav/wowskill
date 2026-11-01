-- GameTooltip, TooltipDataProcessor and C_Item stubs. opts.items[itemID] = { ilvl = n, name = s }.
local M = {}

function M.install(env, api)
  api.Enum = api.Enum or {}
  api.Enum.TooltipDataType = { Item = 0, Spell = 1, Unit = 2 }
  env.tooltip_calls = {}
  api.TooltipDataProcessor = {
    AddTooltipPostCall = function(t, fn)
      local l = env.tooltip_calls[t] or {}
      env.tooltip_calls[t] = l
      l[#l + 1] = fn
    end,
  }
  env.new_frame("GameTooltip", "GameTooltip")

  local function item(id) return env.opts.items and env.opts.items[id] end
  api.C_Item = {
    GetDetailedItemLevelInfo = function(id)
      local it = item(id)
      if it then return it.ilvl, nil, it.ilvl end
    end,
    GetItemInfo = function(id)
      local it = item(id)
      if it then return it.name end
    end,
  }

  -- Show an item tooltip: runs Item post-calls against GameTooltip and returns its lines.
  function env:show_item_tooltip(id)
    local tt = rawget(self.G, "GameTooltip")
    tt.lines = {}
    for _, fn in ipairs(self.tooltip_calls[api.Enum.TooltipDataType.Item] or {}) do
      fn(tt, { type = api.Enum.TooltipDataType.Item, id = id })
    end
    return tt.lines
  end
end

return M
