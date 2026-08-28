bits 64
default rel
%include "compiler/platform/platform_backend.inc"
global _start
extern neboc_platform_backend_for_target,neboc_cli_platform_report,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x1f,3
section .bss align=16
backend: resb NEBOC_PLATFORM_SIZE
out: resq 6
section .text
_start:
 sub rsp,8
 lea rdi,[rel backend]
 lea rsi,[rel target]
 mov edx,0x1f
 call neboc_platform_backend_for_target
 test eax,eax
 jne .done
 lea rsi,[rel out]
 call neboc_cli_platform_report
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
