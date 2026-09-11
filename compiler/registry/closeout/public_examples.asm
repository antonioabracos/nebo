; G148 bounded manifest for the ten versioned public examples.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/closeout/registry_closeout.inc"

section .text

; materializeOperatorPublicExamples(hash64*, count, report*).
; The caller materializes the files; this owner validates that every subgroup
; contributes one distinct, non-zero source identity before publishing proof.
NEBOC_ABI_FUNCTION materializeOperatorPublicExamples
    test rdi,rdi
    jz .invalid_argument
    test rdx,rdx
    jz .invalid_argument
    test rdi,7
    jnz .invalid_argument
    test rdx,7
    jnz .invalid_argument
    test rsi,rsi
    jz .invalid_argument
    cmp rsi,NEBOC_CLOSEOUT_SUBGROUP_COUNT
    ja .limit
    jne .invalid_source
    xor r8d,r8d
    xor r9d,r9d
.outer:
    mov r10,[rdi+r8*8]
    test r10,r10
    jz .invalid_source
    xor r11d,r11d
.unique:
    cmp r11,r8
    jae .accepted
    cmp r10,[rdi+r11*8]
    je .invalid_source
    inc r11
    jmp .unique
.accepted:
    rol r9,9
    xor r9,r10
    mov rax,r8
    inc rax
    xor r9,rax
    inc r8
    cmp r8,NEBOC_CLOSEOUT_SUBGROUP_COUNT
    jb .outer
    mov qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_SCHEMA_OFFSET],NEBOC_CLOSEOUT_SCHEMA_VERSION
    mov qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_COUNT_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov qword [rdx+NEBOC_CLOSEOUT_EXAMPLES_UNIQUE_OFFSET],NEBOC_CLOSEOUT_SUBGROUP_COUNT
    mov [rdx+NEBOC_CLOSEOUT_EXAMPLES_DIGEST_OFFSET],r9
    mov rax,[rdi]
    mov [rdx+NEBOC_CLOSEOUT_EXAMPLES_FIRST_OFFSET],rax
    mov rax,[rdi+(NEBOC_CLOSEOUT_SUBGROUP_COUNT-1)*8]
    mov [rdx+NEBOC_CLOSEOUT_EXAMPLES_LAST_OFFSET],rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid_source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
