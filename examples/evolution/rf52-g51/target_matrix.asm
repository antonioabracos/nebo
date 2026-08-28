bits 64
default rel
global _start
extern neboc_cli_target_matrix,neboc_host_process_exit
section .bss align=16
out: resq 6
section .text
_start:
 sub rsp,8
 lea rdi,[rel out]
 call neboc_cli_target_matrix
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
