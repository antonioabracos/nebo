bits 64
default rel
%include "compiler/scheduler/scheduler.inc"
global _start
extern neboc_build_graph_from_modules,neboc_host_process_exit
section .data
modules: dq 1,2,4, 2,3,4
edges: dq 2,1
section .bss align=16
graph: resb NEBOC_GRAPH_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel graph]
 lea rsi,[rel modules]
 mov edx,2
 lea rcx,[rel edges]
 mov r8d,1
 call neboc_build_graph_from_modules
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
