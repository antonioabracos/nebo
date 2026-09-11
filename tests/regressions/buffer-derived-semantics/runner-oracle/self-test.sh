#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d /tmp/nebo-buffer-oracle-self-test-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT

printf 'LANE\tKEY\tVALUE\nA\tONE\t1\n' > "$tmp/one.tsv"
printf 'LANE\tKEY\tVALUE\nA\tONE\t1\nA\tTWO\t2\n' > "$tmp/two.tsv"

run_case() {
    local id=$1 expected_rc=$2 expected=$3 exit_code=$4 transcript=$5
    printf '%b' "$transcript" > "$tmp/$id.raw"
    set +e
    python3 "$root/parse_transcript.py" \
        --expected "$expected" \
        --raw "$tmp/$id.raw" \
        --parsed "$tmp/$id.parsed.tsv" \
        --exit-code "$exit_code" > "$tmp/$id.stdout" 2> "$tmp/$id.stderr"
    local rc=$?
    set -e
    test "$rc" -eq "$expected_rc"
}

run_case E01 0 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|1\nNEBO_TEST_RESULT|PASS\n'
run_case E02 1 "$tmp/one.tsv" 0 'not-an-assertion\nNEBO_TEST_RESULT|PASS\n'
run_case E03 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|UNKNOWN|1\nNEBO_TEST_RESULT|PASS\n'
run_case E04 1 "$tmp/one.tsv" 0 'NEBO_TEST_RESULT|PASS\n'
run_case E05 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|1\nNEBO_ASSERT|A|ONE|1\nNEBO_TEST_RESULT|PASS\n'
run_case E06 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|2\nNEBO_TEST_RESULT|PASS\n'
run_case E07 1 "$tmp/two.tsv" 0 'NEBO_ASSERT|A|TWO|2\nNEBO_ASSERT|A|ONE|1\nNEBO_TEST_RESULT|PASS\n'
run_case E08 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|FAIL\nNEBO_TEST_RESULT|PASS\n'
run_case E09 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|1\n'
run_case E10 1 "$tmp/one.tsv" 0 'NEBO_ASSERT|A|ONE|1\nNEBO_TEST_RESULT|PASS\nNEBO_TEST_RESULT|PASS\n'
run_case E11 1 "$tmp/one.tsv" 0 'NEBO_TEST_RESULT|PASS\nNEBO_ASSERT|A|ONE|1\n'
run_case E12 1 "$tmp/one.tsv" 139 'NEBO_ASSERT|A|ONE|1\nNEBO_TEST_RESULT|PASS\n'

printf '%s\n' 'RUNNER_ORACLE_SYNTHETIC=PASS cases=12 accepted=1 rejected=11 false_green=0'
