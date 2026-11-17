# QRSPI handoff

Read this when an addon request is bigger than a quick fix: a new multi-file addon, a meaningful new feature, or a fork of an existing addon. QRSPI (Question → Research → Design → Structure → Plan → Worktree → Implement → PR) is provided by the **qrspi-plan-toolkit** plugin. This skill does not reimplement it. It decides when to hand off and supplies WoW Forever inputs at each phase.

**This file is the only place in the skill that names the plugin's commands.** If the plugin renames them, update only this file.

## Detection

- **Installed:** `qrspi-plan-toolkit:1-question` (and the other numbered commands) appear in the available skills list. Use the routing table below.
- **Not installed:** use the skill's direct workflows, and say once: "Install the qrspi-plan-toolkit plugin for the structured planning flow."

## Routing table

| Situation | Path |
|---|---|
| API question, single-file fix, one-off debug, release of an existing addon | **Direct.** QRSPI is overkill. |
| New addon with ≥ 3 Lua files, an options UI, or Ace3 | **Full** `/qrspi-plan-toolkit:1-question` → `/qrspi-plan-toolkit:8-pr` |
| Meaningful feature in an existing addon (new module, new saved-variable schema, new frame) | Hand-write `task.md`, then start at `/qrspi-plan-toolkit:3-design` |
| Fork or extend an existing addon (gap-analysis verdict "fork") | **Full 1 → 8.** Research is where the forked code gets understood objectively. |

The threshold (≥ 3 files / options UI / Ace3) is provisional. Revisit it after the first two addons.

## Per-phase WoW inputs

### `/qrspi-plan-toolkit:1-question <task>`
- Seed `task.md` from `templates/qrspi/task.template.md`: the clarified idea plus the gap-analysis verdict.
- Append the standing questions from `templates/qrspi/questions.wow.md` to `questions.md`, filling in the placeholders with neutral nouns, not goals.
- Point codebase-locator at `<skill>/references/` and at the addon folder (when extending or forking).

### `/qrspi-plan-toolkit:2-research <dir>`
- `<skill>/references/` (`forever-api-index.md`, `forever-api-notes.md`, `events.md`, `saved-variables.md`, …) count as part of the "codebase". Research agents may read them, since they are neutral facts.
- Use `web-search-researcher` **only** when `references/` lacks a fact, for example on warcraft.wiki.gg or in Gethe/wow-ui-source `forever`. Label every such fact with a Forever confidence: verified / reported / unverified.
- Research must stay blind to `task.md`. Never pass intent to research agents.

### `/qrspi-plan-toolkit:3-design <dir>`
- Ask the WoW design questions from `templates/qrspi/design-questions.wow.md` alongside the command's own.
- `design.md` must record as constraints:
  - the Interface number from `references/toc-format.md`;
  - "No never-emit names (`references/forever-api-notes.md`)";
  - "Every API name verified in `references/forever-api-index.md`".

### `/qrspi-plan-toolkit:4-structure <dir>`
- Use vertical slices that each load in-game:
  1. TOC + core + saved variables with defaults + slash command (loadable);
  2. events + the first feature;
  3. UI frame;
  4. options and profiles.
- Every phase's **Verify** line is `<skill>/scripts/lint.sh <addon> && <skill>/scripts/test.sh <addon>`, plus an in-game `/reload` with no errors.

### `/qrspi-plan-toolkit:5-plan <dir>`
- Automated verification is `lint.sh` and `test.sh`. Manual items come from the SKILL.md in-game checklist.
- Before accepting the plan, check every Lua snippet in it against the never-emit list. Paste the snippets into a scratch `.lua` and run `lint.sh` on it, or grep for the names. Reject the plan if any appear.

### `/qrspi-plan-toolkit:6-worktree <dir>`
- Unchanged. Remind the user to symlink `World of Warcraft/_forever_/Interface/AddOns/<Name>` to the worktree's addon folder for in-game testing.

### `/qrspi-plan-toolkit:7-implement <dir>`
- Unchanged. Commit each phase only after `lint.sh` and `test.sh` pass. The manual pause is the in-game `/reload`.

### `/qrspi-plan-toolkit:8-pr <dir>`
- Add two sections to the PR body:
  - **Forever compatibility:** the Interface number, the APIs and namespaces used, and taint exposure (secure frames touched, combat-lockdown handling).
  - **Release:** link to the `.pkgmeta` and `.github/workflows/release.yml` paths. Merging and then pushing a `vX.Y.Z` tag triggers the CurseForge/Wago upload (`references/release-pipeline.md`).

## Artifacts

- Commit `thoughts/qrspi/` in the addon repo. It's the design history that reviewers and future sessions read.
- The release `.pkgmeta` ignores `thoughts`, so it never ships in the addon zip.
