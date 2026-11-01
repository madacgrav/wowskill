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

printf '\n== result: %s\n' "$([ $fail -eq 0 ] && echo PASS || echo FAIL)"
exit $fail
