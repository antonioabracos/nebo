bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/reachability/whole_program_graph.inc"
global _start
extern neboc_whole_program_graph_build,neboc_program_graph_add_root
extern neboc_program_graph_direct_calls,neboc_program_graph_indirect_targets
extern neboc_program_graph_data_references,neboc_program_graph_runtime_dependencies
extern neboc_program_graph_capability_roots,neboc_program_graph_unreachable_symbols
extern neboc_program_graph_why_reachable,neboc_program_graph_validate_closed_world
extern neboc_program_graph_digest,neboc_cli_reachability_report
extern neboc_host_process_exit
section .data
nodes:
 dq 1,NEBOC_WPG_NODE_FUNCTION,0,0x101,0,0,0
 dq 2,NEBOC_WPG_NODE_FUNCTION,0,0x102,0,0,0
 dq 3,NEBOC_WPG_NODE_DATA,0,0x103,0,0,0
 dq 4,NEBOC_WPG_NODE_RUNTIME,0,0x104,0,0,0
 dq 5,NEBOC_WPG_NODE_CAPABILITY,1,0x105,0,0,0
 dq 6,NEBOC_WPG_NODE_FUNCTION,0,0x106,0,0,0
edges:
 dq 1,2,NEBOC_WPG_EDGE_CALL,0
 dq 2,3,NEBOC_WPG_EDGE_DATA,0
 dq 2,0,NEBOC_WPG_EDGE_INDIRECT,1
 dq 2,4,NEBOC_WPG_EDGE_INDIRECT,0
 dq 5,4,NEBOC_WPG_EDGE_RUNTIME,0
section .bss align=16
graph: resb NEBOC_WPG_SIZE
graph_open: resb NEBOC_WPG_SIZE
config: resb NEBOC_WPG_CONFIG_SIZE
ids: resq 8
count: resq 1
unknown: resq 1
why: resb NEBOC_WPG_WHY_SIZE
world: resq 1
digest1: resq 1
digest2: resq 1
report: resb NEBOC_WPG_REPORT_SIZE
section .text
load_config:
 lea rax,[rel nodes]
 mov [rel config+NEBOC_WPG_CONFIG_NODES_OFFSET],rax
 mov qword [rel config+NEBOC_WPG_CONFIG_NODE_COUNT_OFFSET],6
 lea rax,[rel edges]
 mov [rel config+NEBOC_WPG_CONFIG_EDGES_OFFSET],rax
 mov qword [rel config+NEBOC_WPG_CONFIG_EDGE_COUNT_OFFSET],5
 mov qword [rel config+NEBOC_WPG_CONFIG_TARGET_OFFSET],0x8664
 mov qword [rel config+NEBOC_WPG_CONFIG_POLICY_OFFSET],NEBOC_WPG_POLICY_CLOSED
 ret
_start:
 sub rsp,8
 call load_config
 lea rdi,[rel graph]
 lea rsi,[rel config]
 call neboc_whole_program_graph_build
 test eax,eax
 jne .fail1
 ; Entry root propagates calls, data and conservative known indirect target.
 lea rdi,[rel graph]
 mov esi,1
 mov edx,NEBOC_WPG_REASON_ENTRY
 call neboc_program_graph_add_root
 test eax,eax
 jne .fail2
 cmp qword [rel graph+NEBOC_WPG_REACHABLE_OFFSET],4
 jne .fail3
 ; Active capability is an explicit second root and retains runtime dependency.
 lea rdi,[rel graph]
 lea rsi,[rel count]
 call neboc_program_graph_capability_roots
 test eax,eax
 jne .fail4
 cmp qword [rel count],1
 jne .fail5
 cmp qword [rel graph+NEBOC_WPG_REACHABLE_OFFSET],5
 jne .fail6
 cmp qword [rel graph+NEBOC_WPG_ROOTS_OFFSET],2
 jne .fail7

 lea rdi,[rel graph]
 mov esi,1
 lea rdx,[rel ids]
 mov ecx,8
 lea r8,[rel count]
 call neboc_program_graph_direct_calls
 test eax,eax
 jne .fail8
 cmp qword [rel count],1
 jne .fail9
 cmp qword [rel ids],2
 jne .fail10
 lea rdi,[rel graph]
 mov esi,2
 lea rdx,[rel ids]
 mov ecx,8
 lea r8,[rel count]
 lea r9,[rel unknown]
 call neboc_program_graph_indirect_targets
 test eax,eax
 jne .fail11
 cmp qword [rel count],1
 jne .fail12
 cmp qword [rel ids],4
 jne .fail13
 cmp qword [rel unknown],1
 jne .fail14
 lea rdi,[rel graph]
 mov esi,2
 lea rdx,[rel ids]
 mov ecx,8
 lea r8,[rel count]
 call neboc_program_graph_data_references
 test eax,eax
 jne .fail15
 cmp qword [rel ids],3
 jne .fail16
 lea rdi,[rel graph]
 mov esi,5
 lea rdx,[rel ids]
 mov ecx,8
 lea r8,[rel count]
 call neboc_program_graph_runtime_dependencies
 test eax,eax
 jne .fail17
 cmp qword [rel ids],4
 jne .fail18

 lea rdi,[rel graph]
 lea rsi,[rel ids]
 mov edx,8
 lea rcx,[rel count]
 call neboc_program_graph_unreachable_symbols
 test eax,eax
 jne .fail19
 cmp qword [rel count],1
 jne .fail20
 cmp qword [rel ids],6
 jne .fail21
 lea rdi,[rel graph]
 mov esi,3
 lea rdx,[rel why]
 call neboc_program_graph_why_reachable
 test eax,eax
 jne .fail22
 cmp qword [rel why+NEBOC_WPG_WHY_REACHABLE_OFFSET],1
 jne .fail23
 cmp qword [rel why+NEBOC_WPG_WHY_PARENT_OFFSET],2
 jne .fail24
 lea rdi,[rel graph]
 lea rsi,[rel world]
 call neboc_program_graph_validate_closed_world
 test eax,eax
 jne .fail25
 cmp qword [rel world],NEBOC_WPG_WORLD_CONSERVATIVE
 jne .fail26
 lea rdi,[rel graph]
 lea rsi,[rel digest1]
 call neboc_program_graph_digest
 test eax,eax
 jne .fail27
 lea rdi,[rel graph]
 lea rsi,[rel digest2]
 call neboc_program_graph_digest
 test eax,eax
 jne .fail28
 mov rax,[rel digest1]
 cmp rax,[rel digest2]
 jne .fail29
 lea rdi,[rel graph]
 lea rsi,[rel report]
 call neboc_cli_reachability_report
 test eax,eax
 jne .fail30
 cmp qword [rel report+NEBOC_WPG_REPORT_ROOTS_OFFSET],2
 jne .fail31
 cmp qword [rel report+NEBOC_WPG_REPORT_UNREACHABLE_OFFSET],1
 jne .fail32
 cmp qword [rel report+NEBOC_WPG_REPORT_UNKNOWN_OFFSET],1
 jne .fail33

 ; Open-world is classified explicitly, never assumed closed.
 mov qword [rel config+NEBOC_WPG_CONFIG_POLICY_OFFSET],NEBOC_WPG_POLICY_OPEN
 lea rdi,[rel graph_open]
 lea rsi,[rel config]
 call neboc_whole_program_graph_build
 test eax,eax
 jne .fail34
 lea rdi,[rel graph_open]
 lea rsi,[rel world]
 call neboc_program_graph_validate_closed_world
 test eax,eax
 jne .fail35
 cmp qword [rel world],NEBOC_WPG_WORLD_UNSUPPORTED
 jne .fail36

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 36
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
