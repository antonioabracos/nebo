bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=uncertainty A, rsi=uncertainty B. Conservative additive propagation.
global nebo_uncertainty_add_checked
nebo_uncertainty_add_checked:
    test rdi, rdi
    js .domain
    test rsi, rsi
    js .domain
    mov rax, rdi
    add rax, rsi
    jo .overflow
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=value A, rsi=unc A, rdx=value B, rcx=unc B.
; Bound = |A|*uB + |B|*uA + uA*uB. rax=bound, edx=status.
global nebo_uncertainty_product_bound
nebo_uncertainty_product_bound:
    test rsi, rsi
    js .domain
    test rcx, rcx
    js .domain
    mov r8, rdx
    mov r9, rcx
    mov r10, rdi
    test r10, r10
    jns .abs_b
    neg r10
    jo .overflow
.abs_b:
    mov r11, r8
    test r11, r11
    jns .terms
    neg r11
    jo .overflow
.terms:
    imul r10, r9
    jo .overflow
    imul r11, rsi
    jo .overflow
    imul rsi, r9
    jo .overflow
    mov rax, r10
    add rax, r11
    jo .overflow
    add rax, rsi
    jo .overflow
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
