default rel
section .text
global nebo_annotation_target_validate
; rdi=allowed target mask, rsi=target 0 declaration/1 module/2 type/
; 3 function/4 field/5 operator, rdx=out[target,bit].
nebo_annotation_target_validate:
    test rdx, rdx
    jz .invalid
    test rdi, -64
    jnz .invalid
    cmp rsi, 5
    ja .invalid
    bt rdi, rsi
    jnc .forbidden
    mov [rdx], rsi
    mov rax, 1
    mov rcx, rsi
    shl rax, cl
    mov [rdx+8], rax
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.forbidden:
    mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
