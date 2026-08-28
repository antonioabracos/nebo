bits 64
default rel
%include "compiler/linker/link_layout.inc"
global _start
extern neboc_link_layout_new,neboc_cli_link_report,neboc_host_process_exit
section .bss align=16
context: resb NEBOC_LINK_SIZE
report: resb NEBOC_LINK_REPORT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 mov esi,1
 mov edx,1
 mov ecx,4096
 mov r8d,NEBOC_LINK_REQUIRED_SECURITY
 call neboc_link_layout_new
 test eax,eax
 jne .done
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_link_report
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
