; Nebo Assembly — TIPO-PUBLICO-COLOR-CONSTRUCTORS-PARSING-E-ABI target-checked Color codegen descriptor
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_target.inc"
%include "compiler/semantic/color.inc"
%include "compiler/codegen/color.inc"
extern nebo_color_target_validate
global neboc_color_codegen
section .text
; edi=Color, rsi=target, rdx=capabilities, rcx=out Color IR.
neboc_color_codegen:
    test rcx, rcx
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    sub rsp, NEBO_COLOR_TARGET_SIZE + 8
    mov ebx, edi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov rcx, rsp
    call nebo_color_target_validate
    test eax, eax
    jnz .done
    mov eax, ebx
    mov [r14 + NEBOC_COLOR_IR_VALUE_OFFSET], rax
    mov [r14 + NEBOC_COLOR_IR_TARGET_OFFSET], r12
    mov [r14 + NEBOC_COLOR_IR_CAPABILITIES_OFFSET], r13
    mov qword [r14 + NEBOC_COLOR_IR_TYPE_ID_OFFSET], NEBOC_COLOR_TYPE_ID
    mov qword [r14 + NEBOC_COLOR_IR_STATE_OFFSET], NEBOC_COLOR_IR_READY
    xor eax, eax
.done:
    add rsp, NEBO_COLOR_TARGET_SIZE + 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
