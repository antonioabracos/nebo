bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_DIAG_BASE 148132000
%define NEBO_REDUCTION_SUM       1
%define NEBO_REDUCTION_PRODUCT   2

%define NEBO_REDUCTION_RESULT_VALUE      0
%define NEBO_REDUCTION_RESULT_STATUS     8
%define NEBO_REDUCTION_RESULT_INDEX      16
%define NEBO_REDUCTION_RESULT_COUNT      24
%define NEBO_REDUCTION_RESULT_OPERATION  32
%define NEBO_REDUCTION_RESULT_ORDER      40
%define NEBO_REDUCTION_RESULT_WORKERS    48

section .text

; rdi=caller-owned seven-qword result, rsi=value, edx=status,
; rcx=failing index, r8=count, r9=operation.  Validation precedes every store.
global nebo_reduction_result_init
nebo_reduction_result_init:
    test rdi, rdi
    jz .init_invalid
    cmp r9d, NEBO_REDUCTION_SUM
    je .init_operation
    cmp r9d, NEBO_REDUCTION_PRODUCT
    jne .init_invalid
.init_operation:
    cmp rcx, r8
    ja .init_invalid
    test edx, edx
    jz .init_store
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    je .init_store
    cmp edx, NEBO_QUANTITY_ERR_OVERFLOW
    je .init_store
    cmp edx, NEBO_QUANTITY_ERR_PRECISION
    jne .init_invalid
.init_store:
    mov [rdi + NEBO_REDUCTION_RESULT_VALUE], rsi
    mov [rdi + NEBO_REDUCTION_RESULT_STATUS], rdx
    mov [rdi + NEBO_REDUCTION_RESULT_INDEX], rcx
    mov [rdi + NEBO_REDUCTION_RESULT_COUNT], r8
    mov [rdi + NEBO_REDUCTION_RESULT_OPERATION], r9
    mov qword [rdi + NEBO_REDUCTION_RESULT_ORDER], 1
    mov qword [rdi + NEBO_REDUCTION_RESULT_WORKERS], 1
    xor eax, eax
    ret
.init_invalid:
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret

; rdi=result -> eax=true only for a valid successful result.
global nebo_reduction_result_is_ok
nebo_reduction_result_is_ok:
    xor eax, eax
    test rdi, rdi
    jz .is_ok_done
    cmp qword [rdi + NEBO_REDUCTION_RESULT_OPERATION], NEBO_REDUCTION_SUM
    je .is_ok_operation
    cmp qword [rdi + NEBO_REDUCTION_RESULT_OPERATION], NEBO_REDUCTION_PRODUCT
    jne .is_ok_done
.is_ok_operation:
    mov rdx, [rdi + NEBO_REDUCTION_RESULT_INDEX]
    cmp rdx, [rdi + NEBO_REDUCTION_RESULT_COUNT]
    ja .is_ok_done
    cmp qword [rdi + NEBO_REDUCTION_RESULT_ORDER], 1
    jne .is_ok_done
    cmp qword [rdi + NEBO_REDUCTION_RESULT_WORKERS], 1
    jb .is_ok_done
    cmp qword [rdi + NEBO_REDUCTION_RESULT_WORKERS], 64
    ja .is_ok_done
    cmp qword [rdi + NEBO_REDUCTION_RESULT_STATUS], 0
    sete al
.is_ok_done:
    ret

; rdi=result, rsi=fallback -> rax=value for success or fallback for failure.
global nebo_reduction_result_value_or
nebo_reduction_result_value_or:
    mov rax, rsi
    test rdi, rdi
    jz .value_or_done
    call nebo_reduction_result_is_ok
    test eax, eax
    jz .value_or_fallback
    mov rax, [rdi + NEBO_REDUCTION_RESULT_VALUE]
    ret
.value_or_fallback:
    mov rax, rsi
.value_or_done:
    ret

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
    je .failure
    cmp esi, NEBO_QUANTITY_ERR_PRECISION
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
