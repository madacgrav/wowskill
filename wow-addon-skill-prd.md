# PRD: WoW Forever Addon Development Skill for Claude Code

| Field | Value |
|---|---|
| Owner | Adam |
| Status | Draft v0.2 |
| Date | 2026-11-01 |
| Form factor | Claude Code skill (SKILL.md + references + scripts) |
| Target game | World of Warcraft: Forever (Classic+) only |
| Distribution | Shareable Git repo |
| Dependencies | `qrspi-plan-toolkit` plugin (installed) — optional at runtime, required for the skill's own build |

**v0.2 changes:** incorporates the QRSPI (Question → Research → Design → Structure → Plan → Worktree → Implement → PR) workflow, which is installed in Adam's Claude Code as the `qrspi-plan-toolkit` plugin. QRSPI is used in two ways: (a) as the process for building this skill (§13), and (b) as the planning backbone the skill hands off to for non-trivial addon work (§5.7, §7.5).

---

## 1. Problem

Building WoW addons involves a large, poorly documented surface area: the Lua 5.1 dialect Blizzard ships, the frame/widget API, event names, TOC metadata, saved-variable lifecycle, secure-frame taint rules, and client-specific divergences. WoW Forever (Classic+) adds a further layer — its API is a Classic lineage with Forever-specific additions, and most online references (Wowpedia, Warcraft Wiki, forum posts) document Retail or Classic Era, not Forever.

Without a skill, every session re-derives this from scratch, hallucinates Retail-only API calls, and produces addons that error on load. The skill's job is to make Claude a reliable Forever addon collaborator: correct API usage, idiomatic structure, offline testability, and a release path to CurseForge/Wago.

## 2. Goals

1. **Correctness on Forever** — generated code uses only APIs that exist on the WoW Forever client; Retail-only or removed calls are flagged, not emitted.
2. **Scaffold to release in one workflow** — from empty folder to packaged, versioned zip with a CI upload pipeline.
3. **Offline validation** — every addon the skill produces passes `luacheck` and has a mock-API test harness, so bugs are caught before the user alt-tabs into the game.
4. **Don't rebuild what exists** — before scaffolding, check CurseForge for existing addons covering the idea and report gaps rather than duplicating.
5. **Pragmatic library choice** — document the Ace3 vs. vanilla-Lua trade-off and choose per addon based on complexity.
6. **Plan before building anything non-trivial** — the skill routes complex addon work through QRSPI so design alignment happens in a ~200-line `design.md` before Lua is written, and implementation proceeds in verified, individually-committed phases.

## 3. Non-goals

- Retail, Classic Era, Anniversary, Cataclysm/MoP Classic support (future consideration; see §11).
- Running the WoW client or reading live game state.
- A GUI addon builder or WeakAuras-style config export.
- Art/texture asset creation (BLP/TGA).
- Maintaining a full mirror of the WoW API docs — the skill holds a curated Forever-specific delta plus pointers to canonical sources.

## 4. Users

| User | Need |
|---|---|
| Adam (primary) | Build new Forever addons for his warlock/rogue and profession workflows without re-learning the API each time |
| Other Forever addon authors (secondary, via repo) | Drop-in skill that gets Claude producing loadable Forever addons on the first try |

## 5. Capabilities (functional requirements)

### 5.1 Scaffold new addons
- Generate a complete, loadable addon folder: `AddonName.toc` (correct `## Interface` number for Forever), `AddonName.lua`, optional `Core/`, `Modules/`, `Locales/`, `Libs/`.
- Include the standard boilerplate: addon namespace table via `local ADDON, ns = ...`, event frame with `OnEvent` dispatcher, `ADDON_LOADED`/`PLAYER_LOGIN`/`PLAYER_ENTERING_WORLD` handling, `SavedVariables` + `SavedVariablesPerCharacter` with defaults merging and version migration stub, slash command registration, and a `/addonname debug` toggle.
- Ask the user which pattern the addon needs (event-driven, timer/`C_Timer`, UI frame, data broker, tooltip hook) and only include the matching boilerplate.
- Decide Ace3 vs. vanilla:
  - Vanilla when: no options panel, ≤ 3 saved settings, no cross-addon messaging.
  - Ace3 (AceAddon, AceDB, AceConfig, AceEvent, AceConsole, LibDataBroker if minimap button) when: options UI, profiles, or module system are wanted.
  - Record the decision and rationale in `README.md` of the generated addon.
- Always generate `.luacheckrc`, `.pkgmeta`, `CHANGELOG.md`, `README.md`, and `.github/workflows/release.yml` (see §5.5).

### 5.2 Lua / WoW API reference
- Answer questions about the Forever API: function signatures, event payloads, widget methods, `C_*` namespaces available on Forever, frame templates, secure/protected functions and taint.
- Maintain a **Forever API delta file** (`references/forever-api-delta.md`): what exists on Forever that differs from Classic Era, and a list of common Retail-only calls to never emit (e.g. `C_Container` vs `GetContainerItemInfo`, `UnitAura` vs `C_UnitAuras`, spellbook changes, `GetSpellInfo` deprecations).
- Cite the canonical source (Warcraft Wiki page, Blizzard's `BlizzardInterfaceCode` dump, or in-game `/api` output) for every non-trivial claim; state confidence when Forever-specific behavior is unverified.
- Know the Lua 5.1 constraints: no `goto`, no integer subtype, no `bit32` (use `bit.*`), WoW's `string`/`table` extensions (`strsplit`, `tContains`, `wipe`, `SecondsToTime`), and `securecall`.

### 5.3 Review and debug
- Given an addon folder or a pasted error (`BugSack`/`BugGrabber` stack trace), locate the fault, explain it, and propose a fix.
- Check for: globals leakage (missing `local`), taint from touching secure frames in combat, `OnUpdate` without throttling, unhandled nil from unloaded data (e.g. item info before `GET_ITEM_INFO_RECEIVED`), saved-variable access before `ADDON_LOADED`, hard-coded Retail API calls, deprecated event names, and frame-count/memory leaks from recreating frames.
- Run `luacheck` with the WoW globals config and report results.
- Produce a **performance review** when asked: CPU profile hotspots via `GetFunctionCPUUsage`/`UpdateAddOnCPUUsage` instructions, memory via `UpdateAddOnMemoryUsage`.

### 5.4 Gap analysis vs. CurseForge
- Before scaffolding a new idea, search CurseForge (web search / fetch of the Forever-compatible addon listing) for addons that already cover it.
- Report: top 3–5 matches, their last-update date, whether they declare Forever support, and the specific gaps relative to the user's idea.
- Recommend one of: **use existing**, **fork/extend existing** (with license check), or **build new** — and record the rationale in the generated `README.md`.
- Adam's stated preference: don't recreate existing addons unless they have obvious gaps.

### 5.5 Packaging and release pipeline
- Generate `.pkgmeta` compatible with **BigWigs packager** (`release.sh`): externals for embedded libs, `ignore` list, `manual-changelog`, `enable-nolib-creation`.
- Generate `.github/workflows/release.yml` that on tag push runs the BigWigs packager and uploads to **CurseForge** and **Wago** (and optionally GitHub Releases) using `CF_API_KEY`, `WAGO_API_TOKEN`, `GITHUB_OAUTH` secrets. Include the correct game-version flag for Forever.
- Enforce semver tags, keep `## Version` in the TOC synced via `@project-version@` token, and generate `CHANGELOG.md` entries from conventional commits.
- Provide a `/release` checklist: bump version, update changelog, luacheck green, mock tests green, tag, push, verify upload.

### 5.6 Validation (offline)
- **luacheck**: ship `scripts/luacheck/.luacheckrc` with a Forever globals list (Lua std + WoW globals + Ace3 globals). Skill runs it on every generated or edited file.
- **Mock WoW API harness**: ship `scripts/wowmock/` — a plain-Lua (5.1 or LuaJIT via `luajit`/`lua5.1`) shim implementing `CreateFrame`, `RegisterEvent`/`FireEvent`, `C_Timer.After`, `GetTime`, `UnitName`/`UnitClass`, slash command dispatch, `SavedVariables` load/save simulation, and a `busted`-style test runner. Generated addons get a `tests/` folder with at least one test for load, saved-variable defaults, and slash command handling.
- **In-game checklist**: because the harness can't catch rendering or taint, every scaffold/edit ends with a short manual checklist: copy to `Interface/AddOns`, `/reload`, confirm no `BugSack` errors, exercise the feature, check `/fstack` for frame placement, check `/etrace` for expected events.

### 5.7 QRSPI integration (planning backbone)

The `qrspi-plan-toolkit` plugin is already installed. It provides eight numbered slash commands (`/qrspi-plan-toolkit:1-question` … `8-pr`) and four read-only research agents (`codebase-locator`, `codebase-analyzer`, `codebase-pattern-finder`, `web-search-researcher`). Artifacts for a task live in `thoughts/qrspi/<id>/` as `task.md`, `questions.md`, `research.md`, `design.md`, `structure.md`, `plan.md`. The WoW skill does not re-implement any of this; it detects the plugin, hands off to it, and supplies WoW-specific inputs at each phase.

**Detection.** `SKILL.md` instructs Claude to check whether the `/qrspi-plan-toolkit:*` commands are available (listed skills / `ListSkills`). If present, the routing rule below applies. If absent, the skill falls back to its own lightweight workflow (§7.1–7.4) and prints a one-line note that installing `qrspi-plan-toolkit` unlocks the structured flow.

**Routing rule — when to hand off.**

| Situation | Path |
|---|---|
| API question, single-file fix, one-off debug, release of an already-built addon | Direct (§7.2–7.4); QRSPI is overkill |
| New addon that will be ≥ 3 Lua files, has an options UI, or embeds Ace3 | Full QRSPI (1 → 8) |
| Meaningful feature added to an existing addon (new module, new saved-var schema, new frame) | QRSPI from `3-design` onward, with a hand-written `task.md` |
| Fork/extend an existing CurseForge addon (gap-analysis verdict) | Full QRSPI — the Research phase is where the forked codebase gets understood objectively |

**WoW-specific inputs the skill supplies per phase.**

| Phase | What the WoW skill contributes |
|---|---|
| `1-question` | Seeds `task.md` from the clarified idea and the gap-analysis verdict. Adds standing WoW questions to `questions.md`: which events fire for the trigger, which Forever APIs expose the needed data, what the existing addon (if forking) does on `ADDON_LOADED`/`PLAYER_LOGIN`, what saved-variable shape is in use. Points `codebase-locator` at `references/` and any existing addon folder. |
| `2-research` | Research agents read `references/forever-api-delta.md`, `events.md`, `widgets.md` as part of the "codebase". `web-search-researcher` is explicitly permitted for Warcraft Wiki / Blizzard UI source when a Forever API fact is not in `references/`, and must label the Forever-confidence level. Research stays blind to `task.md` per QRSPI rules. |
| `3-design` | The design questions the skill injects: Ace3 vs vanilla (per §5.1 criteria), event-driven vs `OnUpdate`, SV scope (account vs per-character), secure-frame exposure, UI framework (plain frames vs Ace GUI). `design.md` records the Forever `## Interface` target and the "never emit" API list as constraints. |
| `4-structure` | Slices are vertical per QRSPI: e.g. Phase 1 = TOC + core + SV defaults + slash command, loadable; Phase 2 = event handler + first feature; Phase 3 = UI frame; Phase 4 = options/profiles. Every phase's **Verify** line is `scripts/lint.sh && scripts/test.sh` plus an in-game `/reload` check. |
| `5-plan` | Automated verification commands are the skill's `lint.sh`/`test.sh`; manual verification items are drawn from the in-game checklist (§5.6). Code snippets in `plan.md` are checked against the "never emit" list before the plan is accepted. |
| `6-worktree` | Unchanged. Worktree path `~/wt/<addon-repo>/<branch>`; the skill reminds that `Interface/AddOns/<Name>` should be a symlink/junction to the worktree for in-game testing. |
| `7-implement` | Unchanged. Each phase commits after lint + mock tests pass; the pause for manual verification is where Adam `/reload`s in-game. |
| `8-pr` | PR body gains a **Forever compatibility** section (Interface number, APIs used, taint exposure) and a **Release** note linking to the `.pkgmeta`/`release.yml` path (§5.5). Tag push after merge triggers the CurseForge/Wago upload. |

**Artifact handling.** `thoughts/qrspi/` is committed in addon repos (it is the design history reviewers and future-Claude read). The release `.pkgmeta` `ignore` list excludes `thoughts/` so it never ships in the addon zip.

## 6. Skill structure

```
wow-forever-addon-skill/
├── SKILL.md                      # frontmatter + routing: when to use, core workflow, decision tree
├── README.md                     # install instructions (Claude Code, personal or project scope)
├── LICENSE                       # MIT
├── references/
│   ├── forever-api-delta.md      # Forever vs Classic Era vs Retail divergences; "never emit" list
│   ├── toc-format.md             # TOC directives, Interface number for Forever, multi-TOC fallbacks
│   ├── events.md                 # curated event list with payloads, Forever-verified
│   ├── widgets.md                # frame types, templates, common methods, anchor/strata rules
│   ├── saved-variables.md        # lifecycle, defaults merging, migrations
│   ├── taint-and-secure.md       # secure frames, combat lockdown, what breaks
│   ├── ace3-vs-vanilla.md        # decision criteria and embedding instructions
│   ├── performance.md            # OnUpdate throttling, table reuse, profiling commands
│   ├── curseforge-gap-analysis.md# search procedure and report template
│   ├── release-pipeline.md       # .pkgmeta, BigWigs packager, CF/Wago upload, secrets
│   └── qrspi-handoff.md          # routing rule, per-phase WoW inputs, question/design templates
├── templates/
│   ├── vanilla/                  # minimal addon skeleton
│   ├── ace3/                     # Ace-based skeleton with options panel
│   ├── .luacheckrc
│   ├── .pkgmeta
│   ├── release.yml
│   ├── CHANGELOG.md
│   ├── README.addon.md
│   └── qrspi/
│       ├── task.template.md      # WoW-flavoured task.md starter
│       └── questions.wow.md      # standing WoW research questions injected in phase 1
├── scripts/
│   ├── scaffold.sh               # copy template, rename, fill TOC
│   ├── lint.sh                   # run luacheck with WoW config
│   ├── test.sh                   # run mock harness tests
│   └── wowmock/                  # mock WoW API + test runner
└── examples/
    └── (one small worked addon, e.g. a tooltip hook, with tests and CI)
```

**SKILL.md description (triggering):** fires on "WoW addon", "World of Warcraft addon", "Classic+ addon", "WoW Forever", "TOC file", "WoW Lua", "CurseForge addon", "SavedVariables", "CreateFrame", "addon error"/"BugSack", and on any `.toc` file in context.

## 7. Workflows

### 7.1 New addon (simple — below the QRSPI threshold)
1. Clarify idea in ≤ 3 questions (what it shows/does, trigger, UI or not).
2. Gap analysis against CurseForge → recommendation.
3. If build-new: choose vanilla vs Ace3, scaffold, write core logic.
4. Lint + mock tests green.
5. Emit in-game checklist and release next-steps.

### 7.5 New addon or major feature (QRSPI path)
1. Steps 1–2 of §7.1 (clarify, gap analysis).
2. Skill writes `thoughts/qrspi/<date>-<addon>/task.md` from the verdict and invokes `/qrspi-plan-toolkit:1-question`, pre-loading `templates/qrspi/questions.wow.md`.
3. User runs `2-research` → `3-design` → `4-structure` → `5-plan` in fresh contexts; the skill's `references/` are in scope for the research agents at every step.
4. `6-worktree` (optional) → `7-implement`, with `lint.sh`/`test.sh` as the automated gate and the in-game checklist as the manual gate for each phase.
5. `8-pr`; after merge, the §7.4 release flow.
6. The skill's job in this path is narrow: supply correct Forever constraints to each phase and refuse plans that contain "never emit" APIs. It does not replace QRSPI's own commands.

### 7.2 Debug existing
1. Read error / folder.
2. Classify (nil access, taint, API drift, load order, perf).
3. Patch, lint, add a regression test in the mock harness if feasible.
4. Emit in-game verification steps.

### 7.3 API question
1. Answer from `references/`; if not covered, web-search the Warcraft Wiki / Blizzard UI source and state Forever-confidence level.
2. Offer to add the finding to `forever-api-delta.md` or `events.md`.

### 7.4 Release
1. Run `/release` checklist; confirm secrets exist; tag; verify upload.

## 8. Success metrics

| Metric | Target |
|---|---|
| Scaffolded addon loads in Forever with zero errors on first `/reload` | ≥ 90% of scaffolds |
| Retail-only API calls emitted in generated code | 0 (caught by luacheck globals list + review) |
| Time from idea to loadable addon | < 15 minutes of Claude session time |
| luacheck + mock tests pass before user tests in-game | 100% of deliverables |
| Release workflow uploads to CurseForge and Wago on tag push | Works on example addon end-to-end |
| Gap analysis produced before every new build | 100% |
| Addons above the QRSPI threshold have a reviewed `design.md` before any Lua is written | 100% |
| QRSPI phases in `plan.md` each pass `lint.sh && test.sh` before commit | 100% |

## 9. Open questions

1. **Forever Interface number and API baseline** — what `## Interface` value does the Forever client currently expect, and is there a published API dump? Needs verification at build time; the delta file must be seeded from a real client, not assumed.
2. **CurseForge Forever category** — does CurseForge expose a distinct game-version filter for Forever, or do addons list under Classic? Affects both gap analysis and the release upload flag.
3. **Wago support for Forever** — confirm Wago accepts a Forever game version in its upload API.
4. **Mock harness fidelity** — how much of the widget API to stub before diminishing returns? Proposal: start with frames/events/timers/slash/SV and grow from test failures.
5. **Lua runtime for tests** — require `lua5.1`, `luajit`, or vendor a tiny interpreter? Affects portability for other users of the repo.
6. **Ace3 embedding** — vendor via `.pkgmeta` externals only (so the repo stays lib-free), or commit libs for offline testing?
7. **QRSPI threshold tuning** — is "≥ 3 Lua files / options UI / Ace3" the right trigger for the full flow, or does it push too much small work into an 8-phase process? Revisit after the first two addons.
8. **Research blindness vs. Forever facts** — QRSPI's `2-research` must not read `task.md`. Confirm that pointing agents at `references/` doesn't leak intent (it shouldn't — references are neutral facts), and decide whether `web-search-researcher` is on by default for the WoW skill or only when `references/` has a gap.
9. **Skill + plugin layering** — should the WoW skill eventually ship *as* a plugin that declares `qrspi-plan-toolkit` as a dependency, or stay a standalone skill that detects the plugin at runtime? Standalone is simpler for v1.

## 10. Risks

| Risk | Mitigation |
|---|---|
| Forever API drifts with patches; delta file goes stale | Date-stamp every entry; `/api` verification step in workflow; encourage PRs to the repo |
| Claude hallucinates Retail API | "Never emit" list in luacheck globals as `not_globals`; review step grep |
| Mock harness gives false confidence on taint/UI | Mandatory in-game checklist; harness explicitly documents what it does not cover |
| CurseForge scraping is brittle | Prefer CurseForge API (needs key) with web-search fallback; gap analysis degrades gracefully to "unverified" |
| QRSPI plugin renamed/updated; `/qrspi-plan-toolkit:N-name` references in the skill break | Detection step checks command availability at runtime; `qrspi-handoff.md` is the single place that names the commands |
| Full QRSPI applied to trivial addons slows Adam down | Routing table in §5.7 keeps simple work on the direct path; threshold is an explicit open question (§9.7) |
| `thoughts/qrspi/` ships inside the addon zip | `.pkgmeta` template ignores `thoughts/` by default |

## 11. Future considerations

- Add Classic Era / Anniversary targets as additional delta files with a `target` field in TOC generation.
- Retail support with multi-TOC fallback (`_Mainline.toc`, `_Classic.toc`).
- Companion subagent for long autonomous builds (scaffold → test → release) once the skill is stable.
- Localization scaffolding with `AceLocale` and community translation pull.
- Packaging as a Claude Code plugin with `/wow-new`, `/wow-debug`, `/wow-release` slash commands, declaring `qrspi-plan-toolkit` as a dependency.
- A WoW-specific research agent (`wow-api-researcher`) that QRSPI's `2-research` can spawn alongside its four stock agents — knows to consult `references/` first and the Warcraft Wiki second.

## 12. Milestones

| # | Milestone | Deliverable |
|---|---|---|
| M1 | Knowledge base | `SKILL.md`, `references/*` seeded and Forever-verified for TOC, events, API delta |
| M2 | Scaffold + lint | `templates/`, `scaffold.sh`, `.luacheckrc`; vanilla and Ace3 skeletons load in-game |
| M3 | Mock harness | `scripts/wowmock/` with runner; example addon has passing tests |
| M4 | Release pipeline | `.pkgmeta`, `release.yml`; example addon published to CurseForge + Wago from a tag |
| M5 | Gap analysis + debug flows | Procedures documented and exercised on one real debugging session |
| M6 | QRSPI handoff | `references/qrspi-handoff.md`, `templates/qrspi/*`; one addon taken end-to-end through phases 1–8 using the skill's inputs |
| M7 | Public repo | README, LICENSE, install docs; tagged v1.0.0 |

## 13. Building the skill with QRSPI

The skill itself is a multi-file project with real design risk (API baseline, harness scope, template shape), so it should be built with the same QRSPI flow it will later hand off to. Suggested mapping:

| QRSPI phase | Applied to this skill |
|---|---|
| `1-question` | Input: this PRD. Questions target what already exists: how `skill-creator` structures skills, how other installed skills lay out `references/` and `scripts/`, how QRSPI's commands reference agents, what the BigWigs packager expects in `.pkgmeta`, what the Forever client exposes via `/api`. |
| `2-research` | Agents read the installed skills directory and the `qrspi-plan-toolkit` plugin source; `web-search-researcher` gathers Forever API facts and CurseForge/Wago upload API details. Output seeds `references/`. |
| `3-design` | Resolve open questions §9.1–9.9 with Adam. `design.md` becomes the authoritative spec; this PRD is the input, not the output. |
| `4-structure` | Vertical slices ≈ milestones M1–M7, each ending with a loadable or runnable check (e.g. M2 verify: scaffold a dummy addon, `/reload`, no errors). |
| `5-plan` | Per-file plan for `SKILL.md`, each `references/*.md`, templates, scripts. |
| `6-worktree` | Repo `wow-forever-addon-skill`, branch per milestone. |
| `7-implement` | One commit per milestone phase; verification is `lint.sh`/`test.sh` on the example addon plus a `skill-creator` eval run against a few WoW prompts. |
| `8-pr` | PR per milestone into `main`; v1.0.0 tag after M7. |

Kick-off command once the PRD is accepted:

```
/qrspi-plan-toolkit:1-question wow-addon-skill-prd.md
```
