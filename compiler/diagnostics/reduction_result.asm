bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_DIAG_BASE 148132000
%define NEBO_REDUCTION_SUM       1
%define NEBO_REDUCTION_PRODUCT   2

section .text

; edi=operation, esi=primitive status, rdx=failing index, rcx=count.
; rax=stable diagnostic code (zero for success), rdx=index, ecx=field count,
; r8d=explainability status. Facts are renderer-neutral and deterministically ordered.
global nebo_reduction_result_explain
nebo_reduction_result_explain:
    cmp edi, NEBO_REDUCTION_SUM
    je .operation_ok
    cmp edi, NEBO_REDUCTION_PRODUCT
    jne .invalid
.operation_ok:
    cmp rdx, rcx
    ja .invalid
    test esi, esi
    jz .success
    cmp esi, NEBO_QUANTITY_ERR_DOMAIN
    je .failure
    cmp esi, NEBO_QUANTITY_ERR_OVERFLOW
    jne .invalid
.failure:
    mov eax, NEBO_REDUCTION_DIAG_BASE
    add eax, esi
    mov ecx, 5                    ; operation, status, index, count, order
    xor r8d, r8d
    ret
.success:
    xor eax, eax
    xor edx, edx
    mov ecx, 4                    ; operation, status, count, order
    xor r8d, r8d
    ret
.invalid:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov r8d, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
