#!/usr/bin/env bash
# Scaffold a WoW Forever addon from the skill templates.
# usage: scaffold.sh <Name> [--ace3] [--pattern event|timer|ui|ldb|tooltip]... [--license MIT|none] [--dest DIR] [--author A] [--notes TXT]
SK="$(cd "$(dirname "$0")/.." && pwd)"
exec luajit "$SK/scripts/scaffold.lua" "$SK" "$@"
