bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=signed millidegrees. rax=canonical [0,360000), edx=status.
global nebo_angle_normalize
nebo_angle_normalize:
    mov rax, rdi
    cqo
    mov ecx, 360000
    idiv rcx
    mov rax, rdx
    test rax, rax
    jns .normalized
    add rax, rcx
.normalized:
    xor edx, edx
    ret

; Checked addition keeps the Angle unit and reports overflow atomically.
; rax=result, edx=status.
global nebo_angle_add_checked
nebo_angle_add_checked:
    mov rax, rdi
    add rax, rsi
    jo .overflow
    xor edx, edx
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; edi=Unicode scalar, esi=context. U+00B0 is gated Angle suffix syntax.
global nebo_angle_suffix_classify
nebo_angle_suffix_classify:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_SYNTAX
    cmp edi, 0x00b0
    jne .done
    mov ecx, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    and esi, ecx
    cmp esi, ecx
    jne .done
    mov eax, NEBO_UNIT_MILLIDEGREE
    xor edx, edx
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
