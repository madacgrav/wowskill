# wow-forever-addon

A Claude Code plugin with one skill, `wow-forever-addon`, that turns Claude into a reliable collaborator for **World of Warcraft: Forever** (Classic+) addon development. It covers:

- the Forever API surface generated from Blizzard's own docs;
- vanilla and Ace3 addon scaffolds;
- luacheck linting;
- an offline mock WoW API test harness;
- CurseForge gap analysis;
- a tag-to-CurseForge/Wago release pipeline;
- a handoff to the [qrspi-plan-toolkit](https://github.com/matanshavit/qrspi) planning flow for non-trivial work.

> Status: under construction (v0.1.0). See `thoughts/qrspi/2026-11-01-wow-forever-addon-skill/` for the design history.

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

## Prerequisites

```bash
brew install luajit luacheck
```

## Repo checks

```bash
scripts/check.sh
```

## License

MIT, see `LICENSE`.
