; TREE-GRAPH-NODE-E-EDGE-F01 bounded numeric contract validator
bits 64
default rel
%define NEBO_NUMERIC_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/numeric/numeric_contract.inc"

section .text
global nebo_numeric_contract_init
global nebo_numeric_contract_validate

; rdi = aligned 64-byte descriptor
nebo_numeric_contract_init:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_NUMERIC_MAGIC
    mov [rdi+NEBO_NUMERIC_CONTRACT_MAGIC],rax
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_VERSION],NEBO_NUMERIC_VERSION
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_FLAGS],NEBO_NUMERIC_REQUIRED_FLAGS
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_VECTOR],NEBO_NUMERIC_MAX_VECTOR
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_ELEMENTS],NEBO_NUMERIC_MAX_ELEMENTS
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_RANK],NEBO_NUMERIC_MAX_RANK
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_WORKERS],NEBO_NUMERIC_MAX_WORKERS
    mov qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_WORKSPACE],NEBO_NUMERIC_MAX_WORKSPACE
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
    ret

nebo_numeric_contract_validate:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_NUMERIC_MAGIC
    cmp [rdi+NEBO_NUMERIC_CONTRACT_MAGIC],rax
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_VERSION],NEBO_NUMERIC_VERSION
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_FLAGS],NEBO_NUMERIC_REQUIRED_FLAGS
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_VECTOR],NEBO_NUMERIC_MAX_VECTOR
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_ELEMENTS],NEBO_NUMERIC_MAX_ELEMENTS
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_RANK],NEBO_NUMERIC_MAX_RANK
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_WORKERS],NEBO_NUMERIC_MAX_WORKERS
    jne .contract
    cmp qword [rdi+NEBO_NUMERIC_CONTRACT_MAX_WORKSPACE],NEBO_NUMERIC_MAX_WORKSPACE
    jne .contract
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
    ret
.contract:
    mov eax,NEBO_NUMERIC_ERROR_CONTRACT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
