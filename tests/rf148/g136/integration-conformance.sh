#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
cleanup() {
  find "$rf148_tmp" -depth -mindepth 1 -delete
  rmdir "$rf148_tmp"
}
trap cleanup EXIT

for rf148_source in \
  compiler/parser/expression/integral_binder.asm \
  compiler/runtime/calculus/single_integral.asm \
  compiler/runtime/calculus/multidimensional_integral.asm \
  compiler/runtime/calculus/contour_integral.asm \
  compiler/runtime/calculus/adaptive_integrator.asm \
  compiler/semantic/calculus/symbolic_integral.asm \
  compiler/diagnostics/integral_result.asm; do
  rf148_name=$(basename "$rf148_source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name.o" "$rf148_source"
done

cat > "$rf148_tmp/harness.asm" <<'ASM'
bits 64
default rel
extern integral_plan
extern integrate_samples_trapezoid_i64
extern integrate_grid_i64
extern contour_integral2_i64
extern integral_adaptive_decide_i64
extern symbolic_integrate_monomial_i64
extern integral_status_name
section .data
domain: dq 0,2
config: dq 1,1,100
samples: dq 0,1,2
overflow_samples: dq 0x7fffffffffffffff,0x7fffffffffffffff
grid: dq 1,2,3,4
field: dq 1,0,0,1
deltas: dq 2,0,0,3
section .bss
plan: resq 7
result: resq 8
section .text
global _start
fail:
    mov edi, r15d
    mov eax, 60
    syscall
_start:
    mov r15d, 1
    mov edi, 1
    lea rsi, [domain]
    lea rdx, [config]
    lea rcx, [plan]
    call integral_plan
    test eax, eax
    jne fail
    cmp qword [plan+40], 100
    jne fail
    cmp qword [plan+48], 1
    jne fail

    mov r15d, 2
    lea rdi, [samples]
    mov esi, 3
    mov edx, 1
    mov ecx, 1
    lea r8, [result]
    call integrate_samples_trapezoid_i64
    test eax, eax
    jne fail
    cmp qword [result+8], 4
    jne fail
    cmp qword [result+16], 2
    jne fail
    lea rdi, [overflow_samples]
    mov esi, 2
    call integrate_samples_trapezoid_i64
    cmp eax, -13
    jne fail
    cmp qword [result+8], 0
    jne fail
    cmp qword [result+16], 0
    jne fail
    cmp qword [result+24], 0
    jne fail

    mov r15d, 3
    lea rdi, [grid]
    mov esi, 4
    mov edx, 1
    mov ecx, 1
    mov r8d, 2
    lea r9, [result]
    call integrate_grid_i64
    test eax, eax
    jne fail
    cmp qword [result+8], 10
    jne fail
    cmp qword [result+32], 2
    jne fail

    mov r15d, 4
    lea rdi, [field]
    lea rsi, [deltas]
    mov edx, 2
    mov ecx, 1
    lea r8, [result]
    call contour_integral2_i64
    test eax, eax
    jne fail
    cmp qword [result+8], 5
    jne fail
    mov r15d, 8
    mov rcx, -1
    call contour_integral2_i64
    test eax, eax
    jne fail
    cmp qword [result+8], -5
    jne fail

    mov r15d, 5
    mov edi, 10
    mov esi, 12
    mov edx, 2
    mov ecx, 8
    mov r8d, 10
    lea r9, [result]
    call integral_adaptive_decide_i64
    test eax, eax
    jne fail
    cmp qword [result+16], 2
    jne fail
    cmp qword [result+32], 1
    jne fail
    mov edx, 1
    call integral_adaptive_decide_i64
    cmp eax, -14
    jne fail
    mov ecx, 11
    mov r8d, 10
    call integral_adaptive_decide_i64
    cmp eax, -12
    jne fail
    cmp qword [result+8], 0
    jne fail
    cmp qword [result+16], 0
    jne fail
    cmp qword [result+24], 0
    jne fail
    cmp qword [result+32], 0
    jne fail

    mov r15d, 6
    mov edi, 6
    mov esi, 2
    mov edx, 5
    lea rcx, [result]
    call symbolic_integrate_monomial_i64
    test eax, eax
    jne fail
    cmp qword [result+8], 6
    jne fail
    cmp qword [result+16], 3
    jne fail
    cmp qword [result+24], 3
    jne fail
    mov esi, 6
    call symbolic_integrate_monomial_i64
    cmp eax, -15
    jne fail
    cmp qword [result+8], 0
    jne fail
    cmp qword [result+16], 0
    jne fail
    cmp qword [result+24], 0
    jne fail
    cmp qword [result+32], 0
    jne fail
    mov r15d, 7
    mov rdi, -14
    call integral_status_name
    cmp edx, 13
    jne fail
    cmp byte [rax], 'n'
    jne fail
    xor edi, edi
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM

nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
ld -o "$rf148_tmp/integration-conformance" "$rf148_tmp"/*.o
"$rf148_tmp/integration-conformance"
test -z "$(readelf -dW "$rf148_tmp/integration-conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/integration-conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
build/bin/neboc build examples/rf204/G136/RF204-G136-S08.no -o "$rf148_tmp/source-effect" --quiet
set +e
"$rf148_tmp/source-effect"
rf148_source_status=$?
set -e
test "$rf148_source_status" -eq 27
printf '%s\n' 'RF148_G136_INTEGRATION_CONFORMANCE=PASS'
printf '%s\n' 'BINDER_DOMAIN_METHOD_BUDGET=PASS'
printf '%s\n' 'SINGLE_DOUBLE_TRIPLE=PASS'
printf '%s\n' 'CONTOUR_ORIENTATION=PASS'
printf '%s\n' 'TOLERANCE_CONVERGENCE=PASS'
printf '%s\n' 'SYMBOLIC_RULE_BOUND=PASS'
printf '%s\n' 'INTEGRAL_RESULT_DIAGNOSTICS=PASS'
printf '%s\n' 'SOURCE_SYNTAX_INTEGRATED=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
