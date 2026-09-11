#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/cases" "$tmp/evidence"

catalog="$tmp/catalog.tsv"
printf 'test_id\tdomain\ttest_type\tsequence\tscenario\texpected\tevidence_type\tgate\tprimary_front\timplementation_state\tcase_path\n' > "$catalog"
printf 'NEBO-SELF-CONTRACT-001\tSELF\tCONTRACT\t001\tpass case\tPASS\tselftest\tP0\tMF003\tIMPLEMENTED\t%s\n' "$tmp/cases/pass.sh" >> "$catalog"
printf 'NEBO-SELF-CONTRACT-002\tSELF\tCONTRACT\t002\tfail case\tFAIL\tselftest\tP0\tMF003\tIMPLEMENTED\t%s\n' "$tmp/cases/fail.sh" >> "$catalog"
printf 'NEBO-SELF-CONTRACT-003\tSELF\tCONTRACT\t003\tblocked case\tBLOCKED\tselftest\tP0\tMF003\tIMPLEMENTED\t%s\n' "$tmp/cases/blocked.sh" >> "$catalog"
printf 'NEBO-SELF-CONTRACT-004\tSELF\tCONTRACT\t004\tskip case\tSKIPPED\tselftest\tP0\tMF003\tIMPLEMENTED\t%s\n' "$tmp/cases/skipped.sh" >> "$catalog"
printf 'NEBO-SELF-CONTRACT-005\tSELF\tCONTRACT\t005\tmissing case\tNOT_IMPLEMENTED\tselftest\tP0\tMF003\tNOT_IMPLEMENTED\t%s\n' "$tmp/cases/missing.sh" >> "$catalog"

cat > "$tmp/cases/pass.sh" <<'EOF'
#!/usr/bin/env sh
echo pass
exit 0
EOF
cat > "$tmp/cases/fail.sh" <<'EOF'
#!/usr/bin/env sh
echo fail >&2
exit 10
EOF
cat > "$tmp/cases/blocked.sh" <<'EOF'
#!/usr/bin/env sh
echo blocked >&2
exit 20
EOF
cat > "$tmp/cases/skipped.sh" <<'EOF'
#!/usr/bin/env sh
exit 30
EOF
cat > "$tmp/cases/skipped.sh.skip" <<'EOF'
Kind: SKIPPED_NOT_APPLICABLE
Reason: synthetic harness contract test
Authority: MF003 self-test
ReviewAt: MF003 closeout
EOF
chmod +x "$tmp/cases/"*.sh

runner="$root/tests/harness/run-tests.sh"
"$runner" --catalog "$catalog" --expected-count 5 --validate-catalog >/dev/null

expect_result() {
    id=$1 expected=$2 expected_exit=$3
    set +e
    "$runner" --catalog "$catalog" --expected-count 5 --run "$id" --run-id "$id" --evidence-root "$tmp/evidence" --allow-not-implemented >/dev/null
    actual_exit=$?
    set -e
    [ "$actual_exit" -eq "$expected_exit" ] || { echo "$id exit $actual_exit != $expected_exit" >&2; exit 1; }
    actual=$(awk -F '\t' 'NR == 2 { print $2 }' "$tmp/evidence/$id/summary.tsv")
    [ "$actual" = "$expected" ] || { echo "$id result $actual != $expected" >&2; exit 1; }
}

expect_result NEBO-SELF-CONTRACT-001 PASS 0
expect_result NEBO-SELF-CONTRACT-002 FAIL 1
expect_result NEBO-SELF-CONTRACT-003 BLOCKED 2
expect_result NEBO-SELF-CONTRACT-004 SKIPPED_NOT_APPLICABLE 3
expect_result NEBO-SELF-CONTRACT-005 NOT_IMPLEMENTED 0

# Duplicate IDs must fail catalog validation.
cp "$catalog" "$tmp/duplicate.tsv"
tail -n 1 "$catalog" >> "$tmp/duplicate.tsv"
set +e
"$runner" --catalog "$tmp/duplicate.tsv" --expected-count 6 --validate-catalog >/dev/null 2>&1
dup_exit=$?
set -e
[ "$dup_exit" -ne 0 ] || { echo "duplicate catalog unexpectedly passed" >&2; exit 1; }

echo "MF003_HARNESS_SELFTEST_GREEN"
