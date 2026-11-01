# Implementation Plan

## Overview
Turn `wowskill` into a Claude Code plugin whose single skill, `wow-forever-addon`, produces WoW Forever addons that load cleanly. Its API knowledge is generated from Blizzard's `forever` docs, and its offline gate is `lint.sh` and `test.sh` run under `luajit`. It also routes non-trivial work through QRSPI and ships a tag-to-CurseForge/Wago release pipeline. Sources: `design.md`, `structure.md` (P0–P8), `research.md`.

## Conventions & commands

**Paths and the gate**
- Repo root is `$ROOT` = `/Users/madacgrav/Source/wowskill`.
- Skill dir is `$SK` = `$ROOT/skills/wow-forever-addon`.
- **Gate after every phase:** `scripts/check.sh` (repo root) exits 0. Commit per phase as `Phase N: <name>` (7-implement convention).

**Host facts (checked 2026-11-01)**
- macOS bash is **3.2**, so all `.sh` must be bash-3.2 safe: no associative arrays, no `${x,,}`, no `mapfile`.
- Avoid `sed -i`, because it differs between BSD and GNU. Put text processing in Lua (luajit).
- `python3` exists but **PyYAML is missing**, so `check.sh` falls back to a stdlib frontmatter checker.
- `jq` and `git` exist. `svn` and the `claude` CLI are **not** on PATH. Lua tooling is absent.

**One-time setup:** `brew install luajit luacheck`. P7 additionally needs `brew install bash` (the packager needs bash ≥ 4.3).

**Lua compatibility:** every Lua file under `$SK/scripts/` and `$SK/templates/` must run on LuaJIT 2.1 / Lua 5.1, so use `setfenv`, `unpack` and `loadfile`, with no `goto` and no integer ops.

**Script references in SKILL.md and references:** write them as `<skill>/scripts/x.sh`, following the google-workspace pattern (research.md:92). Never use `${CLAUDE_SKILL_DIR}`.

**Interface value:** lives only in `$SK/references/toc-format.md` on a line matching `^Interface: (%d+)`. Everything else reads it from there.

**Generated files** (`forever-api-index.md`, `forever-std.lua`) are committed. If `gen-api.sh` fails because the network or the source is unavailable, keep the committed versions and add missing names by hand to `EXTRA_GLOBALS` in `gen_api.lua`. Note the gap in `forever-api-notes.md`.

---

## Phase 0: Installable plugin skeleton

### Changes

#### 1. Plugin manifests
**File**: `.claude-plugin/plugin.json` — create
```json
{
  "name": "wow-forever-addon",
  "version": "0.1.0",
  "description": "Build, test and release World of Warcraft: Forever (Classic+) addons with Claude Code.",
  "author": { "name": "Adam Graves", "email": "madacgrav@gmail.com" },
  "license": "MIT",
  "keywords": ["wow", "warcraft", "addon", "lua", "forever", "classic-plus"]
}
```
**File**: `.claude-plugin/marketplace.json` — create. Mirror qrspi's shape exactly: `{name: "wow-forever-addon-marketplace", owner{name,email}, plugins:[{name:"wow-forever-addon", source:"./", description}]}`.

#### 2. Skill
**File**: `skills/wow-forever-addon/SKILL.md` — create.
- The description goes on a single line with no `<` or `>`, at most 1024 chars. Check the length with `python3 -c`.
```markdown
---
name: wow-forever-addon
description: Build, debug, review, test and release World of Warcraft addons for WoW Forever (Classic+, codename Camelot, TOC Interface 16xxx). Use whenever the user mentions a WoW addon, World of Warcraft addon, Classic+ or WoW Forever addon, a .toc file, WoW Lua, CreateFrame, SavedVariables, WoW slash commands, BugSack or BugGrabber errors, addon taint, Ace3, CurseForge or Wago addon releases, or the BigWigs packager, or when a .toc file or WoW addon folder is in context, even if Forever is not named. Provides the Forever API surface generated from Blizzard docs, vanilla and Ace3 scaffolds, a luacheck config, an offline mock WoW API test harness, CurseForge gap analysis, a tag-to-CurseForge/Wago release pipeline, and routes non-trivial addon work through the qrspi-plan-toolkit planning flow.
license: MIT
---
```
- Body skeleton (filled in by later phases; keep it under 500 lines):
  1. `# WoW Forever addon development`
  2. `## Ground rules`. Forever is Mainline-family (12.1.5 code), client 1.60.x, Interface in `references/toc-format.md`. Verify every API name against `references/forever-api-index.md`. Never emit names on the never-emit list. Lint and test before handing anything over, and always finish with the in-game checklist.
  3. `## Read before you touch`. Table `Situation | Read first | Why`, with rows added per phase.
  4. `## Workflows`, `## Scripts` (table), `## In-game checklist`.

#### 3. Repo files
- `LICENSE` — replace with the MIT text: "Copyright (c) 2026 Adam Graves".
- `README.md` — rewrite with:
  - what it is;
  - install: `/plugin marketplace add /path/to/wowskill`, then `/plugin install wow-forever-addon@wow-forever-addon-marketplace`;
  - dev mode: `claude --plugin-dir .`;
  - prerequisites: `brew install luajit luacheck`.
- `.gitignore`: `.release/`, `*.skill`, `.cache/`, `evals/results/`, `*-workspace/`, `.env`.
- `scripts/check_frontmatter.py`. A stdlib-only mirror of quick_validate's rules (research.md:17-22):
  - allowed keys `name, description, license, allowed-tools, metadata, compatibility`;
  - `name` matches `^[a-z0-9]+(-[a-z0-9]+)*$` and is at most 64 chars;
  - `description` is at most 1024 chars with no `<` or `>`;
  - exactly one `SKILL.md` under the skill dir.
  - Parse with a regex over the `---` block, one `key: value` per line.

**File**: `scripts/check.sh` — create. It grows each phase, with later phases appending sections.
```bash
#!/usr/bin/env bash
# Repo gate: frontmatter, lint, tests, scaffold smoke. Exit non-zero on any failure.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SK="$ROOT/skills/wow-forever-addon"
SC="${SKILL_CREATOR_DIR:-$HOME/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/c783f22c-a674-4d4d-b0a0-a09dfb07d8e6/228f5f35-228d-4d15-a271-f62273597712/skills/skill-creator}"
fail=0
step() { printf '\n== %s\n' "$1"; }

step "frontmatter"
if [ -f "$SC/scripts/quick_validate.py" ] && python3 -c 'import yaml' 2>/dev/null; then
  python3 "$SC/scripts/quick_validate.py" "$SK" || fail=1
else
  python3 "$ROOT/scripts/check_frontmatter.py" "$SK" || fail=1
fi
# (P1+) lint fixtures, (P2+) scaffold smoke, (P3+) tests, (P5+) qrspi name isolation, (P6+) buggy fixture
exit $fail
```
Also commit `thoughts/` and `wow-addon-skill-prd.md`. Per the design, they are the design history.

### Verification
#### Automated
- [x] `scripts/check.sh` exits 0 (stdlib frontmatter fallback; PyYAML absent)
- [x] `python3 -c "import re;t=open('skills/wow-forever-addon/SKILL.md').read();d=re.search(r'^description: (.*)$',t,re.M).group(1);print(len(d));assert len(d)<=1024"` (791 chars)
- [x] `brew install luajit luacheck && luajit -v && luacheck --version`
- [x] `jq . .claude-plugin/plugin.json .claude-plugin/marketplace.json` parses

#### Manual
- [ ] `claude --plugin-dir .` lists the skill `wow-forever-addon:wow-forever-addon`. If the `claude` CLI is missing, install it via the desktop app's CLI install or `npm i -g @anthropic-ai/claude-code`.
- [ ] A new session with the plugin loaded: "help me write a WoW Forever addon that tracks soul shards" triggers the skill.

---

## Phase 1: Forever API knowledge + lint

### Changes

#### 1. Generator wrapper
**File**: `$SK/scripts/gen-api.sh` — create
```bash
#!/usr/bin/env bash
# Regenerate Forever API index + luacheck std from Gethe/wow-ui-source (branch: forever).
# usage: gen-api.sh [--ref forever] [--src DIR]
set -eu
SK="$(cd "$(dirname "$0")/.." && pwd)"
REF=forever; SRC=""
while [ $# -gt 0 ]; do case "$1" in --ref) REF="$2"; shift 2;; --src) SRC="$2"; shift 2;; *) echo "unknown arg $1" >&2; exit 2;; esac; done
if [ -z "$SRC" ]; then
  SRC="${XDG_CACHE_HOME:-$HOME/.cache}/wowskill/wow-ui-source-$REF"
  if [ -d "$SRC/.git" ]; then git -C "$SRC" fetch --depth 1 origin "$REF" && git -C "$SRC" checkout -q FETCH_HEAD
  else git clone --depth 1 --branch "$REF" https://github.com/Gethe/wow-ui-source.git "$SRC"; fi
fi
COMMIT="$(git -C "$SRC" log -1 --format='%h %s')"
DATE="$(git -C "$SRC" log -1 --format=%cs)"
luajit "$SK/scripts/gen_api.lua" "$SRC" "$SK" "$COMMIT" "$DATE"
```

#### 2. Generator
**File**: `$SK/scripts/gen_api.lua` — create. Doc files have the form `local X = { Name=, Type="System", Namespace="C_X"|nil, Functions={...}, Events={{LiteralName=...}}, Tables={{Type="Enumeration",...}} }; APIDocumentation:AddDocumentationTable(X);`.
```lua
-- luajit gen_api.lua <wow-ui-source> <skill-dir> <commit> <date>
local SRC, SK, COMMIT, DATE = arg[1], arg[2], arg[3] or "unknown", arg[4] or os.date("!%Y-%m-%d")

-- C-side / Lua-extension globals absent from the generated docs. Extend by hand when lint misses a real API.
local EXTRA_GLOBALS = { "CreateFrame", "UIParent", "SlashCmdList", "strsplit", "strtrim", "strjoin",
  "strlower", "strupper", "strlen", "strsub", "strfind", "strmatch", "gsub", "format", "tinsert",
  "tremove", "wipe", "tContains", "bit", "securecall", "issecurevariable", "hooksecurefunc",
  "InCombatLockdown", "GetTime", "GetBuildInfo", "debugstack", "geterrorhandler", "date", "time" }

local function lines(cmd) local t, p = {}, assert(io.popen(cmd)); for l in p:lines() do t[#t+1] = l end; p:close(); return t end
local function sorted(set) local t = {}; for k in pairs(set) do t[#t+1] = k end; table.sort(t); return t end

-- 1) Blizzard_APIDocumentationGenerated
local systems = {}
APIDocumentation = { AddDocumentationTable = function(_, t) systems[#systems+1] = t end }
local docdir = SRC .. "/Interface/AddOns/Blizzard_APIDocumentationGenerated"
for _, f in ipairs(lines('ls "' .. docdir .. '"/*.lua')) do
  local chunk, err = loadfile(f)
  local ok, perr = chunk and pcall(chunk)
  if not chunk or not ok then io.stderr:write("skip ", f, ": ", tostring(err or perr), "\n") end
end
assert(#systems > 0, "no documentation tables loaded from " .. docdir)

local ns, docGlobals, events, fxGlobals = {}, {}, {}, {}
for _, s in ipairs(systems) do
  for _, fn in ipairs(s.Functions or {}) do
    if s.Namespace then ns[s.Namespace] = ns[s.Namespace] or {}; ns[s.Namespace][fn.Name] = true
    else docGlobals[fn.Name] = true end
  end
  for _, ev in ipairs(s.Events or {}) do
    if ev.LiteralName then events[ev.LiteralName] = s.Namespace or s.Name end
  end
end

-- 2) FrameXML globals: top-level `function Name(` / `Name =` in Lua, `name="X"` in XML
for _, f in ipairs(lines('find "' .. SRC .. '/Interface" -name "*.lua"')) do
  for l in io.lines(f) do
    local n = l:match("^function%s+([%a_][%w_]*)%s*%(") or l:match("^([%a_][%w_]*)%s*=[^=]")
    if n and n ~= "local" and not ns[n] then fxGlobals[n] = true end
  end
end
for _, f in ipairs(lines('find "' .. SRC .. '/Interface" -name "*.xml"')) do
  local fh = io.open(f); local s = fh:read("*a"); fh:close()
  for n in s:gmatch('%sname="([%a_][%w_]*)"') do fxGlobals[n] = true end
end
for _, n in ipairs(EXTRA_GLOBALS) do fxGlobals[n] = true end

-- 3) never-emit list from forever-api-notes.md (between the markers), reported against what exists
local notes = io.open(SK .. "/references/forever-api-notes.md"):read("*a")
local block = notes:match("<!%-%- never%-emit:start %-%->(.-)<!%-%- never%-emit:end %-%->") or ""
local never = {}
for n in block:gmatch("\n%- `([%w_%.]+)`") do never[#never+1] = n end
for _, n in ipairs(never) do
  local where = docGlobals[n] and "DOCS (real API — remove from never-emit!)" or fxGlobals[n] and "FrameXML shim (keep; note as deprecated)" or "absent"
  io.stdout:write(("never-emit %-32s %s\n"):format(n, where))
  docGlobals[n], fxGlobals[n] = nil, nil
  local nsName, field = n:match("^([%w_]+)%.([%w_]+)$")
  if nsName and ns[nsName] then ns[nsName][field] = nil end
end

-- 4) luacheck std
local q = function(s) return ('"%s"'):format(s) end
local out = { ("-- GENERATED by gen_api.lua from Gethe/wow-ui-source@forever %s (%s). Do not edit.\n"):format(COMMIT, DATE),
  "stds.forever = { read_globals = {\n  Enum = { other_fields = true },\n" }
for _, n in ipairs(sorted(ns)) do
  local fs = {}; for _, f in ipairs(sorted(ns[n])) do fs[#fs+1] = q(f) end
  out[#out+1] = ("  %s = { fields = { %s } },\n"):format(n, table.concat(fs, ", "))
end
local all = {}; for k in pairs(docGlobals) do all[k] = true end; for k in pairs(fxGlobals) do all[k] = true end
all.Enum = nil
for _, g in ipairs(sorted(all)) do if not ns[g] then out[#out+1] = "  " .. q(g) .. ",\n" end end
out[#out+1] = "} }\n"
local fh = assert(io.open(SK .. "/templates/luacheck/forever-std.lua", "w")); fh:write(table.concat(out)); fh:close()

-- 5) index markdown: ToC, one section per namespace, doc globals, events
local md = { "# Forever API index\n\nGENERATED by `scripts/gen-api.sh` from Gethe/wow-ui-source@forever `" .. COMMIT .. "` (" .. DATE .. "). Do not edit; rerun the script.\n",
  "Names only. For signatures read the matching `*Documentation.lua` in that branch. Never-emit names are removed.\n\n## Contents\n" }
for _, n in ipairs(sorted(ns)) do md[#md+1] = ("- [%s](#%s)\n"):format(n, n:lower()) end
md[#md+1] = "- [Global functions (documented)](#global-functions-documented)\n- [Events](#events)\n"
for _, n in ipairs(sorted(ns)) do md[#md+1] = ("\n## %s\n%s\n"):format(n, table.concat(sorted(ns[n]), ", ")) end
md[#md+1] = "\n## Global functions (documented)\n" .. table.concat(sorted(docGlobals), ", ") .. "\n"
md[#md+1] = ("\nFrameXML/C globals allowed by lint: %d (see templates/luacheck/forever-std.lua)\n"):format(#sorted(fxGlobals))
md[#md+1] = "\n## Events\n"
for _, e in ipairs(sorted(events)) do md[#md+1] = ("- `%s` (%s)\n"):format(e, events[e]) end
fh = assert(io.open(SK .. "/references/forever-api-index.md", "w")); fh:write(table.concat(md)); fh:close()
print(("namespaces=%d docGlobals=%d frameXML=%d events=%d"):format(#sorted(ns), #sorted(docGlobals), #sorted(fxGlobals), #sorted(events)))
```

#### 3. Curated notes
**File**: `$SK/references/forever-api-notes.md` — create. Every bullet carries `(source, YYYY-MM-DD, confidence)`. Sections:
1. **What Forever is.** Mainline family, 12.1.5 base, client 1.60.x, `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT (18)` (research.md:188-190, 208).
2. **Differs from Retail 12.1.5.** Restored Classic systems (`C_SwingTimer`, `C_Trainer`, `C_PetInfo`, `C_StableInfo`, `C_SkillInfo`, …), `C_GameRules` hardcore and self-found flags, Lua `require` → `import`. Each item is verified against the generated index before it is written.
3. **Secret values / Midnight restrictions.** Labelled `[unverified in Forever]` (research.md:191).
4. **Never-emit list**, between `<!-- never-emit:start -->` and `<!-- never-emit:end -->`, one per line as `- \`Name\` — use X instead`. Initial candidates: `GetContainerItemInfo`, `GetContainerNumSlots`, `GetContainerNumFreeSlots`, `PickupContainerItem`, `UseContainerItem`, `UnitAura`, `UnitBuff`, `UnitDebuff`, `GetSpellInfo`, `GetSpellCooldown`, `GetSpellTexture`, `GetAddOnInfo`, `IsAddOnLoaded`, `GetNumAddOns`, `LoadAddOn`, `this`.
   - **After running gen-api, act on each candidate's report line:**
     - `DOCS`: the name is real API, so delete it from the list.
     - `FrameXML shim`: keep it, with the note "deprecated shim".
     - `absent`: keep it.
5. **How to verify a name.** grep `forever-api-index.md`, then the branch docs, then in-game `/dump`. Refresh with `<skill>/scripts/gen-api.sh` after each patch.

**File**: `$SK/references/toc-format.md` — create.
- First lines: `Interface: 16001`, then `(as of 2026-11-01, Forever beta/test; confirm after launch with /dump select(4, GetBuildInfo()) and update this line only)`.
- Then: directives (`Interface`, `Title`, `Notes`, `Author`, `Version: @project-version@`, `SavedVariables`, `SavedVariablesPerCharacter`, `OptionalDeps`, `X-Curse-Project-ID`, `X-Wago-ID`, `IconTexture`, `AddonCompartmentFunc`).
- Then: load order (files top to bottom; saved variables after the last file; 1024-char line limit).
- Then: suffix rules (`_Forever`/`_Camelot` > `_Mainline`; `_Classic` does not load). Cite research.md:179-185, 322-329.

#### 4. Lint config and runner
**File**: `$SK/templates/luacheck/base.luacheckrc` — create
```lua
std = "lua51+forever"
max_line_length = false
codes = true
exclude_files = { "**/Libs/**", "**/tests/wowmock/**", ".release/**" }
ignore = { "211", "212", "213", "212/self", "11./SLASH_.*", "11./BINDING_.*" }
globals = { "SlashCmdList" }   -- writable WoW globals addons legitimately assign into
files["**/tests/**"] = { std = "+busted" }
files["**/scripts/fixtures/**"] = { }
```
**File**: `$SK/scripts/lint.sh` — create. It concatenates the generated std, the base config and the addon's own `.luacheckrc`, then adds the never-emit and OnUpdate heuristics.
```bash
#!/usr/bin/env bash
# usage: lint.sh <addon-dir|file.lua>
set -u
SK="$(cd "$(dirname "$0")/.." && pwd)"
T="${1:?usage: lint.sh <addon-dir|file.lua>}"
CFG="$(mktemp)"; trap 'rm -f "$CFG"' EXIT
cat "$SK/templates/luacheck/forever-std.lua" "$SK/templates/luacheck/base.luacheckrc" > "$CFG"
[ -d "$T" ] && [ -f "$T/.luacheckrc" ] && cat "$T/.luacheckrc" >> "$CFG"
rc=0
luacheck --config "$CFG" --codes "$T" || rc=1
# never-emit: explicit message (luacheck already reports 113; this names the replacement)
NAMES="$(awk '/never-emit:start/{f=1;next}/never-emit:end/{f=0}f' "$SK/references/forever-api-notes.md" | sed -n 's/^- `\([A-Za-z0-9_.]*\)`.*/\1/p')"
FILES="$(find "$T" -name '*.lua' -not -path '*/Libs/*' -not -path '*/tests/wowmock/*')"
for n in $NAMES; do
  hits="$(grep -nwF "$n" $FILES 2>/dev/null | grep -v '^\s*--')" || true
  [ -n "$hits" ] && { echo "NEVER-EMIT: $n (see references/forever-api-notes.md)"; echo "$hits"; rc=1; }
done
# perf heuristic (warning only)
for f in $FILES; do
  if grep -q 'SetScript("OnUpdate"' "$f" && ! grep -qE 'elapsed|throttle|THROTTLE' "$f"; then
    echo "PERF: unthrottled OnUpdate in $f (see references/performance.md)"; fi
done
exit $rc
```
Note: the `grep -nwF` for `this` could false-positive on comments. The `grep -v` drops comment-only lines, so this is acceptable for v1.

#### 5. Fixtures
- `$SK/scripts/fixtures/good.lua`: `local addonName, ns = ...`, a `CreateFrame("Frame", nil, UIParent)`, `RegisterEvent("BAG_UPDATE")`, an OnEvent that calls `C_Container.GetContainerItemInfo(bag, 1)` and reads `.stackCount`, and `C_Timer.After(1, function() print(addonName) end)`.
- `$SK/scripts/fixtures/bad.lua`: `GetContainerItemInfo(0,1)` (never-emit), `C_Fake.Foo()` (113), `C_Container.NotARealFunction(0)` (143), `leaked = 1` (111).

#### 6. Wire into check.sh and SKILL.md
- check.sh gets a section: `lint.sh fixtures/good.lua` must pass, and `lint.sh fixtures/bad.lua` must fail, with output containing `NEVER-EMIT: GetContainerItemInfo`, `(W113)` and `(W143)`.
- SKILL.md:
  - "Read before you touch" rows for `forever-api-index.md` (any API call), `forever-api-notes.md` (anything ported from Classic or Retail) and `toc-format.md` (TOC edits).
  - Scripts table rows for `gen-api.sh` and `lint.sh`.

### Verification
#### Automated
- [ ] `skills/wow-forever-addon/scripts/gen-api.sh` exits 0 and prints counts with namespaces > 100
- [ ] `grep -c '^## C_' skills/wow-forever-addon/references/forever-api-index.md` > 100, and `grep -E '^## (C_Container|C_UnitAuras|C_SwingTimer)$'` matches all three
- [ ] Never-emit report reviewed and notes edited per the rule in §3
- [ ] `skills/wow-forever-addon/scripts/lint.sh skills/wow-forever-addon/scripts/fixtures/good.lua` exits 0
- [ ] `lint.sh fixtures/bad.lua` exits non-zero with `NEVER-EMIT: GetContainerItemInfo`, `W113` (C_Fake) and `W143` (NotARealFunction)
- [ ] `scripts/check.sh` exits 0

#### Manual
- [ ] Spot-check five never-emit decisions against the `forever` branch on GitHub

---

## Phase 2: Vanilla scaffold

### Changes

#### 1. Templates
**Dir**: `$SK/templates/vanilla/` — create
- `__NAME__.toc`:
```
## Interface: __INTERFACE__
## Title: __NAME__
## Notes: __NOTES__
## Author: __AUTHOR__
## Version: @project-version@
## SavedVariables: __NAME__DB
## SavedVariablesPerCharacter: __NAME__CharDB
# ## X-Curse-Project-ID: <id>   (uncomment after creating the project; see references/release-pipeline.md)
# ## X-Wago-ID: <id>

Core.lua
```
- `Core.lua` (pattern blocks are delimited by `--@pattern:x@` … `--@end-pattern@`):
```lua
local addonName, ns = ...
local DB_VERSION = 1
local defaults = { version = DB_VERSION, debug = false,
--@pattern:timer@
  interval = 5,
--@end-pattern@
}
local charDefaults = {
--@pattern:ui@
  point = { "CENTER", "UIParent", "CENTER", 0, 0 }, shown = true,
--@end-pattern@
}

local f = CreateFrame("Frame")
ns.frame = f
f:SetScript("OnEvent", function(self, event, ...) local h = self[event]; if h then h(self, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

function ns.Print(...) print("|cff33ff99" .. addonName .. "|r:", ...) end
function ns.Debug(...) if ns.db and ns.db.debug then ns.Print("[debug]", ...) end end

local function mergeDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      mergeDefaults(dst[k], v)
    elseif dst[k] == nil then dst[k] = v end
  end
  return dst
end
ns.mergeDefaults = mergeDefaults

-- Migrations: add `if from < N then ... end` steps; bump DB_VERSION.
function ns.Migrate(db, from)
  db.version = DB_VERSION
end

function f:ADDON_LOADED(name)
  if name ~= addonName then return end
  __NAME__DB = mergeDefaults(__NAME__DB or {}, defaults)
  __NAME__CharDB = mergeDefaults(__NAME__CharDB or {}, charDefaults)
  ns.db, ns.char = __NAME__DB, __NAME__CharDB
  ns.Migrate(ns.db, ns.db.version or 0)
  self:UnregisterEvent("ADDON_LOADED")
end

function f:PLAYER_LOGIN()
  ns.Debug("loaded")
--@pattern:timer@
  ns.ticker = C_Timer.NewTicker(ns.db.interval, function() ns.ticks = (ns.ticks or 0) + 1 end)
--@end-pattern@
--@pattern:ui@
  ns.CreateWindow()
--@end-pattern@
--@pattern:ldb@
  ns.CreateLauncher()
--@end-pattern@
end
--@pattern:event@

f:RegisterEvent("PLAYER_TARGET_CHANGED")
function f:PLAYER_TARGET_CHANGED()
  ns.Debug("target", UnitName("target") or "none")
end
--@end-pattern@
--@pattern:ui@

function ns.CreateWindow()
  if ns.window then return ns.window end
  local w = CreateFrame("Frame", addonName .. "Window", UIParent, "BackdropTemplate")
  w:SetSize(200, 80)
  local p = ns.char.point
  w:SetPoint(p[1], p[2], p[3], p[4], p[5])
  w:SetMovable(true); w:EnableMouse(true); w:RegisterForDrag("LeftButton")
  w:SetScript("OnDragStart", w.StartMoving)
  w:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local a, _, r, x, y = self:GetPoint()
    ns.char.point = { a, "UIParent", r, x, y }
  end)
  w.text = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  w.text:SetPoint("CENTER")
  w.text:SetText(addonName)
  w:SetShown(ns.char.shown)
  ns.window = w
  return w
end
--@end-pattern@
--@pattern:ldb@

function ns.CreateLauncher()
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb then return end
  ns.launcher = ldb:NewDataObject(addonName, { type = "launcher", icon = 134400,
    OnClick = function() ns.Print("clicked") end })
end
--@end-pattern@
--@pattern:tooltip@

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
  if tooltip ~= GameTooltip or not data or not data.id then return end
  ns.Debug("item tooltip", data.id)
end)
--@end-pattern@

local help = "commands: debug"
--@pattern:ui@
help = help .. ", show"
--@end-pattern@
SLASH___KEY__1 = "/__SLASH__"
SlashCmdList.__KEY__ = function(msg)
  local cmd = strtrim(msg or ""):lower()
  if cmd == "debug" then
    ns.db.debug = not ns.db.debug
    ns.Print("debug", ns.db.debug and "on" or "off")
--@pattern:ui@
  elseif cmd == "show" then
    ns.char.shown = not ns.char.shown
    ns.CreateWindow():SetShown(ns.char.shown)
--@end-pattern@
  else
    ns.Print(help)
  end
end
```
Pattern markers always sit on their own line. Never nest a marker inside a code line.
- `.luacheckrc` (addon-level, small): `globals = { "__NAME__DB", "__NAME__CharDB" }` plus a comment `-- run via <skill>/scripts/lint.sh (adds stds.forever)`.
- Before shipping, verify that `TooltipDataProcessor`, `Enum.TooltipDataType`, `BackdropTemplate` and `C_Timer.NewTicker` exist in the generated std or index. If any is missing, put that pattern on the same API the index shows, e.g. `GameTooltip:HookScript("OnTooltipSetItem", …)`.

**Dir**: `$SK/templates/common/` — create (shared with Ace3). This deviates from structure, which put these files under vanilla/.
- `README.addon.md` → `README.md`: name, what it does, a "Library choice: __LIBCHOICE__ — __LIBREASON__" line, "Gap analysis: (fill in)", install, slash commands, dev commands.
- `CHANGELOG.md`: `## [Unreleased]` with conventional-commit sections.
- `LICENSE.MIT` → `LICENSE`: MIT with `__YEAR__ __AUTHOR__`.

#### 2. Scaffolder
**File**: `$SK/scripts/scaffold.sh` — thin wrapper: `exec luajit "$SK/scripts/scaffold.lua" "$SK" "$@"`.
**File**: `$SK/scripts/scaffold.lua` — create
```lua
-- luajit scaffold.lua <skill-dir> <Name> [--ace3] [--pattern p]... [--license MIT|none] [--dest DIR] [--author A] [--notes TXT]
local SK, NAME = arg[1], arg[2]
assert(NAME and NAME:match("^[A-Za-z][A-Za-z0-9_]*$"), "usage: scaffold.sh <Name> [...]; Name must be [A-Za-z][A-Za-z0-9_]*")
local opt = { patterns = {}, license = "MIT", dest = ".", ace3 = false }
local i = 3
while arg[i] do
  local a = arg[i]
  if a == "--ace3" then opt.ace3 = true; i = i + 1
  elseif a == "--pattern" then opt.patterns[arg[i+1]] = true; i = i + 2
  elseif a == "--license" or a == "--dest" or a == "--author" or a == "--notes" then opt[a:sub(3)] = arg[i+1]; i = i + 2
  else error("unknown arg " .. a) end
end
local VALID = { event = 1, timer = 1, ui = 1, ldb = 1, tooltip = 1 }
for p in pairs(opt.patterns) do assert(VALID[p], "unknown pattern " .. p) end

local function read(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function write(p, s) os.execute('mkdir -p "' .. p:match("^(.*)/") .. '"'); local f = assert(io.open(p, "wb")); f:write(s); f:close() end
local function files(dir) local t, p = {}, io.popen('cd "' .. dir .. '" && find . -type f'); for l in p:lines() do t[#t+1] = l:sub(3) end; p:close(); return t end

local iface = assert(read(SK .. "/references/toc-format.md"):match("\nInterface: (%d+)") or read(SK .. "/references/toc-format.md"):match("^Interface: (%d+)"), "Interface not found in toc-format.md")
local author = opt.author or (io.popen("git config user.name"):read("*l")) or "Unknown"
local tokens = {
  __NAME__ = NAME, __KEY__ = NAME:upper():gsub("[^%w]", ""), __SLASH__ = NAME:lower(),
  __INTERFACE__ = iface, __AUTHOR__ = author, __NOTES__ = opt.notes or "",
  __YEAR__ = os.date("%Y"), __LIBCHOICE__ = opt.ace3 and "Ace3" or "vanilla",
  __LIBREASON__ = opt.ace3 and "options UI / profiles / modules wanted (see ace3-vs-vanilla.md)"
                              or "no options panel, <=3 settings, no cross-addon messaging (see ace3-vs-vanilla.md)",
}
local function render(s)
  local out, skip = {}, false
  for line in (s:sub(-1) == "\n" and s or s .. "\n"):gmatch("(.-)\n") do
    local p = line:match("@pattern:([%w_]+)@")
    if p then skip = not opt.patterns[p]
    elseif line:match("@end%-pattern@") then skip = false
    elseif not skip then out[#out+1] = line end
  end
  s = table.concat(out, "\n") .. "\n"
  for k, v in pairs(tokens) do s = s:gsub(k, (v:gsub("%%", "%%%%"))) end
  return s
end

local root = opt.dest .. "/" .. NAME
local tpl = SK .. "/templates/" .. (opt.ace3 and "ace3" or "vanilla")
for _, rel in ipairs(files(tpl)) do write(root .. "/" .. rel:gsub("__NAME__", NAME), render(read(tpl .. "/" .. rel))) end
local common = { ["README.addon.md"] = "README.md", ["CHANGELOG.md"] = "CHANGELOG.md" }
if opt.license ~= "none" then common["LICENSE.MIT"] = "LICENSE" end
for src, dst in pairs(common) do write(root .. "/" .. dst, render(read(SK .. "/templates/common/" .. src))) end
-- (P3) vendor the mock harness: tests/wowmock/*
print("created " .. root)
```
Gotcha: gsub with `__KEY__` as the pattern is fine, because `_` is not magic in Lua patterns. Don't add tokens that contain `%`.

#### 3. References and SKILL.md
- `$SK/references/saved-variables.md`:
  - lifecycle: loaded after the last TOC file; available at `ADDON_LOADED` with `arg1 == addonName`; written on logout and `/reload`;
  - per-account vs per-character paths;
  - the defaults-merge and `Migrate(db, from)` pattern, citing research.md:316-326.
- `$SK/references/events.md`:
  - core lifecycle: `ADDON_LOADED`, `PLAYER_LOGIN` (once), `PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)` (every loading screen), `PLAYER_LOGOUT`;
  - pointer: "full event list: `forever-api-index.md#events`".
- SKILL.md:
  - **Workflow: new addon (simple).** Clarify in ≤3 questions, then gap analysis (P6), then `scaffold.sh`, then implement, then lint and test, then the in-game checklist.
  - **In-game checklist:** copy or symlink into `Interface/AddOns/<Name>`, `/reload`, no BugSack errors, exercise the feature, `/fstack` placement, `/etrace` events.
  - Scripts table row for `scaffold.sh`.

#### 4. check.sh
Add a "scaffold smoke" step. For each set in `"" "--pattern event" "--pattern timer" "--pattern ui" "--pattern ldb" "--pattern tooltip"`, scaffold `Demo` into `$(mktemp -d)` and run `lint.sh` on it. Fail on any non-zero.

### Verification
#### Automated
- [ ] `d=$(mktemp -d); skills/wow-forever-addon/scripts/scaffold.sh Demo --dest $d && skills/wow-forever-addon/scripts/lint.sh $d/Demo` exits 0
- [ ] Same for each `--pattern` value, plus all five patterns together
- [ ] `grep -q '^## Interface: 16001' $d/Demo/Demo.toc` and no leftover `__` tokens: `! grep -rn '__[A-Z]*__' $d/Demo`
- [ ] `scripts/check.sh` exits 0

#### Manual (post-launch, ≥ 2026-11-04)
- [ ] Copy `Demo` into `Interface/AddOns`, `/reload`: no errors. `/demo debug` toggles. `/demo show` toggles the window for the ui pattern.

---

## Phase 3: Mock harness + tests + example addon

### Changes

#### 1. wowmock modules
**Dir**: `$SK/scripts/wowmock/`. Each module exports `install(env, api)`.

**`init.lua`**
```lua
local M = {}
local Env = {}; Env.__index = Env
M.Env = Env
local STD = { "assert","error","ipairs","next","pairs","pcall","xpcall","select","tonumber","tostring","type",
  "unpack","rawget","rawset","rawequal","setmetatable","getmetatable","string","table","math","bit","date","time","coroutine" }

local function deepcopy(v) if type(v) ~= "table" then return v end local t = {} for k, x in pairs(v) do t[k] = deepcopy(x) end return t end
M.deepcopy = deepcopy

function M.new_env(opts)
  opts = opts or {}
  local self = setmetatable({ opts = opts, now = 0, timers = {}, frames = {}, handlers = {}, output = {},
    saved_in = deepcopy(opts.saved or {}), sv_names = {} }, Env)
  local api = {}
  for _, k in ipairs(STD) do api[k] = _G[k] end
  api.print = function(...)
    local t = {}; for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
    self.output[#self.output+1] = table.concat(t, " ")
  end
  self.api = api
  self.G = setmetatable({}, { __index = api })
  self.G._G = self.G
  for _, m in ipairs({ "luaext", "frames", "events", "timer", "unit", "slash", "tooltip", "ace" }) do
    require("wowmock." .. m).install(self, api)
  end
  return self
end

function Env:load_addon(dir)
  local toc = require("wowmock.toc").parse(dir)
  local ns = {}
  for _, path in ipairs(toc.files) do
    local chunk, err = loadfile(path)
    if not chunk then error("wowmock: " .. err, 2) end
    setfenv(chunk, self.G)
    chunk(toc.name, ns)
  end
  for _, field in ipairs({ "SavedVariables", "SavedVariablesPerCharacter" }) do
    for sv in (toc.fields[field] or ""):gmatch("[%w_]+") do
      self.sv_names[#self.sv_names+1] = sv
      rawset(self.G, sv, deepcopy(self.saved_in[sv]))
    end
  end
  self.addon_dir, self.ns, self.toc = dir, ns, toc
  self:fire("ADDON_LOADED", toc.name)
  if self.opts.login ~= false then self:fire("PLAYER_LOGIN"); self:fire("PLAYER_ENTERING_WORLD", true, false) end
  return ns
end

function Env:saved()
  local t = {}; for _, n in ipairs(self.sv_names) do t[n] = deepcopy(rawget(self.G, n)) end; return t
end

function Env:reload()
  local o = {}; for k, v in pairs(self.opts) do o[k] = v end
  o.saved = self:saved()
  local e = M.new_env(o)
  return e, e:load_addon(self.addon_dir)
end

return M
```
**`toc.lua`**: `parse(dir) -> { name, fields = {}, files = {abs...} }`.
- `name` is the basename of `dir`, and the TOC is read from `dir/<name>.toc`.
- `## Key: Value` lines go into `fields`. Other `#` lines are skipped. Blank lines are skipped.
- File lines are trimmed and have `\` mapped to `/`.
- A `.xml` entry expands recursively, in document order, via `for tag, f in s:gmatch('<(%a+)%s+file="([^"]+)"')`: `Script` adds a file and `Include` recurses. Paths are relative to the xml's dir.
- A missing file whose path contains `/Libs/` is skipped silently (Ace stubs stand in). Any other missing file raises an error.

**`luaext.lua`**: `strsplit(sep, s, n)`, `strtrim(s, chars)`, `strjoin`, `strlower/strupper/strlen/strsub/strfind/strmatch/gsub/format` (aliases of `string.*`), `tinsert/tremove/wipe/tContains`, `CopyTable`, `Mixin(obj, ...)`, `CreateFromMixins(...)`, `hooksecurefunc(tbl?, name, fn)` (wraps), `securecall(fn, ...)`, `InCombatLockdown()` → `env.in_combat == true`, `GetBuildInfo()` → `"1.60.1", "70532", "Oct 22 2026", 16001`, `GetLocale()` → `"enUS"`.

**`frames.lua`**: `CreateFrame(ftype, name, parent, template) -> frame`.
- A named frame is `rawset` into `env.G[name]`. Every frame is appended to `env.frames`. `env.G.UIParent = CreateFrame("Frame", "UIParent")`.
- Methods are implemented on a shared `Frame` table:
  - `GetName`, `GetParent`, `GetObjectType`, `Show`, `Hide`, `IsShown`, `SetShown`
  - `SetScript`, `GetScript`, `HookScript` (chains)
  - `RegisterEvent`, `RegisterUnitEvent`, `UnregisterEvent`, `UnregisterAllEvents`, `IsEventRegistered`
  - `SetPoint` (stores args) and `GetPoint` (returns them)
  - `CreateFontString`, `CreateTexture` (child objects with the same metatable)
  - `SetText`, `GetText`
  - `StartMoving`, `StopMovingOrSizing`
  - a NOOP list: `ClearAllPoints, SetAllPoints, SetSize, SetWidth, SetHeight, SetAlpha, SetScale, SetFrameStrata, SetFrameLevel, EnableMouse, SetMovable, RegisterForDrag, SetClampedToScreen, SetBackdrop, SetBackdropColor, SetBackdropBorderColor, SetTexture, SetColorTexture, SetVertexColor, SetJustifyH, SetJustifyV, SetFontObject, SetTextColor`.
  - GameTooltip-type extras: `AddLine`, `AddDoubleLine`, `ClearLines`, `NumLines`, `SetOwner`. Lines are stored in `frame.lines`.
- Unknown keys:
```lua
local mt = { __index = function(t, k)
  local m = Frame[k]; if m ~= nil then return m end
  if type(k) == "string" and k:match("^%u") and not k:match("^[%u%d_]+$") then
    error("wowmock: unimplemented Frame:" .. k .. " (add it to wowmock/frames.lua)", 2)
  end
end }
```
ALL_CAPS keys (event-handler lookups) and lowercase custom fields return nil.

**`events.lua`**:
- `RegisterEvent` appends the frame to `env.handlers[event]`, keeping it in a set.
- `Env:fire(event, ...)` iterates a copy of the list and calls `frame:GetScript("OnEvent")(frame, event, ...)` when the frame is still registered.
- It also runs `OnUpdate` only when `Env:update(elapsed)` is called, which calls each shown frame's `OnUpdate(frame, elapsed)`.

**`timer.lua`**:
- `C_Timer.After(s, fn)`, `C_Timer.NewTimer(s, fn)` and `C_Timer.NewTicker(s, fn, n)` return a handle `{ Cancel = fn, IsCancelled = fn }`. `GetTime()` returns `env.now`.
- `Env:advance(dt)` loops: it takes the earliest uncancelled timer due by `now + dt`, sets `now`, runs it, and reschedules tickers until `n` runs are done. Finally `now = now + dt` (clamped).

**`unit.lua`**:
- `UnitName("player")` returns `opts.player_name or "Tester", nil`. For other units it returns `opts.units[u]` or nil.
- `UnitClass("player")` returns `"Warlock","WARLOCK",9`. `UnitLevel` returns 60. `UnitGUID` returns `"Player-0-00000001"`.
- `UnitExists(u)` is true for player or for a unit in `opts.units`. `GetRealmName()` returns `"Mockrealm"`.

**`slash.lua`**:
- `api.SlashCmdList = {}`.
- `Env:slash(line)` splits off `cmd` and `rest`, scans `pairs(rawtable G)` for `^SLASH_(.-)%d+$` keys whose value lower-cases to `cmd`, and calls `G.SlashCmdList[key](rest, nil)`. It errors `wowmock: no slash command <cmd>` if none matches.

**`tooltip.lua`**:
- `Enum = { TooltipDataType = { Item = 0, Spell = 1, Unit = 2 } }`.
- `GameTooltip = CreateFrame("GameTooltip", "GameTooltip")`.
- `TooltipDataProcessor.AddTooltipPostCall(type, fn)` stores callbacks.
- `Env:show_item_tooltip(id)` clears `GameTooltip.lines`, calls each Item callback with `(GameTooltip, { type = 0, id = id })`, and returns the lines.
- `C_Item.GetDetailedItemLevelInfo(id)` returns `opts.items[id].ilvl, nil, opts.items[id].ilvl`.
- `C_Item.GetItemInfo(id)` returns `opts.items[id].name`.

**`ace.lua`**: installs `LibStub` (P3: the registry plus `LibStub(major, silent)` → nil when silent and missing). Phase 4 fills in the Ace libraries.

#### 2. Runner
**File**: `$SK/scripts/wowmock/runner.lua` — create
```lua
-- luajit runner.lua <addon-dir> <spec.lua>...
ADDON_DIR = arg[1]
local pass, fail, stack, befores = 0, 0, {}, {}
local function deq(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local A = {
  equals = function(e, a, m) if e ~= a then error(("%sexpected %s, got %s"):format(m and m .. ": " or "", tostring(e), tostring(a)), 2) end end,
  same = function(e, a, m) if not deq(e, a) then error((m or "tables differ"), 2) end end,
  truthy = function(v, m) if not v then error(m or "expected truthy", 2) end end,
  falsy = function(v, m) if v then error(m or "expected falsy", 2) end end,
  matches = function(p, s, m) if not tostring(s):match(p) then error((m or "no match") .. ": " .. tostring(s), 2) end end,
  errors = function(fn, p) local ok, e = pcall(fn); if ok then error("expected error", 2) end
    if p and not tostring(e):match(p) then error("error did not match: " .. tostring(e), 2) end end,
}
assert = setmetatable(A, { __call = function(_, v, m, ...) if not v then error(m or "assertion failed", 2) end return v, m, ... end })
function describe(name, fn) stack[#stack+1] = name; befores[#stack] = {}; fn(); befores[#stack] = nil; stack[#stack] = nil end
function before_each(fn) table.insert(befores[#stack], fn) end
function it(name, fn)
  local full = table.concat(stack, " > ") .. " > " .. name
  local ok, err = xpcall(function()
    for lvl = 1, #stack do for _, b in ipairs(befores[lvl]) do b() end end
    fn()
  end, debug.traceback)
  if ok then pass = pass + 1; print("ok   " .. full) else fail = fail + 1; print("FAIL " .. full .. "\n     " .. err) end
end
for i = 2, #arg do dofile(arg[i]) end
print(("\n%d passed, %d failed"):format(pass, fail))
os.exit(fail > 0 and 1 or 0)
```

#### 3. test.sh and vendoring
**File**: `$SK/scripts/test.sh` — create
```bash
#!/usr/bin/env bash
# usage: test.sh <addon-dir>   — runs <addon-dir>/tests/*_spec.lua under luajit with wowmock
set -u
SK="$(cd "$(dirname "$0")/.." && pwd)"
D="$(cd "${1:?usage: test.sh <addon-dir>}" && pwd)"
MOCK="$D/tests/wowmock"; [ -d "$MOCK" ] || MOCK="$SK/scripts/wowmock"
set -- "$D"/tests/*_spec.lua
[ -e "$1" ] || { echo "no tests in $D/tests"; exit 1; }
LUA_PATH="$(dirname "$MOCK")/?.lua;$(dirname "$MOCK")/?/init.lua;;" luajit "$MOCK/runner.lua" "$D" "$@"
```
- In `scaffold.lua`, copy `$SK/scripts/wowmock/*.lua` to `<addon>/tests/wowmock/`, and write `<addon>/tests/run.sh` (the same as test.sh but self-contained, using the vendored copy). This deviates from structure, which only says tests ship. Vendoring keeps addon repos self-contained.

#### 4. Template tests
**File**: `$SK/templates/vanilla/tests/core_spec.lua` — create
```lua
local wowmock = require("wowmock")
describe("__NAME__", function()
  local env, ns
  before_each(function() env = wowmock.new_env(); ns = env:load_addon(ADDON_DIR) end)
  it("loads and applies defaults", function()
    assert.truthy(ns.db); assert.equals(false, ns.db.debug); assert.equals(1, ns.db.version)
  end)
  it("slash debug toggles and persists across reload", function()
    env:slash("/__SLASH__ debug"); assert.equals(true, ns.db.debug)
    local env2, ns2 = env:reload(); assert.equals(true, ns2.db.debug)
  end)
--@pattern:timer@
  it("ticker fires on interval", function() env:advance(ns.db.interval * 3 + 0.1); assert.equals(3, ns.ticks) end)
--@end-pattern@
--@pattern:ui@
  it("window toggles", function() env:slash("/__SLASH__ show"); assert.equals(false, ns.window:IsShown()) end)
--@end-pattern@
end)
```

#### 5. Example addon
**Dir**: `examples/TooltipItemLevel/`. Create it with `scaffold.sh TooltipItemLevel --pattern tooltip --dest examples`, then edit:
- `Core.lua` tooltip block: `local ilvl = C_Item.GetDetailedItemLevelInfo(data.id); if ilvl then tooltip:AddLine(("Item Level: %d"):format(ilvl), 1, 1, 1) end`. Verify that `C_Item.GetDetailedItemLevelInfo` is in `forever-api-index.md`. If not, use the index's item-level API and update the mock.
- `tests/tooltip_spec.lua`: `new_env{ items = { [19019] = { ilvl = 80 } } }`, then `show_item_tooltip(19019)` contains `"Item Level: 80"`, and `show_item_tooltip(1)` adds no line.
- README: purpose, plus "Gap analysis: example only".

#### 6. Reference, SKILL.md, check.sh
- `$SK/references/testing.md` covers:
  - harness API (`new_env`, `load_addon`, `fire`, `advance`, `update`, `slash`, `saved`, `reload`, `show_item_tooltip`, opts);
  - how to add a missing stub (from the "unimplemented" error);
  - **not covered**: taint, secure frames, rendering and layout, secret values, real library behaviour;
  - future option: hogsim or wowless (research.md:303-307), not wired in.
- SKILL.md: a "Read before you touch" row for testing.md, and a Scripts row for `test.sh`.
- check.sh: for each `examples/*/`, run lint plus test. In scaffold smoke, also run `test.sh` (and `tests/run.sh` once).

### Verification
#### Automated
- [ ] `skills/wow-forever-addon/scripts/test.sh examples/TooltipItemLevel` exits 0
- [ ] Fresh scaffold with all patterns: `test.sh $d/Demo` exits 0, and `$d/Demo/tests/run.sh` exits 0
- [ ] `lint.sh examples/TooltipItemLevel` exits 0
- [ ] Negative check: temporarily break `mergeDefaults` in a scratch copy. `test.sh` must exit 1.
- [ ] `scripts/check.sh` exits 0

#### Manual
- [ ] Post-launch: TooltipItemLevel in-game shows an "Item Level" line on item tooltips, and `/reload` gives no errors

---

## Phase 4: Ace3 path

### Changes

#### 1. Templates
**Dir**: `$SK/templates/ace3/`
- `__NAME__.toc`: same header as vanilla, minus `SavedVariablesPerCharacter`, plus `## OptionalDeps: Ace3` and `## X-Embeds: Ace3`. Files are `embeds.xml`, `Core.lua`, `Options.lua`.
- `embeds.xml`:
```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <Script file="Libs\LibStub\LibStub.lua"/>
  <Include file="Libs\CallbackHandler-1.0\CallbackHandler-1.0.xml"/>
  <Include file="Libs\AceAddon-3.0\AceAddon-3.0.xml"/>
  <Include file="Libs\AceEvent-3.0\AceEvent-3.0.xml"/>
  <Include file="Libs\AceConsole-3.0\AceConsole-3.0.xml"/>
  <Include file="Libs\AceDB-3.0\AceDB-3.0.xml"/>
  <Include file="Libs\AceDBOptions-3.0\AceDBOptions-3.0.xml"/>
  <Include file="Libs\AceGUI-3.0\AceGUI-3.0.xml"/>
  <Include file="Libs\AceConfig-3.0\AceConfig-3.0.xml"/>
</Ui>
```
- `Core.lua`:
```lua
local addonName, ns = ...
local A = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
ns.addon = A
local defaults = { profile = { enabled = true, debug = false } }
function A:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("__NAME__DB", defaults, true)
  ns.SetupOptions(self)
  self:RegisterChatCommand("__SLASH__", "ChatCommand")
end
function A:OnEnable() self:RegisterEvent("PLAYER_ENTERING_WORLD") end
function A:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
  if self.db.profile.debug then self:Print(event, isLogin, isReload) end
end
function A:ChatCommand(input)
  input = strtrim(input or ""):lower()
  if input == "debug" then
    self.db.profile.debug = not self.db.profile.debug
    self:Print("debug", self.db.profile.debug and "on" or "off")
  else
    LibStub("AceConfigDialog-3.0"):Open(addonName)
  end
end
```
- `Options.lua`: `ns.SetupOptions(addon)` builds `{ name = addonName, type = "group", args = { enabled = toggle, debug = toggle, profiles = AceDBOptions:GetOptionsTable(addon.db) } }`. Toggles use `get`/`set` on `addon.db.profile`. It then calls `RegisterOptionsTable(addonName, options)` and `addon.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, addonName)`.
- `.luacheckrc`: `globals = { "__NAME__DB" }`.
- `tests/core_spec.lua`:
  - `OnInitialize` ran (`ns.addon.db` exists);
  - `env:saved().__NAME__DB.profiles.Default.enabled == true`;
  - `/__SLASH__ debug` flips `db.profile.debug`, and that survives `env:reload()`;
  - `OnEnable` registered `PLAYER_ENTERING_WORLD`;
  - `/__SLASH__` with no args calls `AceConfigDialog:Open` (the stub records `env.ace_opened`).

#### 2. Ace stubs
**File**: `$SK/scripts/wowmock/ace.lua` — extend
- `LibStub(major, silent)`: a registry, with `LibStub:NewLibrary` returning nil (libs are pre-registered).
- **AceAddon-3.0**: `NewAddon(name, ...)` applies the mixins (by name lookup in the registry) and queues the addon.
  - An internal frame registers `ADDON_LOADED` (it runs `OnInitialize` for all queued addons that haven't been initialized) and `PLAYER_LOGIN` (it runs `OnEnable` for initialized ones).
  - `GetAddon(name)`.
- **AceEvent-3.0** mixin: `RegisterEvent(event, handler?)` uses a per-addon frame. The handler is a string method, a function, or `self[event]`, called as `(self, event, ...)`. Also `UnregisterEvent`.
- **AceConsole-3.0** mixin: `RegisterChatCommand(cmd, handler)` sets `SLASH_ACECONSOLE_<CMD>1 = "/"..cmd` and `SlashCmdList["ACECONSOLE_<CMD>"] = function(msg) <call handler as self:method(msg)> end`. `Print(...)` is `print(name .. ":", ...)`.
- **AceDB-3.0**: `New(sv, defaults, defaultProfile)`:
  - Takes `G[sv]` or `{}` and assigns it back.
  - `profileKeys["Tester - Mockrealm"]` picks the profile name: an existing key, else `"Default"` when `defaultProfile == true`, else the string or the char key.
  - It merges `defaults.profile` into `sv.profiles[name]`, recursively filling missing keys.
  - Returns `{ sv=, profile=, global=sv.global (merged defaults.global), SetProfile(n), GetCurrentProfile(), GetProfiles(), RegisterCallback=noop }`.
  - Documented divergence: real AceDB strips defaults on logout. The stub does not.
- **AceDBOptions-3.0**: `GetOptionsTable(db)` returns `{ type = "group", name = "Profiles", args = {} }`.
- **AceConfig-3.0**: `RegisterOptionsTable(name, t)` stores `env.ace_options[name] = t`.
- **AceConfigDialog-3.0**: `AddToBlizOptions` returns a frame. `Open(name)` sets `env.ace_opened = name`.

#### 3. Reference + SKILL.md
- `$SK/references/ace3-vs-vanilla.md`:
  - PRD §5.1 criteria: vanilla when there's no options panel, ≤3 settings and no cross-addon messaging. Ace3 when options UI, profiles, modules or LDB are wanted.
  - Lifecycle summary (research.md:330-343).
  - Soft-embed via `.pkgmeta` externals, per library, from `https://repos.wowace.com/wow/ace3/trunk/<Lib>` (research.md:336-337). Never commit `Libs/`.
  - For an in-game test before packaging, run `release.sh -d` (P7) once, or check out the externals by hand into `Libs/`. Keep `Libs/` gitignored.
- SKILL.md: a decision-rule row in "Read before you touch", and `scaffold.sh --ace3` in the Scripts table.
- `scaffold.lua`: for `--ace3`, also write `.gitignore` with `Libs/`.

#### 4. check.sh
Scaffold smoke adds `scaffold.sh AceDemo --ace3`, then lint, then test.

### Verification
#### Automated
- [ ] `scaffold.sh AceDemo --ace3 --dest $d && lint.sh $d/AceDemo && test.sh $d/AceDemo` exits 0
- [ ] Vanilla scaffold tests still pass (the ace.lua LibStub changes must not break them)
- [ ] `scripts/check.sh` exits 0

#### Manual (post-launch)
- [ ] AceDemo with libs (from the P7 packager dry run, or checked out by hand) `/reload`s with no errors. `/acedemo` opens the options panel. The profile switch works.

---

## Phase 5: QRSPI handoff

### Changes
#### 1. Handoff reference
**File**: `$SK/references/qrspi-handoff.md` — create. This is the **only** file that names `/qrspi-plan-toolkit:*`. It covers:
- **Detection.** If `qrspi-plan-toolkit:1-question` appears in the available skills list, QRSPI is installed. Otherwise use the direct workflow and print once: "Install the qrspi-plan-toolkit plugin for the structured planning flow."
- **Routing table** (PRD §5.7):

  | Situation | Path |
  |---|---|
  | API question, single-file fix, one-off debug, release of an existing addon | Direct |
  | New addon with ≥3 Lua files, an options UI or Ace3 | Full 1→8 |
  | Meaningful feature (new module, new saved-variable schema, new frame) | Hand-write `task.md`, start at 3-design |
  | Fork or extend an existing addon | Full 1→8 |
- **Per-phase inputs:**
  - **1-question:** seed `task.md` from `templates/qrspi/task.template.md` (idea plus the gap-analysis verdict), and append `templates/qrspi/questions.wow.md`. Point codebase-locator at `<skill>/references/` and the addon folder.
  - **2-research:** references count as codebase, and `web-search-researcher` is used only for gaps, with a Forever-confidence label. Do not mention intent.
  - **3-design:** inject `templates/qrspi/design-questions.wow.md`. `design.md` must record the Interface number and the never-emit list as constraints.
  - **4-structure:** slices are TOC+core+saved variables+slash (loadable), then events and the first feature, then UI, then options. Every Verify is `<skill>/scripts/lint.sh <addon> && <skill>/scripts/test.sh <addon>` plus an in-game `/reload`.
  - **5-plan:** reject any snippet that uses a never-emit name, checked with `lint.sh` on extracted snippets or a grep. Manual items come from the in-game checklist.
  - **6-worktree:** symlink `Interface/AddOns/<Name>` to the worktree.
  - **7-implement:** commit after lint and test. The manual pause is the in-game `/reload`.
  - **8-pr:** add a "Forever compatibility" section (Interface, APIs used, taint exposure) and a "Release" section (link to `.pkgmeta` and `release.yml`).
- **Artifacts:** commit `thoughts/qrspi/`, and `.pkgmeta` ignores `thoughts`.

#### 2. Templates
- `$SK/templates/qrspi/task.template.md`: "Build <Name>: <what it shows/does>, triggered by <event/trigger>, UI: <yes/no>. Gap analysis verdict: <use/fork/build> because <gaps>. Target: WoW Forever, Interface <n>."
- `$SK/templates/qrspi/questions.wow.md`, five neutral questions:
  1. Which events fire for <trigger> and what are their payloads (`references/events.md`, `forever-api-index.md#events`)?
  2. Which Forever APIs expose <data> (`forever-api-index.md`)?
  3. In <existing addon>, what happens on `ADDON_LOADED`/`PLAYER_LOGIN`?
  4. What saved-variable shape does <existing addon> use?
  5. Which frames or templates does <existing addon> create?
- `$SK/templates/qrspi/design-questions.wow.md`:
  - Ace3 vs vanilla (→ ace3-vs-vanilla.md)
  - event-driven vs `OnUpdate` (→ performance.md)
  - saved-variable scope, account vs character (→ saved-variables.md)
  - secure-frame exposure (→ taint-and-secure.md)
  - UI framework, plain frames vs AceGUI (→ widgets.md)

#### 3. SKILL.md + check.sh
- SKILL.md gets a `## Routing` section: a 4-line summary pointing to `references/qrspi-handoff.md` and the detection rule. Do not repeat the command names.
- check.sh: `if grep -rl 'qrspi-plan-toolkit:' skills/ | grep -v 'references/qrspi-handoff.md'; then fail=1; fi`.

### Verification
#### Automated
- [ ] `scripts/check.sh` exits 0, including the name-isolation check
- [ ] `grep -c 'qrspi-plan-toolkit:' skills/wow-forever-addon/references/qrspi-handoff.md` ≥ 8

#### Manual
- [ ] With the plugin loaded, "build me a Forever addon with an options panel that tracks warlock soul shards" routes to QRSPI. 1-question produces a `questions.md` containing the WoW questions and no intent. 3-design asks the WoW design questions.

---

## Phase 6: Debug, review, performance, gap analysis

### Changes
#### 1. References
- `$SK/references/taint-and-secure.md`: protected functions, `InCombatLockdown()` gating, `PLAYER_REGEN_ENABLED` deferral, `hooksecurefunc` vs replacing, secure templates, and a "what breaks" list. The secret-values section is labelled unverified.
- `$SK/references/performance.md`:
  - OnUpdate throttle snippet (an `elapsed` accumulator), event-driven alternatives, table reuse (`wipe`), upvalue caching;
  - profiling: `/run UpdateAddOnCPUUsage(); print(GetAddOnCPUUsage("X"))` with `scriptProfile` CVar caveats, and `UpdateAddOnMemoryUsage`/`GetAddOnMemoryUsage`. Verify each name against the index and use the `C_AddOns` variants if the globals are absent.
- `$SK/references/widgets.md`: frame types, `CreateFrame` templates (`BackdropTemplate`), anchors (`SetPoint`), strata and level, FontString and Texture, and `/fstack`. Only names that are present in the index.
- `$SK/references/curseforge-gap-analysis.md`:
  - procedure: web-search `site:curseforge.com/wow/addons <idea> forever`, then the CurseForge page for each match (flavor list, last updated, license), then Wago;
  - report template:

  | # | Addon | Last update | Forever flavor listed? | License | Covers | Gaps |
  |---|---|---|---|---|---|---|

  - Verdict **use / fork / build**, with a reason. Write it into the addon README's "Gap analysis" line. Anything not confirmed gets "unverified".

#### 2. Buggy fixture
**Dir**: `$SK/scripts/fixtures/buggy/Buggy/`, with `Buggy.toc` (`SavedVariables: BuggyDB`), `Core.lua` and `tests/buggy_spec.lua`. The seeded faults are:
1. Global leak: `count = 0`, flagged as W111.
2. Never-emit: `UnitAura("player", 1)`, flagged as `NEVER-EMIT: UnitAura`.
3. Saved variables at file scope: `local cfg = BuggyDB.scale`. The test load errors with `attempt to index global 'BuggyDB'`.
4. Unthrottled `OnUpdate` with no elapsed accumulator, flagged as `PERF: unthrottled OnUpdate`.
5. A frame recreated per event: a `BAG_UPDATE` handler calls `CreateFrame`. The spec fires `BAG_UPDATE` 50× and asserts `#env.frames` grows by ≤1, which fails.

Add `Env:frame_count()` to the mock if it's convenient. Otherwise use `#env.frames`.

#### 3. SKILL.md
- **Workflow: debug.** Read the error or folder, classify it with the table below, patch, run lint and test, add a regression spec, then give the in-game steps.

  | Class | Signals | Read | Regression test |
  |---|---|---|---|
  | nil access | "attempt to index nil" | saved-variables.md / events.md | load + fire event |
  | taint | "ADDON_ACTION_BLOCKED", combat | taint-and-secure.md | (manual) |
  | API drift | undefined global / method | forever-api-notes.md + index | lint |
  | load order | SV nil at file scope | saved-variables.md | load_addon |
  | perf | FPS drop, OnUpdate | performance.md | update() counts |
- **Review checklist**: luacheck 111/112/113, OnUpdate throttle, saved variables before `ADDON_LOADED`, never-emit names, frames recreated per call, item data used before `GET_ITEM_INFO_RECEIVED`.
- **Workflow: API question.** Answer from references, then the index, then a web search labelled with Forever confidence. Offer to add the finding to notes or events.
- **Gap analysis** becomes step 2 of the new-addon workflow.

#### 4. check.sh
- `lint.sh fixtures/buggy/Buggy` must exit non-zero, with output containing `W111`, `NEVER-EMIT: UnitAura` and `PERF: unthrottled OnUpdate`.
- `test.sh fixtures/buggy/Buggy` must exit non-zero, with output containing `attempt to index global 'BuggyDB'`.
- Lint exclusions:
  - Keep the fixture out of the "all lint must pass" sets.
  - In `base.luacheckrc`, `files["**/scripts/fixtures/**"]` must not suppress these codes.

### Verification
#### Automated
- [ ] `scripts/check.sh` exits 0, including all five buggy-fixture expectations (fault 5 shows up as a failing spec name in `test.sh` output)
- [ ] Every profiling and API name in performance.md, taint-and-secure.md and widgets.md appears in `forever-api-index.md` or `forever-std.lua`. Check with a small `grep` loop listed in the file's footer.

#### Manual
- [ ] One real debugging session (a pasted BugSack trace) follows the workflow end to end
- [ ] One gap-analysis run on a sample idea produces the report table and a verdict

---

## Phase 7: Release pipeline

### Changes
#### 1. Templates
**File**: `$SK/templates/common/.pkgmeta` — create. `scaffold.lua` copies it, and `--ace3` keeps the externals block.
```yaml
package-as: __NAME__
manual-changelog:
  filename: CHANGELOG.md
  markup-type: markdown
enable-nolib-creation: no
ignore:
  - tests
  - thoughts
  - .github
  - .luacheckrc
  - .pkgmeta
  - .gitignore
#@pattern:ace3@
externals:
  Libs/LibStub: https://repos.wowace.com/wow/libstub/trunk
  Libs/CallbackHandler-1.0: https://repos.wowace.com/wow/callbackhandler/trunk/CallbackHandler-1.0
  Libs/AceAddon-3.0: https://repos.wowace.com/wow/ace3/trunk/AceAddon-3.0
  Libs/AceEvent-3.0: https://repos.wowace.com/wow/ace3/trunk/AceEvent-3.0
  Libs/AceConsole-3.0: https://repos.wowace.com/wow/ace3/trunk/AceConsole-3.0
  Libs/AceDB-3.0: https://repos.wowace.com/wow/ace3/trunk/AceDB-3.0
  Libs/AceDBOptions-3.0: https://repos.wowace.com/wow/ace3/trunk/AceDBOptions-3.0
  Libs/AceGUI-3.0: https://repos.wowace.com/wow/ace3/trunk/AceGUI-3.0
  Libs/AceConfig-3.0: https://repos.wowace.com/wow/ace3/trunk/AceConfig-3.0
#@end-pattern@
```
- `scaffold.lua` sets `opt.patterns.ace3 = opt.ace3` so the existing pattern stripper handles this block.
- The LibStub and CallbackHandler URLs are not covered by research. Verify them with `svn ls <url>` (`brew install subversion`) or the WoWAce project pages. If they differ, use the URLs the Ace3 repo's own `.pkgmeta` lists (github.com/WoWUIDev/Ace3/.pkgmeta).

**File**: `$SK/templates/common/release.yml` → `.github/workflows/release.yml`
```yaml
name: Package and release
on:
  push:
    tags: ['v*']
permissions:
  contents: write
jobs:
  release:
    runs-on: ubuntu-latest
    env:
      CF_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
      WAGO_API_TOKEN: ${{ secrets.WAGO_API_TOKEN }}
      GH_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: BigWigsMods/packager@v2
```
- research.md:256 marks `actions/checkout@v7` as unconfirmed. Use the newest major that `gh api repos/actions/checkout/releases/latest --jq .tag_name` reports, at implementation time.
- No `-g` flag: the game type comes from Interface 16001 (research.md:242).
- Tokens that aren't set are skipped by the packager, so the workflow is safe before projects exist.

#### 2. Example wiring
- `examples/TooltipItemLevel/.pkgmeta` and `.github/workflows/release.yml`, rendered from the templates. A workflow under `examples/` doesn't run in this repo, which is intended: it is copied when the example becomes its own repo.

#### 3. Repo CI
**File**: `.github/workflows/ci.yml`
```yaml
name: check
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y luajit lua-check
      - run: scripts/check.sh
```
- Ubuntu's `lua-check` package provides the `luacheck` binary. If it's missing, fall back to `leafo/gh-actions-lua` (`luaVersion: luajit-2.1`) plus `leafo/gh-actions-luarocks` plus `luarocks install luacheck`.
- `check.sh` already falls back to `check_frontmatter.py` when skill-creator is absent.

#### 4. Reference + checklist
- `$SK/references/release-pipeline.md`:
  - **Packager.** The `.pkgmeta` keys used, and tokens (`@project-version@`, `@project-date-iso@`, `--@debug@` blocks). TOC `X-Curse-Project-ID`/`X-Wago-ID`. Game type auto-detected from 16xxx → forever; Forever's CurseForge type is 88568 and Wago's is `forever` (research.md:226-261).
  - **Secrets.** `CF_API_TOKEN`, `WAGO_API_TOKEN`, `GH_API_TOKEN`. Note that `CF_API_KEY`/`GITHUB_OAUTH` are deprecated.
  - **Local dry run.** `brew install bash jq`, then `curl -fsSLo /tmp/release.sh https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh`, then `$(brew --prefix)/bin/bash /tmp/release.sh -d -t <addon-dir>`. `-d` skips uploads, and output goes to `<addon-dir>/.release/`.
  - **`/release` checklist:**
    - [ ] Version: bump CHANGELOG `## [x.y.z]` from conventional commits
    - [ ] Lint is green
    - [ ] Tests are green
    - [ ] Commit
    - [ ] Tag: `git tag vX.Y.Z && git push --tags`
    - [ ] Verify the upload on the CurseForge and Wago pages, and in the GitHub Release
- SKILL.md: Workflow "release", pointing to the checklist.

### Verification
#### Automated
- [ ] `scripts/check.sh` exits 0 (examples still lint- and test-green with the new files)
- [ ] Local dry run: `$(brew --prefix)/bin/bash /tmp/release.sh -d -t examples/TooltipItemLevel` exits 0
- [ ] `unzip -l examples/TooltipItemLevel/.release/*.zip` lists no `tests/`, `thoughts/` or `.github/`
- [ ] `unzip -p … TooltipItemLevel/TooltipItemLevel.toc | grep '## Version:'` shows no literal `@project-version@`
- [ ] Scaffold smoke for Ace3: the rendered `.pkgmeta` contains `externals:`. The vanilla one does not.
- [ ] Push a branch: `ci.yml` is green on GitHub (`gh run list --workflow check --limit 1`)

#### Manual (owner-gated)
- [ ] Create CurseForge and Wago projects for the example, add `X-Curse-Project-ID`/`X-Wago-ID` and the repo secrets, push `v0.1.0`, and confirm both uploads list the Forever flavor

---

## Phase 8: Trigger evals + public release

### Changes
#### 1. Trigger set
**File**: `evals/trigger-set.json`: 20 entries `{ "query", "should_trigger" }`.
- **12 positive**:
  - "scaffold a WoW Forever addon that shows my soul shard count"
  - "why does my addon throw attempt to index nil in BugSack"
  - "what's the Forever API for container items"
  - "set up CurseForge and Wago release for my addon"
  - "my .toc Interface number is wrong"
  - "add an options panel with Ace3 to my addon"
  - "CreateFrame OnUpdate is lagging"
  - "SavedVariables are nil on login"
  - "is there already a CurseForge addon for tracking warlock pet happiness"
  - "port this Classic Era addon to Forever"
  - "luacheck globals for WoW"
  - "Classic+ addon idea: rogue poison reminder"
- **8 negative**:
  - "write a Python script to parse CSV"
  - "explain Lua metatables"
  - "build a Roblox Lua game script"
  - "set up a Neovim Lua config"
  - "what's the best warlock talent build in WoW"
  - "make a Discord bot for my guild"
  - "write a Minecraft mod"
  - "create a GitHub Actions workflow for a Node app"

#### 2. Behavior cases
**Dir**: `evals/cases/<case>/{prompt.md, case.yaml, graders/01-*.md}` in the schema from research.md:36-39.
- `scaffold-vanilla`: "Create a Forever addon called ShardCount that prints soul shards on login." Expected: it uses scaffold.sh, lint and test are green, and it emits the in-game checklist.
- `retail-api-trap`: "Use UnitAura to check if I have Demon Armor." Expected: it does not emit `UnitAura` and uses the `C_UnitAuras` API from the index.
- `qrspi-routing`: "Build a full raid-cooldown tracker with an options panel and profiles." Expected: it routes to QRSPI (or gives the install hint) before writing Lua.

#### 3. Run + tune
- Requires the `claude` CLI on PATH (not present on 2026-11-01). Install it via the desktop app or `npm i -g @anthropic-ai/claude-code`.
- Run from the repo root with a `.claude/` dir present, because run_eval walks up for `.claude/` (research.md:50):
```bash
mkdir -p .claude
SC="${SKILL_CREATOR_DIR:-$HOME/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/c783f22c-a674-4d4d-b0a0-a09dfb07d8e6/228f5f35-228d-4d15-a271-f62273597712/skills/skill-creator}"
PYTHONPATH="$SC" python3 -m scripts.run_eval --eval-set evals/trigger-set.json --skill-path skills/wow-forever-addon --model claude-opus-5-5 > evals/results/trigger.json
```
- If the pass rate is below 0.85, run `scripts.run_loop` with the same args plus `--max-iterations 5 --results-dir evals/results`. Apply `best_description` to SKILL.md by hand and re-run `check.sh`.
- Behavior cases: run `claude plugin eval . --allow-tools Write,Edit,Bash` if the CLI is ≥ v2.1.269. Otherwise run each prompt by hand in a session with the plugin loaded and grade it against `case.yaml`.

#### 4. Docs + release
- `README.md`: install (marketplace and dev), prerequisites, what the skill does, workflows, scripts, the post-launch "confirm Interface + rerun gen-api" note, how to contribute API notes, and the license.
- `CHANGELOG.md`: `## [1.0.0] - <date>` summarising P0–P8.
- `.claude-plugin/plugin.json`: `"version": "1.0.0"`.
- **Full QRSPI run.** Structure mistakenly said "Phase 9"; it belongs here. Take one small real addon through 1→8 with the skill loaded, and record the artifact dir path in CHANGELOG.

### Verification
#### Automated
- [ ] `jq '.summary.passed / .summary.total' evals/results/trigger.json` ≥ 0.85
- [ ] `scripts/check.sh` exits 0 locally, and the CI `check` run is green
- [ ] `git tag v1.0.0` on the merged main

#### Manual
- [ ] All three behavior cases pass, by grader or by hand
- [ ] One addon taken through QRSPI 1→8 with the skill's inputs
- [ ] Post-launch: confirm the live Interface (`/dump select(4, GetBuildInfo())`), update `toc-format.md`, rerun `gen-api.sh`, and repeat the P2 and P4 in-game checks
