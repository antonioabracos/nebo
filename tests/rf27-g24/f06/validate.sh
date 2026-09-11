#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
python3 tests/rf27-g24/f06/adapter_oracle.py > "$tmp_root/a"
python3 tests/rf27-g24/f06/adapter_oracle.py > "$tmp_root/b"
cmp "$tmp_root/a" "$tmp_root/b"
cat "$tmp_root/a"
python3 -c "import json; json.load(open('editors/vscode/package.json'))"
test -z "$(rg -n 'https?://|fetch\(|XMLHttpRequest|WebSocket|shell: true|childProcess\.exec\(' editors/vscode/extension.js editors/vscode/package.json || true)"
rg -q "shell: false" editors/vscode/extension.js
rg -q "tools/rf27-lsp.py" editors/vscode/extension.js
rg -q "tools/rf27-format.py" editors/vscode/extension.js
rg -q "'nebo.check': \['check'\]" editors/vscode/extension.js
rg -q "'nebo.build': \['build'\]" editors/vscode/extension.js
rg -q "'nebo.emitAsm': \['emit-asm'\]" editors/vscode/extension.js
test -z "$(find editors/vscode tests/rf27-g24/f06 -type d \( -name node_modules -o -name __pycache__ \) -print)"
printf '%s\n' 'RF27_G24_F06_GREEN profile=HEADLESS_OR_SOURCE_GREEN_ENVIRONMENT_LIMITED static_assertions=22 protocol_cases=10000 commands=check_build_emit_asm_format local_compiler=yes stdio_lsp=yes shell=false telemetry=false network=false downloads=false dependencies=0 output_max=1048576 redaction_pre_sink=yes mocked_vscode_fixture=present javascript_runtime=not_available live_vscode_host=not_available source_syntax=not_activated'
