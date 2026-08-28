bits 64
default rel
%include "compiler/memory/compiler_memory.inc"
global _start
extern neboc_compiler_arena_new,neboc_arena_allocate,neboc_arena_stats
extern neboc_cli_compiler_memory,neboc_host_process_exit

section .data
layout: dq 64,16

section .bss align=16
arena: resb neboc_compiler_memory_ARENA_SIZE
backing: resb 256
allocation: resq 1
stats: resb NEBOC_ARENA_STATS_SIZE
arena_list: resq 1
summary: resb NEBOC_MEMORY_SUMMARY_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel arena]
 lea rsi,[rel backing]
 mov edx,256
 mov ecx,NEBOC_ARENA_POLICY_PHASE
 mov r8d,1
 call neboc_compiler_arena_new
 test eax,eax
 jne .done
 lea rdi,[rel arena]
 lea rsi,[rel layout]
 lea rdx,[rel allocation]
 call neboc_arena_allocate
 test eax,eax
 jne .done
 lea rdi,[rel arena]
 lea rsi,[rel stats]
 call neboc_arena_stats
 test eax,eax
 jne .done
 lea rax,[rel arena]
 mov [rel arena_list],rax
 lea rdi,[rel arena_list]
 mov esi,1
 lea rdx,[rel summary]
 call neboc_cli_compiler_memory
.done:
 mov edi,eax
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
