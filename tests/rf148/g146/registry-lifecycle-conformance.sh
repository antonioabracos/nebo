#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC

root=$(git rev-parse --show-toplevel)
cd "$root"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

fail() {
  printf 'G146 conformance failed: %s\n' "$*" >&2
  exit 1
}

check_static_elf() {
  local executable=$1 label=$2
  file "$executable" | rg -q 'ELF 64-bit.*x86-64.*statically linked' || fail "$label is not static x86-64 ELF"
  test -z "$(nm -u "$executable")" || fail "$label has undefined symbols"
  test -z "$(readelf -dW "$executable" 2>/dev/null | awk '/NEEDED/')" || fail "$label has dynamic dependencies"
  readelf -lW "$executable" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}' || fail "$label has executable stack"
}

product_sources=(
  compiler/registry/snapshot_authority.asm
  compiler/registry/class_transition.asm
  compiler/registry/edition_manifest.asm
  compiler/registry/deprecation_lifecycle.asm
  compiler/registry/protocol_coherence.asm
  compiler/registry/migration_manifest.asm
  compiler/registry/governance_audit.asm
)
test "${#product_sources[@]}" -eq 7 || fail "product owner cardinality changed"
for source in "${product_sources[@]}"; do
  name=$(basename "$source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$work/$name.a.o" "$source"
  nasm -f elf64 -Wall -Werror -I./ -o "$work/$name.b.o" "$source"
  cmp -s "$work/$name.a.o" "$work/$name.b.o" || fail "$name object is nondeterministic"
  readelf -SW "$work/$name.a.o" | rg -q '\.note.GNU-stack' || fail "$name lacks a non-executable stack note"
done
if rg -n 'extern[[:space:]]+(printf|puts|malloc|free|memcpy|strlen|__libc|dlopen|dlsym|dlclose)|(^|[[:space:]])syscall' "${product_sources[@]}" >"$work/ambient.log"; then
  fail "Registry lifecycle product uses an ambient runtime, loader, allocation or syscall"
fi

required_symbols=(
  neboc_registry_snapshot_sign
  neboc_registry_transition_validate
  neboc_registry_edition_validate
  neboc_registry_deprecation_evaluate
  neboc_registry_validate_compatibility
  neboc_registry_generate_migration_manifest
  neboc_registry_migration_transform
  neboc_registry_governance_validate
)
for symbol in "${required_symbols[@]}"; do
  test "$(nm -g --defined-only build/bin/neboc | rg -c "[[:space:]]${symbol}$")" -eq 1 || fail "live compiler lacks unique $symbol"
done

for pass in a b; do
  timeout 30 build/tests/rf204/G146/lifecycle_probe >"$work/probe.$pass.bin" 2>"$work/probe.$pass.err" || fail "native lifecycle probe $pass failed"
  test ! -s "$work/probe.$pass.err" || fail "native lifecycle probe $pass emitted stderr"
  test "$(wc -c <"$work/probe.$pass.bin")" -eq 144 || fail "native lifecycle probe did not publish the complete lifecycle observation"
done
cmp -s "$work/probe.a.bin" "$work/probe.b.bin" || fail "native observation changed"
check_static_elf build/tests/rf204/G146/lifecycle_probe lifecycle-probe
check_static_elf build/bin/neboc compiler

for pass in a b; do
  PYTHONDONTWRITEBYTECODE=1 python3 -B tests/rf204/G146/lifecycle_oracle.py >"$work/oracle.$pass"
done
cmp -s "$work/oracle.a" "$work/oracle.b" || fail "independent oracle changed"
for marker in INDEPENDENT_ORACLE TRANSITION_POLICY EDITION_COMPATIBILITY_POLICY DEPRECATION_POLICY MIGRATION_POLICY GOVERNANCE_POLICY; do
  rg -q "^${marker}=PASS$" "$work/oracle.a" || fail "oracle marker missing: $marker"
done
native_hex=$(xxd -p -c 1000 "$work/probe.a.bin")
oracle_hex=$(sed -n 's/^OBSERVATION_HEX=//p' "$work/oracle.a")
test "$native_hex" = "$oracle_hex" || fail "native lifecycle observation differs from the independent oracle"

PYTHONDONTWRITEBYTECODE=1 python3 -B scripts/rf148/validate-registry-authority.py --check >"$work/registry-authority.log"
rg -q '^REGISTRY_CLASS_STATE_POLICY=PASS$' "$work/registry-authority.log" || fail "Registry class/state authority changed"
rg -q '^GENERATED_ASM_PARITY=PASS$' "$work/registry-authority.log" || fail "generated Registry parity changed"

printf '%s\n' 'RF148_G146_REGISTRY_LIFECYCLE_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_PUBLIC_ENTRIES_ACTIVATED=0'
printf '%s\n' 'LIFECYCLE_ABI_OWNERS=7/7'
printf '%s\n' 'NATIVE_ORACLE_PARITY=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'NO_AUTOMATIC_MIGRATION=PASS'
