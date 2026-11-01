# Performance

Read this before using `OnUpdate`, polling, or work that runs on frequent events, and when a performance review is requested.

## Prefer events over polling

- Find an event for the change in `forever-api-index.md#events` (`UNIT_POWER_UPDATE`, `BAG_UPDATE_DELAYED`, …) before reaching for `OnUpdate`.
- For periodic work, use `C_Timer.NewTicker(interval, fn)`. It's cheaper than an `OnUpdate` you throttle by hand, and easy to `:Cancel()`.

## If you must use OnUpdate: throttle it

`OnUpdate` runs every frame (60+ times a second). `lint.sh` warns `PERF: unthrottled OnUpdate` when a file sets one without an elapsed accumulator.

```lua
local THROTTLE, elapsed = 0.1, 0
frame:SetScript("OnUpdate", function(self, dt)
  elapsed = elapsed + dt
  if elapsed < THROTTLE then return end
  elapsed = 0
  -- work
end)
```

Hide the frame (or `SetScript("OnUpdate", nil)`) when there's nothing to do. Hidden frames don't get `OnUpdate`.

## Allocation and lookups

- **Reuse tables:** `wipe(t)` instead of `t = {}` in hot paths. Garbage from per-event tables causes collection stutter.
- **Create frames once.** Never call `CreateFrame` inside an event handler or update loop. Create lazily once, then `Show`/`Hide`. Frames are never garbage collected.
- **Cache upvalues** for hot globals: `local GetTime, C_UnitAuras = GetTime, C_UnitAuras` at file top.
- **Coalesce bursty events:** for example `BAG_UPDATE` (per bag) → `BAG_UPDATE_DELAYED`, or debounce with `C_Timer.After(0, ...)` and a pending flag.
- **Item and spell data** may not be cached. Handle nil and wait for `GET_ITEM_INFO_RECEIVED` rather than retrying in a loop.

## Profiling commands (in-game)

All names verified in `forever-api-index.md` (global functions, 2026-11-01):

- **CPU:** set `/console scriptProfile 1`, then `/reload` (profiling has its own overhead, so turn it off afterwards). Then `/run UpdateAddOnCPUUsage(); print(GetAddOnCPUUsage("MyAddon"))` gives milliseconds since reset.
- **Memory:** `/run UpdateAddOnMemoryUsage(); print(GetAddOnMemoryUsage("MyAddon"))` gives KB.
- **Timing a block:** `local t = debugprofilestop(); ...; print(debugprofilestop() - t)` gives milliseconds.
- In tests, `env:update(elapsed)` drives `OnUpdate` offline. Count calls or work done to assert throttling.

## Performance review checklist

- [ ] No unthrottled `OnUpdate`; tickers are cancelled when idle.
- [ ] No `CreateFrame` in handlers or loops (frame count stable across repeated events).
- [ ] Hot paths don't allocate tables per call.
- [ ] Bursty events are coalesced.
- [ ] CPU and memory measured in-game before and after the change, with numbers reported.
