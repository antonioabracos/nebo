; Nebo Assembly — Linux x86-64 process entry for the public neboc CLI
bits 64
default rel

global _start
extern neboc_cli_main
extern neboc_host_process_exit

section .text
_start:
    mov rdi,[rsp]
    lea rsi,[rsp+8]
    call neboc_cli_main
    mov edi,eax
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
