#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
# Match the explicit /usr/bin toolchain used by the isolated SDK rebuild.
export PATH=/usr/bin:/bin
unset PYTHONHOME PYTHONPATH LD_LIBRARY_PATH LD_PRELOAD
export PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1 LC_ALL=C
work=$(mktemp -d "${TMPDIR:-/tmp}/nebo-public-ci.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
export PYTHONPYCACHEPREFIX="$work/pycache"
bounded() {
  local name=$1 seconds=$2
  shift 2
  python3 -B tests/release/post-g204-remediation/runner.py     --timeout "$seconds" --report "$work/$name.process.json" -- "$@"
}
python3 -B tests/public/policy.py
python3 -B tests/public/privacy_selftest.py > "$work/privacy-selftests.json"
bounded relocation 180 python3 -B tests/public/relocation_selftest.py --report "$work/relocation.json"
python3 -B scripts/check-version-consistency.py > "$work/version.json"
python3 -B tests/release/version-consistency/selftest.py > "$work/version-selftests.json"
# Collection validation composes an SDK and needs every native SDK tool.
python3 -B -c 'import subprocess; from compiler.sdk.sdk_builder import NATIVE; subprocess.run(["ninja", "-j2", *NATIVE], check=True)'
python3 -B scripts/build-public-docs.py
python3 -B tests/public/documentation.py
bounded sdk 900 python3 -B tests/public/sdk_lifecycle.py --work "$work/reproducibility" --report "$work/sdk.json"
bounded indexing 180 bash tests/release/indexing-compatibility/validate.sh --report "$work/indexing.json"
bounded examples 300 python3 -B tests/public/examples.py --report "$work/examples.json"
bounded collections 1200 bash tests/rf204/G007/validate.sh
bounded data-streams 1200 bash tests/rf204/G010/validate.sh
bounded complexity 300 python3 -B tests/public/complexity.py --report "$work/complexity.json"
bounded runner-controls 120 python3 -B tests/release/post-g204-remediation/cluster_test.py --report "$work/runner-controls.json"
bounded scientific 300 python3 -B tests/release/post-g204-remediation/scientific_test.py --report "$work/scientific.json"
bounded oracle-self 180 python3 -B tests/release/post-g204-remediation/source_suite.py self --report "$work/oracle-self.json"
bounded console-public 900 python3 -B tests/release/post-g204-remediation/source_suite.py console_public --report "$work/console-public.json"
bounded scan-public 900 python3 -B tests/release/post-g204-remediation/source_suite.py scan_public --report "$work/scan-public.json"
printf '%s\n' 'PUBLIC_CI=PASS'
