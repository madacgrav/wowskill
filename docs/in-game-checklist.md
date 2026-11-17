# In-game verification checklist

These checks couldn't be done before WoW Forever went live on 2026-11-04. Work through them once you can log in, tick each box, and fill in the **Result** lines. Anything that fails goes back into the skill: update `references/`, rerun `gen-api.sh`, and run `scripts/check.sh`.

> Paths below are relative to the repo root. `SK=skills/wow-forever-addon`. The AddOns folder is `<WoW install>/_forever_/Interface/AddOns/` (folder name verified 2026-11-17).

---

## 0. Setup

- [x] Find the Forever client's AddOns folder. Result: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns` (2026-11-17)
- [x] Install **BugSack + BugGrabber** for Forever, so errors are captured instead of popping up. (2026-11-17: installed.)
- [x] Generate the test addons into a scratch folder (Demo done 2026-11-17 into `D:\wow-test-addons`; AceDemo pending, see section 4):
  ```bash
  SK=skills/wow-forever-addon
  OUT=~/wow-test-addons && mkdir -p "$OUT"
  $SK/scripts/scaffold.sh Demo --dest "$OUT" --pattern event --pattern timer --pattern ui --pattern ldb --pattern tooltip
  $SK/scripts/scaffold.sh AceDemo --ace3 --dest "$OUT"
  ```
- [x] Symlink each one into AddOns, so edits show after a `/reload` (on Windows, copied `Demo.toc`+`Core.lua` and `TooltipItemLevel.toc`+`Core.lua` instead, 2026-11-17):
  ```bash
  ADDONS="<path from step 0>"
  ln -s "$OUT/Demo" "$ADDONS/Demo"
  ln -s "$PWD/examples/TooltipItemLevel" "$ADDONS/TooltipItemLevel"
  # AceDemo needs its libraries first, see section 4
  ```

---

## 1. Confirm the live Interface number (blocks everything else)

- [x] `/dump select(4, GetBuildInfo())`. Result: `16001` (2026-11-17, unchanged from beta)
- [x] `/dump GetBuildInfo()` (version and build). Result: `1.60.1`, `70959`, `Nov 13 2026` (2026-11-17)
- [x] `/dump WOW_PROJECT_ID, WOW_PROJECT_CAMELOT`. Expect `18, 18`. Result: `18, 18` (2026-11-17)
- [x] ~~If the Interface number differs~~ (unchanged, no edits needed):  edit the first line of `$SK/references/toc-format.md`, then update `examples/TooltipItemLevel/TooltipItemLevel.toc` and `$SK/scripts/fixtures/buggy/Buggy/Buggy.toc`.
- [x] Regenerate the API index for the live build, then re-run the gate (done 2026-11-17 in WSL; no DOCS lines, check.sh PASS):
  ```bash
  $SK/scripts/gen-api.sh        # check the never-emit report: any "DOCS" line means remove that name from the list
  scripts/check.sh
  ```
  Result (gen-api counts line): `namespaces=262 docGlobals=734 frameXML=19480 events=1816 skippedDocs=0 methodSystems=81`

---

## 2. API facts the skill relies on (`/dump` in chat)

Each line should print the shown result. A `nil` where a function is expected means the skill is wrong, so note it.

**Present (should print `function`):** All printed `function` and `true` on 2026-11-17.
- [x] `/dump type(C_Container.GetContainerItemInfo)`
- [x] `/dump type(C_UnitAuras.GetAuraDataByIndex)`
- [x] `/dump type(C_Spell.GetSpellInfo)`
- [x] `/dump type(C_AddOns.IsAddOnLoaded)`
- [x] `/dump type(C_Timer.NewTicker)`
- [x] `/dump type(C_Item.GetDetailedItemLevelInfo)`
- [x] `/dump type(C_SwingTimer.IsTargetWithinSwingRange)` (Forever-specific)
- [x] `/dump type(C_PetInfo.GetPetHappiness)` (Forever-specific)
- [x] `/dump type(TooltipDataProcessor.AddTooltipPostCall)`
- [x] `/dump type(GetAddOnCPUUsage), type(GetAddOnMemoryUsage)`
- [x] `/dump BackdropTemplateMixin ~= nil` should print `true`

**Absent (never-emit list; each should print `nil`):** Printed `empty result` (all nil) on 2026-11-17.
- [x] `/dump GetContainerItemInfo, UnitAura, UnitBuff, GetSpellInfo`
- [x] `/dump GetAddOnInfo, IsAddOnLoaded, LoadAddOn, GetSpellCooldown`

**Unverified claims:**
- [x] Is Lua `require` renamed to `import`? `/dump type(require), type(import)`. Result: `nil`, `function` (2026-11-17, **verified**)
- [x] Secret values / Midnight restrictions: in combat, does reading a target's aura or health from an addon return real numbers? Result: `UnitHealth("target")`, `UnitHealthMax("target")` both `<secret> 0` in combat (2026-11-17). Restrictions **active**; notes updated.. Update the "Secret values" section of `forever-api-notes.md` either way.

---

## 3. Vanilla scaffold: `Demo` (all patterns)

- [x] `/reload`: no BugSack errors. (2026-11-17: sack empty.)
- [x] Login chat is quiet (debug is off by default). (2026-11-17: only `[debug] loaded`, and only because debug was toggled on.)
- [x] `/demo` prints `commands: debug, show`. (2026-11-17: yes.)
- [x] `/demo debug` prints `debug on`. After a `/reload`, it's still on (SavedVariables persisted). (2026-11-17: `[debug] loaded` printed at login after reload.)
- [x] **ui pattern:** a small "Demo" window shows at screen centre. (2026-11-17: FAILED first pass, frame had no backdrop so only the text was visible and `/demo show` looked like a no-op; template fixed, mock now records `SetBackdrop`, retest 2026-11-17: window visible with backdrop, draggable, `/demo show` hides and shows it with chat feedback. Position after reload confirmed: DemoCharDB.point saved as CENTER -994,-156.) It can be dragged; `/reload` keeps its new position. `/demo show` hides and shows it.
- [x] **event pattern:** with debug on, changing target prints `[debug] target <name>`. (2026-11-17: yes.)
- [x] **timer pattern:** after ~15s, `/dump DemoDB` shows nothing broken. Ticks are internal, so this just confirms no errors. (2026-11-17: `interval=5, version=1, debug=true`, no errors.)
- [x] **tooltip pattern:** with debug on, hovering an item prints `[debug] item tooltip <id>`. (2026-11-17: yes; fires several times per hover as the tooltip refreshes, which is expected.)
- [x] **ldb pattern:** with no LibDataBroker installed, there are no errors. (2026-11-17: yes.)
- [x] `/fstack` over the window shows `DemoWindow` at a sensible strata. (2026-11-17: yes.)
- [x] `WTF/Account/<acct>/SavedVariables/Demo.lua` exists after logout and contains `debug` and `version = 1`. (2026-11-17: present after `/reload`, holds `interval = 5`, `version = 1`, `debug = true`.)

Result / notes: all pass on 2026-11-17 after the backdrop fix; see the ui line.

---

## 4. Ace3 scaffold: `AceDemo`

The libraries aren't in the repo. Fetch them with the packager:

```bash
brew install subversion                       # once
cd "$OUT/AceDemo" && git init -q && git add -A && git -c user.name=me -c user.email=me@example.com commit -qm init
"$(brew --prefix)/bin/bash" /path/to/release.sh -d      # see references/release-pipeline.md for the release.sh download
ln -s "$OUT/AceDemo/.release/AceDemo" "$ADDONS/AceDemo"
```

- [x] `.release/AceDemo/Libs/` contains LibStub, CallbackHandler-1.0 and the 7 Ace libraries. If any external fails, note the URL. (2026-11-17: all 9 fetched by `release.sh -d` in WSL with svn 1.13; `## Version` became the commit hash; tests, `.pkgmeta`, `.luacheckrc` excluded. The packaged folder was copied into AddOns for the in-game checks.)
- [x] `/reload`: no BugSack errors.
- [x] `/acedemo` opens the options dialog with **Enabled**, **Debug output** and a **Profiles** tab.
- [x] `/acedemo debug` toggles. With debug on, zoning or `/reload` prints `PLAYER_ENTERING_WORLD …`.
- [x] The options also appear under the game's Settings → AddOns.
- [x] Profiles: create a new profile, switch to it, and the toggles reset to defaults. Switch back and the old values return.
- [x] Settings persist across `/reload` and relog.

Result / notes: all pass on 2026-11-17 with the packager-built folder (Ace3 trunk externals).

---

## 5. Example: `TooltipItemLevel`

- [x] `/reload`: no errors.
- [x] Hovering an item in your bags shows a white **Item Level: N** line.
- [x] It also works on the character sheet, in vendor windows and on chat item links.
- [x] Spells and units show **no** extra line.

Result / notes: all pass on 2026-11-17.

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

- [x] Install the macOS Claude Code CLI (`npm i -g @anthropic-ai/claude-code`). The desktop app's bundled binary is Linux-only. (2026-11-17: on Windows, `claude` 2.1.207 is on PATH at `~/.local/bin`.)
- [x] `claude --plugin-dir .` lists `wow-forever-addon:wow-forever-addon`. (2026-11-17: every `claude -p --plugin-dir .` eval run invoked `Skill wow-forever-addon:wow-forever-addon`.)
- [x] Trigger eval at or above 0.85. Commands are in `thoughts/qrspi/2026-11-01-wow-forever-addon-skill/plan.md`, Phase 8 §3. Result: `18/20 = 0.90` (2026-11-17, 3 runs per query, default model, user-level caveman+ponytail hooks active). skill-creator's `run_eval.py` uses `select` on a pipe and cannot run on Windows, so a drop-in runner that loads the real plugin via `--plugin-dir` and counts first-turn `Skill` calls was used instead. First pass scored 13/20; the description was then widened to symptom phrasings (SavedVariables nil, OnUpdate lag, BugSack traces, TOC out of date, Ace3 profiles, porting, gap analysis). Still weak: "SavedVariables are nil on login" and "attempt to index nil in BugSack" trigger 1/3 each; the model answers those from memory.
- [x] Behavior cases pass: `cd skills/wow-forever-addon && claude plugin eval . --allow-tools Write,Edit,Bash` (`scaffold-vanilla`, `retail-api-trap`, `qrspi-routing`). Result: `plugin eval` is gated ("early access") on CLI 2.1.207, so each prompt was run by hand with `claude -p --plugin-dir .` and graded against the graders (2026-11-17). `retail-api-trap` 2/2 (C_UnitAuras.GetAuraDataBySpellName, lint clean). `qrspi-routing` 2/2 after the Routing section was rewritten to decide first; QRSPI is not installed at CLI scope, so the fallback sentence branch was exercised. `scaffold-vanilla` 1/3: scaffold.sh and lint.sh fail on native Windows (luajit shells out to cmd.exe; luacheck.exe rejects the temp config path), so graders 1 and 2 are environment failures; the agent tried both scripts first, read toc-format.md and the index, and gave the in-game steps. Side finding: it used `UnitPower` for soul shards, which are items in Forever; now documented in forever-api-notes.md. Also found 14 undocumented C globals the index lacked; 13 were added to `gen_api.lua` (IsInRaid, GetNumGroupMembers, GetRaidRosterInfo, GetInventoryItemLink, ...), and `CombatLogGetCurrentEventInfo` dumped as `nil` in-game so it went on the never-emit list with `C_CombatLogSecure.GetCurrentEventInfo` as the replacement. In-game `/dump type()` on 2026-11-17: all 13 kept names print `function`; only `CombatLogGetCurrentEventInfo` printed `nil`.
- [ ] One real debugging session (paste a BugSack trace) follows SKILL.md's debug workflow.
- [ ] One gap-analysis run on a real idea produces the report table and a verdict.
- [ ] One small real addon taken through QRSPI 1 → 8 with the skill loaded.

---

## 8. Wrap-up

- [x] Tick the matching manual boxes in `thoughts/qrspi/2026-11-01-wow-forever-addon-skill/plan.md`. (2026-11-17: P2, P3, P4 in-game and the post-launch line ticked.)
- [x] Commit any fixes (Interface, notes, never-emit list, mock stubs), and confirm `scripts/check.sh` and CI are green. (2026-11-17: `b0593e7` plus the Windows toolchain merge `3c0dcd1`; check.sh PASS in Git Bash and WSL, CI green on the branch and on main.)
- [x] Merge PR #1, then `git tag v1.0.0 && git push --tags`. (2026-11-17: merged as `38f6ebd`, tag `v1.0.0` pushed.)
