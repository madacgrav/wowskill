# Ace3 vs vanilla

Read this before scaffolding (`--ace3` or not), and whenever an addon grows an options panel, profiles or modules.

## Decision rule

| Choose | When |
|---|---|
| **Vanilla** (`scaffold.sh <Name>`) | No options panel, **≤ 3** saved settings, and no cross-addon messaging. |
| **Ace3** (`scaffold.sh <Name> --ace3`) | Any of: an options UI (AceConfig), **profiles** (AceDB), a module system, a minimap/LDB launcher with settings, or AceComm messaging. |

Record the choice and the reason in the generated README's "Library choice" line. The scaffold fills in a default reason; replace it with the real one.

## Ace3 lifecycle (template)

- `LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")` creates the addon object with mixins.
- `OnInitialize()` runs once when the addon loads (`ADDON_LOADED`). Create `self.db = LibStub("AceDB-3.0"):New("NameDB", defaults, true)` here, then register options and chat commands.
- `OnEnable()` runs at login, and again if the addon is re-enabled. Register events here (`self:RegisterEvent("EVENT")` calls `self:EVENT(event, ...)`).
- `OnDisable()` is optional. Unregister anything `OnEnable` set up.
- AceDB: `defaults = { profile = {...}, global = {...} }`. Read and write `self.db.profile.x`. `true` as the third argument selects a shared "Default" profile. `AceDBOptions-3.0:GetOptionsTable(db)` adds a profiles panel.
- AceConfig: `RegisterOptionsTable(name, optionsTable)` plus `AceConfigDialog-3.0:AddToBlizOptions(name, name)`. `:Open(name)` opens the standalone dialog.

Sources: warcraft.wiki.gg WelcomeHome:_Your_first_Ace3_Addon (2024-05-26); ketho-wow/HelloAce (2025-04-17); wowace.com Ace3 getting started; research.md:330-343.

## Embedding: soft, never committed

- **Do not commit `Libs/`.** The Ace3 scaffold writes `.gitignore` with `Libs/`.
- Libraries arrive at package time through `.pkgmeta` `externals`, one entry per library, from `https://repos.wowace.com/wow/ace3/trunk/<Lib>`, which the Ace3 README calls "the primary authority" for `.pkgmeta`. Reference individual libraries, not the whole Ace3 package (research.md:336-337). The release template carries the externals block (see `release-pipeline.md`).
- `embeds.xml` loads `Libs\LibStub\LibStub.lua` first, then `CallbackHandler-1.0`, then each Ace library's XML. The TOC lists `embeds.xml` before the addon's own files and declares `## OptionalDeps: Ace3` and `## X-Embeds: Ace3`.

## Testing Ace3 addons

- Offline tests use the stubs in `wowmock/ace.lua`: lifecycle, AceDB profiles and defaults, AceEvent, AceConsole chat commands, and AceConfig registration and `Open`. Missing `Libs/` files are skipped by the TOC loader.
- Known divergence: real AceDB strips default values on logout, and the stub does not. Don't assert that defaults are absent from saved data.
- In-game testing needs the real libraries. Either run the packager dry run (`release-pipeline.md`), which fetches the externals into `.release/<Name>/Libs/`, or check the externals out into `Libs/` by hand (it's gitignored).
