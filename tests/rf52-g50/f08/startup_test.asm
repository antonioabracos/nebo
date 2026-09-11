bits 64
default rel
%include "runtime/startup.inc"
global _start
extern neboc_startup_graph_build,neboc_startup_graph_eager_components
extern neboc_startup_graph_lazy_components,neboc_startup_graph_defer
extern neboc_startup_graph_measure,neboc_runtime_init_once,neboc_runtime_init_failure
extern neboc_runtime_exit_cleanup_graph,neboc_footprint_rss_report
extern neboc_footprint_compare,neboc_cli_startup_report,neboc_host_process_exit
section .data
components:
 dq 1,NEBOC_STARTUP_FLAG_EAGER,0,0,0,0,0,64
 dq 2,NEBOC_STARTUP_FLAG_EAGER,0,0,0,0,0,64
 dq 3,NEBOC_STARTUP_FLAG_LAZY,0,0,0,0,0,128
deps: dq 2,1,3,2
bad_dep: dq 1,2
section .data
context: dq components,3,deps,2,0,0,0,0,0,0,0,0,0
section .bss align=16
report: resq 5
other: resq 5
value: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 call neboc_startup_graph_build
 test eax,eax
 jne .fail1
 lea rdi,[rel context]
 lea rsi,[rel value]
 call neboc_startup_graph_eager_components
 cmp qword [rel value],2
 jne .fail2
 lea rdi,[rel context]
 lea rsi,[rel value]
 call neboc_startup_graph_lazy_components
 cmp qword [rel value],1
 jne .fail3
 lea rdi,[rel context]
 mov esi,2
 mov edx,NEBOC_STARTUP_FLAG_GUARD_PROVED
 call neboc_startup_graph_defer
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 mov esi,5
 mov edx,0xabc
 call neboc_startup_graph_measure
 test eax,eax
 jne .fail5
 lea rdi,[rel context]
 mov esi,1
 call neboc_runtime_init_once
 test eax,eax
 jne .fail6
 lea rdi,[rel context]
 mov esi,1
 call neboc_runtime_init_once
 test eax,eax
 jne .fail7
 cmp qword [rel components+NEBOC_STARTUP_COMP_INIT_COUNT_OFFSET],1
 jne .fail8
 lea rdi,[rel context]
 mov esi,3
 call neboc_runtime_init_once
 test eax,eax
 jne .fail9
 lea rdi,[rel context]
 mov esi,3
 mov edx,77
 call neboc_runtime_init_failure
 test eax,eax
 jne .fail10
 cmp qword [rel components+NEBOC_STARTUP_COMP_SIZE*2+NEBOC_STARTUP_COMP_STATE_OFFSET],NEBOC_STARTUP_STATE_FAILED
 jne .fail11
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_footprint_rss_report
 test eax,eax
 jne .fail12
 lea rdi,[rel context]
 lea rsi,[rel other]
 call neboc_cli_startup_report
 test eax,eax
 jne .fail13
 lea rdi,[rel report]
 lea rsi,[rel other]
 xor edx,edx
 lea rcx,[rel value]
 call neboc_footprint_compare
 test eax,eax
 jne .fail14
 cmp qword [rel value],0
 jne .fail15
 lea rdi,[rel context]
 call neboc_runtime_exit_cleanup_graph
 test eax,eax
 jne .fail16
 cmp qword [rel context+NEBOC_STARTUP_CTX_INITIALIZED_OFFSET],0
 jne .fail17
 ; Invalid topological edge is a deterministic cycle candidate failure.
 lea rax,[rel bad_dep]
 mov [rel context+NEBOC_STARTUP_CTX_DEPS_OFFSET],rax
 mov qword [rel context+NEBOC_STARTUP_CTX_DEP_COUNT_OFFSET],1
 lea rdi,[rel context]
 call neboc_startup_graph_build
 test eax,eax
 jz .fail18
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 18
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
