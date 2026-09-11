#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f05-tests >/dev/null
build/tests/rf27-g24/f05/lsp_test
python3 tests/rf27-g24/f05/lsp_oracle.py
file build/tests/rf27-g24/f05/lsp_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f05/lsp_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f05/lsp_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g24/f05/lsp_test
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G24_F05_GREEN native_assertions=15 jsonrpc=stdio_only diagnostics=neboc_check completion_hover_navigation_rename_tokens=yes stale_suppressed=yes cancellation=yes utf8_utf16=yes static_elf=yes no_c_no_libc=yes'
