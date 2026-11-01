# __NAME__

__NOTES__

A World of Warcraft: Forever addon (Interface __INTERFACE__).

- **Library choice:** __LIBCHOICE__ — __LIBREASON__
- **Gap analysis:** (fill in: existing addons checked, gaps found, verdict use / fork / build)

## Install

Copy or symlink this folder to `World of Warcraft/_forever_/Interface/AddOns/__NAME__`, then `/reload`.

## Usage

- `/__SLASH__` shows help.
- `/__SLASH__ debug` toggles debug output.

## Development

- Lint: `<skill>/scripts/lint.sh .`
- Tests: `tests/run.sh` (offline, LuaJIT + bundled wowmock)
- Release: push a `vX.Y.Z` tag (see `.github/workflows/release.yml`)
