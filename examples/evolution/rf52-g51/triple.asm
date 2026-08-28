bits 64
default rel
%include "compiler/target/triple.inc"
global _start
extern neboc_cli_triple_normalize,neboc_host_process_exit
section .bss align=16
triple: resb NEBOC_TRIPLE_SIZE
token: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel triple]
 mov esi,1
 lea rdx,[rel token]
 call neboc_cli_triple_normalize
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
