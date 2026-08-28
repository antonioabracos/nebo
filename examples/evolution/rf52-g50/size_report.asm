bits 64
default rel
%include "compiler/linker/size_report.inc"
global _start
extern neboc_size_report_from_artifact,neboc_cli_size_report,neboc_host_process_exit
section .data
entry: dq 1,1,1,1,1,64,4096,4096
section .bss align=16
context: resb NEBOC_SIZE_CTX_SIZE
out: resq 3
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 lea rsi,[rel entry]
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 call neboc_size_report_from_artifact
 test eax,eax
 jne .done
 lea rdi,[rel context]
 lea rsi,[rel out]
 call neboc_cli_size_report
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
