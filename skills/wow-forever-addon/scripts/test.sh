#!/usr/bin/env bash
# Run an addon's offline tests (<addon-dir>/tests/*_spec.lua) under LuaJIT with wowmock.
# Uses the addon's vendored tests/wowmock if present, else the skill's copy.
# usage: test.sh <addon-dir>
set -u
SK="$(cd "$(dirname "$0")/.." && pwd)"
D="$(cd "${1:?usage: test.sh <addon-dir>}" && pwd)"
MOCK="$D/tests/wowmock"
[ -d "$MOCK" ] || MOCK="$SK/scripts/wowmock"
set -- "$D"/tests/*_spec.lua
[ -e "$1" ] || { echo "no tests in $D/tests"; exit 1; }
BASE="$(dirname "$MOCK")"
LUA_PATH="$BASE/?.lua;$BASE/?/init.lua;;" luajit "$MOCK/runner.lua" "$D" "$@"
