# wow-forever-addon

A Claude Code plugin with one skill, `wow-forever-addon`, that makes Claude a reliable collaborator for **World of Warcraft: Forever** (Classic+, codename Camelot) addon development. Its goal is addons that load on the first `/reload`, built on APIs that actually exist in Forever.

Forever is a **Mainline-family** client built from Retail 12.1.5 code (client 1.60.x, `## Interface: 16001`), not a Classic Era branch. The skill's API knowledge is generated from Blizzard's own Forever documentation, so it doesn't rely on Retail or Classic memory.

## What it does

| Capability | How |
|---|---|
| Correct Forever APIs | `references/forever-api-index.md`, generated from Gethe/wow-ui-source `forever` (262 namespaces, 1,814 events), plus curated notes and a **never-emit** list of Classic Era globals |
| Scaffolding | `scaffold.sh <Name> [--pattern event\|timer\|ui\|ldb\|tooltip]` for vanilla, or `--ace3` for options and profiles |
| Linting | `lint.sh`: luacheck with a generated `stds.forever`, never-emit detection, an unthrottled-`OnUpdate` warning |
| Offline tests | `test.sh`: a busted-style runner plus **wowmock** (frames, events, `C_Timer` clock, slash commands, SavedVariables and `/reload`, tooltips, Ace3 stubs) under LuaJIT |
| Debug and review | Error classification (nil access, taint, API drift, load order, perf) with matching references and regression tests |
| Gap analysis | A CurseForge/Wago search procedure and a use / fork / build verdict before building anything |
| Release | `.pkgmeta` + `release.yml`: push a `vX.Y.Z` tag, and the BigWigs packager uploads to CurseForge, Wago and GitHub with Forever auto-detected |
| Planning | Routes non-trivial work through the [qrspi-plan-toolkit](https://github.com/matanshavit/qrspi) plugin and supplies WoW inputs at each phase, if that plugin is installed |

## Install

Install it as a plugin marketplace:

```
/plugin marketplace add /path/to/wowskill
/plugin install wow-forever-addon@wow-forever-addon-marketplace
```

During development, load it straight from this repo:

```bash
claude --plugin-dir .
```

Then ask for things like "build a WoW Forever addon that tracks soul shards" or "why does my addon error on login (BugSack trace attached)".

## Prerequisites

```bash
brew install luajit luacheck            # lint + offline tests
brew install bash jq subversion         # only for local packager dry runs
```

## Layout

```
.claude-plugin/              plugin.json, marketplace.json
skills/wow-forever-addon/
  SKILL.md                   ground rules, routing, workflows, scripts, in-game checklist
  references/                API index + notes, TOC, events, SVs, testing, Ace3, taint, perf, widgets, gap analysis, release, QRSPI handoff
  templates/                 vanilla/, ace3/, common/ (README, CHANGELOG, LICENSE, .pkgmeta, release.yml), luacheck/, qrspi/
  scripts/                   scaffold, lint, test, gen-api, wowmock/, fixtures/
  evals/                     behavior cases for `claude plugin eval`
examples/TooltipItemLevel/   worked addon: tooltip hook, tests, release workflow
evals/trigger-set.json       triggering queries for skill-creator's run_eval
scripts/check.sh             repo gate (also run in CI)
thoughts/qrspi/              design history (task, research, design, structure, plan)
```

## After Forever launches (2026-11-04)

All Forever numbers here date from the beta (1.60.1). After launch:

1. In-game: `/dump select(4, GetBuildInfo())`, then update the first line of `references/toc-format.md` if the number changed.
2. Run `skills/wow-forever-addon/scripts/gen-api.sh` to regenerate the API index and lint std, then `scripts/check.sh`.
3. Re-check any never-emit entries the generator reports as `DOCS`.

## Contributing API facts

Add Forever-specific findings to `references/forever-api-notes.md` with a source, date and confidence label (verified / reported / unverified). Regenerated files (`forever-api-index.md`, `templates/luacheck/forever-std.lua`) must not be edited by hand.

## Repo checks

```bash
scripts/check.sh
```

## License

MIT, see `LICENSE`.
