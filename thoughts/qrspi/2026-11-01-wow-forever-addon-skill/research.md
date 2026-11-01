# Research Findings

Researched 2026-11-01. All web sources accessed 2026-11-01. Path prefixes:
- **S** = `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/c783f22c-a674-4d4d-b0a0-a09dfb07d8e6/228f5f35-228d-4d15-a271-f62273597712`
- **SC** = `S/skills/skill-creator`
- **R** = `~/Library/Application Support/Claude/local-agent-mode-sessions/228f5f35-228d-4d15-a271-f62273597712/c783f22c-a674-4d4d-b0a0-a09dfb07d8e6/rpm`
- **Q** = `R/plugin_01SZ84JctFtwsb1y4seYAs2E` (qrspi-plan-toolkit)
- **T** = `~/Source/trainme/thoughts/qrspi`

`[U]` = unconfirmed / not verified against a primary source. "(verified)" = checked directly by fetching the raw file or API in this session.

## Q1: How does `skill-creator` define a skill's structure, triggering, bundled dirs, and eval tooling?

### Findings
**Frontmatter**
- Prose says `name` and `description` are required (`SC/SKILL.md:75-79`). `compatibility` is "optional, rarely needed" (`SC/SKILL.md:66-68`).
- `quick_validate.py` enforces the following:
  - Allowed keys are exactly `name, description, license, allowed-tools, metadata, compatibility`, and any other key fails (`SC/scripts/quick_validate.py:84-92`). `name` and `description` are required (`:95-98`).
  - `name` must match `^[a-z0-9-]+$`, with no leading or trailing `-` and no `--`, at most 64 chars (`:102-112`).
  - `description` must be a string with no `<` or `>`, at most 1024 chars (`:117-125`). `compatibility` is at most 500 chars (`:129-134`).
  - Exactly one SKILL.md is allowed in the tree. `evals/` at the root, `__pycache__` and `node_modules` are excluded from the count. The stated reason is that the Skills API and claude.ai reject multiple SKILL.md files (`:15-61`).
  - CLI: `python quick_validate.py <dir>`, exit 0 or 1 (`:140-147`). It needs PyYAML (`:8`).

**Triggering**
- `description` is "the primary triggering mechanism". All "when to use" information belongs there, not in the body. The skill advises "pushy" wording because Claude tends to undertrigger (`SC/SKILL.md:67`, `:356`).
- Skills appear in `available_skills` as name + description. Claude consults a skill only for tasks it can't easily do alone, so simple one-step queries may not trigger it (`SC/SKILL.md:419`).
- The improver prompt targets about 100-200 words and a hard 1024-char limit (`SC/scripts/improve_description.py:127-132`).

**Bundled resources and progressive disclosure**
- `scripts/` holds deterministic or repetitive code, `references/` holds docs loaded as needed, and `assets/` holds files used in output (`SC/SKILL.md:75-84`).
- There are three loading levels: metadata (about 100 words, always loaded), the SKILL.md body (when triggered, ideally under 500 lines), and resources (as needed; scripts may run without being loaded) (`SC/SKILL.md:88-93`).
- Guidance: reference files "clearly from SKILL.md with guidance on when to read them". Add a table of contents to references over 300 lines. Use a domain split such as `references/aws.md|gcp.md|azure.md` (`SC/SKILL.md:96-109`).
- If every test run writes a similar helper, bundle it in `scripts/` (`SC/SKILL.md:325`).

**Test cases**
- Layout is `evals/<case>/{prompt.md, case.yaml, graders/NN-*.md, files/}` (`SC/SKILL.md:147-156`, `SC/references/schemas.md:7-71`).
- prompt.md settings: `tags`, `max_turns`, `timeout_seconds`, `allowed_tools`. An unknown key fails the load (`schemas.md:16-26`).
- case.yaml has `schema_version: "1.1"`, `name` and `expected_outcome` (`:32-35`). Graders use `type: llm`, `focus`, `weight`, and at least one grader is required (`:41-52`).
- Optional CLI: `claude plugin eval . --allow-tools Write,Edit,Bash` (Claude Code v2.1.269+), which writes to `evals/results/` (`schemas.md:71`).
- Legacy `evals/evals.json` is read-only (`schemas.md:75-119`).

**Eval loop (workspace)**
- Layout: `<skill>-workspace/iteration-N/<case>/{eval_metadata.json, with_skill|without_skill|old_skill/{outputs/,grading.json,timing.json}}`, plus `benchmark.json` and `benchmark.md` (`SC/SKILL.md:168-183`).
- With-skill and baseline subagents are spawned in the same turn (`:185-202`). Grading follows `SC/agents/grader.md`, then aggregation, then the analyzer agent, then the viewer (`:242-272`).

**Scripts** (run as `python -m scripts.<name>` from SC; `SC/SKILL.md:250,403,434`)
- `run_eval.py`:
  - Args: `--eval-set`, `--skill-path`, `--num-workers` (10), `--timeout` (30), `--runs-per-query` (3), `--trigger-threshold` (0.5), `--model` (`SC/scripts/run_eval.py:261-269`).
  - Input is a JSON list of `{query, should_trigger}`.
  - For each query it writes a temporary `.claude/commands/<skill>-skill-<uuid8>.md` (`:51-68`). It then runs `claude -p <query> --output-format stream-json --verbose --include-partial-messages` with `CLAUDECODE` removed (`:70-91`).
  - "Triggered" means a `Skill` or `Read` tool_use that references that temporary name (`:129-168`).
  - Output is JSON on stdout: `{skill_name, description, results[{query,should_trigger,trigger_rate,triggers,runs,pass}], summary}` (`:247-256`).
- `improve_description.py`:
  - Calls `claude -p` with the prompt on stdin and a 300s timeout, using session auth (no API key) (`SC/scripts/improve_description.py:5-47`).
  - The reply comes back in `<new_description>` tags. It re-asks if the result is over 1024 chars (`:142-182`). Output is `{description, history}` (`:233-243`).
- `run_loop.py`:
  - Takes run_eval's args plus `--max-iterations` (5), `--holdout` (0.4), `--model` (required), `--report` and `--results-dir` (`SC/scripts/run_loop.py:246-258`).
  - Uses a stratified split with seed 42 (`:24-44`). The improver does not see test scores (`:194-208`). The best result is chosen by test score (`:217-222`).
  - Writes JSON to stdout, and with `--results-dir` also writes `results.json`, `report.html` and `logs/` (`:284-321`). It does not edit SKILL.md; `best_description` is applied manually (`SC/SKILL.md:423-425`).
- `aggregate_benchmark.py <benchmark_dir> [--skill-name --skill-path -o]`:
  - Reads `grading.json`, `timing.json` and `eval_metadata.json`.
  - Writes `benchmark.json` and `.md` with mean, stddev, min, max and delta (`SC/scripts/aggregate_benchmark.py:444-502`). The schema is at `schemas.md:303-389`.
- `package_skill.py <skill-folder> [out-dir]`: validates first, then writes `<name>.skill`, a zip with `<name>/...` entries. It excludes `evals/` at the root, `__pycache__`, `node_modules`, `*.pyc` and `.DS_Store` (`SC/scripts/package_skill.py:20-24,70-132`).
- `eval-viewer/generate_review.py <workspace> [--port 3117 --static PATH --previous-workspace --benchmark]`: serves an HTTP viewer, and `/api/feedback` writes `feedback.json` (`SC/eval-viewer/generate_review.py:469-523,563-593`). It uses the stdlib only.
- External dependencies: the `claude` CLI (run_eval and improve_description), PyYAML, optionally `lsof` and a browser. Claude.ai cannot run `claude -p` (`SC/SKILL.md:453`). Cowork can (`:475`).

## Q2: How do installed skills with `references/`/`scripts/` load them, how big are they, and how are skills installed by scope?

### Findings
| skill | SKILL.md lines | references (files / lines) | scripts |
|---|---|---|---|
| google-workspace | 97 | 4 / 1056 | 4 .py (136–461 lines) |
| deep-research | 146 | 2 / 187 | 0 |
| pdf | 314 | 2 top-level .md (FORMS 294, REFERENCE 612) | 8 .py |
| pptx | 271 | 0 | 5 + `scripts/office/` |
| docx | 93 | 0 | 3 + `scripts/office/` |
| xlsx | 99 | 0 | `recalc.py` + `scripts/office/` |
| skill-creator | 506 | `references/schemas.md` 514, plus `agents/*.md` 701 | 8 .py + eval-viewer |
| create-cowork-plugin (plugin) | 267 | 2 / 748 | 0 |

**How SKILL.md points to references**
- google-workspace uses a table "Read the reference before you touch the file" that maps each file type to `references/<x>.md` (`S/skills/google-workspace/SKILL.md:10-16`).
- deep-research tells its subagents "As a first step, you must read {path_to_skill}/references/researcher.md" (`S/skills/deep-research/SKILL.md:89,115,140`).
- pdf uses bare filenames: "see REFERENCE.md… read FORMS.md and follow its instructions" (`S/skills/pdf/SKILL.md:11,307-314`).

**How SKILL.md invokes scripts**
- Most skills use `python scripts/<x>.py …` with paths relative to the skill dir:
  - `S/skills/docx/SKILL.md:42-86`
  - `S/skills/xlsx/SKILL.md:37`
  - `S/skills/pptx/SKILL.md:17,25-31,77-82`
  - pdf keeps its invocations in `S/skills/pdf/FORMS.md:4,8,54,75`
- google-workspace uses a `<skill>` placeholder: "Run them by their full path inside this skill's folder" (`S/skills/google-workspace/SKILL.md:59`; e.g. `references/docs.md:209-219`).
- pptx also uses Node: `require("<this skill's directory>/scripts/apply_theme.js")` (`S/skills/pptx/SKILL.md:29`).
- `${CLAUDE_PLUGIN_ROOT}` is documented only for plugin hooks and MCP configs (`R/plugin_0155zZVATbJU3jHUmPP9NvMC/skills/create-cowork-plugin/SKILL.md:126-128,225-226`).
- Only `morning` uses `assets/` (fonts).

**Install scope**
- `~/.claude/skills` does not exist. `/Users/madacgrav/Source/wowskill/.claude` does not exist. No personal-scope or project-scope skills are installed.
- Desktop-managed skills: the `S/.claude-plugin/plugin.json` name is `anthropic-skills` (`:1-5`). `S/manifest.json` has `skills[]` entries with `skillId, name, description, creatorType, source, updatedAt, enabled` (`:5-11`).
- Plugins: `R/manifest.json` has `plugins[]` entries with `id, name, marketplaceName, installedBy, installationPreference` (`:3-13`). Four are installed: qrspi-plan-toolkit ("My Uploads"), engineering, productivity and cowork-plugin-management (knowledge-work-plugins).
- Plugin layout per create-cowork-plugin:
  - `.claude-plugin/plugin.json` is required and only `name` is mandatory. `skills/*/SKILL.md`, `agents/*.md`, `.mcp.json` and `hooks/hooks.json` sit at the plugin root (`…/create-cowork-plugin/SKILL.md:34-55,90-94`).
  - `commands/` is "Legacy… new plugins should use `skills/*/SKILL.md`" (`:44`).
  - Packaged with `zip -r name.plugin .` (`:242-252`).
- skill-creator does not mention `~/.claude/skills` or `.claude/skills`. It distributes a `.skill` file via `present_files` or `SendUserFile`; "[Save skill] installs the skill into their profile" (`SC/SKILL.md:431-437`). It notes "The installed skill path may be read-only" (`:461`).

## Q3: How do qrspi-plan-toolkit commands and agents work, and how did trainme use them?

### Findings
**Commands.** Each command takes `$ARGUMENTS`. None has `allowed-tools`. Frontmatter has `description`, `argument-hint`, and `model: opus` for 1-5 only.

| Cmd | Reads | Writes | Agents |
|---|---|---|---|
| 1-question (`Q/commands/1-question.md:1-67`) | the ticket or input | `mkdir thoughts/qrspi/<id>/` (id `PROJ-1234-desc` or `YYYY-MM-DD-desc`, `:33-36`), `task.md` (`:38`), `questions.md` (`:40-53`) | codebase-locator (`:19`) |
| 2-research (`Q/commands/2-research.md`) | `questions.md` only (`:13`) | `research.md`, about 300 lines (`:32-54`) | locator, analyzer, pattern-finder in parallel (`:22-24`) |
| 3-design (`3-design.md`) | task, questions, research (`:13`) | `design.md`, about 200 lines, after asking 3-5 questions and waiting (`:21-66,79`) | optional pattern-finder or analyzer |
| 4-structure | design, research (`:13`) | `structure.md` (`:38-63`) | none |
| 5-plan | structure, design, research (`:13`) | `plan.md` with mandatory `- [ ]` boxes (`:25-60,79`) | none |
| 6-worktree | checks plan.md exists (`:61`) | `git worktree add ~/wt/<repo>/<branch> -b <branch>` after confirmation, then `cp -r` of the artifacts (`:21-45`) | none |
| 7-implement | plan.md and the phase files (`:12,18`) | code, ticked boxes, one commit per phase "Phase N: <name>" (`:36-38`) | used sparingly |
| 8-pr | design.md, `git diff/log` (`:12-19`) | `gh pr create` or `gh pr edit` (`:22-59`) | none |

- Each command ends with "Next: run `/qrspi-plan-toolkit:N-…`". Commands 1-5 also have a "When to Go Back" section.

**Agents.** All are read-only and use model sonnet:
- codebase-locator: `Grep, Glob, LS` (`Q/agents/codebase-locator.md:2-5`).
- codebase-analyzer: `Read, Grep, Glob, LS` (`Q/agents/codebase-analyzer.md:2-5`).
- codebase-pattern-finder: `Grep, Glob, Read, LS` (`Q/agents/codebase-pattern-finder.md:2-5`).
- web-search-researcher: `WebSearch, WebFetch, TodoWrite, Read, Grep, Glob, LS` (`Q/agents/web-search-researcher.md:2-6`). No command spawns it by name.

**Blindness of 2-research is instruction-only.**
- "That file is your only input" (`Q/commands/2-research.md:13`). "Do NOT read `task.md`" (`:15`, `:68`). "You do not know what is being built" (`:9`).
- No tool restriction exists. `task.md` sits in the same directory (`1-question.md:38`), and the subagents have unrestricted Read (`codebase-analyzer.md:4`).
- Upstream, 1-question forbids putting goals in questions.md (`1-question.md:65-67`). Rationale: `Q/README.md:109`.

**Manifest and detection**
- `Q/.claude-plugin/plugin.json:2-3` has name `qrspi-plan-toolkit`, version `1.0.0`, MIT license, upstream github.com/matanshavit/qrspi (`:9`). It has no `commands` or `agents` keys; both are discovered from the default directories.
- `marketplace.json` defines `qrspi-marketplace` (`:2-12`). Install: `/plugin marketplace add <path>` then `/plugin install qrspi-plan-toolkit@qrspi-marketplace` (`Q/README.md:67-68`). Dev mode: `claude --plugin-dir` (`:74`).
- Namespace is `/<plugin>:<file-basename>`, hardcoded in the "Next:" lines (`Q/README.md:11-18,85-98,114`).
- The only documented availability check is typing `/qrspi-plan-toolkit:` and seeing 8 autocompletions (`Q/README.md:79`).
- In this session the commands appear in the skill list as `qrspi-plan-toolkit:1-question`…`8-pr`, and the agents appear as `qrspi-plan-toolkit:codebase-locator` etc. (observed).
- There are no hooks, skills or MCP servers (`Q/README.md:35`).

**trainme usage** (non-empty line counts; task.md exists in all six dirs and was not read)

| Dir | questions | research | design | structure | plan | extras |
|---|---|---|---|---|---|---|
| 2026-07-08-trainme-ios-app | 44 | 224 | 125 | 173 | 533 | decisions.md, tooling-notes.md |
| 2026-10-26-review-gaps-and-app-icon | 45 | 130 | 158 | 121 | 955 | – |
| 2026-10-26-tech-debt | 40 | 125 | 182 | 149 | 1037 | – |
| 2026-10-26-p1-reporting | 17 | 119 | 158 | 135 | 1308 | – |
| 2026-10-26-ui-refresh-and-icon | 46 | 389 | 143 | 162 | 973 | screenshots/ (44 PNG) |
| GH-7-series-edit-cancel-calendar | 36 | 349 | 150 | 127 | 734 | – |

- Every plan.md uses `- [ ]`/`- [x]`. Three have unchecked boxes left: ios-app 13/10, ui-refresh 22/16, review-gaps 23/23 (checked/unchecked).
- Plans run 533-1308 lines, above the guidance in `Q/commands/5-plan.md:82`.
- `T/GH-7-series-edit-cancel-calendar/plan.md:1-66`: a conventions block (exact build and test commands, a test baseline of 115) comes before the `## Phase 1` sections. Those sections use `#### 1. … **File**:` and code snippets.
- `T/GH-7-…/research.md:1-40`:
  - It opens with a "Refreshed 2026-11-01 against origin/main @ 01ddbaf" note.
  - It defines path abbreviations and cites `file:line` densely.
  - At 349 lines it is over the ~300 target.
- `T/2026-07-08-trainme-ios-app/decisions.md:1-4` records resolved PRD decisions "from owner".
- `tooling-notes.md:3-15` is a tooling assessment written during the Question phase. It names web-search-researcher as useful for phase 2.
- No directory has any artifact from phases 6-8.

## Q4: What is publicly documented about the World of Warcraft: Forever client?

### Findings
**What it is**
- "World of Warcraft: Forever" ("Classic+") was announced at BlizzCon on 2026-09-12. Beta began 2026-09-17 and launch is 2026-11-04.
  - Source: blizzardwatch.com/2026/09/12/world-warcraft-forever-…-november-4-2026/ (2026-09-12).
  - Source: warcraft.wiki.gg/wiki/Patch_1.60 (latest cited item 2026-10-22).
- The game: level cap 60, Windows and macOS, raids unlocking 2026-12-09, Hardcore planned for winter 2026/27 (wiki Patch_1.60).
- Internal codename is **Camelot**. The client version is **1.60.x**.
- **Gethe/wow-ui-source** `forever` branch (verified via the GitHub API): HEAD is commit `ca8368f2` "1.60.1 (70532)", dated 2026-10-22.
- Beta builds listed on the wiki: 70009 (09-23), 70170 (10-01), 70291 (10-07, Beta 4), 70425 (10-16, Beta 5). No launch build was seen. [U]

**TOC and Interface number**
- **Interface 16001** is listed for Forever Beta and Test, with the Live cell blank. The page is flagged "may be outdated". Source: warcraft.wiki.gg/wiki/TOC_format (last edited 2026-10-17).
- The BigWigs packager maps `16???` → `forever` (verified, `release.sh:212,228,1305`). Its README example includes `16001`.
- Comma-separated multi-interface lines are supported (since 10.2.7). Same TOC_format page, 2026-10-17. Whether the Forever client honors them is [U].
- Flavor TOC suffixes on the same page: `_Forever.toc` and `_Camelot.toc` for Forever.
  - The family suffix `_Mainline.toc` covers standard, forever, camelot, plunderstorm and wowhack. `_Classic.toc` covers vanilla through mists.
  - Wago's game API lists Forever TOC suffixes `-Camelot, _Camelot, -Forever, _Forever` (verified: addons.wago.io/api/data/game, 2026-11-01).
  - The packager writes `_Camelot.toc` for generated Forever TOCs (verified, `release.sh:2014`).

**API lineage**
- Wiki API notes entry dated 2026-09-15: Forever and Midnight are "two game types within the Mainline code family". Source: warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes (last updated 2026-10-17).
- The API diff base is 12.1.5 (build 69952) → 1.60.1 (70205), dated 2026-10-02. Source: warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes (latest entry 2026-10-16).
- So the lineage is Mainline/Retail, not Classic Era or Anniversary.
- Midnight addon restrictions ("secret values") reportedly also apply in Forever. Secondary sources only: gamewave.fr and Icy Veins (the Icy Veins page returned 403; dates not captured). [U]

**C_* namespaces** (verified in the Gethe `forever` branch tree, 2026-10-22)
- `Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua:5` has `Namespace = "C_Container"`.
- `UnitAuraDocumentation.lua:5` has `Namespace = "C_UnitAuras"`. Its `GetAuraDataByIndex` is at `:208`.
- `AddOnsDocumentation.lua` is present (C_AddOns).
- `C_Timer` is used by Blizzard code in the branch (`Blizzard_SharedXMLBase/TimerUtil.lua:15`, `C_Timer.NewTimedSignalMap`). No `C_Timer` documentation file exists there, so its exact function list is [U].
- `Blizzard_Settings/Blizzard_Settings.lua` and its `.toc` exist (Settings UI).
- The `C_UnitAuras.GetRefreshCarryOverDuration` change is listed on the wiki API_changes page.

**API dumps and source mirrors**
- Gethe/wow-ui-source branches (verified 2026-11-01): `automation, beta, classic_anniversary, classic_beta, classic_era_ptr, classic_era, classic_ptr, classic_titan, classic, forever, live, ptr, ptr2`. The `forever` branch includes `Blizzard_APIDocumentationGenerated` (the data `/api` reads).
- The wiki's FrameXML config points Forever to `Ketho/wow-ui-source-forever` (warcraft.wiki.gg/wiki/Module:Wowapi/data/cfg, date not captured).
- The wiki API_changes page links diffs from Gethe `12.1.5..forever` and Ketho/BlizzardInterfaceResources `12.1.5..1.60.1`.
- Whether in-game `/api` works in the Forever client is [U].

**WOW_PROJECT_ID**
- **18 = `WOW_PROJECT_CAMELOT`**, added in 1.60.1 Beta. Source: warcraft.wiki.gg/wiki/WOW_PROJECT_ID (last edited 2026-10-17; flagged possibly out of date).
- Other values on that page: 1 MAINLINE, 2 CLASSIC (Era/Anniversary), 5 BURNING_CRUSADE_CLASSIC, 11 WRATH, 14 CATA, 19 MISTS.

**Reference TOC numbers** (TOC_format, 2026-10-17)

| Flavor | Interface |
|---|---|
| Retail (Midnight) Live | 120105 |
| Retail Test | 120107 |
| Classic Era Live | 11509 |
| TBC Anniversary Live | 20506 |
| Mists Live | 50504 |
| Cata Live | 40402 |
| Wrath Live | 30405 |
| Titan Reforged | 38002 |

## Q5: What does the BigWigs packager expect, and do CurseForge and Wago expose a Forever game version?

### Findings
Source: github.com/BigWigsMods/packager, `release.sh` on master, 3441 lines. Latest commit `0f24d216` is dated 2026-10-10 and the latest release is v2.6.1, published 2026-09-18 (both verified via the GitHub API).
- **.pkgmeta keys** parsed by release.sh: `enable-nolib-creation` (`:1038`), `enable-toc-creation` (`:1043`), `manual-changelog` (`:1051,1103`), `package-as` (`:1058`), `externals` (`:2403`).
  - The README also lists `ignore`, `plain-copy`, `move-folders`, `license-output`, `changelog-title`, `tools-used`, `required-dependencies`, `optional-dependencies`, `embedded-libraries`, and WoWI options `wowi-archive-previous`, `wowi-create-changelog`, `wowi-convert-changelog`.
  - Externals take `url`, `tag` and `type`. Without a type it is inferred: `*.zip` gives zip, `svn:` gives svn, otherwise git. An external's own .pkgmeta is read only for `ignore`.
  - README: "nolib packages will only be uploaded to GitHub and attached to a release". A manual changelog, if set, is always used.
- **Tokens** substituted by sed at `release.sh:1544-1550`: `@project-abbreviated-hash@`, `@project-date-iso@`, `@project-version@`, `@file-revision@`.
  - The README also lists file and project variants (hash, author, date-integer, timestamp), `@build-date@`/`-iso@`/`-integer@`, `@build-timestamp@` and `@localization(...)@`.
  - Build-type comment blocks: alpha, debug, do-not-package, no-lib-strip, retail, and version-{retail,classic,bcc,wrath,cata,mists}. Each takes a `non-` prefix, except do-not-package.
  - release.sh also handles `version-forever`, `version-titan` and `version-vanilla` (verified, `:1924-1991`).
- **TOC handling**:
  - Reads `## X-Curse-Project-ID`, `## X-WoWI-ID` and `## X-Wago-ID`.
  - A comma-separated `## Interface:` line is allowed. README example: `11509, 20506, 30405, 38002, 40402, 50504, 120100, 16001`.
  - `## Interface-[Type]:` lines with `-S` or `enable-toc-creation` generate per-flavor TOCs. For Forever the file is `_Camelot.toc` (`:2014`).
  - `_Mainline` TOCs are allowed to carry both retail and forever (`:1242-1252`).
- **Game version selection**:
  - The game type comes from the TOC Interface prefix (`16???` → forever, `:212,228`) or from `-g`.
  - `-g` accepts `retail|classic|bcc|wrath|cata|mists|titan|forever`, plus the alias `camelot` → forever (`:308-323`). The flavor map is at `:80`. README examples: `-g classic`, `-g 1.15.9`, `-g "5.5.4,1.15.9"`.
- **CurseForge upload**:
  - GETs `$project_site/api/game/wow/versions` with header `x-api-token` (`:2896`).
  - Forever maps to `gameVersionTypeID` **88568** (`:2909`, verified). If the exact version is missing it falls back to the nearest lower one (`:2915-2932`).
  - The payload field is `gameVersions` (`:2956`).
- **Wago upload**:
  - Reads `https://addons.wago.io/api/data/game` `.patches` (`:3134`). The type map is bcc→bc, wrath→wotlk, mists→mop, otherwise the type as-is, so forever→`forever` (`:3140-3143`).
- **WoWInterface** uses `api.wowinterface.com/addons/compatible.json` (`:3017`). titan and forever share a branch in its type mapping (`:3026`).
- **Env vars**:
  - `CF_API_TOKEN` (`CF_API_KEY` deprecated), `GH_API_TOKEN`/`GITHUB_API_TOKEN` (`GITHUB_OAUTH` deprecated), `WOWI_API_TOKEN`, `WAGO_API_TOKEN`. A `.env` file in the top dir or cwd is loaded.
  - Dependencies: bash 4.3+, curl, zip, jq 1.5+ (for uploads), git/svn/hg as needed.
- **GitHub Action**:
  - README: `uses: BigWigsMods/packager@v2` with `args: -p <cf> -w <wowi> -a <wago>`.
  - The wiki workflow triggers on `push: tags: '**'` and runs `actions/checkout` with `fetch-depth: 0` (it shows `@v7` [U]), then `BigWigsMods/packager@v2`. Its env still uses the legacy names `CF_API_KEY` and `GITHUB_OAUTH: ${{ secrets.GITHUB_TOKEN }}`, plus `WOWI_API_TOKEN` and `WAGO_API_TOKEN`.
  - Source: warcraft.wiki.gg/wiki/Using_the_BigWigs_Packager_with_GitHub_Actions (last edited 2026-10-04).
- **Distinct Forever version**:
  - **Wago** (verified, addons.wago.io/api/data/game, 2026-11-01): `patches.forever = ["1.60.1"]` and `live_patches.supported_forever_patches = "1.60.1"`. For comparison, the same response has `supported_classic_patches = "1.15.9"` and `supported_retail_patches = "12.1.5"`.
  - **CurseForge**: addon pages list Flavor "Forever" and Game Version 1.60.1. Source: curseforge.com/wow/addons/foreverui (updated 2026-10-20).
  - The packager hardcodes CurseForge type id 88568 for Forever. `wow.curseforge.com/api/game/versions` returned HTTP 401 without a token, so its payload is [U].

## Q6: How are luacheck and busted configured and run for WoW addons?

### Findings
**`.luacheckrc` examples**
- BigWigs (raw.githubusercontent.com/BigWigsMods/BigWigs/master/.luacheckrc, date not captured):
  - `std="lua51"`, `max_line_length=false`, `exclude_files={"**/Libs"}`.
  - `ignore={"113/BigWigs","212/self","1/[A-Z][A-Z][A-Z0-9_]+","211","212","213"}`.
  - WoW API names live in `globals`, not `read_globals`.
- Capping (BigWigsMods/Capping): `std="lua51"`, `codes=true`, `exclude_files={"**/Libs"}`, `ignore={"111/SLASH_Capping1","113/BasicMessageDialog","212/self"}`. Its `globals` lists `C_AddOns`, `C_ChatInfo`, `LibStub`, etc.
- WeakAuras2 (main/.luacheckrc, about 538k chars):
  - `std="lua51"`. It excludes `WeakAuras/Libs/` and generated files.
  - It ignores `11./SLASH_.*`, `11./BINDING_.*`, `113/LE_.*`, 211-214, 311, 314, 42., 43., 542 and 581-582.
  - It has a large `globals` list. Its `read_globals` is [U] (file read only partly).
- A gist defining a custom `stds.wow` with `std="lua51+wow"` (gist.github.com/LenweSaralonde/13a217b5…).
- The DBM, Details and Ace3 configs were not retrieved [U]. None of the files read uses `not_globals`.
- luacheck docs define `lua51` ("without deprecated ones") and `lua51c` (luacheck.readthedocs.io/en/stable/cli.html).

**Generated globals**
- Ketho/vscode-wow-api: LuaLS annotations, MIT, last push 2026-10-03. Its README does not mention luacheck.
- No published BigWigs "wow-globals" luacheck std and no luarocks "WoWAddOn" std was found [U].

**macOS install**
- `lua@5.1`: formulae.brew.sh returns 404. A homebrew-core commit "lua@5.1: disable" dated 2024-02-17 was seen in search [U].
- `luajit` 2.1.1793383622 is not deprecated (formulae.brew.sh/api/formula/luajit.json, 2026-11-01).
- `luarocks` 3.13.0 depends on Homebrew `lua`, not 5.1.
- `luacheck` 1.2.0 has bottles.
- hererocks (github.com/luarocks/hererocks, MIT, last push 2026-08-25) installs Lua/LuaJIT and LuaRocks into a local dir. The `hererocks env -l5.1 -rlatest` usage is untested [U].
- lunarmodules/luacheck: latest release v1.2.0 (2024-05-24), last push 2026-07-31.
- lunarmodules/busted: v2.3.0 (2026-01-07), MIT.

**GitHub Actions**
- `nebularg/actions-luacheck` (last push 2024-06-17).
- `leafo/gh-actions-lua` (2026-10-23).
- `leafo/gh-actions-luarocks` (2026-10-24).
- Inputs not fetched [U].

**WoW API mocks.** The features CreateFrame, events, C_Timer, SlashCmdList and SavedVariables are not stated in any of these READMEs [U] unless noted.

| Project | Description | Last push / release | License |
|---|---|---|---|
| wowless/wowless | "headless WoW client Lua and FrameXML interpreter. Intended for addon testing". Runs the real FrameXML. | 2026-11-01 | MIT |
| Adirelle/wowmock | LuaUnit + mockagne env; "most are not implemented yet" | 2014-09-14 | MIT |
| opussf/WoWTests | "Test framework and stubbing system for WoW" (Ant build) | 2025-12-25 | none listed |
| Booyaka101/wow-addon-sim | "stub layer built from real client captures" | 2026-10-11 | MIT |
| Hogtron-Solutions-Tech-Stack/hogsim | "Headless WoW Forever UI simulator … based on wowless" | 2026-11-01 | MIT |
| WoWUnit (wowace 17415) | In-game, with `mocks` table | last release 2014-11 per search snippet | – |
| WoWMock/LuaUnit (wowinterface 14863) | Offline luaUnit with partial API | – | – |

- No "wow-api-mock" or busted-specific WoW mock was found [U].

## Q7: How do public Ace3-based and vanilla addons structure files and boilerplate?

### Findings
- **Namespace**: every file receives `addonName, addonTable = ...`. The table is shared across the addon's files. Source: warcraft.wiki.gg/wiki/Using_the_AddOn_namespace (last edited 2025-09-16).
- **Load order**: warcraft.wiki.gg/wiki/AddOn_loading_process (last edited 2026-08-04).
  - Saved variables load after the last TOC file, unless `LoadSavedVariablesFirst` is set.
  - `ADDON_LOADED` is "the earliest time for an AddOn to read its saved variables".
  - `PLAYER_LOGIN` fires before the first `PLAYER_ENTERING_WORLD`. PEW fires on every loading screen.
  - The `arg1 == addonName` check is common practice but is not stated on that page [U].
- **TOC fields**: warcraft.wiki.gg/wiki/TOC_format (2026-10-17).
  - Field meanings:
    - `Interface` is comma-delimited.
    - `Title`, `Notes`, `Author`, `Version`.
    - `SavedVariables` is stored in `WTF/<acct>/SavedVariables/`. `SavedVariablesPerCharacter` is stored in `WTF/<acct>/<realm>/<char>/SavedVariables/`.
    - `OptionalDeps`, `IconTexture`, `Category`.
    - `AddonCompartmentFunc` names a global function.
  - Files load top to bottom. Only the first 1024 chars of each line are read. Flavor-suffixed TOCs take precedence over the plain one.
- **Ace3 tutorial**: warcraft.wiki.gg/wiki/WelcomeHome:_Your_first_Ace3_Addon (2024-05-26).
  - TOC has `## SavedVariables: WelcomeHomeDB`, `## OptionalDeps: Ace3` and `## X-Embeds: Ace3`.
  - `embeds.xml` loads `Libs\LibStub\LibStub.lua` first, then each library.
  - Core: `LibStub("AceAddon-3.0"):NewAddon("WelcomeHome","AceConsole-3.0","AceEvent-3.0")`. `OnInitialize` sets `self.db = LibStub("AceDB-3.0"):New("WelcomeHomeDB", defaults, true)` with a `profile` table, then calls `self:RegisterChatCommand("wh","ChatCommand")`.
- **Slash commands (vanilla)**: `SLASH_NAME1 = "/x"` + `SlashCmdList.NAME = function(msg, editBox) … end`. The key must match the `SLASH_<KEY>N` suffix. Source: warcraft.wiki.gg/wiki/UI_beginner%27s_guide (search snippet; date not captured) [U].
- **Ace3 sourcing**: github.com/WoWUIDev/Ace3 README (date not captured).
  - The WoWAce SVN `https://repos.wowace.com/wow/ace3/trunk/<Lib>` "remains the primary authority, and what should be used in .pkgmeta".
  - It recommends referencing individual libraries rather than the whole package.
- **Example repos**
  - **ketho-wow/HelloAce** (last commit 2025-04-17): hard-embedded `Libs/` listed directly in the TOC (LibStub, CallbackHandler, then Ace libraries), then `Core.lua` and `Options.lua`.
    - TOC: Interface 110007, `SavedVariables: HelloAceDB`.
    - `OnInitialize` builds AceDB with a "Default" profile plus AceConfig and AceDBOptions panels, and registers `/ha` and `/helloace`.
    - `OnEnable` registers events.
    - README: "The Ace3 libs are hard-embedded … for simplicity". It recommends soft-embedding via .pkgmeta.
  - **iamcal/wow-NewAddon** (last commit 2012-10-09): single file, Interface 40300, per-character SavedVariables, defaults filled on load, position saved on logout. It does not use the `...` namespace [U].
  - **TekNoLogic/addontemplate** (last commit 2009-12-14): split into `EventDispatcher.lua`, `Slashcommand.lua`, `Database.lua`, `Locale.lua`, `UtilityFunctions.lua` and `LibStub.lua`. Contents not read [U].
  - **yak3d/wow-minimap-consolidator** (last commit 2026-10-07, self-described template): `__ADDON_NAME__/`, `.github/workflows/`, `.pkgmeta` (package-as, move-folders and ignore, no externals), `.luacheckrc`, `Makefile`. Its claimed "SavedVariables with defaults and migration hook" is not verified [U].
- No verified public example was found of a schema-version migration function, or of `## Category`/`## IconTexture`/`## AddonCompartmentFunc` in use [U].

## Cross-Cutting Observations
- **Forever naming.** Forever has two names across tools. "Camelot" is the internal and API name: `WOW_PROJECT_CAMELOT`, the `_Camelot.toc` the packager generates, and `-g camelot`. "Forever" is the public name: the CurseForge and Wago flavor, `_Forever.toc`, and `-g forever`. The wiki, Wago and the packager all accept both.
- **Forever version numbers.** The Forever client reports version 1.60.x and Interface 16001, while its code lineage is Mainline 12.1.5. The Interface prefix (16), not the lineage, is what the packager uses to classify it. Blizzard's own TOC family puts it under `_Mainline`, not `_Classic`.
- **Live values unconfirmed.** Every Forever number seen (16001, 1.60.1, builds) dates from beta (Sept–Oct 2026). Launch is 2026-11-04, three days after this research.
- **Instruction-only constraints.** The installed skills and the plugin enforce constraints through prose, not tool restrictions. Examples: 2-research blindness, and "read X when Y" pointers in SKILL.md files. Script paths in skills are relative to the skill directory, or use a `<skill>`/`{path_to_skill}` placeholder.
- **Two ways to declare WoW names in luacheck.** Public configs list WoW API names in `globals`, or define a custom `stds.wow`. No widely published generated luacheck std was located.

## Open Areas
- Forever **Live** Interface number and launch build. Whether in-game `/api` and the multi-value `## Interface` line work in the Forever client.
- `C_Timer` function list in Forever (no generated documentation file).
- CurseForge `/api/game/wow/versions` payload (needs a token). Only the packager's hardcoded type id 88568 is known.
- `.luacheckrc` for DBM, Details and Ace3, and `read_globals` in WeakAuras2.
- Feature coverage (CreateFrame, events, C_Timer, SlashCmdList, SavedVariables) of wowless, hogsim, wow-addon-sim and WoWTests. None was verified at code level.
- Current Homebrew status of `lua@5.1` (404 plus a 2024 "disable" commit seen in search). Behavior of `luarocks --lua-version=5.1` and `hererocks` was not exercised (no Lua tooling installed locally).
- AceDB defaults and profile semantics, and AceConsole docs, were not fetched beyond the tutorial.
