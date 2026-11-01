#!/usr/bin/env bash
# Lint a WoW Forever addon (or one .lua file) with the generated Forever std.
# usage: lint.sh <addon-dir|file.lua>
set -u
SK="$(cd "$(dirname "$0")/.." && pwd)"
T="${1:?usage: lint.sh <addon-dir|file.lua>}"
CFG="$(mktemp)"
trap 'rm -f "$CFG"' EXIT
cat "$SK/templates/luacheck/forever-std.lua" "$SK/templates/luacheck/base.luacheckrc" > "$CFG"
# config globs resolve relative to the config file, so re-anchor the path-based rules at the target
if [ -d "$T" ]; then
  A="$(cd "$T" && pwd)"
  cat >> "$CFG" <<EOF
exclude_files = { "$A/**/Libs/**", "$A/Libs/**", "$A/**/tests/wowmock/**", "$A/tests/wowmock/**", "$A/.release/**" }
files["$A/tests/**"] = { std = "+busted", read_globals = { "ADDON_DIR" } }
files["$A/**/tests/**"] = { std = "+busted", read_globals = { "ADDON_DIR" } }
EOF
  if [ -f "$T/.luacheckrc" ]; then cat "$T/.luacheckrc" >> "$CFG"; fi
fi

rc=0
luacheck --config "$CFG" --codes "$T" || rc=1

# never-emit: explicit message naming the replacement (luacheck already reports W113)
NAMES="$(awk '/never-emit:start/{f=1;next}/never-emit:end/{f=0}f' "$SK/references/forever-api-notes.md" \
  | sed -n 's/^- `\([A-Za-z0-9_.]*\)`.*/\1/p')"
FILES="$(find "$T" -name '*.lua' -not -path '*/Libs/*' -not -path '*/tests/wowmock/*')"
for n in $NAMES; do
  # bare use only: not preceded by `.`/`:` or an identifier char (so C_Container.GetContainerItemInfo is fine)
  re="(^|[^.:A-Za-z0-9_])$(printf '%s' "$n" | sed 's/\./\\./g')([^A-Za-z0-9_]|$)"
  # shellcheck disable=SC2086
  hits="$(grep -nE "$re" $FILES /dev/null 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*--')" || true
  if [ -n "$hits" ]; then
    echo "NEVER-EMIT: $n (see references/forever-api-notes.md)"
    echo "$hits"
    rc=1
  fi
done

# perf heuristic (warning only)
for f in $FILES; do
  if grep -q 'SetScript("OnUpdate"' "$f" && ! grep -vE '^[[:space:]]*--' "$f" | grep -qE 'elapsed|throttle|THROTTLE'; then
    echo "PERF: unthrottled OnUpdate in $f (see references/performance.md)"
  fi
done
exit $rc
