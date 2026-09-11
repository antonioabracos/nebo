#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d "$rf148_root/build/rf148-g138.XXXXXX")
cleanup() {
  find "$rf148_tmp" -depth -mindepth 1 -delete
  rmdir "$rf148_tmp"
}
trap cleanup EXIT INT TERM HUP
cat > "$rf148_tmp/h.asm" <<'ASM'
default rel
extern nebo_probability_operator_plan, nebo_distributed_as_validate, nebo_independence_relation
extern nebo_conditional_probability_i64, nebo_random_variable_validate
extern nebo_reproducible_sample_u64, nebo_probability_status_code
global _start
section .data
rv_desc dq 1,1,-10,10,1,1
sample_state dq 88172645463325252
section .text
_start:
 mov edi,2
 mov esi,1
 call nebo_probability_operator_plan
 test eax,eax
 jnz fail
 mov rdi,1
 mov rsi,1
 mov rdx,2
 mov rcx,2
 call nebo_distributed_as_validate
 cmp rax,1
 jne fail
 mov rdi,1
 mov rsi,10
 mov rdx,11
 mov rcx,1
 call nebo_independence_relation
 cmp rax,1
 jne fail
 mov rdi,1
 mov rsi,4
 mov rdx,1
 mov rcx,2
 call nebo_conditional_probability_i64
 test rcx,rcx
 jnz fail
 cmp rax,1
 jne fail
 cmp rdx,2
 jne fail
 mov rdi,rv_desc
 call nebo_random_variable_validate
 test eax,eax
 jnz fail
 mov rdi,sample_state
 mov rsi,10
 call nebo_reproducible_sample_u64
 test rdx,rdx
 jnz fail
 cmp rax,10
 jae fail
 mov rdi,2
 call nebo_probability_status_code
 test rdx,rdx
 jnz fail
 cmp rax,138002
 jne fail
 mov edi,2
 xor esi,esi
 call nebo_probability_operator_plan
 cmp eax,1
 jne fail
 mov rdi,1
 mov rsi,4
 xor edx,edx
 mov rcx,2
 call nebo_conditional_probability_i64
 cmp rcx,2
 jne fail
 mov rdi,1
 mov rsi,10
 mov rdx,11
 xor ecx,ecx
 call nebo_independence_relation
 cmp rax,2
 jne fail
 cmp rdx,2
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
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a1.o" compiler/parser/expression/probability_model_plan.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a2.o" compiler/semantic/probability/distributed_as.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a3.o" compiler/semantic/probability/independence.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a4.o" compiler/runtime/probability/conditional_probability.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a5.o" compiler/semantic/probability/random_variable.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a6.o" compiler/runtime/probability/reproducible_sampling.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a7.o" compiler/diagnostics/probability_result.asm
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/h.o" "$rf148_tmp/h.asm"
ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/h" "$rf148_tmp/h.o" "$rf148_tmp"/a*.o
"$rf148_tmp/h"
if rg -n 'extern[[:space:]]+(printf|puts|malloc|free|memcpy|strlen|__libc|dlopen|dlsym|dlclose)' \
  compiler/parser/expression/probability_model_plan.asm \
  compiler/semantic/probability/distributed_as.asm \
  compiler/semantic/probability/independence.asm \
  compiler/runtime/probability/conditional_probability.asm \
  compiler/semantic/probability/random_variable.asm \
  compiler/runtime/probability/reproducible_sampling.asm \
  compiler/diagnostics/probability_result.asm \
  compiler/semantic/probability/probability_notation_source_vertical.inc; then
  exit 1
fi
build/bin/neboc build examples/rf204/G138/RF204-G138-S08.no -o "$rf148_tmp/source.elf" --quiet
set +e
"$rf148_tmp/source.elf"
source_status=$?
set -e
test "$source_status" -eq 20
file "$rf148_tmp/source.elf" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
test -z "$(nm -u "$rf148_tmp/source.elf")"
printf '%s\n' \
  RF148_G138_CONFORMANCE=PASS \
  POSITIVE_NEGATIVE=PASS \
  CONDITIONAL_CONTEXT=PASS \
  UNKNOWN_DISTINCT=PASS \
  REPRODUCIBILITY=PASS \
  SOURCE_SYNTAX_INTEGRATED=PASS \
  MAXIMAL_MUNCH=PASS \
  NO_C_NO_LIBC=PASS \
  ELF=PASS
