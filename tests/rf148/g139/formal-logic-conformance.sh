#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
cat > "$rf148_tmp/h.asm" <<'ASM'
default rel
extern nebo_formal_logic_operator_plan, nebo_formal_logic_registry_lookup
extern nebo_forall_bounded, nebo_exists_bounded, nebo_not_exists_bounded
extern nebo_logic_implies, nebo_logic_iff, nebo_proof_accepts, nebo_model_satisfies
extern nebo_logic_nand, nebo_logic_nor, nebo_solver_result_code
global _start
section .data
all_true dd 1,1,1
all_false dd 0,0,0
mixed dd 1,2,1
timed dd 1,3,1
false_timed dd 0,3,1
section .text
_start:
 mov edi,8
 mov esi,1
 call nebo_formal_logic_operator_plan
 test eax,eax
 jnz fail
 mov r12,0x000000010000003d
 mov r13d,173
.registry_loop:
 mov rdi,r12
 mov esi,1
 call nebo_formal_logic_registry_lookup
 test rax,rax
 jz fail
 cmp edx,r13d
 jne fail
 inc r12
 inc r13d
 cmp r13d,182
 jb .registry_loop
 mov rdi,0x000000010000003d
 xor esi,esi
 call nebo_formal_logic_registry_lookup
 test rax,rax
 jnz fail
 mov rdi,all_true
 mov rsi,3
 mov rdx,3
 call nebo_forall_bounded
 cmp eax,1
 jne fail
 mov rdi,mixed
 mov rsi,3
 mov rdx,3
 call nebo_forall_bounded
 cmp eax,2
 jne fail
 mov rdi,timed
 mov rsi,3
 mov rdx,3
 call nebo_forall_bounded
 cmp eax,3
 jne fail
 mov rdi,false_timed
 mov rsi,3
 mov rdx,3
 call nebo_forall_bounded
 test eax,eax
 jnz fail
 mov rdi,all_true
 mov rsi,3
 mov rdx,3
 call nebo_exists_bounded
 cmp eax,1
 jne fail
 mov rdi,all_false
 mov rsi,3
 mov rdx,3
 call nebo_not_exists_bounded
 cmp eax,1
 jne fail
 mov edi,1
 xor esi,esi
 call nebo_logic_implies
 test eax,eax
 jnz fail
 mov edi,1
 mov esi,1
 call nebo_logic_iff
 cmp eax,1
 jne fail
 mov edi,4
 mov esi,100
 call nebo_proof_accepts
 test eax,eax
 jnz fail
 cmp edx,4
 jne fail
 mov edi,2
 mov esi,100
 call nebo_model_satisfies
 cmp eax,1
 jne fail
 mov edi,1
 mov esi,1
 call nebo_logic_nand
 test eax,eax
 jnz fail
 xor edi,edi
 xor esi,esi
 call nebo_logic_nor
 cmp eax,1
 jne fail
 mov edi,4
 mov esi,100
 call nebo_solver_result_code
 test edx,edx
 jnz fail
 cmp ecx,4
 jne fail
 mov edi,5
 mov esi,100
 call nebo_solver_result_code
 test edx,edx
 jnz fail
 cmp ecx,5
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
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a1.o" compiler/parser/expression/formal_logic_plan.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a2.o" compiler/runtime/logic/universal_quantifier.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a3.o" compiler/runtime/logic/existential_quantifier.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a4.o" compiler/semantic/logic/implication_equivalence.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a5.o" compiler/runtime/logic/proof_satisfaction.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a6.o" compiler/semantic/logic/nand_nor.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a7.o" compiler/diagnostics/solver_result.asm
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/h.o" "$rf148_tmp/h.asm"
ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/h" "$rf148_tmp/h.o" "$rf148_tmp"/a*.o
"$rf148_tmp/h"
timeout 30 build/bin/neboc check examples/rf204/G139/RF204-G139-S08.no --message-format json-lines --color never >"$rf148_tmp/source.check"
test ! -s "$rf148_tmp/source.check"
timeout 30 build/bin/neboc build examples/rf204/G139/RF204-G139-S08.no -o "$rf148_tmp/source.elf" --quiet
set +e
"$rf148_tmp/source.elf"
source_exit=$?
set -e
test "$source_exit" -eq 25
printf '%s\n' RF148_G139_CONFORMANCE=PASS REGISTRY_ROWS=PASS UNKNOWN_TIMEOUT_DISTINCT=PASS UNKNOWN_IS_NOT_PROOF=PASS BUDGETS=PASS STRICT_NAND_NOR=PASS SOURCE_SYNTAX_INTEGRATED=PASS
