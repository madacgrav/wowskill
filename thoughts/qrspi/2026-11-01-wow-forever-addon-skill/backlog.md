# Backlog — WoW Forever Addon Skill

Derived from `wow-addon-skill-prd.md` v0.2 §6, §12, §13. Not read by `2-research`. Ordering and slicing get finalized in `4-structure`; open questions are resolved in `3-design`.

## M0 — Decisions (resolved in design.md, 2026-11-01)
- [x] Q1 Interface 16001 (beta; reconfirm after 2026-11-04 launch); API baseline = Gethe `forever` branch, Mainline 12.1.5 lineage
- [x] Q2 CurseForge has a Forever flavor (packager type 88568)
- [x] Q3 Wago accepts `forever` (1.60.1)
- [x] Q4 Own minimal mock: frames/events/timers/slash/SV + LibStub/Ace stubs
- [x] Q5 luajit via Homebrew + own runner; no luarocks/busted
- [x] Q6 `.pkgmeta` externals only (per-lib from WoWAce SVN)
- [x] Q7 PRD threshold kept; revisit after two addons
- [x] Q8 web-search-researcher only on `references/` gap
- [x] Q9 Repo is a plugin; skill at `skills/wow-forever-addon/`
- [x] License: switch to MIT
- [ ] Owner: confirm live Interface + rerun `gen-api` after launch

## M1 — Knowledge base
- [ ] `SKILL.md`: frontmatter + triggering description (PRD §6), routing/decision tree, QRSPI detection + fallback
- [ ] Plugin scaffold: `.claude-plugin/plugin.json` + `marketplace.json`, `skills/wow-forever-addon/`
- [ ] `scripts/gen-api` → `references/forever-api-index.md` + `templates/luacheck/forever-globals.lua`
- [ ] `references/forever-api-notes.md` (vs Retail 12.1.5; never-emit list → `not_globals`), date-stamped
- [ ] `references/toc-format.md`
- [ ] `references/events.md`
- [ ] `references/widgets.md`
- [ ] `references/saved-variables.md`
- [ ] `references/taint-and-secure.md`
- [ ] `references/ace3-vs-vanilla.md`
- [ ] `references/performance.md`
- [ ] Verify: `quick_validate.py` passes on the skill

## M2 — Scaffold + lint
- [ ] `templates/vanilla/` skeleton
- [ ] `templates/ace3/` skeleton with options panel
- [ ] `templates/.luacheckrc` (WoW globals + Retail-only as `not_globals`)
- [ ] `scripts/scaffold.sh` (copy, rename, fill TOC)
- [ ] `scripts/lint.sh`
- [ ] Verify: scaffold dummy addon → lint green → `/reload` in-game, no errors

## M3 — Mock harness
- [ ] `scripts/wowmock/`: CreateFrame, Register/FireEvent, C_Timer.After, GetTime, UnitName/UnitClass, slash dispatch, SV load/save
- [ ] Test runner (busted or busted-style)
- [ ] `scripts/test.sh`
- [ ] Template `tests/` (load, SV defaults, slash command)
- [ ] Verify: example addon tests pass

## M4 — Release pipeline
- [ ] `templates/.pkgmeta` (externals, ignore incl. `thoughts/`, manual-changelog, nolib)
- [ ] `templates/release.yml` (CF_API_KEY, WAGO_API_TOKEN, GITHUB_OAUTH)
- [ ] `templates/CHANGELOG.md`, `templates/README.addon.md`
- [ ] `references/release-pipeline.md` + `/release` checklist
- [ ] Verify: example addon published to CurseForge + Wago from a tag

## M5 — Gap analysis + debug flows
- [ ] `references/curseforge-gap-analysis.md` (procedure + report template, API-first with web fallback)
- [ ] Debug workflow (§7.2) in SKILL.md: classify, patch, regression test, in-game steps
- [ ] Performance review procedure
- [ ] Verify: exercised on one real debugging session

## M6 — QRSPI handoff
- [ ] `references/qrspi-handoff.md` (routing table, per-phase WoW inputs; single place naming the commands)
- [ ] `templates/qrspi/task.template.md`
- [ ] `templates/qrspi/questions.wow.md`
- [ ] Verify: one addon taken through phases 1–8

## M7 — Public repo
- [ ] `examples/` worked addon (e.g. tooltip hook) with tests + CI
- [ ] README install docs (personal/project scope), LICENSE (PRD says MIT; repo currently has GPL-3.0 — decide)
- [ ] skill-creator eval run on WoW prompts
- [ ] Tag v1.0.0
