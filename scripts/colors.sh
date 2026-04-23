#!/bin/bash
# Shared color output helpers. Usage: source scripts/colors.sh

_c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
info()    { _c "34" "[info] $1"; }
success() { _c "32" "[ok] $1"; }
warn()    { _c "33" "[warn] $1"; }
error()   { _c "31" "[error] $1" >&2; }
