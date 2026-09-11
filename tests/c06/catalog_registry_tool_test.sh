#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 AUTHORITY_ROOT REPOSITORY_ROOT OUTPUT_ROOT" >&2
  exit 64
fi

authority_root=$1
repository_root=$2
output_root=$3
tool_path="${repository_root}/tools/c06-catalog-registry.py"
snapshot=${C06_SNAPSHOT_FINGERPRINT:-TEST_SNAPSHOT}
verified_at=${C06_VERIFIED_AT:-2000-01-01T00:00:00Z}

export PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="${output_root}/python-cache"

if [[ -e "${output_root}" ]]; then
  echo "refusing to overwrite output root: ${output_root}" >&2
  exit 65
fi
mkdir -p "${output_root}"

for run_name in a b; do
  run_root="${output_root}/${run_name}"
  python3 -B "${tool_path}" classify \
    --authority "${authority_root}" \
    --repo "${repository_root}" \
    --output "${run_root}" \
    --snapshot "${snapshot}" \
    --verified-at "${verified_at}"
  python3 -B "${tool_path}" extract-live \
    --authority "${authority_root}" \
    --repo "${repository_root}" \
    --output "${run_root}" \
    --snapshot "${snapshot}" \
    --verified-at "${verified_at}"
  python3 -B "${tool_path}" validate \
    --authority "${authority_root}" \
    --repo "${repository_root}" \
    --output "${run_root}" \
    --snapshot "${snapshot}" \
    --verified-at "${verified_at}"
done

python3 -B "${tool_path}" diff \
  --output "${output_root}/a" \
  --against "${output_root}/b" \
  --diff-output "${output_root}/DETERMINISM-DIFF.tsv"

if grep -q $'\tNO$' "${output_root}/DETERMINISM-DIFF.tsv"; then
  echo "non-deterministic registry output" >&2
  exit 66
fi

cp -a "${output_root}/a" "${output_root}/negative-evidence-hash"
python3 -B - "${output_root}/negative-evidence-hash/PUBLIC-SURFACE-REGISTRY.tsv" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines()
fields = lines[0].split("\t")
hash_index = fields.index("evidence_sha256")
row = lines[1].split("\t")
row[hash_index] = "0" * 64
lines[1] = "\t".join(row)
path.write_text("\n".join(lines) + "\n")
PY

if python3 -B "${tool_path}" validate \
  --authority "${authority_root}" \
  --repo "${repository_root}" \
  --output "${output_root}/negative-evidence-hash" \
  --snapshot "${snapshot}" \
  --verified-at "${verified_at}"; then
  echo "validator accepted a mismatched evidence hash" >&2
  exit 67
fi

if find "${repository_root}" \( -type d -name __pycache__ -o -type f -name '*.pyc' -o -type f -name '*.pyo' \) -print -quit | grep -q .; then
  echo "repository Python cache detected" >&2
  exit 68
fi

echo "C06_CATALOG_REGISTRY_TOOL_TEST=PASS"
