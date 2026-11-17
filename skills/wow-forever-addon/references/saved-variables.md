# SavedVariables

Read this before adding, reading or changing persisted settings.

## Lifecycle

1. The TOC declares `## SavedVariables: NameDB` (per account) and/or `## SavedVariablesPerCharacter: NameCharDB` (per character).
2. All TOC files execute first. **The SV globals are still nil at file scope.**
3. The client then loads the saved values, unless `## LoadSavedVariablesFirst` is set, and fires `ADDON_LOADED` with `arg1 == addonName`. This is the **earliest safe read**.
4. The client writes the globals back on logout, on `/reload` and on a disconnect. Only data reachable from those globals is saved, so no functions or frames.

Storage paths:
- Per account: `WTF/Account/<ACCOUNT>/SavedVariables/<Addon>.lua`.
- Per character: `WTF/Account/<ACCOUNT>/<Realm>/<Char>/SavedVariables/<Addon>.lua`.

Sources: warcraft.wiki.gg AddOn_loading_process (2026-08-04), TOC_format (2026-10-17); research.md:317-326.

## Pattern used by the scaffold

```lua
function f:ADDON_LOADED(name)
  if name ~= addonName then return end
  NameDB = mergeDefaults(NameDB or {}, defaults)   -- fill missing keys only; never overwrite user values
  ns.db = NameDB
  ns.Migrate(ns.db, ns.db.version or 0)
  self:UnregisterEvent("ADDON_LOADED")
end
```

- **Defaults merge** fills only missing keys, recursively, so new settings appear without wiping old ones.
- **Migrations**: bump `DB_VERSION` and add a step to `ns.Migrate`:
  ```lua
  function ns.Migrate(db, from)
    if from < 2 then db.scale = db.size; db.size = nil end   -- v1 -> v2 rename
    db.version = DB_VERSION
  end
  ```
- **Account vs character:** account-wide for preferences that should follow the player, per character for positions, per-class settings and per-character data.
- In Ace3 addons, AceDB replaces all of this (profiles, `defaults.profile`). See `ace3-vs-vanilla.md`.

## Common bugs

- Reading `NameDB.x` at file scope: it's nil there, and indexing it errors at load.
- Storing a frame or function in an SV: it's silently dropped.
- Forgetting the `name ~= addonName` check: the handler runs once for every addon that loads.
