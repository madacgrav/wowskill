# TooltipItemLevel

Shows the item level on item tooltips.

A World of Warcraft: Forever addon (Interface 16001).

- **Library choice:** vanilla — no options panel, <=3 settings, no cross-addon messaging (see ace3-vs-vanilla.md)
- **Gap analysis:** example only. This addon demonstrates the skill and is not a gap-filling release.

## Install

Copy or symlink this folder to `World of Warcraft/_forever_/Interface/AddOns/TooltipItemLevel`, then `/reload`.

## Usage

- `/tooltipitemlevel` shows help.
- `/tooltipitemlevel debug` toggles debug output.

## Development

- Lint: `<skill>/scripts/lint.sh .`
- Tests: `tests/run.sh` (offline, LuaJIT + bundled wowmock)
- Release: push a `vX.Y.Z` tag (see `.github/workflows/release.yml`)
