#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
unset http_proxy https_proxy all_proxy no_proxy

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
compiler=${NEBOC:-$repo/build/bin/neboc}
fixtures=$repo/tests/regressions/false-green-buffer-route
tmp=$(mktemp -d /tmp/nebo-false-green-buffer-route-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT

assert_asm_text() {
    local marker=$1
    local asm=$2
    local bytes
    bytes=$(printf '%s' "$marker" | od -An -tu1 -v | tr '\n' ' ' | xargs | tr ' ' ',')
    rg -Fq "db $bytes" "$asm"
}

assert_elf_text() {
    local marker=$1
    local elf=$2
    grep -aFq "$marker" "$elf"
}

assert_material_start() {
    local asm=$1
    local body=$tmp/start-body.asm
    sed -n '/^nebo_fn_1:$/,/^\.nebo_function_return_1:$/p' "$asm" > "$body"
    test "$(wc -l < "$body")" -gt 5
    rg -q '^    call ' "$body"
}

compile_fixture() {
    local name=$1
    local source=$fixtures/$name.no
    "$compiler" check "$source"
    "$compiler" emit-asm "$source" -o "$tmp/$name.asm"
    "$compiler" build "$source" -o "$tmp/$name.elf"
    file "$tmp/$name.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
    ! readelf -lW "$tmp/$name.elf" | rg -q INTERP
    test -z "$(nm -u "$tmp/$name.elf")"
    assert_material_start "$tmp/$name.asm"
}

for name in \
    r-a-one-scan-explicit-return \
    r-b-two-interleaved-scans \
    r-c-two-consecutive-scans \
    r-d-console-before-buffer \
    r-e-scan-before-buffer \
    r-f-transition-prefix \
    NEBO-v1.0-INVENTARIO-PRATICO; do
    compile_fixture "$name"
done

# The byte-faithful historical transition prefix also contains three nominal
# declarations whose first uses occur later in the full inventory. Before the
# Buffer trigger it was already RED; the correction must restore that result
# and must never create the old whole-file ASM/ELF stub.
exact=$fixtures/r-f-transition-prefix-exact.no
for mode in check emit-asm build; do
    stdout=$tmp/r-f-exact.$mode.stdout
    stderr=$tmp/r-f-exact.$mode.stderr
    artifact=$tmp/r-f-exact.$mode.artifact
    set +e
    if [[ $mode == check ]]; then
        "$compiler" check "$exact" >"$stdout" 2>"$stderr"
    else
        "$compiler" "$mode" "$exact" -o "$artifact" >"$stdout" 2>"$stderr"
    fi
    rc=$?
    set -e
    test "$rc" -eq 1
    test ! -e "$artifact"
    rg -q 'source validation failed|NEBO_PARSE_UNEXPECTED_TOKEN' "$stderr"
done

test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/r-a-one-scan-explicit-return.asm")" -eq 1
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/r-b-two-interleaved-scans.asm")" -eq 2
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/r-c-two-consecutive-scans.asm")" -eq 2
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/r-e-scan-before-buffer.asm")" -eq 1
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/r-f-transition-prefix.asm")" -eq 2
test "$(rg -c '^    call nebo_runtime_scan_console_handle$' "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm")" -eq 2

for marker in MARKER_BEFORE_BUFFER MARKER_AFTER_BUFFER; do
    assert_asm_text "$marker" "$tmp/r-d-console-before-buffer.asm"
    assert_elf_text "$marker" "$tmp/r-d-console-before-buffer.elf"
done

for name in r-d-console-before-buffer r-e-scan-before-buffer r-f-transition-prefix NEBO-v1.0-INVENTARIO-PRATICO; do
    ! rg -q '^global nebo_buffer_descriptor$' "$tmp/$name.asm"
    rg -q '^    call nebo_runtime_console_publish_text$' "$tmp/$name.asm"
done

for marker in \
    'NEBO 1.0' \
    'Nome do operador: ' \
    'Etiqueta da sessão: ' \
    'FIM DO TESTE'; do
    assert_asm_text "$marker" "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm"
    assert_elf_text "$marker" "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.elf"
done

rg -q '^    call nebo_runtime_console_publish_(text|int|bool)$' "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm"
rg -q '^    call nebo_runtime_scan_console_handle$' "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm"
rg -q '^    call nebo_scientific_owner_[0-9]+$' "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm"

# R-H: the dedicated Buffer backend is legal only after its whole-body
# coverage invariant proves that every top-level statement belongs to the
# exact Buffer owner graph. Mixed programs above must take FunctionTable.
rg -q '^cli_buffer_source_requires_composition:$' compiler/driver/cli/linux-x86_64/cli_driver.asm
rg -q '^ call cli_buffer_source_requires_composition$' compiler/driver/cli/linux-x86_64/cli_driver.asm

expected_inventory_sha=ac5d5fdb43a2c2c1946a9a786090eb89ca0c6ca1f8673e6d633073c7da19aa7f
test "$(sha256sum "$fixtures/NEBO-v1.0-INVENTARIO-PRATICO.no" | cut -d' ' -f1)" = "$expected_inventory_sha"

for name in r-f-transition-prefix NEBO-v1.0-INVENTARIO-PRATICO; do
    "$compiler" emit-asm "$fixtures/$name.no" -o "$tmp/$name.second.asm"
    "$compiler" build "$fixtures/$name.no" -o "$tmp/$name.second.elf"
    cmp -s "$tmp/$name.asm" "$tmp/$name.second.asm"
    cmp -s "$tmp/$name.elf" "$tmp/$name.second.elf"
done

test "$(sha256sum "$tmp/r-f-transition-prefix.asm" | cut -d' ' -f1)" != \
    "$(sha256sum "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.asm" | cut -d' ' -f1)"
test "$(sha256sum "$tmp/r-f-transition-prefix.elf" | cut -d' ' -f1)" != \
    "$(sha256sum "$tmp/NEBO-v1.0-INVENTARIO-PRATICO.elf" | cut -d' ' -f1)"

printf '%s\n' 'FALSE_GREEN_BUFFER_ROUTE=PASS cases=8 check=8 emit_asm=10 build=10 scan_return=yes mixed_buffer_composition=yes exact_transition_red_without_artifact=yes body_omission_guard=yes inventory_exact=yes markers_asm_elf=yes outputs_distinct=yes deterministic_asm=yes deterministic_elf=yes'
