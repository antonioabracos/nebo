; G147-S07 factual target matrix: one tested host and two explicit skips.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION runOperatorMultiTargetConformance
    test rdi,rdi
    jz .invalid
    cmp rsi,3
    jb .limit
    mov qword [rdi+0],NEBO_OPERATOR_TARGET_X86_64
    mov qword [rdi+8],NEBO_OPERATOR_TARGET_ALL
    mov qword [rdi+16],NEBO_OPERATOR_TARGET_ALL
    mov qword [rdi+24],0
    mov qword [rdi+32],NEBO_OPERATOR_TARGET_MATURITY_HARDWARE
    mov qword [rdi+40],NEBO_OPERATOR_TARGET_I386
    mov qword [rdi+48],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    mov qword [rdi+56],0
    mov qword [rdi+64],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    mov qword [rdi+72],NEBO_OPERATOR_TARGET_MATURITY_CONTRACT
    mov qword [rdi+80],NEBO_OPERATOR_TARGET_AARCH64
    mov qword [rdi+88],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    mov qword [rdi+96],0
    mov qword [rdi+104],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    mov qword [rdi+112],NEBO_OPERATOR_TARGET_MATURITY_CONTRACT
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_target_lookup
    test rdi,rdi
    jz .invalid
    test rcx,rcx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,3
    ja .limit
.scan:
    cmp [rdi+NEBO_OPERATOR_TARGET_ID_OFFSET],rdx
    je .found
    add rdi,NEBO_OPERATOR_TARGET_SIZE
    dec rsi
    jnz .scan
    mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
    ret
.found:
    mov r8,5
.copy:
    mov rax,[rdi]
    mov [rcx],rax
    add rdi,8
    add rcx,8
    dec r8
    jnz .copy
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_target_matrix_validate
    test rdi,rdi
    jz .invalid
    cmp rsi,3
    jne .invalid
    cmp qword [rdi+0],NEBO_OPERATOR_TARGET_X86_64
    jne .source
    cmp qword [rdi+16],NEBO_OPERATOR_TARGET_ALL
    jne .source
    cmp qword [rdi+32],NEBO_OPERATOR_TARGET_MATURITY_HARDWARE
    jne .source
    cmp qword [rdi+40],NEBO_OPERATOR_TARGET_I386
    jne .source
    cmp qword [rdi+56],0
    jne .source
    cmp qword [rdi+64],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    jne .source
    cmp qword [rdi+80],NEBO_OPERATOR_TARGET_AARCH64
    jne .source
    cmp qword [rdi+96],0
    jne .source
    cmp qword [rdi+104],NEBO_OPERATOR_TARGET_COMPILE | NEBO_OPERATOR_TARGET_OBJECT
    jne .source
    xor eax,eax
    ret
.source:
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
