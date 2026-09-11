#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
cat > "$rf148_tmp/h.asm" <<'ASM'
default rel
extern nebo_graph_arrow_plan, nebo_graph_arrow_registry_lookup
extern nebo_directed_edge_construct, nebo_async_edge_construct
extern nebo_state_transition_construct, nebo_endpoint_contract_validate
extern nebo_graph_policy_validate, nebo_graph_provenance_hash
global _start
section .bss
edge_out resq 6
section .data
endpoint_desc dq 1,2,3,1
edges dq 1,2,8,1, 2,3,4,0
self_cycle dq 1,1,1,0
section .text
_start:
 mov edi,3
 mov esi,3
 call nebo_graph_arrow_plan
 test eax,eax
 jnz fail
 mov r12,0x0000000100000046
 mov r13d,182
 xor r14d,r14d
.registry_loop:
 mov esi,1
 cmp r14d,2
 jb .registry_profile_ready
 mov esi,r14d
.registry_profile_ready:
 mov rdi,r12
 call nebo_graph_arrow_registry_lookup
 test rax,rax
 jz fail
 cmp edx,r13d
 jne fail
 inc r12
 inc r13d
 inc r14d
 cmp r14d,4
 jb .registry_loop
 mov rdi,1
 mov rsi,2
 mov rdx,7
 mov rcx,7
 mov r8,edge_out
 xor r9d,r9d
 call nebo_directed_edge_construct
 test eax,eax
 jnz fail
 mov rdi,1
 mov rsi,2
 mov rdx,7
 mov rcx,8
 mov r8,1
 mov r9,edge_out
 call nebo_async_edge_construct
 test eax,eax
 jnz fail
 mov rdi,1
 mov rsi,2
 mov rdx,1
 mov rcx,1
 mov r8,1
 mov r9,edge_out
 call nebo_state_transition_construct
 test eax,eax
 jnz fail
 mov rdi,endpoint_desc
 call nebo_endpoint_contract_validate
 test eax,eax
 jnz fail
 mov rdi,edges
 mov rsi,2
 xor edx,edx
 call nebo_graph_policy_validate
 test eax,eax
 jnz fail
 mov rdi,edges
 mov rsi,2
 mov rdx,1
 call nebo_graph_provenance_hash
 test rdx,rdx
 jnz fail
 test rax,rax
 jz fail
 mov r15,rax
 mov rdi,edges
 mov rsi,2
 mov rdx,1
 call nebo_graph_provenance_hash
 test rdx,rdx
 jnz fail
 cmp rax,r15
 jne fail
 mov edi,0
 xor esi,esi
 call nebo_graph_arrow_plan
 cmp eax,1
 jne fail
 mov rdi,self_cycle
 mov rsi,1
 xor edx,edx
 call nebo_graph_policy_validate
 cmp eax,4
 jne fail
 mov rdi,1
 mov rsi,2
 mov rdx,7
 mov rcx,8
 mov r8,edge_out
 xor r9d,r9d
 call nebo_directed_edge_construct
 cmp eax,2
 jne fail
 cmp qword [edge_out],1
 jne fail
 cmp qword [edge_out+8],2
 jne fail
 cmp qword [edge_out+16],1
 jne fail
 cmp qword [edge_out+24],1
 jne fail
 cmp qword [edge_out+32],3
 jne fail
 mov rdi,1
 mov rsi,2
 mov rdx,7
 xor ecx,ecx
 mov r8,1
 mov r9,edge_out
 call nebo_async_edge_construct
 cmp eax,2
 jne fail
 cmp qword [edge_out+32],3
 jne fail
 mov rdi,1
 mov rsi,2
 mov rdx,1
 mov rcx,8
 mov r8,3
 mov r9,edge_out
 call nebo_state_transition_construct
 cmp eax,2
 jne fail
 cmp qword [edge_out+32],3
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
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a1.o" compiler/parser/expression/graph_arrow_plan.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a2.o" compiler/semantic/graph/directed_edges.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a3.o" compiler/semantic/graph/async_edge.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a4.o" compiler/semantic/graph/state_transition.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a5.o" compiler/semantic/graph/endpoint_contract.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a6.o" compiler/runtime/graph/causality_policy.asm
nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a7.o" compiler/format/graph_provenance.asm
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/h.o" "$rf148_tmp/h.asm"
ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$rf148_tmp/h" "$rf148_tmp/h.o" "$rf148_tmp"/a*.o
"$rf148_tmp/h"
timeout 30 build/bin/neboc check examples/rf204/G140/RF204-G140-S08.no --message-format json-lines --color never >"$rf148_tmp/source.check"
test ! -s "$rf148_tmp/source.check"
timeout 30 build/bin/neboc build examples/rf204/G140/RF204-G140-S08.no -o "$rf148_tmp/source.elf" --quiet
set +e
"$rf148_tmp/source.elf"
source_exit=$?
set -e
test "$source_exit" -eq 120
printf '%s\n' RF148_G140_CONFORMANCE=PASS REGISTRY_ROWS=PASS ARROW_CONTEXT_ISOLATION=PASS FAILURE_ATOMICITY=PASS PROVENANCE_REPLAY=PASS SOURCE_SYNTAX_INTEGRATED=PASS
