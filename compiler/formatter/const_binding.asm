; Nebo Assembly — RF116 ConstBinding semantics-preserving formatter
bits 64
default rel
%include "compiler/semantic/name_style.inc"
%include "compiler/semantic/const_binding.inc"
%include "compiler/formatter/const_binding.inc"
extern neboc_name_style_classify
global neboc_format_const_name
section .text
; rdi=name, rsi=len, rdx=out, rcx=capacity. Exact spelling is preserved.
neboc_format_const_name:
    test rdx, rdx
    jz .invalid
    cmp rcx, rsi
    jb .capacity
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    call neboc_name_style_classify
    cmp eax, NEBOC_NAME_ALL_CAPS
    jne .not_caps
    xor r14d, r14d
.copy:
    cmp r14, r12
    jae .ok
    mov al, [rbx + r14]
    mov [r13 + r14], al
    inc r14
    jmp .copy
.ok:
    xor eax, eax
    jmp .done
.not_caps:
    mov eax, NEBOC_CONST_NAME_NOT_ALL_CAPS
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.capacity:
    mov eax, NEBOC_CONST_FORMAT_CAPACITY
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
