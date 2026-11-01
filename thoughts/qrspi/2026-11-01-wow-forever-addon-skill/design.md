# Design Discussion

Inputs: `task.md`, `questions.md`, `research.md` (cited as `R:<line>`), PRD `wow-addon-skill-prd.md` v0.2. Decisions below were agreed with the owner on 2026-11-01 ("take all recommendations"). Where this document and the PRD disagree, this document wins.

## Current State

**Repo.** `wowskill` holds only `README.md`, `LICENSE` (GPL-3.0), the untracked PRD, and `thoughts/qrspi/`. No Lua tooling is installed locally (`lua`, `luajit`, `luacheck`, `busted`, `luarocks` are all absent). Nothing is installed at `~/.claude/skills` or `.claude/skills` (R:98).

**Forever is not what the PRD assumed.** The PRD treats Forever as a Classic lineage with a "delta vs Classic Era". Research shows:
- Forever ("Classic+", codename Camelot, client 1.60.x) is a **Mainline-family** game type built from **12.1.5** code (R:188-190). It launches **2026-11-04**, so every number we have dates from the beta (R:170, R:352).
- `## Interface: 16001` (beta/test; the live value is blank on the wiki) (R:179). TOC suffixes are `_Forever`/`_Camelot`. `_Mainline` covers Forever; `_Classic` does not (R:182-185).
- `C_Container`, `C_UnitAuras` (incl. `GetAuraDataByIndex`) and `C_AddOns` exist in the Forever branch (R:194-196). The PRD's "never emit" examples are therefore inverted.
- Blizzard's generated API docs for Forever live in Gethe/wow-ui-source branch `forever` (`Blizzard_APIDocumentationGenerated/`, HEAD "1.60.1 (70532)", 2026-10-22) (R:175, R:202).
- `WOW_PROJECT_ID` 18 = `WOW_PROJECT_CAMELOT` (R:208). Midnight's "secret value" restrictions reportedly apply [U] (R:191).

**Distribution ecosystem already knows Forever.**
- BigWigs packager maps `16???` → `forever` and accepts `-g forever|camelot` (R:242-243). It uploads to CurseForge type 88568 (R:246) and to Wago `forever` (R:249). It generates `_Camelot.toc` (R:239).
- Wago lists `forever` 1.60.1 (R:259), and CurseForge pages show a "Forever" flavor (R:260).
- Secrets: `CF_API_TOKEN` and `GH_API_TOKEN`. `CF_API_KEY` and `GITHUB_OAUTH` are deprecated, although the wiki workflow still uses them (R:252, R:256).

**Skill and plugin conventions on this machine.**
- `SKILL.md` frontmatter keys are limited to `name, description, license, allowed-tools, metadata, compatibility`. There is exactly one `SKILL.md` per tree, `description` is at most 1024 chars, and `name` matches `^[a-z0-9-]+$` (R:17-22).
- The description is the only trigger (R:25-26). Keep the body under 500 lines, and give references over 300 lines a table of contents (R:31-32).
- Plugins: only `name` is required in `.claude-plugin/plugin.json`. Skills sit at `skills/*/SKILL.md`, and `commands/` is legacy (R:101-104). There is no dependency field, and qrspi is detected only by its presence in the skill list (R:137-141).

**Tooling facts.**
- `luajit` and `luacheck` are available from Homebrew. `lua@5.1` was likely disabled [U], and `luarocks` there targets Lua 5.4 (R:285-288).
- Public `.luacheckrc` files use `std="lua51"`, exclude `**/Libs`, and put WoW names in `globals` (R:267-277).
- Mocks: `wowless`/`hogsim` (high fidelity, unverified) and the stale `wowmock` (2014) (R:301-309).

## Desired End State

A Claude Code **plugin repo** whose single skill, `wow-forever-addon`, makes Claude produce Forever addons that load cleanly. Verified by:
1. `quick_validate.py skills/wow-forever-addon` exits 0.
2. `scripts/scaffold.sh` produces a vanilla addon and an Ace3 addon. On both, `lint.sh` is green and `test.sh` is green under `luajit`.
3. The scaffolded addons `/reload` in the Forever client with zero errors. This is a manual check, after launch.
4. `examples/` contains one worked addon with tests and a `release.yml` that uploads to CurseForge and Wago from a tag (milestone M4).
5. `luacheck` with the generated Forever globals flags a Classic-Era-only or removed call, e.g. global `GetContainerItemInfo` (verify which names are actually absent in Forever).
6. A trigger eval (`run_eval.py`) over about 20 WoW and non-WoW prompts reaches the threshold (R:47-52).
7. One addon goes through QRSPI phases 1-8 using the skill's inputs (milestone M6).

## Patterns to Follow

**Skill authoring**
- A "Read before you touch" routing table in SKILL.md that maps situation → `references/<x>.md`, as in google-workspace (R:82). Every reference gets a "when to read" line (R:32).
- Scripts are invoked as `scripts/<x>.sh` relative to the skill dir, or via the `<skill>` placeholder (R:87-92). No `${CLAUDE_SKILL_DIR}`, because nothing on this machine uses it (R:94).
- A "pushy" trigger description under 1024 chars, listing the PRD §6 trigger phrases plus "Forever", "Camelot" and `.toc` (R:25-27).
- Domain split for future flavors: `references/forever-*.md` now. Later flavors get sibling files, following the aws/gcp/azure pattern (R:32).

**QRSPI integration**
- Name the commands only in `references/qrspi-handoff.md`. They are `/qrspi-plan-toolkit:N-name` (R:139).
- Detect qrspi via the skill list (R:141). Research blindness is instruction-only (R:131-133), so WoW references must stay neutral fact files with no addon intent in them.
- Supplementary artifacts such as `decisions.md` are fine. trainme did it (R:162), and this repo now has `backlog.md`.

**Addon boilerplate** (templates)
- `local addonName, ns = ...` in every file (R:316).
- Read saved variables only from `ADDON_LOADED` with `arg1 == addonName`. Do world-dependent setup on `PLAYER_LOGIN`, not PEW, because PEW repeats (R:318-321).
- Vanilla slash commands use `SLASH_<KEY>1` and `SlashCmdList.<KEY>` (R:334).
- Ace3: `NewAddon` → `OnInitialize` (AceDB with defaults and a profile, AceConfig and AceDBOptions panels, chat command) → `OnEnable` (event registration). Follow HelloAce for structure (R:339-343).
- Ace3 libs come in as soft embeds: `.pkgmeta` externals from `repos.wowace.com/wow/ace3/trunk/<Lib>`, per library (R:336-337), and `embeds.xml` loads LibStub first (R:332).
- `.luacheckrc`: `std="lua51"`, `max_line_length=false`, `exclude_files={"**/Libs"}`, `ignore` 211/212/213 plus `212/self`, and WoW names from a generated file (R:268-270).

**Do NOT follow**
- The wiki's GitHub Actions example's env names (`CF_API_KEY`, `GITHUB_OAUTH`). They are deprecated (R:252, R:256).
- Hard-embedded Ace3 `Libs/` committed to the repo (HelloAce does it "for simplicity") (R:343).
- Huge hand-maintained `globals` lists (WeakAuras is about 538k chars) (R:272-275). Generate the list instead.
- The PRD's Classic-delta framing and its inverted "never emit" examples.
- trainme's 500-1300-line plans (R:156). Keep `plan.md` closer to the command's guidance.

## Design Decisions

1. **Packaging: the repo is a plugin.** `.claude-plugin/plugin.json` (+ `marketplace.json`), with the skill at `skills/wow-forever-addon/` (`SKILL.md`, `references/`, `templates/`, `scripts/`). `examples/`, `evals/`, the repo README, LICENSE and CI stay at the repo root. Install mirrors qrspi (`/plugin marketplace add` then `/plugin install`). There are no commands in v1, but the layout leaves room for `/wow-new`. *Why:* this matches how the owner installs plugins, it keeps the example addon's CI out of the skill folder, and it satisfies the one-SKILL.md rule (R:21).

2. **API knowledge is generated plus curated.**
   - `scripts/gen-api.sh` (or `.lua`) shallow-fetches Gethe/wow-ui-source `forever`, parses `Blizzard_APIDocumentationGenerated/*.lua`, and writes two files:
     - (a) `templates/luacheck/forever-globals.lua`, a luacheck `stds.forever` with `read_globals` for every documented namespace and function plus the FrameXML globals we need;
     - (b) `references/forever-api-index.md`, a compact namespace → function list with a ToC.
   - Hand-curated `references/forever-api-notes.md`. This replaces `forever-api-delta.md` and covers:
     - differences from Retail 12.1.5: restored Classic systems (`C_SwingTimer`, `C_Trainer`, `C_PetInfo`, …), Forever-specific changes, and the Midnight secret-value rules;
     - a **never-emit** list: Classic Era-only and removed globals that don't exist in Forever. It goes into luacheck `not_globals`.
   - Every entry is date-stamped and carries a source.
   - *Why:* this gives an exact, auditable allowlist from Blizzard's own docs, and luacheck catches hallucinated APIs automatically.

3. **Offline harness: own minimal mock plus a test runner on `luajit`.**
   - `scripts/wowmock/` is plain Lua (5.1/LuaJIT compatible) and covers:
     - `CreateFrame` (with a frame-method subset), `RegisterEvent`/`FireEvent`;
     - `C_Timer.After`/`NewTicker` with a manual clock, and `GetTime`;
     - `UnitName`/`UnitClass`;
     - `SlashCmdList` dispatch and saved-variable load/save to a temp file;
     - `LibStub` plus Ace stubs, enough to run AceAddon lifecycle hooks.
   - A small busted-style runner (`describe`/`it`/`assert`) ships with the mock.
   - Setup is `brew install luajit luacheck`, with no luarocks and no busted.
   - The harness documents what it does *not* cover: taint, rendering, secure frames and secrets.
   - `hogsim`/`wowless` are noted in the references as a possible higher-fidelity tier, unverified and not wired in.
   - *Why:* portable, zero-dependency, and grows from test failures (PRD §9.4).

4. **TOC: a single `Name.toc` with `## Interface: 16001`.**
   - The Interface value lives in exactly one place, `references/toc-format.md` (front-matter-style "as of" line), and `scaffold.sh` reads it from there.
   - The skill tells users to confirm the live value with `/dump select(4, GetBuildInfo())` after 2026-11-04, then update that one line.
   - `## Version: @project-version@`, plus `X-Curse-Project-ID`/`X-Wago-ID` placeholders.
   - *Why:* simplest. Forever-only suffix files can come later if Retail loading becomes a problem.

5. **Release: BigWigs packager `@v2`.**
   - `release.yml` triggers on a tag push, uses `fetch-depth: 0`, and sets env `CF_API_TOKEN`, `WAGO_API_TOKEN`, and `GH_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}`.
   - The game type is auto-detected from Interface 16001, so no `-g` flag is needed.
   - `.pkgmeta` holds `package-as`, per-library Ace3 `externals`, `manual-changelog: CHANGELOG.md`, `enable-nolib-creation: no`, and `ignore: [tests, thoughts, .github, .luacheckrc, *.md except README]`.

6. **License: MIT.** Replace the repo's GPL-3.0 `LICENSE` with MIT. Generated addons get an MIT `LICENSE` by default, and `scaffold.sh --license` can change it.

7. **Ace3 vs vanilla criteria and the QRSPI routing table: as in PRD §5.1 and §5.7**, unchanged.
   - `web-search-researcher` runs only when `references/` lacks a fact, and it must label Forever confidence.
   - When qrspi is absent, the skill falls back to the PRD §7.1-7.4 direct workflows with a one-line install hint.

8. **Milestone order: M1 → M2 → M3 → M6 → M5 → M4 → M7.** M4 (a real CurseForge/Wago publish) needs live projects and tokens, so it is gated on the owner. M6 (QRSPI handoff) comes earlier because the owner uses QRSPI daily. Each milestone is one PR, per PRD §13.

## What We're NOT Doing

- Supporting any flavor other than Forever: no Retail, Classic Era, Anniversary, Mists or Titan. Separate reference files are the extension path.
- Multi-TOC or `_Forever`/`_Camelot` suffix files in v1.
- Integrating `wowless`/`hogsim`, or emulating taint, secure frames, secret values or rendering.
- Committing Ace3 libraries to the skill repo. Tests use stubs only.
- A full API doc mirror. The generated index lists names only; prose stays curated.
- Slash commands or hooks in the plugin in v1.
- A CurseForge API key for gap analysis. Gap analysis uses web search and fetch, and degrades to "unverified".
- WoWInterface uploads. The packager supports them, but they aren't in the PRD.
- Automating in-game verification.

## Open Risks

- **Launch drift (2026-11-04).** The live Interface number, API surface and build may change from beta 1.60.1 (R:352). Mitigation: Interface sits in one place, `gen-api` is re-runnable, and entries are date-stamped.
- **Generator input format.** `Blizzard_APIDocumentationGenerated` is Lua tables. Parsing them needs a Lua runtime (luajit) or a careful pattern parser. FrameXML globals (frames, mixins, constants) are not in those docs and need a supplementary list.
- **Secret-value restrictions** are only reported secondhand [U] (R:191). Curated notes must label them unverified until the owner confirms them in-game.
- **Never-emit accuracy.** Which Classic Era globals are actually absent in Forever (`GetSpellInfo`, `UnitAura`, `GetContainerItemInfo`) is not yet verified. The generated index decides this, not memory.
- **Mock fidelity** gives false confidence. Mitigation: the in-game checklist is mandatory in every workflow.
- **Trigger evals** need the `claude` CLI and PyYAML (R:22, R:65). The owner's environment must provide both.
- **Ace stub drift.** The minimal Ace stubs may diverge from real AceDB semantics (defaults and profiles not fetched, R:363). Keep the stubs small and test against real libs in-game.
- **LICENSE change** from GPL-3.0 to MIT is fine while the owner is the sole author. Confirm there are no outside contributions first.
