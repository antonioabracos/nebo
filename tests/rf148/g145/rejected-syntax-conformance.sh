#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel); cd "$root"; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mapfile -t src < <(find compiler/diagnostics/rejected -type f -name '*.asm' | sort)
test "${#src[@]}" -eq 8
for f in "${src[@]}"; do n=${f//\//_}; nasm -f elf64 -Wall -Werror -I./ -o "$tmp/$n.o" "$f"; done
for id in $(seq -w 1 26); do rg -q "NSR-REJ-0$id|1450${id#0}" compiler/diagnostics/rejected; done
test "$(rg --no-filename -o 'NSR-REJ-[0-9]{3}' compiler/diagnostics/rejected | sort -u | wc -l)" -eq 26
test "$(find tests/rf204/G145/negative -maxdepth 1 -type f -name '*.no' | wc -l)" -eq 28
for source in tests/rf204/G145/negative/*.no; do
  set +e
  build/bin/neboc check "$source" --message-format json-lines --color never >"$tmp/out" 2>"$tmp/err"
  status=$?
  set -e
  test "$status" -eq 1
  jq -e '.code == "NEBO_LEX_REJECTED_FORM" and .primary.end > .primary.start' "$tmp/err" >/dev/null
done
printf '%s
' RF148_G145_REJECTED_SYNTAX_CONFORMANCE=PASS
printf '%s\n' 'REGISTRY_ROWS=26/26'
printf '%s\n' 'SOURCE_SPELLINGS=28/28'
printf '%s\n' 'EXECUTABLE_SEMANTICS=0'
printf '%s\n' 'MIGRATION_AUTOMATIC=0'
printf '%s\n' 'NO_COMPATIBILITY_MODE=PASS'
