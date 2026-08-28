bits 64
default rel
%include "runtime/scientific/reproducibility.inc"
extern nebo_scientific_context_digest
section .rodata
context db "RF46-SCICTX-v1;dtype=f64;round=nearest;threads=1;deterministic=1"
context_len equ $-context
section .bss
digest resq 1
section .text
global _start
_start:
    lea rdi,[context]
    mov esi,context_len
    lea rdx,[digest]
    call nebo_scientific_context_digest
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
