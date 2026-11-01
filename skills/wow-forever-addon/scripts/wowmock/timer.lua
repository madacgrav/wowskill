-- C_Timer and GetTime driven by a manual clock: env:advance(seconds).
local M = {}

function M.install(env, api)
  env.now, env.timers = 0, {}

  -- left: remaining runs (nil = forever)
  local function schedule(delay, fn, left)
    local h = { due = env.now + delay, delay = math.max(delay, 0.001), fn = fn, left = left, cancelled = false }
    function h:Cancel() self.cancelled = true end
    function h:IsCancelled() return self.cancelled end
    env.timers[#env.timers + 1] = h
    return h
  end

  api.C_Timer = {
    After = function(d, fn) schedule(d, fn, 1) end,
    NewTimer = function(d, fn) return schedule(d, fn, 1) end,
    NewTicker = function(d, fn, n) return schedule(d, fn, n) end,
  }
  api.GetTime = function() return env.now end

  -- Advance the clock, running due timers in time order (tickers reschedule).
  function env:advance(dt)
    local target = self.now + dt
    while true do
      local best, bi
      for i, h in ipairs(self.timers) do
        if not h.cancelled and h.due <= target and (not best or h.due < best.due) then best, bi = h, i end
      end
      if not best then break end
      self.now = best.due
      if best.left then best.left = best.left - 1 end
      if best.left == 0 then table.remove(self.timers, bi) else best.due = best.due + best.delay end
      best.fn(best)
    end
    self.now = target
  end
end

return M
