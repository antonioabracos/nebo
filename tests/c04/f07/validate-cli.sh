#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
neboc="$repo_root/build/bin/neboc"
source_file="$repo_root/examples/evolution/g01/float-foundation.no"

"$neboc" check "$source_file" --warn unused >/dev/null 2>&1

set +e
"$neboc" check "$source_file" --warn NEBO-W9999 >/dev/null 2>&1
unknown_status=$?
"$neboc" check "$source_file" --warn unused --deny unused >/dev/null 2>&1
duplicate_status=$?
set -e

[[ "$unknown_status" -eq 2 ]]
[[ "$duplicate_status" -eq 2 ]]

printf '%s\n' 'C04_F07_CLI_SELECTOR_VALIDATION=PASS'
