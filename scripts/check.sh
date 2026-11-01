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
done
[ $fail -eq 0 ] && echo "scaffold smoke OK ($n variants)"

# (P3+) tests, (P5+) qrspi name isolation, (P6+) buggy fixture

printf '\n== result: %s\n' "$([ $fail -eq 0 ] && echo PASS || echo FAIL)"
exit $fail
