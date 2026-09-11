#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d "$rf148_root/build/rf148-g137.XXXXXX")
cleanup() {
  find "$rf148_tmp" -depth -mindepth 1 -delete
  rmdir "$rf148_tmp"
}
trap cleanup EXIT INT TERM HUP
cat > "$rf148_tmp/h.asm" <<'ASM'
default rel
extern nebo_differential_operator_plan, nebo_partial_central_i64, nebo_gradient_central_i64
extern nebo_divergence_i64, nebo_curl3_i64, nebo_laplacian_central_i64
extern nebo_differentiation_bridge_plan, nebo_field_contract_validate
global _start
section .data
plus dq 6,10
minus dq 2,2
calc_out dq 0,0,0
diag dq 1,2,3
jac dq 0,1,2,3,4,5,6,7,8
lap_plus dq 7,9
lap_minus dq 3,5
field dq 3,1,2,1,100
section .text
_start:
 mov edi,4
 mov esi,1
 call nebo_differential_operator_plan
 test eax,eax
 jnz fail
 mov rdi,14
 mov rsi,2
 mov rdx,2
 call nebo_partial_central_i64
 cmp rax,3
 jne fail
 test rdx,rdx
 jnz fail
 mov rdi,plus
 mov rsi,minus
 mov rdx,2
 mov rcx,2
 mov r8,calc_out
 mov r9,2
 call nebo_gradient_central_i64
 test eax,eax
 jnz fail
 cmp qword [calc_out],1
 jne fail
 cmp qword [calc_out+8],2
 jne fail
 mov rdi,diag
 mov rsi,3
 call nebo_divergence_i64
 cmp rax,6
 jne fail
 mov rdi,jac
 mov rsi,calc_out
 call nebo_curl3_i64
 test eax,eax
 jnz fail
 cmp qword [calc_out],2
 jne fail
 cmp qword [calc_out+8],-4
 jne fail
 cmp qword [calc_out+16],2
 jne fail
 ; An invalid gradient request cannot publish a partial caller-owned result.
 xor edi,edi
 mov rsi,minus
 mov rdx,2
 mov rcx,2
 mov r8,calc_out
 mov r9,2
 call nebo_gradient_central_i64
 cmp eax,1
 jne fail
 cmp qword [calc_out],2
 jne fail
 cmp qword [calc_out+8],-4
 jne fail
 cmp qword [calc_out+16],2
 jne fail
 mov rdi,lap_plus
 mov rsi,lap_minus
 mov rdx,4
 mov rcx,2
 mov r8,2
 call nebo_laplacian_central_i64
 cmp rax,4
 jne fail
 mov rdi,2
 mov rsi,100
 call nebo_differentiation_bridge_plan
 test rdx,rdx
 jnz fail
 mov rdi,field
 call nebo_field_contract_validate
 test eax,eax
 jnz fail
 mov rdi,1
 mov rsi,0
 mov rdx,0
 call nebo_partial_central_i64
 cmp rdx,1
 jne fail
 xor edi,edi
 xor esi,esi
 call nebo_differential_operator_plan
 cmp eax,1
 jne fail
 mov eax,60
 xor edi,edi
 syscall
fail:
 mov eax,60
 mov edi,1
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a1.o" compiler/parser/expression/differential_operator_plan.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a2.o" compiler/runtime/calculus/partial_derivative.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a3.o" compiler/runtime/calculus/gradient.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a4.o" compiler/runtime/calculus/divergence_curl.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a5.o" compiler/runtime/calculus/laplacian.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a6.o" compiler/semantic/calculus/differentiation_bridge.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a7.o" compiler/semantic/calculus/field_contract.asm
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/h.o" "$rf148_tmp/h.asm"
ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/h" "$rf148_tmp/h.o" "$rf148_tmp"/a*.o
"$rf148_tmp/h"
if rg -n 'extern[[:space:]]+(printf|puts|malloc|free|memcpy|strlen|__libc|dlopen|dlsym|dlclose)' \
  compiler/parser/expression/differential_operator_plan.asm \
  compiler/runtime/calculus/partial_derivative.asm \
  compiler/runtime/calculus/gradient.asm \
  compiler/runtime/calculus/divergence_curl.asm \
  compiler/runtime/calculus/laplacian.asm \
  compiler/semantic/calculus/differentiation_bridge.asm \
  compiler/semantic/calculus/field_contract.asm; then
  exit 1
fi
build/bin/neboc build examples/rf204/G137/RF204-G137-S08.no -o "$rf148_tmp/source.elf" --quiet
set +e
"$rf148_tmp/source.elf"
source_status=$?
set -e
test "$source_status" -eq 36
file "$rf148_tmp/source.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u "$rf148_tmp/source.elf")"
printf '%s\n' \
  RF148_G137_CONFORMANCE=PASS \
  POSITIVE_NEGATIVE=PASS \
  REFERENCE_METAMORPHIC=PASS \
  FAILURE_ATOMICITY=PASS \
  SOURCE_SYNTAX_INTEGRATED=PASS \
  MAXIMAL_MUNCH=PASS \
  NO_C_NO_LIBC=PASS \
  ELF=PASS
