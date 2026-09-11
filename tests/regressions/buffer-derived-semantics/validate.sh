#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
unset http_proxy https_proxy all_proxy no_proxy

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
root=$repo/tests/regressions/buffer-derived-semantics
fixtures=$root/fixtures
compiler=${NEBOC:-$repo/build/bin/neboc}
runtime=$repo/build/obj/runtime_practical_io.o
tmp=$(mktemp -d /tmp/nebo-buffer-derived-semantics-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT

test -x "$compiler"
test -f "$runtime"
nasm -f elf64 "$root/runner-oracle/capture_stub.asm" -o "$tmp/capture_stub.o"
cp "$runtime" "$tmp/runtime_capture.o"
objcopy \
    --redefine-sym nebo_runtime_console_publish_text=nebo_product_console_publish_text \
    --redefine-sym nebo_runtime_console_publish_int=nebo_product_console_publish_int \
    --redefine-sym nebo_runtime_console_publish_bool=nebo_product_console_publish_bool \
    --redefine-sym nebo_runtime_scan_console_handle=nebo_product_scan_console_handle \
    "$tmp/runtime_capture.o"

capture_fixture() {
    local name=$1 source=$2 expected_exit=$3
    local dir=$tmp/$name
    mkdir -p "$dir"
    "$compiler" check "$source"
    "$compiler" emit-asm "$source" -o "$dir/program.asm"
    "$compiler" build "$source" -o "$dir/product.elf"
    file "$dir/product.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
    ! readelf -lW "$dir/product.elf" | rg -q INTERP
    test -z "$(nm -u "$dir/product.elf")"
    nasm -f elf64 "$dir/program.asm" -o "$dir/program.o"
    ld -nostdlib -z noexecstack -e _start -o "$dir/capture.elf" \
        "$dir/program.o" "$tmp/capture_stub.o" "$tmp/runtime_capture.o"
    set +e
    timeout 10 "$dir/capture.elf" > "$dir/transcript.raw" 2> "$dir/stderr.raw"
    local actual_exit=$?
    set -e
    test "$actual_exit" -eq "$expected_exit"
    test ! -s "$dir/stderr.raw"
}

declare -A passed=( [A]=0 [B]=0 [C]=0 )
declare -A total=( [A]=0 [B]=0 [C]=0 )
while IFS=$'\t' read -r name expected lane; do
    [[ $name == FIXTURE ]] && continue
    total[$lane]=$((total[$lane] + 1))
    capture_fixture "$name" "$fixtures/$name.no" "$expected"
    passed[$lane]=$((passed[$lane] + 1))
done < "$root/expected/probe-exits.tsv"

capture_fixture inventory-machine "$fixtures/inventory-machine.no" 0
python3 "$root/runner-oracle/parse_transcript.py" \
    --expected "$root/expected/inventory-machine.tsv" \
    --raw "$tmp/inventory-machine/transcript.raw" \
    --parsed "$tmp/inventory-machine/parsed.tsv" \
    --exit-code 0 > "$tmp/inventory-machine/oracle.stdout"
! rg -q 'FAIL' "$tmp/inventory-machine/transcript.raw"
test "$(tail -n 1 "$tmp/inventory-machine/transcript.raw")" = 'NEBO_TEST_RESULT|PASS'

capture_fixture inventory-readable "$fixtures/inventory-readable.no" 0
test "$(wc -l < "$tmp/inventory-readable/transcript.raw")" -eq 10
! rg -q 'FAIL' "$tmp/inventory-readable/transcript.raw"
test "$(tail -n 1 "$tmp/inventory-readable/transcript.raw")" = 'NEBO_TEST_RESULT|PASS'

capture_fixture d00-console-newline "$fixtures/d00-console-newline.no" 0
test "$(od -An -tx1 -v "$tmp/d00-console-newline/transcript.raw" | tr -d ' \n')" = 410a42

bash "$root/runner-oracle/self-test.sh" > "$tmp/runner-self-test.log"
rg -q '^RUNNER_ORACLE_SYNTHETIC=PASS cases=12 ' "$tmp/runner-self-test.log"

# The byte-faithful historical source is preserved and explicitly classified.
historical=$repo/tests/regressions/false-green-buffer-route/NEBO-v1.0-INVENTARIO-PRATICO.no
test "$(sha256sum "$historical" | cut -d' ' -f1)" = ac5d5fdb43a2c2c1946a9a786090eb89ca0c6ca1f8673e6d633073c7da19aa7f
capture_fixture historical-inventory "$historical" 0
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/historical-inventory/program.asm")" -eq 2
test "$(sha256sum "$tmp/historical-inventory/program.asm" | cut -d' ' -f1)" != b892610bd01e0f5d568db4556d09dca8bd507898c24420c60f7366fc69e1cc5e

# Candidate output and transcript must be deterministic for the strict fixture.
"$compiler" emit-asm "$fixtures/inventory-machine.no" -o "$tmp/inventory-machine/second.asm"
"$compiler" build "$fixtures/inventory-machine.no" -o "$tmp/inventory-machine/second.elf"
cmp -s "$tmp/inventory-machine/program.asm" "$tmp/inventory-machine/second.asm"
cmp -s "$tmp/inventory-machine/product.elf" "$tmp/inventory-machine/second.elf"

printf 'BUFFER_DERIVED_SEMANTICS=PASS lane_a=%s/%s lane_b=%s/%s lane_c=%s/%s lane_d=1/1 lane_e=12/12 automatic_inventory=PASS historical=CLASSIFIED_FIXTURE_CONTRACT newline_hex=410a42 deterministic_asm_elf=yes\n' \
    "${passed[A]}" "${total[A]}" \
    "${passed[B]}" "${total[B]}" \
    "${passed[C]}" "${total[C]}"
