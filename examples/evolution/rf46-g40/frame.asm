bits 64
default rel
%include "runtime/protocol/frame.inc"
extern nebo_frame_wrap
extern nebo_frame_checksum
section .data
payload db 'nebo'
section .bss
frame resb 64
section .text
global _start
_start:
    lea rdi,[payload]
    mov esi,4
    lea rdx,[frame]
    mov ecx,64
    xor r8d,r8d
    call nebo_frame_wrap
    test eax,eax
    jnz fail
    lea rdi,[frame]
    mov esi,NEBO_FRAME_HEADER+4
    call nebo_frame_checksum
    mov edi,eax
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
