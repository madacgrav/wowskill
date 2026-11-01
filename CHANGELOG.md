# Changelog

## [1.0.0] - 2026-11-01

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

### Known limits
- Forever data dates from the beta (1.60.1). Reconfirm the Interface and rerun `gen-api.sh` after the 2026-11-04 launch.
- The mock harness doesn't model taint, rendering, secret values or real Ace3 behaviour. The in-game checklist remains mandatory.
