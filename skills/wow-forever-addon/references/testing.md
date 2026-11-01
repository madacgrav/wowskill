# Offline testing with wowmock

Read this before writing or running addon tests. Every scaffolded addon ships `tests/core_spec.lua`, a vendored copy of the mock in `tests/wowmock/`, and `tests/run.sh`. Run the tests with `tests/run.sh` or `<skill>/scripts/test.sh <addon-dir>`. Both need only `luajit`.

## Writing a spec

Specs are `tests/*_spec.lua`, in a busted style:

```lua
local wowmock = require("wowmock")
describe("MyAddon", function()
  local env, ns
  before_each(function()
    env = wowmock.new_env({ items = { [19019] = { ilvl = 80 } } })
    ns = env:load_addon(ADDON_DIR)        -- ADDON_DIR is set by the runner
  end)
  it("does the thing", function()
    env:slash("/myaddon debug")
    assert.equals(true, ns.db.debug)
  end)
end)
```

Assertions: `assert(v)`, `assert.equals(expected, actual)`, `assert.same(t1, t2)` (deep), `assert.truthy`, `assert.falsy`, `assert.matches(pattern, s)`, `assert.errors(fn, pattern?)`.

## Harness API

| Call | Effect |
|---|---|
| `wowmock.new_env(opts)` | Fresh sandboxed `_G`. `opts`: `saved` (SV name → table), `login = false` (skip `PLAYER_LOGIN`), `player_name`, `units` (unit → name), `items` (itemID → `{ilvl, name}`), `in_combat` |
| `env:load_addon(dir)` | Parses `<dir>/<dir>.toc` (and XML includes), runs each file with `(addonName, ns)`, loads SVs, fires `ADDON_LOADED`, then `PLAYER_LOGIN` and `PLAYER_ENTERING_WORLD(true, false)`. Returns `ns`. |
| `env:fire(event, ...)` | Delivers an event to registered frames' `OnEvent`. |
| `env:advance(seconds)` | Moves the clock, running due `C_Timer` callbacks and tickers in time order. `GetTime()` follows it. |
| `env:update(elapsed)` | One `OnUpdate` tick on every shown frame. |
| `env:slash("/cmd args")` | Resolves `SLASH_<KEY>N` and calls `SlashCmdList[KEY]("args")`. |
| `env:saved()` | The SV tables as they would be written on logout. |
| `env:reload()` | Returns `env2, ns2`: a fresh env loaded with the current SVs, like `/reload`. |
| `env:show_item_tooltip(itemID)` | Runs the `TooltipDataProcessor` Item post-calls on `GameTooltip` and returns its lines. |
| `env.frames`, `env.output` | Every frame created (regions excluded), and every `print` line. |

## When a stub is missing

An unimplemented frame method raises `wowmock: unimplemented Frame:X (add it to wowmock/frames.lua)`. A missing global function fails as "attempt to call global 'X' (a nil value)".

1. Confirm the API exists in `forever-api-index.md`. If it doesn't, the addon code is wrong, not the mock.
2. Add the smallest faithful stub to the matching module in `<skill>/scripts/wowmock/`: `frames`, `events`, `timer`, `unit`, `slash`, `tooltip`, `luaext` or `ace`.
3. Re-vendor the mock into the addon (copy the folder over `tests/wowmock/`).

## What the harness does NOT cover

- **Taint and secure frames:** protected calls, combat lockdown and `ADDON_ACTION_BLOCKED`.
- **Rendering and layout:** anchors resolve to nothing, and textures and fonts are no-ops.
- **Secret values / Midnight restrictions.**
- **Real library behaviour:** LibStub only exposes the stubs registered in `wowmock/ace.lua`.
- **Real data:** items, spells and units only return what you put in `opts`.

That is why every change still ends with the in-game checklist in SKILL.md.

## Higher-fidelity option (not wired in)

`wowless` (MIT; runs the real FrameXML headlessly) and `hogsim`, a "Headless WoW Forever UI simulator … based on wowless", were both active on 2026-11-01 but are unverified at code level (research.md:303-307). Consider them if mock fidelity becomes the bottleneck.
