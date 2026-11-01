#!/usr/bin/env bash
# Run this addon's offline tests (LuaJIT + bundled wowmock).
set -u
D="$(cd "$(dirname "$0")/.." && pwd)"
set -- "$D"/tests/*_spec.lua
LUA_PATH="$D/tests/?.lua;$D/tests/?/init.lua;;" exec luajit "$D/tests/wowmock/runner.lua" "$D" "$@"
