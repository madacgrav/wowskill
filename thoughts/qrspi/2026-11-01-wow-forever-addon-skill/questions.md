# Research Questions

## Context
Focus on the Claude Code skills and plugins installed on this machine (under `~/Library/Application Support/Claude/local-agent-mode-sessions/`, including the `skill-creator` skill, skills with `references/`/`scripts/` directories, and the `qrspi-plan-toolkit` plugin's `commands/` and `agents/`), the prior QRSPI artifacts in `~/Source/trainme/thoughts/qrspi/`, and external public documentation about the World of Warcraft: Forever client, Lua 5.1 tooling, and addon distribution platforms. The `wowskill` repo itself currently contains only a README and LICENSE. No Lua runtime, luacheck, busted, or luarocks is installed locally.

## Questions
1. How does the `skill-creator` skill define a skill's structure: required `SKILL.md` frontmatter fields, how the `description` field drives triggering, how `references/`, `scripts/`, `assets/` are meant to be used, and how its eval tooling (`run_eval.py`, `run_loop.py`, `quick_validate.py`, `package_skill.py`) runs, including its inputs and outputs?

2. Across the installed skills that ship `references/` and/or `scripts/` (e.g. `google-workspace`, `deep-research`, `pdf`, `pptx`), how does `SKILL.md` point to and load reference files and invoke scripts, how long are `SKILL.md` files compared with their references, and how are skills installed at personal vs. project scope (`~/.claude/skills`, `.claude/skills`, or plugin packaging)?

3. How do the `qrspi-plan-toolkit` commands (`1-question` through `8-pr`) and agents work: what inputs each command takes, what files it reads and writes in `thoughts/qrspi/<id>/`, which agents each phase spawns and with what tool restrictions, how `2-research` is kept from reading `task.md`, and how a session can detect whether the plugin's commands are available? How did the `trainme` artifacts use these files in practice?

4. What is publicly documented about the World of Warcraft: Forever (Classic+) client: its current `## Interface` TOC number, its API lineage relative to Classic Era/Anniversary and Retail, available `C_*` namespaces (e.g. `C_Container`, `C_UnitAuras`, `C_Timer`), and whether an API dump (`/api`, BlizzardInterfaceCode/`wow-ui-source` branch) exists for it? Label each fact with source and date.

5. What does the BigWigs packager (`release.sh` / `BigWigsMods/packager` GitHub Action) expect in `.pkgmeta` (externals, ignore, manual-changelog, enable-nolib-creation), which tokens it substitutes (`@project-version@`, etc.), which secrets/env vars it uses for CurseForge, Wago, and GitHub uploads, and how it selects game versions? Do CurseForge's and Wago's upload APIs and addon listings expose a distinct game version for WoW Forever?

6. How are luacheck and busted configured and run for WoW addons in public projects: standard `.luacheckrc` layouts (std, `globals`, `read_globals`, `not_globals`, generated WoW globals lists), how Lua 5.1/LuaJIT/luacheck/busted are installed on macOS (Homebrew, luarocks, hererocks), and what existing WoW API mock/stub libraries (e.g. `wowmock`, `wow-api-mock`, others) implement `CreateFrame`, events, `C_Timer`, slash commands, and SavedVariables?

7. How do public Ace3-based and vanilla WoW addons structure their files and boilerplate: the `local ADDON, ns = ...` namespace pattern, event-frame dispatchers, `ADDON_LOADED`/`PLAYER_LOGIN` handling, SavedVariables defaults merging and migrations, slash command registration, and how Ace3 libraries are embedded (committed `Libs/` vs. `.pkgmeta` externals with `embeds.xml`)?
