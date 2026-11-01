-- Event registration and dispatch: env:fire(event, ...) and env:update(elapsed) for OnUpdate.
local M = {}

function M.install(env)
  env.handlers = {}

  function env:_register(frame, e)
    local l = self.handlers[e]
    if not l then l = {}; self.handlers[e] = l end
    if not frame._events[e] then
      frame._events[e] = true
      l[#l + 1] = frame
    end
  end

  function env:_unregister(frame, e)
    frame._events[e] = nil
    local l = self.handlers[e]
    if not l then return end
    for i = #l, 1, -1 do if l[i] == frame then table.remove(l, i) end end
  end

  -- Deliver an event to every registered frame's OnEvent script, in registration order.
  function env:fire(event, ...)
    local l = self.handlers[event]
    if not l then return end
    local copy = {}
    for i, f in ipairs(l) do copy[i] = f end
    for _, f in ipairs(copy) do
      if f._events[event] then
        local s = f._scripts.OnEvent
        if s then s(f, event, ...) end
      end
    end
  end

  -- Run one OnUpdate tick on every shown frame that has an OnUpdate script.
  function env:update(elapsed)
    for _, f in ipairs(self.frames) do
      local s = f._scripts.OnUpdate
      if s and f._shown then s(f, elapsed) end
    end
  end
end

return M
