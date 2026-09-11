#!/usr/bin/env sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$root"
python3 -B scripts/mf020/audit-ast-layout.py
build/tests/mf020/ast_test 2
