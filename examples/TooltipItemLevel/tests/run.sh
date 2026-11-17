#!/usr/bin/env bash
# Run this addon's offline tests (LuaJIT + bundled wowmock).
set -u
D="$(cd "$(dirname "$0")/.." && pwd)"
command -v cygpath >/dev/null && D="$(cygpath -m "$D")" # Git Bash: luajit.exe needs a Windows path in LUA_PATH
set -- "$D"/tests/*_spec.lua
LUA_PATH="$D/tests/?.lua;$D/tests/?/init.lua;;" exec luajit "$D/tests/wowmock/runner.lua" "$D" "$@"
