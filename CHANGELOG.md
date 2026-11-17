# Changelog

## [1.0.0] - 2026-11-17

First release of the `wow-forever-addon` plugin. It was built through QRSPI (`thoughts/qrspi/2026-11-01-wow-forever-addon-skill/`), and each phase of the plan is one commit.

### Added
- **P0:** plugin manifests, the `wow-forever-addon` skill, an MIT license, and the `scripts/check.sh` repo gate.
- **P1:** the Forever API index and luacheck `stds.forever`, generated from Gethe/wow-ui-source `forever` (`ca8368f 1.60.1 (70532)`). Also `lint.sh` with never-emit and `OnUpdate` checks, curated `forever-api-notes.md`, and `toc-format.md` as the single source of the Interface number.
- **P2:** the vanilla scaffold with opt-in patterns (event, timer, ui, ldb, tooltip), `saved-variables.md` and `events.md`.
- **P3:** the wowmock offline harness and test runner, `test.sh`, the vendored per-addon tests, and the `examples/TooltipItemLevel` worked addon.
- **P4:** the Ace3 scaffold (AceAddon, AceDB profiles, AceConfig options), Ace stubs, and `ace3-vs-vanilla.md`.
- **P5:** the QRSPI handoff: routing, per-phase WoW inputs, and task/question/design templates.
- **P6:** debug, review, performance and API-question workflows; taint, performance, widget and gap-analysis references; a seeded-fault fixture.
- **P7:** a `.pkgmeta` and tag-triggered BigWigs packager release workflow (CurseForge, Wago, GitHub), `release-pipeline.md`, and repo CI.
- **P8:** a 20-query trigger set, three behavior eval cases, and the full README.

### Verified after launch (2026-11-17, client 1.60.1 build 70959)
- Interface `16001` unchanged; the API index and lint std were regenerated from `forever@3d8abb1`.
- Midnight secret values are active in Forever: unit health and aura reads return opaque values in combat. Lua `require` is `import`.
- Vanilla game data behind Retail APIs: warlock soul shards are items (6265), not a power type.
- In-game checklist sections 0-5 pass for the vanilla scaffold, the Ace3 scaffold (externals from the packager) and `TooltipItemLevel`.
- Trigger eval 18/20; `retail-api-trap` and `qrspi-routing` behavior cases pass.

### Fixed
- Vanilla `ui` pattern: the window had no backdrop and was invisible. The mock now records `SetBackdrop` and the template test asserts it.
- 13 undocumented C globals (`IsInRaid`, `GetNumGroupMembers`, `GetRaidRosterInfo`, `GetInventoryItemLink`, ...) added to the index and lint std; `CombatLogGetCurrentEventInfo` is `nil` in Forever and joins the never-emit list.
- Scripts run natively from Git Bash on Windows with `luajit.exe` and `luacheck.exe`; `.gitattributes` forces LF.
- Routing decides the planning path before any scaffold or template read; the skill description triggers on symptom phrasings.

### Known limits
- The mock harness doesn't model taint, rendering, secret values or real Ace3 behaviour. The in-game checklist remains mandatory.
