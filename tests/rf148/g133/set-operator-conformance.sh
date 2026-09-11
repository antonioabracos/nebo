#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

for rf148_source in \
  compiler/semantic/sets/membership.asm \
  compiler/runtime/sets/union_intersection.asm \
  compiler/runtime/sets/difference.asm \
  compiler/semantic/sets/subset_relations.asm \
  compiler/runtime/sets/cartesian_product.asm \
  compiler/semantic/sets/empty_set.asm \
  compiler/runtime/sets/set_laws.asm; do
  rf148_name=$(basename "$rf148_source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name.o" "$rf148_source"
done

cat > "$rf148_tmp/harness.asm" <<'ASM'
bits 64
default rel
extern set_contains_i64
extern set_not_contains_i64
extern set_union_i64
extern set_intersection_i64
extern set_difference_i64
extern set_symmetric_difference_i64
extern set_is_subset_i64
extern set_is_proper_subset_i64
extern set_is_superset_i64
extern set_is_proper_superset_i64
extern set_cartesian_product_i64
extern empty_set_init
extern set_element_types_match
extern set_validate_canonical_i64
extern set_fingerprint_i64
section .data
a: dq 1,3,5
b: dq 3,4
c: dq 1,5
bad: dq 2,1
section .bss
out: resq 16
desc: resq 3
desc2: resq 3
section .text
global _start
fail:
    mov edi, 1
    mov eax, 60
    syscall
_start:
    lea rdi, [a]
    mov esi, 3
    mov edx, 3
    call set_contains_i64
    cmp eax, 1
    jne fail
    lea rdi, [a]
    mov esi, 3
    mov edx, 2
    call set_contains_i64
    test eax, eax
    jne fail
    lea rdi, [a]
    mov esi, 3
    mov edx, 2
    call set_not_contains_i64
    cmp eax, 1
    jne fail

    mov qword [out], 0x55
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 1
    call set_union_i64
    cmp rax, -1
    jne fail
    cmp qword [out], 0x55
    jne fail
    mov r9d, 8
    call_union:
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 8
    call set_union_i64
    cmp eax, 4
    jne fail
    cmp qword [out], 1
    jne fail
    cmp qword [out+24], 5
    jne fail

    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 8
    call set_intersection_i64
    cmp eax, 1
    jne fail
    cmp qword [out], 3
    jne fail
    mov qword [out], 0x66
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    xor r9d, r9d
    call set_intersection_i64
    cmp rax, -1
    jne fail
    cmp qword [out], 0x66
    jne fail

    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 8
    call set_difference_i64
    cmp eax, 2
    jne fail
    cmp qword [out+8], 5
    jne fail
    mov qword [out], 0x77
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 1
    call set_difference_i64
    cmp rax, -1
    jne fail
    cmp qword [out], 0x77
    jne fail
    call_union_sym:
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 8
    call set_symmetric_difference_i64
    cmp eax, 3
    jne fail
    cmp qword [out+8], 4
    jne fail
    mov qword [out], 0x88
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 2
    call set_symmetric_difference_i64
    cmp rax, -1
    jne fail
    cmp qword [out], 0x88
    jne fail

    lea rdi, [c]
    mov esi, 2
    lea rdx, [a]
    mov ecx, 3
    call set_is_subset_i64
    cmp eax, 1
    jne fail
    lea rdi, [c]
    mov esi, 2
    lea rdx, [a]
    mov ecx, 3
    call set_is_proper_subset_i64
    cmp eax, 1
    jne fail
    lea rdi, [a]
    mov esi, 3
    lea rdx, [c]
    mov ecx, 2
    call set_is_subset_i64
    test eax, eax
    jne fail
    lea rdi, [a]
    mov esi, 3
    lea rdx, [c]
    mov ecx, 2
    call set_is_superset_i64
    cmp eax, 1
    jne fail
    lea rdi, [a]
    mov esi, 3
    lea rdx, [c]
    mov ecx, 2
    call set_is_proper_superset_i64
    cmp eax, 1
    jne fail
    lea rdi, [a]
    mov esi, 3
    lea rdx, [a]
    mov ecx, 3
    call set_is_proper_superset_i64
    test eax, eax
    jne fail

    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 6
    call set_cartesian_product_i64
    cmp eax, 6
    jne fail
    cmp qword [out], 1
    jne fail
    cmp qword [out+8], 3
    jne fail
    cmp qword [out+80], 5
    jne fail
    cmp qword [out+88], 4
    jne fail
    mov qword [out], 0x99
    lea rdi, [a]
    mov esi, 3
    lea rdx, [b]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 5
    call set_cartesian_product_i64
    cmp rax, -1
    jne fail
    cmp qword [out], 0x99
    jne fail

    lea rdi, [desc]
    mov esi, 7
    call empty_set_init
    test eax, eax
    jne fail
    cmp qword [desc], 7
    jne fail
    cmp qword [desc+16], 0
    jne fail
    lea rdi, [desc2]
    mov esi, 7
    call empty_set_init
    test eax, eax
    jne fail
    lea rdi, [desc]
    lea rsi, [desc2]
    call set_element_types_match
    cmp eax, 1
    jne fail
    mov qword [desc2], 8
    lea rdi, [desc]
    lea rsi, [desc2]
    call set_element_types_match
    test eax, eax
    jne fail
    mov qword [desc2], 0xaa
    lea rdi, [desc2]
    xor esi, esi
    call empty_set_init
    cmp rax, -2
    jne fail
    cmp qword [desc2], 0xaa
    jne fail

    lea rdi, [a]
    mov esi, 3
    call set_validate_canonical_i64
    cmp eax, 1
    jne fail
    lea rdi, [bad]
    mov esi, 2
    call set_validate_canonical_i64
    test eax, eax
    jne fail
    lea rdi, [a]
    mov esi, 3
    call set_fingerprint_i64
    mov r12, rax
    lea rdi, [a]
    mov esi, 3
    call set_fingerprint_i64
    cmp rax, r12
    jne fail

    xor edi, edi
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM

nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
ld -o "$rf148_tmp/set-conformance" "$rf148_tmp"/*.o
"$rf148_tmp/set-conformance"
test -z "$(readelf -dW "$rf148_tmp/set-conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/set-conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'

printf '%s\n' 'RF148_G133_SET_OPERATOR_CONFORMANCE=PASS'
printf '%s\n' 'POSITIVE_NEGATIVE_RELATIONS=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'CARDINALITY_BOUNDS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
