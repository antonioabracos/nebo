bits 64
default rel
%include "runtime/protocol/transport.inc"
extern nebo_in_memory_transport_pair
section .bss
a resb NEBO_TRANSPORT_SIZE
b resb NEBO_TRANSPORT_SIZE
qa resq 4
qb resq 4
section .text
global _start
_start:
    lea rdi,[a]
    lea rsi,[b]
    lea rdx,[qa]
    lea rcx,[qb]
    mov r8d,4
    mov r9d,4096
    call nebo_in_memory_transport_pair
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
