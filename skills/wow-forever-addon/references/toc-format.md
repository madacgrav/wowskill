Interface: 16001
(as of 2026-11-01, Forever beta/test; confirm after launch with /dump select(4, GetBuildInfo()) and update this line only)

# TOC format for WoW Forever

Read this before creating or editing any `.toc` file. The `Interface:` line above is the **single source** of the Forever interface number. `scripts/scaffold.sh` reads it, so never hard-code the number anywhere else.

## Directives

| Directive | Notes |
|---|---|
| `## Interface: 16001` | Comma-separated values are allowed (since 10.2.7). Whether Forever honours multi-value lines is unverified. |
| `## Title:` / `## Notes:` / `## Author:` | Shown in the AddOns list. |
| `## Version: @project-version@` | The BigWigs packager substitutes the git tag. |
| `## SavedVariables: NameDB` | Stored per account in `WTF/<account>/SavedVariables/`. |
| `## SavedVariablesPerCharacter: NameCharDB` | Stored per character in `WTF/<account>/<realm>/<char>/SavedVariables/`. |
| `## OptionalDeps:` / `## Dependencies:` | Load-order hints and hard requirements. |
| `## X-Curse-Project-ID:` / `## X-Wago-ID:` | Read by the packager for uploads (see `release-pipeline.md`). |
| `## IconTexture:` / `## AddonCompartmentFunc:` | Optional; `AddonCompartmentFunc` names a global function. |

Sources: warcraft.wiki.gg/wiki/TOC_format (2026-10-17); research.md:322-329.

## Load order

- Files load top to bottom as listed. `.xml` files load their `<Script>` and `<Include>` children in document order.
- SavedVariables load **after the last TOC file**, unless `LoadSavedVariablesFirst` is set. The earliest safe read is `ADDON_LOADED` with `arg1 == addonName`.
- Only the first 1024 characters of each TOC line are read.

## File suffixes

The client loads the most specific TOC that matches:

1. A game-type suffix: `Name_Forever.toc` or `Name_Camelot.toc` (aliases).
2. A family suffix: `Name_Mainline.toc` covers standard, forever, camelot, plunderstorm and wowhack. `Name_Classic.toc` covers vanilla through mists, so it does **not** load in Forever.
3. The plain `Name.toc`.

The skill's v1 default is a single plain `Name.toc` with the Forever interface number. The packager generates `_Camelot.toc` when per-flavor TOC creation is enabled.

Sources: warcraft.wiki.gg/wiki/TOC_format (2026-10-17); addons.wago.io/api/data/game (2026-11-01); BigWigs `release.sh:2014`.
