# In-game verification checklist

These checks couldn't be done before WoW Forever went live on 2026-11-04. Work through them once you can log in, tick each box, and fill in the **Result** lines. Anything that fails goes back into the skill: update `references/`, rerun `gen-api.sh`, and run `scripts/check.sh`.

> Paths below are relative to the repo root. `SK=skills/wow-forever-addon`. The AddOns folder is `<WoW install>/<Forever client folder>/Interface/AddOns/`. The README writes this folder as `_forever_`, but that name is **unverified**, so note the real one in step 0.

---

## 0. Setup

- [ ] Find the Forever client's AddOns folder. Result: `__________________________`
- [ ] Install **BugSack + BugGrabber** for Forever, so errors are captured instead of popping up.
- [ ] Generate the test addons into a scratch folder:
  ```bash
  SK=skills/wow-forever-addon
  OUT=~/wow-test-addons && mkdir -p "$OUT"
  $SK/scripts/scaffold.sh Demo --dest "$OUT" --pattern event --pattern timer --pattern ui --pattern ldb --pattern tooltip
  $SK/scripts/scaffold.sh AceDemo --ace3 --dest "$OUT"
  ```
- [ ] Symlink each one into AddOns, so edits show after a `/reload`:
  ```bash
  ADDONS="<path from step 0>"
  ln -s "$OUT/Demo" "$ADDONS/Demo"
  ln -s "$PWD/examples/TooltipItemLevel" "$ADDONS/TooltipItemLevel"
  # AceDemo needs its libraries first, see section 4
  ```

---

## 1. Confirm the live Interface number (blocks everything else)

- [ ] `/dump select(4, GetBuildInfo())`. Result: `_______` (beta value was **16001**)
- [ ] `/dump GetBuildInfo()` (version and build). Result: `_______` (beta was `1.60.1`, `70532`)
- [ ] `/dump WOW_PROJECT_ID, WOW_PROJECT_CAMELOT`. Expect `18, 18`. Result: `_______`
- [ ] **If the Interface number differs:** edit the first line of `$SK/references/toc-format.md`, then update `examples/TooltipItemLevel/TooltipItemLevel.toc` and `$SK/scripts/fixtures/buggy/Buggy/Buggy.toc`.
- [ ] Regenerate the API index for the live build, then re-run the gate:
  ```bash
  $SK/scripts/gen-api.sh        # check the never-emit report: any "DOCS" line means remove that name from the list
  scripts/check.sh
  ```
  Result (gen-api counts line): `__________________________`

---

## 2. API facts the skill relies on (`/dump` in chat)

Each line should print the shown result. A `nil` where a function is expected means the skill is wrong, so note it.

**Present (should print `function`):**
- [ ] `/dump type(C_Container.GetContainerItemInfo)`
- [ ] `/dump type(C_UnitAuras.GetAuraDataByIndex)`
- [ ] `/dump type(C_Spell.GetSpellInfo)`
- [ ] `/dump type(C_AddOns.IsAddOnLoaded)`
- [ ] `/dump type(C_Timer.NewTicker)`
- [ ] `/dump type(C_Item.GetDetailedItemLevelInfo)`
- [ ] `/dump type(C_SwingTimer.IsTargetWithinSwingRange)` (Forever-specific)
- [ ] `/dump type(C_PetInfo.GetPetHappiness)` (Forever-specific)
- [ ] `/dump type(TooltipDataProcessor.AddTooltipPostCall)`
- [ ] `/dump type(GetAddOnCPUUsage), type(GetAddOnMemoryUsage)`
- [ ] `/dump BackdropTemplateMixin ~= nil` should print `true`

**Absent (never-emit list; each should print `nil`):**
- [ ] `/dump GetContainerItemInfo, UnitAura, UnitBuff, GetSpellInfo`
- [ ] `/dump GetAddOnInfo, IsAddOnLoaded, LoadAddOn, GetSpellCooldown`

**Unverified claims:**
- [ ] Is Lua `require` renamed to `import`? `/dump type(require), type(import)`. Result: `_______`
- [ ] Secret values / Midnight restrictions: in combat, does reading a target's aura or health from an addon return real numbers? Result: `_______`. Update the "Secret values" section of `forever-api-notes.md` either way.

---

## 3. Vanilla scaffold: `Demo` (all patterns)

- [ ] `/reload`: no BugSack errors.
- [ ] Login chat is quiet (debug is off by default).
- [ ] `/demo` prints `commands: debug, show`.
- [ ] `/demo debug` prints `debug on`. After a `/reload`, it's still on (SavedVariables persisted).
- [ ] **ui pattern:** a small "Demo" window shows at screen centre. It can be dragged; `/reload` keeps its new position. `/demo show` hides and shows it.
- [ ] **event pattern:** with debug on, changing target prints `[debug] target <name>`.
- [ ] **timer pattern:** after ~15s, `/dump DemoDB` shows nothing broken. Ticks are internal, so this just confirms no errors.
- [ ] **tooltip pattern:** with debug on, hovering an item prints `[debug] item tooltip <id>`.
- [ ] **ldb pattern:** with no LibDataBroker installed, there are no errors.
- [ ] `/fstack` over the window shows `DemoWindow` at a sensible strata.
- [ ] `WTF/Account/<acct>/SavedVariables/Demo.lua` exists after logout and contains `debug` and `version = 1`.

Result / notes: `__________________________`

---

## 4. Ace3 scaffold: `AceDemo`

The libraries aren't in the repo. Fetch them with the packager:

```bash
brew install subversion                       # once
cd "$OUT/AceDemo" && git init -q && git add -A && git -c user.name=me -c user.email=me@example.com commit -qm init
"$(brew --prefix)/bin/bash" /path/to/release.sh -d      # see references/release-pipeline.md for the release.sh download
ln -s "$OUT/AceDemo/.release/AceDemo" "$ADDONS/AceDemo"
```

- [ ] `.release/AceDemo/Libs/` contains LibStub, CallbackHandler-1.0 and the 7 Ace libraries. If any external fails, note the URL.
- [ ] `/reload`: no BugSack errors.
- [ ] `/acedemo` opens the options dialog with **Enabled**, **Debug output** and a **Profiles** tab.
- [ ] `/acedemo debug` toggles. With debug on, zoning or `/reload` prints `PLAYER_ENTERING_WORLD …`.
- [ ] The options also appear under the game's Settings → AddOns.
- [ ] Profiles: create a new profile, switch to it, and the toggles reset to defaults. Switch back and the old values return.
- [ ] Settings persist across `/reload` and relog.

Result / notes: `__________________________`

---

## 5. Example: `TooltipItemLevel`

- [ ] `/reload`: no errors.
- [ ] Hovering an item in your bags shows a white **Item Level: N** line.
- [ ] It also works on the character sheet, in vendor windows and on chat item links.
- [ ] Spells and units show **no** extra line.

Result / notes: `__________________________`

---

## 6. Packaging and upload (needs CurseForge/Wago projects)

- [ ] Create a CurseForge project (WoW → Forever flavor available?) and a Wago project for TooltipItemLevel. Result: `_______`
- [ ] Put the example in its own GitHub repo, uncomment and fill `X-Curse-Project-ID` and `X-Wago-ID` in its TOC, and add the `CF_API_TOKEN` and `WAGO_API_TOKEN` secrets.
- [ ] Push tag `v0.1.0` and confirm the "Package and release" Action is green.
- [ ] The CurseForge file lists game version **Forever 1.60.x**. Result: `_______`
- [ ] The Wago version lists **forever** patch support. Result: `_______`
- [ ] Download the uploaded zip, install it, `/reload`: no errors.

---

## 7. Skill checks (no game needed, but not done yet)

- [ ] Install the macOS Claude Code CLI (`npm i -g @anthropic-ai/claude-code`). The desktop app's bundled binary is Linux-only.
- [ ] `claude --plugin-dir .` lists `wow-forever-addon:wow-forever-addon`.
- [ ] Trigger eval at or above 0.85. Commands are in `thoughts/qrspi/2026-11-01-wow-forever-addon-skill/plan.md`, Phase 8 §3. Result: `_______`
- [ ] Behavior cases pass: `cd skills/wow-forever-addon && claude plugin eval . --allow-tools Write,Edit,Bash` (`scaffold-vanilla`, `retail-api-trap`, `qrspi-routing`). Result: `_______`
- [ ] One real debugging session (paste a BugSack trace) follows SKILL.md's debug workflow.
- [ ] One gap-analysis run on a real idea produces the report table and a verdict.
- [ ] One small real addon taken through QRSPI 1 → 8 with the skill loaded.

---

## 8. Wrap-up

- [ ] Tick the matching manual boxes in `thoughts/qrspi/2026-11-01-wow-forever-addon-skill/plan.md`.
- [ ] Commit any fixes (Interface, notes, never-emit list, mock stubs), and confirm `scripts/check.sh` and CI are green.
- [ ] Merge PR #1, then `git tag v1.0.0 && git push --tags`.
