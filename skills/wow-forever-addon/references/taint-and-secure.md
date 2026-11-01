# Taint and secure frames

Read this when an addon touches action buttons, unit frames, Blizzard UI frames, protected functions, or anything that must work in combat, and when debugging `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN`.

## The model

- Blizzard code runs **secure**, and addon code is **tainted**. Taint spreads to any value or variable an addon writes, and to any code path that reads tainted values.
- **Protected functions** (casting, targeting, moving or showing secure frames, changing action bars, and so on) may only run from a secure execution path. Some only refuse in combat; others always refuse.
- When tainted code calls a protected function, the client blocks it and fires `ADDON_ACTION_BLOCKED` (in combat) or `ADDON_ACTION_FORBIDDEN` (always forbidden). Both events are in the Forever index.
- **Forever caveat:** Midnight's "secret value" restrictions reportedly apply in Forever, limiting what combat and unit data addons can read. **[unverified in Forever]** See `forever-api-notes.md`.

## Rules

1. **Check combat first.** Gate anything that touches secure frames on `InCombatLockdown()`. If it's true, queue the work and run it on `PLAYER_REGEN_ENABLED`:
   ```lua
   local pending = {}
   local function runOrQueue(fn) if InCombatLockdown() then pending[#pending + 1] = fn else fn() end end
   f:RegisterEvent("PLAYER_REGEN_ENABLED")
   function f:PLAYER_REGEN_ENABLED() for i = 1, #pending do pending[i]() end; wipe(pending) end
   ```
2. **Hook, don't replace.** Use `hooksecurefunc("FuncName", post)` or `hooksecurefunc(tbl, "Method", post)` to run after Blizzard code without tainting it. Never reassign a Blizzard global function or method.
3. **Don't write into Blizzard tables or frames** (including fields like `frame.someFlag`) from addon code. Keep state in your own `ns` table, keyed by frame if needed.
4. **Secure templates for actions.** Buttons that cast, target or use items must inherit `SecureActionButtonTemplate` and be configured with attributes (`SetAttribute("type", "spell")`) **outside combat**. `/fstack` shows a frame's template.
5. **Don't show, hide or move secure frames in combat.** Use a state driver (`RegisterStateDriver`) or defer to `PLAYER_REGEN_ENABLED`.
6. **`issecurevariable(tbl, "key")`** reports whether a value is still secure, and identifies which addon tainted it when debugging.

## Debugging taint

- Enable taint logging: `/console taintLog 1` (or `2` for verbose), reproduce, `/reload`, then read `Logs/taint.log`. The first tainted write named there is usually the culprit.
- BugSack shows `ADDON_ACTION_BLOCKED` with the protected function's name.
- The offline harness cannot detect taint. Every fix needs an in-game check, entering combat.

Sources: Blizzard FrameXML secure-execution conventions; warcraft.wiki.gg Secure_Execution_and_Tainting (reported). Event and function names verified in `forever-api-index.md` (2026-11-01).
