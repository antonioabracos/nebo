bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT   1048576
%define NEBO_REDUCTION_MAX_WORKERS 64
%define NEBO_PARALLEL_OPT_IN       1

section .text

; rdi=count, esi=requested workers, edx=explicit capability.
; eax=effective workers, edx=canonical merge levels, ecx=status.
global nebo_deterministic_parallel_plan
nebo_deterministic_parallel_plan:
    cmp edx, NEBO_PARALLEL_OPT_IN
    jne .domain
    cmp rdi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test esi, esi
    jz .domain
    cmp esi, NEBO_REDUCTION_MAX_WORKERS
    ja .domain
    mov eax, esi
    test rdi, rdi
    jz .empty
    cmp rax, rdi
    jbe .levels
    mov eax, edi
.levels:
    lea r8d, [eax - 1]
    xor r9d, r9d
.level_loop:
    test r8d, r8d
    jz .ok
    shr r8d, 1
    inc r9d
    jmp .level_loop
.empty:
    mov eax, 1
    xor r9d, r9d
.ok:
    mov edx, r9d
    xor ecx, ecx
    ret
.domain:
    xor eax, eax
    xor edx, edx
    mov ecx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
