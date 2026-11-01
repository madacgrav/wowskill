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
| Writing or reviewing any WoW API call | `references/forever-api-index.md` | The generated list of every documented Forever namespace, function and event. If a name isn't there, don't emit it. |
| Porting code from Classic Era or Retail, or using an API from memory | `references/forever-api-notes.md` | What differs from Retail 12.1.5, the never-emit list and its replacements, and the secret-values caveat. |
| Creating or editing a `.toc` file | `references/toc-format.md` | Holds the single Interface number, plus directives, load order and suffix rules. |
| Adding or reading persisted settings | `references/saved-variables.md` | SVs are nil until `ADDON_LOADED`, plus the defaults-merge and migration patterns. |
| Registering events or placing init code | `references/events.md` | Lifecycle order and what each event is for. The full list is in the index. |
| Writing or running tests, or a stub is missing | `references/testing.md` | The wowmock harness API, how to add stubs, and what it can't catch. |
| Choosing a scaffold, or adding options, profiles or modules | `references/ace3-vs-vanilla.md` | The vanilla vs `--ace3` decision rule, the Ace3 lifecycle, and soft-embedding libraries. |

## Workflows

### New addon (simple)
1. **Clarify** in at most 3 questions: what it shows or does, what triggers it, and whether it has UI.
2. **Gap analysis**: check whether an existing addon already covers it (see the gap-analysis workflow) and recommend use / fork / build.
3. **Scaffold**: choose vanilla or `--ace3` per `references/ace3-vs-vanilla.md`, then run `<skill>/scripts/scaffold.sh <Name> --dest <dir> [--ace3] [--pattern event|timer|ui|ldb|tooltip]...`. Patterns apply to vanilla only; select just the ones the addon needs.
4. **Implement** the feature in `Core.lua`, verifying every API name against the index.
5. **Lint** with `<skill>/scripts/lint.sh <dir>/<Name>` until it's clean.
6. **Test**: add a spec for the feature in `tests/`, then run `<skill>/scripts/test.sh <dir>/<Name>` until it's green.
7. Hand over with the **in-game checklist** below.

## Scripts

Scripts live in this skill's folder; references write that folder as `<skill>`. Run them by full path.

| Command | Purpose |
|---|---|
| `<skill>/scripts/lint.sh <addon-dir or file.lua>` | Run luacheck with the generated Forever std, plus never-emit and unthrottled-`OnUpdate` checks. Non-zero exit means fix before handing over. |
| `<skill>/scripts/gen-api.sh [--src DIR]` | Regenerate `forever-api-index.md` and the lint std from Gethe/wow-ui-source `forever`. Run after launch and after each patch. |
| `<skill>/scripts/scaffold.sh <Name> [--pattern p]... [--dest DIR] [--license MIT\|none] [--author A] [--notes TXT]` | Render a vanilla addon (TOC, `Core.lua`, `.luacheckrc`, README, CHANGELOG, LICENSE, `tests/` with the vendored mock) with only the selected patterns. |
| `<skill>/scripts/scaffold.sh <Name> --ace3 [--dest DIR] ...` | Render an Ace3 addon (TOC, `embeds.xml`, `Core.lua`, `Options.lua` with a profiles panel, tests, `.gitignore` for `Libs/`). |
| `<skill>/scripts/test.sh <addon-dir>` | Run `tests/*_spec.lua` offline under LuaJIT with wowmock. Non-zero exit means a failing test. |

## In-game checklist

End every scaffold or edit with these steps. Offline lint and tests cannot catch taint, rendering or real client behaviour.

1. Copy or symlink the addon folder to `World of Warcraft/_forever_/Interface/AddOns/<Name>`.
2. `/reload`, then confirm there are no errors (install BugSack and BugGrabber to capture them).
3. Exercise the feature: run each slash command, and trigger each event the addon handles.
4. `/fstack` to check frame placement and strata.
5. `/etrace` to confirm the expected events fire.
