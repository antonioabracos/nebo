bits 64
default rel
%include "compiler/bootstrap/bootstrap.inc"
global _start
extern neboc_bootstrap_stage0,neboc_cli_bootstrap_verify,neboc_host_process_exit
section .bss align=16
state: resb NEBOC_BOOT_SIZE
out: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel state]
 mov esi,1
 mov edx,2
 mov ecx,3
 call neboc_bootstrap_stage0
 lea rdi,[rel state]
 lea rsi,[rel out]
 call neboc_cli_bootstrap_verify
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
