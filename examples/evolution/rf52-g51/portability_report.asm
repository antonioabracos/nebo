bits 64
default rel
%include "compiler/target/portability.inc"
global _start
extern neboc_cli_portability_check,neboc_cli_portability_report,neboc_host_process_exit
section .data
capsets: dq 0x1f,0x0f
section .bss align=16
report: resb NEBOC_PORT_REPORT_SIZE
out: resq 4
section .text
_start:
 sub rsp,8
 lea rdi,[rel report]
 lea rsi,[rel capsets]
 mov edx,2
 mov ecx,0x0f
 call neboc_cli_portability_check
 test eax,eax
 jne .done
 lea rdi,[rel report]
 lea rsi,[rel out]
 call neboc_cli_portability_report
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
