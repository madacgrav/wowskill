#!/usr/bin/env bash
# Regenerate the Forever API index + luacheck std from Gethe/wow-ui-source (branch: forever).
# usage: gen-api.sh [--ref forever] [--src DIR]
set -eu
SK="$(cd "$(dirname "$0")/.." && pwd)"
REF=forever
SRC=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --src) SRC="$2"; shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 2 ;;
  esac
done
if [ -z "$SRC" ]; then
  SRC="${XDG_CACHE_HOME:-$HOME/.cache}/wowskill/wow-ui-source-$REF"
  if [ -d "$SRC/.git" ]; then
    git -C "$SRC" fetch -q --depth 1 origin "$REF" && git -C "$SRC" checkout -q FETCH_HEAD
  else
    mkdir -p "$(dirname "$SRC")"
    git clone -q --depth 1 --branch "$REF" https://github.com/Gethe/wow-ui-source.git "$SRC"
  fi
fi
COMMIT="$(git -C "$SRC" log -1 --format='%h %s')"
DATE="$(git -C "$SRC" log -1 --format=%cs)"
luajit "$SK/scripts/gen_api.lua" "$SRC" "$SK" "$COMMIT" "$DATE"
