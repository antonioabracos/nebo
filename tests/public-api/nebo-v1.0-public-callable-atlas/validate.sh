#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
generator="$repo_root/tools/nebo-public-callable-atlas.py"
manifest="$repo_root/tests/public-api/nebo-v1.0-public-callable-atlas/manifest.tsv"
atlas="$repo_root/examples/conformance/nebo-v1.0-public-callable-atlas.no"
tmp_root=${TMPDIR:-/tmp}/nebo-public-callable-atlas-validate-$$
mkdir -p "$tmp_root"
trap 'rm -f "$tmp_root/generated-a.no" "$tmp_root/generated-b.no" "$tmp_root/summary-a.json" "$tmp_root/summary-b.json" "$tmp_root/tampered.tsv"' EXIT

env -u DISPLAY -u XAUTHORITY -u WAYLAND_DISPLAY \
  -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u NO_PROXY \
  PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-/tmp/nebo-public-callable-atlas-python-cache}" \
  python3 -B "$generator" --manifest "$manifest" --output "$atlas" --check --summary "$tmp_root/summary-a.json"

env -u DISPLAY -u XAUTHORITY -u WAYLAND_DISPLAY \
  -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u NO_PROXY \
  PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-/tmp/nebo-public-callable-atlas-python-cache}" \
  python3 -B "$generator" --manifest "$manifest" --output "$tmp_root/generated-a.no" --summary "$tmp_root/summary-a.json"
env -u DISPLAY -u XAUTHORITY -u WAYLAND_DISPLAY \
  -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u NO_PROXY \
  PYTHONDONTWRITEBYTECODE=1 PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-/tmp/nebo-public-callable-atlas-python-cache}" \
  python3 -B "$generator" --manifest "$manifest" --output "$tmp_root/generated-b.no" --summary "$tmp_root/summary-b.json"
cmp -s "$tmp_root/generated-a.no" "$tmp_root/generated-b.no"
cmp -s "$tmp_root/generated-a.no" "$atlas"

test "$(rg -c '^// ATLAS_GROUP ' "$atlas")" -eq 204
test "$(rg -c '^// ATLAS_SUBGROUP ' "$atlas")" -eq 1634
test "$(rg -c '^// ATLAS_VARIANT ' "$atlas")" -eq 207
test "$(rg -c '^    // ACTIVE_VARIANT ' "$atlas")" -eq 207
test "$(rg -c '^// VALUE_PRELUDE ' "$atlas")" -eq 23
test "$(rg -c '^start\(\)\{' "$atlas")" -eq 1
! rg -q 'ENTRYPOINT\(' "$atlas"
! rg -qi '\bprint\s*\(' "$atlas"

cp "$manifest" "$tmp_root/tampered.tsv"
sed -i '/^VARIANT\t/s/[0-9a-f]\{64\}$/0000000000000000000000000000000000000000000000000000000000000000/' "$tmp_root/tampered.tsv"
if env -u DISPLAY -u XAUTHORITY -u WAYLAND_DISPLAY PYTHONDONTWRITEBYTECODE=1 \
  PYTHONPYCACHEPREFIX="${PYTHONPYCACHEPREFIX:-/tmp/nebo-public-callable-atlas-python-cache}" \
  python3 -B "$generator" --manifest "$tmp_root/tampered.tsv" --output "$tmp_root/tampered.no" >/dev/null 2>&1; then
  echo 'tampered manifest was not rejected' >&2
  exit 1
fi

echo 'C13_PRC_A2_ATLAS_GENERATOR_STRUCTURAL_GREEN groups=204 subgroups=1634 variants=207 preludes=23 deterministic=yes tamper_rejected=yes'
