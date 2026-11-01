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

step "lint fixtures"
"$SK/scripts/lint.sh" "$SK/scripts/fixtures/good.lua" >/dev/null || { echo "good.lua should pass lint"; fail=1; }
out="$("$SK/scripts/lint.sh" "$SK/scripts/fixtures/bad.lua" 2>&1)" && { echo "bad.lua should fail lint"; fail=1; }
for want in "NEVER-EMIT: GetContainerItemInfo" "(W113)" "(W143)" "(W111)"; do
  case "$out" in *"$want"*) ;; *) echo "bad.lua lint output missing: $want"; fail=1 ;; esac
done
[ $fail -eq 0 ] && echo "fixtures OK"

step "scaffold smoke"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
n=0
for pats in "" "event" "timer" "ui" "ldb" "tooltip" "event timer ui ldb tooltip"; do
  n=$((n + 1))
  args=""
  for p in $pats; do args="$args --pattern $p"; done
  # shellcheck disable=SC2086
  "$SK/scripts/scaffold.sh" Demo --dest "$TMP/$n" $args >/dev/null || { echo "scaffold failed: [$pats]"; fail=1; continue; }
  if grep -rqE '__[A-Z]+__|@pattern:|@end-pattern@' "$TMP/$n/Demo"; then echo "leftover tokens: [$pats]"; fail=1; fi
  "$SK/scripts/lint.sh" "$TMP/$n/Demo" >/dev/null || { echo "lint failed: [$pats]"; fail=1; }
  "$SK/scripts/test.sh" "$TMP/$n/Demo" >/dev/null || { echo "tests failed: [$pats]"; fail=1; }
done
"$TMP/$n/Demo/tests/run.sh" >/dev/null || { echo "vendored tests/run.sh failed"; fail=1; }
"$SK/scripts/scaffold.sh" AceDemo --ace3 --dest "$TMP/ace" >/dev/null || { echo "ace3 scaffold failed"; fail=1; }
"$SK/scripts/lint.sh" "$TMP/ace/AceDemo" >/dev/null || { echo "lint failed: ace3"; fail=1; }
"$SK/scripts/test.sh" "$TMP/ace/AceDemo" >/dev/null || { echo "tests failed: ace3"; fail=1; }
diff -rq "$SK/scripts/wowmock" "$ROOT/examples/TooltipItemLevel/tests/wowmock" >/dev/null \
  || { echo "examples/TooltipItemLevel/tests/wowmock is stale: re-copy from $SK/scripts/wowmock"; fail=1; }
[ $fail -eq 0 ] && echo "scaffold smoke OK ($n variants, lint + tests)"

step "examples"
for d in "$ROOT"/examples/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  "$SK/scripts/lint.sh" "$d" >/dev/null || { echo "lint failed: $name"; fail=1; }
  "$SK/scripts/test.sh" "$d" >/dev/null || { echo "tests failed: $name"; fail=1; }
  echo "checked $name"
done

step "qrspi name isolation"
leaks="$(grep -rl 'qrspi-plan-toolkit:' "$ROOT/skills/" | grep -v 'references/qrspi-handoff.md')"
if [ -n "$leaks" ]; then echo "qrspi command names outside qrspi-handoff.md:"; echo "$leaks"; fail=1; else echo "isolation OK"; fi

step "buggy fixture (every seeded fault must be caught)"
BUG="$SK/scripts/fixtures/buggy/Buggy"
lout="$("$SK/scripts/lint.sh" "$BUG" 2>&1)" && { echo "lint should fail on Buggy"; fail=1; }
for want in "(W111)" "NEVER-EMIT: UnitAura" "PERF: unthrottled OnUpdate"; do
  case "$lout" in *"$want"*) ;; *) echo "Buggy lint output missing: $want"; fail=1 ;; esac
done
tout="$("$SK/scripts/test.sh" "$BUG" 2>&1)" && { echo "tests should fail on Buggy"; fail=1; }
for want in "attempt to index global 'BuggyDB'" "FAIL Buggy > does not create frames per event"; do
  case "$tout" in *"$want"*) ;; *) echo "Buggy test output missing: $want"; fail=1 ;; esac
done
[ $fail -eq 0 ] && echo "all 5 seeded faults caught"

step "reference API names"
# every profiling/taint global named in the references must exist in the index or the lint std
for n in UpdateAddOnCPUUsage GetAddOnCPUUsage UpdateAddOnMemoryUsage GetAddOnMemoryUsage debugprofilestop \
         InCombatLockdown hooksecurefunc issecurevariable CreateFrame UIParent GameTooltip TooltipDataProcessor \
         BackdropTemplate GameFontNormal; do
  grep -qw "$n" "$SK/references/forever-api-index.md" || grep -q "\"$n\"" "$SK/templates/luacheck/forever-std.lua" \
    || { echo "reference names unknown API: $n"; fail=1; }
done
for e in PLAYER_REGEN_ENABLED ADDON_ACTION_BLOCKED ADDON_ACTION_FORBIDDEN GET_ITEM_INFO_RECEIVED SPELL_DATA_LOAD_RESULT \
         BAG_UPDATE_DELAYED UNIT_POWER_UPDATE; do
  grep -q "\`$e\`" "$SK/references/forever-api-index.md" || { echo "reference names unknown event: $e"; fail=1; }
done
[ $fail -eq 0 ] && echo "reference names OK"

printf '\n== result: %s\n' "$([ $fail -eq 0 ] && echo PASS || echo FAIL)"
exit $fail
