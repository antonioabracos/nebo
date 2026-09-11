#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$root/tests/harness/lib.sh"

catalog="$root/tests/manifest/TEST-CATALOG.tsv"
action=""
selected_id=""
selected_suite=""
expected_count=326
allow_not_implemented=0
run_id=""
evidence_root="$root/tests/evidence/runs"

usage() {
    cat <<'EOF'
usage: tests/harness/run-tests.sh [options]

  --validate-catalog
  --list
  --run TEST-ID
  --suite DOMAIN
  --all
  --catalog PATH
  --expected-count N
  --allow-not-implemented
  --run-id ID
  --evidence-root PATH
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --validate-catalog|--list|--all)
            [ -z "$action" ] || nebo_die "only one action may be selected"
            action=${1#--}
            shift ;;
        --run)
            [ -z "$action" ] || nebo_die "only one action may be selected"
            [ "$#" -ge 2 ] || nebo_die "--run requires TEST-ID"
            action=run; selected_id=$2; shift 2 ;;
        --suite)
            [ -z "$action" ] || nebo_die "only one action may be selected"
            [ "$#" -ge 2 ] || nebo_die "--suite requires DOMAIN"
            action=suite; selected_suite=$2; shift 2 ;;
        --catalog)
            [ "$#" -ge 2 ] || nebo_die "--catalog requires PATH"
            catalog=$2; shift 2 ;;
        --expected-count)
            [ "$#" -ge 2 ] || nebo_die "--expected-count requires N"
            expected_count=$2; shift 2 ;;
        --allow-not-implemented)
            allow_not_implemented=1; shift ;;
        --run-id)
            [ "$#" -ge 2 ] || nebo_die "--run-id requires ID"
            run_id=$2; shift 2 ;;
        --evidence-root)
            [ "$#" -ge 2 ] || nebo_die "--evidence-root requires PATH"
            evidence_root=$2; shift 2 ;;
        --help|-h)
            usage; exit 0 ;;
        *) nebo_die "unknown option: $1" ;;
    esac
done

[ -n "$action" ] || nebo_die "an action is required"
[ -f "$catalog" ] || nebo_die "catalog not found: $catalog"

validate_catalog() {
    expected_header='test_id\tdomain\ttest_type\tsequence\tscenario\texpected\tevidence_type\tgate\tprimary_front\timplementation_state\tcase_path'
    actual_header=$(sed -n '1p' "$catalog")
    [ "$actual_header" = "$(printf '%b' "$expected_header")" ] || nebo_die "invalid catalog header"

    rows=$(awk 'END { print NR - 1 }' "$catalog")
    [ "$rows" -eq "$expected_count" ] || nebo_die "catalog rows $rows != expected $expected_count"

    duplicates=$(tail -n +2 "$catalog" | cut -f1 | sort | uniq -d)
    [ -z "$duplicates" ] || nebo_die "duplicate IDs: $duplicates"

    awk -F '\t' '
        NR == 1 { next }
        NF != 11 { print "invalid field count at line " NR > "/dev/stderr"; bad=1; next }
        $1 !~ /^NEBO-[A-Z0-9]+-[A-Z0-9_]+-[0-9][0-9][0-9]$/ { print "invalid ID " $1 > "/dev/stderr"; bad=1 }
        $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || $9 == "" || $10 == "" || $11 == "" { print "empty field at line " NR > "/dev/stderr"; bad=1 }
        $8 !~ /^P[0-3]$/ { print "invalid gate " $8 > "/dev/stderr"; bad=1 }
        $9 !~ /^MF0[0-6][0-9]$/ || $9 == "MF000" || $9 > "MF065" { print "invalid front " $9 > "/dev/stderr"; bad=1 }
        $10 !~ /^(NOT_IMPLEMENTED|READY|IMPLEMENTED|DEFERRED|SUPERSEDED)$/ { print "invalid implementation state " $10 > "/dev/stderr"; bad=1 }
        END { exit bad ? 1 : 0 }
    ' "$catalog" || nebo_die "catalog semantic validation failed"

    echo "NEBO_TEST_CATALOG_GREEN rows=$rows"
}

validate_catalog

case "$action" in
    validate-catalog) exit 0 ;;
    list)
        awk -F '\t' 'NR == 1 { next } { printf "%s\t%s\t%s\t%s\n", $1, $2, $9, $10 }' "$catalog"
        exit 0 ;;
esac

if [ -z "$run_id" ]; then
    run_id=$(date -u '+%Y%m%dT%H%M%SZ')-$$
fi
printf '%s\n' "$run_id" | grep -Eq '^[A-Za-z0-9._-]+$' || nebo_die "unsafe run ID"
run_dir="$evidence_root/$run_id"
[ ! -e "$run_dir" ] || nebo_die "run directory already exists: $run_dir"
mkdir -p "$run_dir/logs" "$run_dir/results"

catalog_hash=$(sha256sum "$catalog" | awk '{print $1}')
start=$(nebo_now_utc)
{
    echo "RUN_ID=$run_id"
    echo "START_UTC=$start"
    echo "CATALOG=$catalog"
    echo "CATALOG_SHA256=$catalog_hash"
    echo "ACTION=$action"
} > "$run_dir/metadata.txt"
printf 'test_id\tresult\texit_code\tstart_utc\tend_utc\tcase_path\n' > "$run_dir/summary.tsv"

selected="$run_dir/selected.tsv"
case "$action" in
    run)
        nebo_valid_test_id "$selected_id" || nebo_die "invalid test ID: $selected_id"
        awk -F '\t' -v id="$selected_id" 'NR == 1 { next } $1 == id { print; found=1 } END { exit found ? 0 : 1 }' "$catalog" > "$selected" || nebo_die "test ID not found: $selected_id" ;;
    suite)
        printf '%s\n' "$selected_suite" | grep -Eq '^[A-Z0-9]+$' || nebo_die "invalid suite domain"
        awk -F '\t' -v domain="$selected_suite" 'NR == 1 { next } $2 == domain { print; found=1 } END { exit found ? 0 : 1 }' "$catalog" > "$selected" || nebo_die "suite has no tests: $selected_suite" ;;
    all)
        tail -n +2 "$catalog" > "$selected" ;;
esac

fail_count=0
blocked_count=0
not_implemented_count=0
skipped_count=0
not_executed_count=0
pass_count=0

tab=$(printf '\t')
while IFS="$tab" read -r test_id domain test_type sequence scenario expected evidence_type gate primary_front implementation_state case_path; do
    [ -n "$test_id" ] || continue
    case "$case_path" in
        /*) case_file="$case_path" ;;
        *)  case_file="$root/${case_path#./}" ;;
    esac
    stdout_file="$run_dir/logs/$test_id.stdout.txt"
    stderr_file="$run_dir/logs/$test_id.stderr.txt"
    result_file="$run_dir/results/$test_id.txt"
    test_start=$(nebo_now_utc)

    if [ ! -f "$case_file" ]; then
        result=NOT_IMPLEMENTED
        exit_code=127
        : > "$stdout_file"
        echo "case not implemented: $case_path" > "$stderr_file"
        not_implemented_count=$((not_implemented_count + 1))
    elif [ ! -x "$case_file" ]; then
        result=FAIL
        exit_code=126
        : > "$stdout_file"
        echo "case is not executable: $case_path" > "$stderr_file"
        fail_count=$((fail_count + 1))
    else
        set +e
        NEBO_TEST_ID="$test_id" \
        NEBO_REPO_ROOT="$root" \
        NEBO_EVIDENCE_DIR="$run_dir" \
        "$case_file" > "$stdout_file" 2> "$stderr_file"
        exit_code=$?
        set -e
        result=$(nebo_result_for_exit "$exit_code")
        case "$result" in
            PASS) pass_count=$((pass_count + 1)) ;;
            FAIL) fail_count=$((fail_count + 1)) ;;
            BLOCKED) blocked_count=$((blocked_count + 1)) ;;
            SKIPPED_NOT_APPLICABLE)
                if ! nebo_validate_reason_file "$case_file.skip" SKIPPED_NOT_APPLICABLE; then
                    result=FAIL
                    exit_code=41
                    echo "invalid or missing skip metadata: $case_file.skip" >> "$stderr_file"
                    fail_count=$((fail_count + 1))
                else
                    skipped_count=$((skipped_count + 1))
                fi ;;
            NOT_EXECUTED_WITH_REASON)
                if ! nebo_validate_reason_file "$case_file.reason" NOT_EXECUTED_WITH_REASON; then
                    result=FAIL
                    exit_code=42
                    echo "invalid or missing reason metadata: $case_file.reason" >> "$stderr_file"
                    fail_count=$((fail_count + 1))
                else
                    not_executed_count=$((not_executed_count + 1))
                fi ;;
        esac
    fi

    test_end=$(nebo_now_utc)
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$test_id" "$result" "$exit_code" "$test_start" "$test_end" "$case_path" >> "$run_dir/summary.tsv"
    {
        echo "TEST_ID=$test_id"
        echo "RESULT=$result"
        echo "EXIT_CODE=$exit_code"
        echo "PRIMARY_FRONT=$primary_front"
        echo "GATE=$gate"
        echo "EXPECTED=$expected"
        echo "EVIDENCE_TYPE=$evidence_type"
    } > "$result_file"
done < "$selected"

end=$(nebo_now_utc)
{
    echo "END_UTC=$end"
    echo "PASS=$pass_count"
    echo "FAIL=$fail_count"
    echo "BLOCKED=$blocked_count"
    echo "SKIPPED_NOT_APPLICABLE=$skipped_count"
    echo "NOT_EXECUTED_WITH_REASON=$not_executed_count"
    echo "NOT_IMPLEMENTED=$not_implemented_count"
} >> "$run_dir/metadata.txt"

cat "$run_dir/summary.tsv"
echo "NEBO_TEST_RUN_COMPLETE run_id=$run_id pass=$pass_count fail=$fail_count blocked=$blocked_count skipped=$skipped_count not_executed=$not_executed_count not_implemented=$not_implemented_count"

[ "$fail_count" -eq 0 ] || exit 1
[ "$blocked_count" -eq 0 ] || exit 2
[ "$skipped_count" -eq 0 ] || exit 3
[ "$not_executed_count" -eq 0 ] || exit 4
if [ "$not_implemented_count" -ne 0 ] && [ "$allow_not_implemented" -ne 1 ]; then
    exit 5
fi
exit 0
