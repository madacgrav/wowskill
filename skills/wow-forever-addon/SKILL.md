---
name: wow-forever-addon
description: Build, debug, review, test and release World of Warcraft addons for WoW Forever (Classic+, codename Camelot, TOC Interface 16xxx). Use whenever the user mentions a WoW addon, World of Warcraft addon, Classic+ or WoW Forever addon, a .toc file, WoW Lua, CreateFrame, SavedVariables, WoW slash commands, BugSack or BugGrabber errors, addon taint, Ace3, CurseForge or Wago addon releases, or the BigWigs packager, or when a .toc file or WoW addon folder is in context, even if Forever is not named. Provides the Forever API surface generated from Blizzard docs, vanilla and Ace3 scaffolds, a luacheck config, an offline mock WoW API test harness, CurseForge gap analysis, a tag-to-CurseForge/Wago release pipeline, and routes non-trivial addon work through the qrspi-plan-toolkit planning flow.
license: MIT
---

# WoW Forever addon development

## Ground rules

- **Forever is Mainline-family, not Classic.** WoW Forever (client 1.60.x, codename Camelot) is built from Retail 12.1.5 code. Classic Era idioms and APIs are not safe by default.
- **The TOC Interface number lives in one place:** `references/toc-format.md`. Read it from there; never hard-code it elsewhere.
- **Verify every API name** against `references/forever-api-index.md` before emitting it. Do not rely on memory of Retail or Classic.
- **Never emit** names on the never-emit list in `references/forever-api-notes.md`.
- **Lint and test before handing anything over**, then always finish with the in-game checklist below.

## Read before you touch

| Situation | Read first | Why |
|---|---|---|

## Workflows

## Scripts

Scripts live in this skill's folder; references write that folder as `<skill>`. Run them by full path.

| Command | Purpose |
|---|---|

## In-game checklist
