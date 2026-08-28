bits 64
default rel
%include "runtime/protocol/rpc.inc"
extern nebo_rpc_method_unary
section .bss
method resb NEBO_METHOD_SIZE
section .text
global _start
_start:
    lea rdi,[method]
    mov esi,1
    mov edx,1
    mov ecx,2
    xor r8d,r8d
    call nebo_rpc_method_unary
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
