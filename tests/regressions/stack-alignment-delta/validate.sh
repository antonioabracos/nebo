#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C LANG=C TERM=dumb TZ=UTC PYTHONDONTWRITEBYTECODE=1
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy

root="$(cd -- "$(dirname -- "$0")/../../.." && pwd)"
auth="$root/tests/regressions/stack-alignment-delta/authenticated-seven-findings.tsv"
primary="$root/scripts/mf056/audit-stack-alignment.py"
oracle="$root/scripts/release/nebo-1.0/prepublication-remediation/stack_alignment_oracle.py"

test "$(sha256sum "$primary" | awk '{print $1}')" = b735cb0e368209c3918f168c965afd2083209b021d9e362fcd1bb248f7426b65
test "$(sha256sum "$oracle" | awk '{print $1}')" = 9e29c7fce77c79e94432d9cf4ac1379c74ffde7201c8cea49babb02de8bb6806

scratch="$(mktemp -d -t nebo-stack-alignment-release-XXXXXXXX)"
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
mkdir -p "$scratch/oracle"

ninja -C "$root" -j2 build/bin/neboc > "$scratch/build.txt"
test "$("$root/build/bin/neboc" --version)" = 'neboc 1.0.1'

set +e
(cd "$root" && python3 -B "$primary" build/bin/neboc \
  --ninja-target build/bin/neboc \
  --report-tsv "$scratch/mf056.tsv" \
  --report-json "$scratch/mf056.json") > "$scratch/mf056.txt" 2>&1
mf056_rc=$?
python3 -B "$oracle" --root "$root" --binary build/bin/neboc \
  --output-dir "$scratch/oracle" > "$scratch/oracle.txt" 2>&1
oracle_rc=$?
set -e

test "$mf056_rc" -eq 1
test "$oracle_rc" -eq 1

python3 - "$auth" "$scratch/mf056.tsv" "$scratch/oracle/ORACLE-REPORT.json" <<'PY'
import csv
import json
import sys

auth_path, primary_path, oracle_path = sys.argv[1:]

with open(auth_path, newline="", encoding="utf-8") as stream:
    authenticated = list(csv.DictReader(stream, delimiter="\t"))
if len(authenticated) != 7 or len({row["finding_id"] for row in authenticated}) != 7:
    raise SystemExit("AUTHENTICATED_SEVEN_FINDINGS_INVALID")

with open(primary_path, newline="", encoding="utf-8") as stream:
    primary_red = [row for row in csv.DictReader(stream, delimiter="\t")
                   if row["outcome"].endswith("_RED")]
if len(primary_red) != 285:
    raise SystemExit(f"MF056_COUNT_RED release={len(primary_red)}")

remaining = {row["finding_id"] for row in authenticated} & {
    row["finding_id"] for row in primary_red
}
if remaining:
    raise SystemExit(f"AUTHENTICATED_SEVEN_FINDINGS_REMAINING={sorted(remaining)}")

with open(oracle_path, encoding="utf-8") as stream:
    oracle_findings = json.load(stream)["findings"]
oracle_red = [row for row in oracle_findings
              if row["kind"] == "CALL" and row["outcome"] == "CALL_ALIGNMENT_RED"]
if len(oracle_red) != 133:
    raise SystemExit(f"ORACLE_COUNT_RED release={len(oracle_red)}")

print("AUTHENTICATED_CORRECTED_CALL_SITES=7")
print("AUTHENTICATED_SEVEN_FINDINGS_REMAINING=0")
print("MF056_RELEASE_FAILURES=285")
print("MF056_NEW_FINDINGS=0")
print("INDEPENDENT_ORACLE_RELEASE_FAILURES=133")
print("INDEPENDENT_ORACLE_NEW_FINDINGS=0")
print("STACK_ALIGNMENT_DELTA_GATE=PASS")
PY

echo STACK_ALIGNMENT_DELTA_REGRESSION=PASS
