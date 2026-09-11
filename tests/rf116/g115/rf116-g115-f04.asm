bits 64
default rel
global _start
extern nebo_g115_source_probe
section .text
_start:
    mov edi,4
    mov esi,3504
    call nebo_g115_source_probe
    cmp eax,3504
    jne .fail
    mov eax,60
    xor edi,edi
    syscall
.fail:
    mov eax,60
    mov edi,1
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
