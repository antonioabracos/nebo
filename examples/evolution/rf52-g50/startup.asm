bits 64
default rel
%include "runtime/startup.inc"
global _start
extern neboc_startup_graph_build,neboc_cli_startup_report,neboc_host_process_exit
section .data
component: dq 1,NEBOC_STARTUP_FLAG_EAGER,0,0,0,0,0,64
context: dq component,1,0,0,0,0,0,0,0,0,0,0,0
section .bss align=16
report: resq 5
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 call neboc_startup_graph_build
 test eax,eax
 jne .done
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_startup_report
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
