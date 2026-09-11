#!/usr/bin/env bash
set -euo pipefail
umask 022
export LC_ALL=C
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX=${TMPDIR:-/tmp}/nebo-c03-f07-python-cache

repo=$(cd "$(dirname "$0")/../../.." && pwd -P)
neboc=${NEBOC:-$repo/build/bin/neboc}
fixture=$repo/tests/c03/f07/fixtures
stage=$(mktemp -d "${TMPDIR:-/tmp}/nebo-c03-f07-test.XXXXXXXX")
cleanup() { find "$stage" -depth -delete; }
trap cleanup EXIT

"$repo/build/tests/c03/f07/manifest_target_test"
cp "$fixture"/*.no "$stage/"
cp "$fixture/manifest.nebo.targets" "$stage/"

"$neboc" check --manifest "$stage/manifest.nebo.targets" --target app-alpha
"$neboc" check --manifest "$stage/manifest.nebo.targets"
"$neboc" emit-asm --manifest "$stage/manifest.nebo.targets" --target app-alpha -o "$stage/alpha.asm"
"$neboc" emit-asm --manifest "$stage/manifest.nebo.targets" --target app-beta -o "$stage/beta.asm"
! cmp -s "$stage/alpha.asm" "$stage/beta.asm"
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target app-alpha -o "$stage/alpha"
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target app-beta -o "$stage/beta"
"$stage/alpha"
set +e
"$stage/beta"
beta_status=$?
set -e
test "$beta_status" -eq 1

"$neboc" build --manifest "$stage/manifest.nebo.targets" --target core -o "$stage/core.o"
readelf -h "$stage/core.o" | grep -Eq 'Type:[[:space:]]+REL'
! readelf -Ws "$stage/core.o" | grep -Eq '[[:space:]]_start$'

"$neboc" emit-asm --manifest "$stage/manifest.nebo.targets" --target checks -o "$stage/checks.asm"
grep -Eq 'lea rdi, \[rel nebo_test_runner_[0-9a-f]{16}\]' "$stage/checks.asm"
grep -Eq '^static nebo_test_runner_[0-9a-f]{16}:function$' "$stage/checks.asm"
! grep -Eq '^global nebo_test_runner_' "$stage/checks.asm"
nasm -f elf64 -Wall -Werror -o "$stage/checks.o" "$stage/checks.asm"
readelf -Ws "$stage/checks.o" | grep -Eq 'FUNC[[:space:]]+LOCAL.*nebo_test_runner_[0-9a-f]{16}$'
grep -Eq '^    xor edi, edi$' "$stage/checks.asm"
grep -Eq '^    test rax, rax$' "$stage/checks.asm"
runner_instructions=$(objdump -d --no-show-raw-insn "$stage/checks.o" | awk '/<nebo_test_runner_[0-9a-f]+>:/ {inside=1; next} inside && /^[[:space:]]*[0-9a-f]+:/ {n++} END {print n+0}')
runner_bytes=$(objdump -d "$stage/checks.o" | awk '/<nebo_test_runner_[0-9a-f]+>:/ {inside=1; next} inside && /^[[:space:]]*[0-9a-f]+:/ {for(i=2;i<=NF;i++){if($i ~ /^[0-9a-f][0-9a-f]$/)n++;else break}} END {print n+0}')
test "$runner_instructions" -le 16
test "$runner_bytes" -le 96
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target checks -o "$stage/checks"
"$stage/checks"
test ! -s "$stage/checks.stdout"

sed 's/case_pass$/case_fail/' "$stage/manifest.nebo.targets" > "$stage/failing.nebo.targets"
"$neboc" build --manifest "$stage/failing.nebo.targets" --target checks -o "$stage/checks-fail"
set +e
"$stage/checks-fail" >"$stage/checks.stdout" 2>"$stage/checks.stderr"
fail_status=$?
set -e
test "$fail_status" -eq 1
test ! -s "$stage/checks.stdout"
test ! -s "$stage/checks.stderr"

# Canonical empty NI-v1 (64 bytes) generated outside the repository.
printf 'NEBO.NI\000\001\000\100\000\000\000\000\000' > "$stage/shared.ni"
dd if=/dev/zero bs=1 count=48 status=none >> "$stage/shared.ni"
printf '\100\000\000\000' | dd of="$stage/shared.ni" bs=1 seek=52 conv=notrunc status=none
test "$(wc -c < "$stage/shared.ni")" -eq 64
sed 's#target app-alpha executable alpha.no - -#target app-alpha executable alpha.no shared.ni -#' \
  "$stage/manifest.nebo.targets" > "$stage/interface.nebo.targets"
"$neboc" check --manifest "$stage/interface.nebo.targets" --target app-alpha
"$neboc" emit-asm --manifest "$stage/interface.nebo.targets" --target app-alpha -o "$stage/interface.asm"
"$neboc" build --manifest "$stage/interface.nebo.targets" --target app-alpha -o "$stage/interface-alpha"
cmp "$stage/alpha.asm" "$stage/interface.asm"
cmp "$stage/alpha" "$stage/interface-alpha"
cp "$stage/shared.ni" "$stage/corrupt.ni"
printf X | dd of="$stage/corrupt.ni" bs=1 seek=0 conv=notrunc status=none
sed 's/shared.ni/corrupt.ni/' "$stage/interface.nebo.targets" > "$stage/corrupt.nebo.targets"
set +e
"$neboc" check --manifest "$stage/corrupt.nebo.targets" --target app-alpha >"$stage/corrupt.out" 2>"$stage/corrupt.err"
corrupt_status=$?
set -e
test "$corrupt_status" -eq 1
grep -q 'NEBO-C03-TARGET-016' "$stage/corrupt.err"

# Exact selector and canonical manifest fail closed.
set +e
"$neboc" check --manifest "$stage/manifest.nebo.targets" --target app >"$stage/unknown.out" 2>"$stage/unknown.err"
unknown_status=$?
set -e
test "$unknown_status" -eq 1
grep -q 'NEBO-C03-TARGET-009' "$stage/unknown.err"
sed '4h;5d;3G' "$stage/manifest.nebo.targets" > "$stage/reordered.nebo.targets"
set +e
"$neboc" check --manifest "$stage/reordered.nebo.targets" --target app-alpha >"$stage/order.out" 2>"$stage/order.err"
order_status=$?
set -e
test "$order_status" -eq 1

# Repeated build/emit is deterministic and selected closure ignores an
# unselected source that has a duplicate start.
"$neboc" emit-asm --manifest "$stage/manifest.nebo.targets" --target checks -o "$stage/checks-2.asm"
cmp "$stage/checks.asm" "$stage/checks-2.asm"
printf 'start(){0.return;}\nstart(){0.return;}\n' > "$stage/unselected-bad.no"
sed 's#target core library core.no - -#target core library unselected-bad.no - -#' \
  "$stage/manifest.nebo.targets" > "$stage/unselected.nebo.targets"
"$neboc" check --manifest "$stage/unselected.nebo.targets" --target app-alpha

# Example is independently runnable; every runnable artifact is static ELF64,
# has one process entry and no dynamic/C/libc dependency.
sed 's/target app-alpha executable/target app-alpha example/' \
  "$stage/manifest.nebo.targets" > "$stage/example.nebo.targets"
"$neboc" check --manifest "$stage/example.nebo.targets" --target app-alpha
"$neboc" emit-asm --manifest "$stage/example.nebo.targets" --target app-alpha -o "$stage/example.asm"
"$neboc" build --manifest "$stage/example.nebo.targets" --target app-alpha -o "$stage/example"
"$stage/example"
for artifact in "$stage/alpha" "$stage/beta" "$stage/checks" "$stage/example"; do
  file "$artifact" | grep -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$artifact" | grep -q 'INTERP'
  ! readelf -dW "$artifact" | grep -q 'NEEDED'
  test -z "$(nm -u "$artifact")"
  readelf -lW "$artifact" | awk '/GNU_STACK/{seen=1; if ($0 ~ /E/) exit 1} END{exit seen ? 0 : 1}'
  test "$(readelf -Ws "$artifact" | awk '$8 == "_start" && $5 == "GLOBAL" {n++} END{print n+0}')" -eq 1
done
test "$(nm -g "$stage/checks" | grep -c 'nebo_test_runner_' || true)" -eq 0

# Explicit/default/sole selection and CLI spelling are exact and fail closed.
sed '/^default /d' "$stage/manifest.nebo.targets" > "$stage/no-default.nebo.targets"
set +e
"$neboc" check --manifest "$stage/no-default.nebo.targets" >"$stage/selection.out" 2>"$stage/selection.err"
selection_status=$?
"$neboc" check --manifest "$stage/manifest.nebo.targets" --target >"$stage/missing-selector.out" 2>"$stage/missing-selector.err"
missing_selector_status=$?
"$neboc" check --manifest "$stage/manifest.nebo.targets" --target app-alpha --target app-beta >"$stage/duplicate-selector.out" 2>"$stage/duplicate-selector.err"
duplicate_selector_status=$?
"$neboc" check --manifest "$stage/manifest.nebo.targets" --target App-alpha >"$stage/case-selector.out" 2>"$stage/case-selector.err"
case_selector_status=$?
"$neboc" check --manifest "$stage/manifest.nebo.targets" --filter case_pass >"$stage/filter.out" 2>"$stage/filter.err"
filter_status=$?
set -e
test "$selection_status" -eq 1
grep -q 'NEBO-C03-TARGET-010' "$stage/selection.err"
test "$missing_selector_status" -eq 2
test "$duplicate_selector_status" -eq 2
test "$case_selector_status" -eq 1
grep -q 'NEBO-C03-TARGET-007' "$stage/case-selector.err"
test "$filter_status" -eq 2

printf '%s\n' 'nebo-target-manifest 1' 'target only executable alpha.no - -' > "$stage/sole.nebo.targets"
"$neboc" check --manifest "$stage/sole.nebo.targets"

# The canonical diagnostic identity is invariant across machine formats.
for format in human short json json-lines sarif; do
  set +e
  "$neboc" check --manifest "$stage/manifest.nebo.targets" --target app \
    --message-format "$format" >"$stage/$format.out" 2>"$stage/$format.err"
  format_status=$?
  set -e
  test "$format_status" -eq 1
  grep -q 'NEBO-C03-TARGET-009' "$stage/$format.err"
done
grep -q '^{' "$stage/json.err"
grep -q '"ruleId":"NEBO-C03-TARGET-009"' "$stage/sarif.err"

# Reserved diagnostic causes retain their precise identities.
printf '%s\n' 'nebo-target-manifest 1' 'default absent' 'target only executable alpha.no - -' > "$stage/default-unknown.nebo.targets"
printf '%s\n' 'nebo-target-manifest 1' 'target  executable alpha.no - -' > "$stage/missing-id.nebo.targets"
printf '%s\n' 'nebo-target-manifest 1' 'target Bad executable alpha.no - -' > "$stage/bad-id.nebo.targets"
printf '%s\n' 'nebo-target-manifest 1' 'target same executable alpha.no - -' 'target same executable beta.no - -' > "$stage/duplicate-id.nebo.targets"
printf '%s\n' 'nebo-target-manifest 1' 'target strange binary alpha.no - -' > "$stage/bad-kind.nebo.targets"
dd if=/dev/zero of="$stage/oversize.nebo.targets" bs=4097 count=1 status=none
for diagnostic_case in default-unknown:12 missing-id:6 bad-id:7 duplicate-id:8 bad-kind:15 oversize:21; do
  case_name=${diagnostic_case%%:*}
  case_code=${diagnostic_case##*:}
  printf -v expected_code '%03d' "$case_code"
  set +e
  "$neboc" check --manifest "$stage/$case_name.nebo.targets" >"$stage/$case_name.out" 2>"$stage/$case_name.err"
  case_status=$?
  set -e
  test "$case_status" -eq 1
  grep -q "NEBO-C03-TARGET-$expected_code" "$stage/$case_name.err"
done
set +e
"$neboc" check --manifest "$stage/does-not-exist.nebo.targets" >"$stage/missing-manifest.out" 2>"$stage/missing-manifest.err"
missing_manifest_status=$?
set -e
test "$missing_manifest_status" -eq 3
grep -q 'NEBO-C03-TARGET-001' "$stage/missing-manifest.err"

# Manifest/member symlinks and canonical path escapes are rejected. An output
# hard-link alias is also rejected before publication.
ln -s "$stage/manifest.nebo.targets" "$stage/manifest-link.nebo.targets"
set +e
"$neboc" check --manifest "$stage/manifest-link.nebo.targets" --target app-alpha >"$stage/manifest-link.out" 2>"$stage/manifest-link.err"
manifest_link_status=$?
set -e
test "$manifest_link_status" -eq 1
grep -q 'NEBO-C03-TARGET-013' "$stage/manifest-link.err"

ln -s alpha.no "$stage/alpha-link.no"
sed 's/alpha.no/alpha-link.no/' "$stage/manifest.nebo.targets" > "$stage/member-link.nebo.targets"
set +e
"$neboc" check --manifest "$stage/member-link.nebo.targets" --target app-alpha >"$stage/member-link.out" 2>"$stage/member-link.err"
member_link_status=$?
set -e
test "$member_link_status" -eq 1
grep -q 'NEBO-C03-TARGET-013' "$stage/member-link.err"

printf '%s\n' 'nebo-target-manifest 1' 'default self' 'target self executable manifest-alias.no - -' > "$stage/manifest-alias.no"
set +e
"$neboc" check --manifest "$stage/manifest-alias.no" --target self >"$stage/source-manifest-alias.out" 2>"$stage/source-manifest-alias.err"
source_manifest_alias_status=$?
set -e
test "$source_manifest_alias_status" -eq 1
grep -q 'NEBO-C03-TARGET-011' "$stage/source-manifest-alias.err"

ln "$stage/alpha.no" "$stage/source-alias.ni"
sed 's#target app-alpha executable alpha.no - -#target app-alpha executable alpha.no source-alias.ni -#' \
  "$stage/manifest.nebo.targets" > "$stage/source-interface-alias.nebo.targets"
set +e
"$neboc" check --manifest "$stage/source-interface-alias.nebo.targets" --target app-alpha >"$stage/source-interface-alias.out" 2>"$stage/source-interface-alias.err"
source_interface_alias_status=$?
set -e
test "$source_interface_alias_status" -eq 1
grep -q 'NEBO-C03-TARGET-016' "$stage/source-interface-alias.err"

mkdir "$stage/directory.no"
sed 's/alpha.no/directory.no/' "$stage/manifest.nebo.targets" > "$stage/directory-member.nebo.targets"
set +e
"$neboc" check --manifest "$stage/directory-member.nebo.targets" --target app-alpha >"$stage/directory-member.out" 2>"$stage/directory-member.err"
directory_member_status=$?
set -e
test "$directory_member_status" -eq 1
grep -q 'NEBO-C03-TARGET-011' "$stage/directory-member.err"

sed 's#alpha.no#../alpha.no#' "$stage/manifest.nebo.targets" > "$stage/escape.nebo.targets"
set +e
"$neboc" check --manifest "$stage/escape.nebo.targets" --target app-alpha >"$stage/escape.out" 2>"$stage/escape.err"
escape_status=$?
set -e
test "$escape_status" -eq 1
grep -q 'NEBO-C03-TARGET-012' "$stage/escape.err"

long_path=$(printf 'a%.0s' {1..253})'.no'
printf '%s\n' 'nebo-target-manifest 1' "target long executable $long_path - -" > "$stage/path-limit.nebo.targets"
set +e
"$neboc" check --manifest "$stage/path-limit.nebo.targets" --target long >"$stage/path-limit.out" 2>"$stage/path-limit.err"
path_limit_status=$?
set -e
test "$path_limit_status" -eq 1
grep -q 'NEBO-C03-TARGET-021' "$stage/path-limit.err"

ln "$stage/alpha.no" "$stage/output-alias"
set +e
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target app-alpha -o "$stage/output-alias" >"$stage/alias.out" 2>"$stage/alias.err"
alias_status=$?
set -e
test "$alias_status" -eq 1
grep -q 'NEBO-C03-TARGET-014' "$stage/alias.err"
test ! -e "$stage/output-alias"

# Rejected operations remove the exact stale output and compiler-owned
# temporaries, then a valid selection in the same matrix remains independent.
printf 'stale\n' > "$stage/stale.elf"
printf 'stale\n' > "$stage/stale.elf.neboc.asm"
printf 'stale\n' > "$stage/stale.elf.neboc.o"
set +e
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target does-not-exist -o "$stage/stale.elf" >"$stage/stale.out" 2>"$stage/stale.err"
stale_status=$?
set -e
test "$stale_status" -eq 1
test ! -e "$stage/stale.elf"
test ! -e "$stage/stale.elf.neboc.asm"
test ! -e "$stage/stale.elf.neboc.o"
"$neboc" check --manifest "$stage/manifest.nebo.targets" --target app-alpha

# Test targets require one exact test item and forbid a source-owned start.
sed 's/case_pass$/-/' "$stage/manifest.nebo.targets" > "$stage/empty-test.nebo.targets"
set +e
"$neboc" check --manifest "$stage/empty-test.nebo.targets" --target checks >"$stage/empty-test.out" 2>"$stage/empty-test.err"
empty_test_status=$?
set -e
test "$empty_test_status" -eq 1
grep -q 'NEBO-C03-TARGET-019' "$stage/empty-test.err"

printf '%s\n' '(Int.self)case_with_start(){0.return;}' 'start(){0.return;}' > "$stage/with-start.no"
sed 's/checks.no/with-start.no/; s/case_pass$/case_with_start/' "$stage/manifest.nebo.targets" > "$stage/with-start.nebo.targets"
set +e
"$neboc" check --manifest "$stage/with-start.nebo.targets" --target checks >"$stage/with-start.out" 2>"$stage/with-start.err"
with_start_status=$?
set -e
test "$with_start_status" -eq 1
grep -q 'NEBO_ENTRYPOINT_FORBIDDEN_FOR_TARGET' "$stage/with-start.err"

printf '%s\n' '(Int.self)some_other_test(){0.return;}' > "$stage/unresolved-test.no"
sed 's/checks.no/unresolved-test.no/' "$stage/manifest.nebo.targets" > "$stage/unresolved-test.nebo.targets"
set +e
"$neboc" check --manifest "$stage/unresolved-test.nebo.targets" --target checks >"$stage/unresolved-test.out" 2>"$stage/unresolved-test.err"
unresolved_test_status=$?
set -e
test "$unresolved_test_status" -eq 1
grep -q 'NEBO-C03-TARGET-017' "$stage/unresolved-test.err"

runner_label=$(sed -n 's/^static \(nebo_test_runner_[0-9a-f]\{16\}\):function$/\1/p' "$stage/checks.asm")
test -n "$runner_label"
printf '%s\n' '(Int.self)case_pass(){0.return;}' "(Int.self)$runner_label(){0.return;}" > "$stage/runner-collision.no"
sed 's/checks.no/runner-collision.no/' "$stage/manifest.nebo.targets" > "$stage/runner-collision.nebo.targets"
set +e
"$neboc" build --manifest "$stage/runner-collision.nebo.targets" --target checks -o "$stage/runner-collision" >"$stage/runner-collision.out" 2>"$stage/runner-collision.err"
runner_collision_status=$?
set -e
test "$runner_collision_status" -eq 70
grep -q 'NEBO-C03-TARGET-020' "$stage/runner-collision.err"
test ! -e "$stage/runner-collision"

# Existing runtime trap behavior remains distinct from the 0/1 test result.
printf '%s\n' '(Int.self)case_trap(){(1 / 0).return;}' > "$stage/trap.no"
printf '%s\n' 'nebo-target-manifest 1' 'target trap test trap.no - case_trap' > "$stage/trap.nebo.targets"
"$neboc" build --manifest "$stage/trap.nebo.targets" --target trap -o "$stage/trap"
set +e
"$stage/trap" >"$stage/trap.out" 2>"$stage/trap.err"
trap_status=$?
set -e
test "$trap_status" -ne 0
test "$trap_status" -ne 1

# Root moves and source renames do not change selected logical output. Cold
# repeated Assembly and final ELF bytes are identical.
"$neboc" build --manifest "$stage/manifest.nebo.targets" --target app-alpha -o "$stage/alpha-2"
cmp "$stage/alpha" "$stage/alpha-2"
mkdir "$stage/moved"
cp "$stage/alpha.no" "$stage/moved/alpha.no"
cp "$stage/manifest.nebo.targets" "$stage/moved/manifest.nebo.targets"
"$neboc" emit-asm --manifest "$stage/moved/manifest.nebo.targets" --target app-alpha -o "$stage/moved-alpha.asm"
"$neboc" build --manifest "$stage/moved/manifest.nebo.targets" --target app-alpha -o "$stage/moved-alpha"
cmp "$stage/alpha.asm" "$stage/moved-alpha.asm"
cmp "$stage/alpha" "$stage/moved-alpha"
cp "$stage/alpha.no" "$stage/alpha-renamed.no"
sed 's/alpha.no/alpha-renamed.no/' "$stage/manifest.nebo.targets" > "$stage/renamed.nebo.targets"
"$neboc" build --manifest "$stage/renamed.nebo.targets" --target app-alpha -o "$stage/renamed-alpha"
cmp "$stage/alpha" "$stage/renamed-alpha"

printf '%s\n' 'C03_F07_GREEN manifest_v1=yes targetid_exact=yes two_executables=yes example=yes library_rel=yes ni_v1=yes selected_closure=yes synthetic_runner_local_func=yes result_0_1_trap=yes diagnostics=yes security=yes failure_atomicity=yes static_elf=yes deterministic=yes offline=yes'
