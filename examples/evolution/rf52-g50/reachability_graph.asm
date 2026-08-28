bits 64
default rel
%include "compiler/reachability/whole_program_graph.inc"
global _start
extern neboc_whole_program_graph_build,neboc_host_process_exit
section .data
nodes: dq 1,NEBOC_WPG_NODE_FUNCTION,0,1,0,0,0
section .bss align=16
graph: resb NEBOC_WPG_SIZE
config: resb NEBOC_WPG_CONFIG_SIZE
section .text
_start:
 sub rsp,8
 lea rax,[rel nodes]
 mov [rel config],rax
 mov qword [rel config+8],1
 mov qword [rel config+32],0x8664
 mov qword [rel config+40],NEBOC_WPG_POLICY_CLOSED
 lea rdi,[rel graph]
 lea rsi,[rel config]
 call neboc_whole_program_graph_build
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
