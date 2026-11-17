# Events

Read this before registering events or deciding where initialisation code goes. For the complete Forever event list (1,800+ events with their owning system), see `forever-api-index.md#events`. Payload signatures are in the matching `*Documentation.lua` in Gethe/wow-ui-source `forever`.

## Lifecycle events (in firing order)

| Event | Fires | Use it for |
|---|---|---|
| `ADDON_LOADED(addonName)` | Once per addon, after its files and SVs load | Reading SavedVariables and merging defaults. Always check `addonName`. |
| `PLAYER_LOGIN()` | Once per session, before the first `PLAYER_ENTERING_WORLD` | World-dependent setup: unit data, UI creation, tickers |
| `PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)` | **Every** loading screen (login, reload, instance change) | Zone- or instance-dependent refresh. Not one-time init. |
| `PLAYER_LOGOUT()` | On logout and reload, before SVs are written | Last-chance cleanup of SV data |

Sources: warcraft.wiki.gg AddOn_loading_process (2026-08-04); research.md:317-321.

## Dispatcher idiom (scaffold default)

```lua
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) local h = self[event]; if h then h(self, ...) end end)
f:RegisterEvent("PLAYER_LOGIN")
function f:PLAYER_LOGIN() ... end
```

## Rules

- Verify every event name in `forever-api-index.md#events` before registering it. A misspelled event registers silently and never fires.
- For unit events, prefer `RegisterUnitEvent(event, "player")` over filtering in the handler.
- Item and spell data may be uncached on first query. Wait for `GET_ITEM_INFO_RECEIVED` / `SPELL_DATA_LOAD_RESULT` before using nil results.
