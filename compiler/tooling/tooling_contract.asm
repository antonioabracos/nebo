; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F01 unified compiler/tooling source-of-truth contract
bits 64
default rel
%define NEBO_TOOLING_CONTRACT_IMPLEMENTATION 1
%include "compiler/tooling/tooling_contract.inc"

section .text
global nebo_tooling_contract_init
global nebo_tooling_contract_validate
global nebo_tooling_contract_fingerprint
global nebo_tooling_span_validate
global nebo_tooling_workspace_validate

; rdi = aligned, writable NEBO_TOOLING_CONTRACT_SIZE-byte descriptor.
; Invalid pointers fail before the first write (failure atomicity).
nebo_tooling_contract_init:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_TOOLING_MAGIC
    mov [rdi+NEBO_TOOLING_CONTRACT_MAGIC],rax
    mov qword [rdi+NEBO_TOOLING_CONTRACT_VERSION],NEBO_TOOLING_VERSION
    mov qword [rdi+NEBO_TOOLING_CONTRACT_FLAGS],NEBO_TOOLING_REQUIRED_FLAGS
    mov rax,NEBO_TOOLING_PARSER_PROTOCOL
    mov [rdi+NEBO_TOOLING_CONTRACT_PARSER],rax
    mov rax,NEBO_TOOLING_TYPECHECKER_PROTOCOL
    mov [rdi+NEBO_TOOLING_CONTRACT_TYPECHECKER],rax
    mov rax,NEBO_TOOLING_SPAN_PROTOCOL
    mov [rdi+NEBO_TOOLING_CONTRACT_SPAN],rax
    mov rax,NEBO_TOOLING_DIAGNOSTIC_PROTOCOL
    mov [rdi+NEBO_TOOLING_CONTRACT_DIAGNOSTIC],rax
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_SOURCE],NEBO_TOOLING_MAX_SOURCE_BYTES
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_DOCUMENTS],NEBO_TOOLING_MAX_DOCUMENTS
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_SYMBOLS],NEBO_TOOLING_MAX_SYMBOLS
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_DIAGNOSTICS],NEBO_TOOLING_MAX_DIAGNOSTICS
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_WORKSPACE],NEBO_TOOLING_MAX_WORKSPACE_BYTES
    mov qword [rdi+NEBO_TOOLING_CONTRACT_MAX_OUTPUT],NEBO_TOOLING_MAX_OUTPUT_BYTES
    push rdi
    call nebo_tooling_contract_fingerprint
    pop rdi
    mov [rdi+NEBO_TOOLING_CONTRACT_CATALOG_ID],rax
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_TOOLING_ERROR_ARGUMENT
    ret

nebo_tooling_contract_validate:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_TOOLING_MAGIC
    cmp [rdi+NEBO_TOOLING_CONTRACT_MAGIC],rax
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_VERSION],NEBO_TOOLING_VERSION
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_FLAGS],NEBO_TOOLING_REQUIRED_FLAGS
    jne .contract
    mov rax,NEBO_TOOLING_PARSER_PROTOCOL
    cmp [rdi+NEBO_TOOLING_CONTRACT_PARSER],rax
    jne .contract
    mov rax,NEBO_TOOLING_TYPECHECKER_PROTOCOL
    cmp [rdi+NEBO_TOOLING_CONTRACT_TYPECHECKER],rax
    jne .contract
    mov rax,NEBO_TOOLING_SPAN_PROTOCOL
    cmp [rdi+NEBO_TOOLING_CONTRACT_SPAN],rax
    jne .contract
    mov rax,NEBO_TOOLING_DIAGNOSTIC_PROTOCOL
    cmp [rdi+NEBO_TOOLING_CONTRACT_DIAGNOSTIC],rax
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_SOURCE],NEBO_TOOLING_MAX_SOURCE_BYTES
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_DOCUMENTS],NEBO_TOOLING_MAX_DOCUMENTS
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_SYMBOLS],NEBO_TOOLING_MAX_SYMBOLS
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_DIAGNOSTICS],NEBO_TOOLING_MAX_DIAGNOSTICS
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_WORKSPACE],NEBO_TOOLING_MAX_WORKSPACE_BYTES
    jne .contract
    cmp qword [rdi+NEBO_TOOLING_CONTRACT_MAX_OUTPUT],NEBO_TOOLING_MAX_OUTPUT_BYTES
    jne .contract
    push rdi
    call nebo_tooling_contract_fingerprint
    pop rdi
    cmp [rdi+NEBO_TOOLING_CONTRACT_CATALOG_ID],rax
    jne .contract
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_TOOLING_ERROR_ARGUMENT
    ret
.contract:
    mov eax,NEBO_TOOLING_ERROR_CONTRACT
    ret

; Deterministic identity of the immutable compiler-owned catalog fields.
; rdi = aligned descriptor, rax = FNV-1a identity or zero for invalid input.
nebo_tooling_contract_fingerprint:
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    mov rax,NEBO_TOOLING_FNV1A64_OFFSET
    mov r8,NEBO_TOOLING_FNV1A64_PRIME
    xor ecx,ecx
.hash:
    cmp ecx,NEBO_TOOLING_CONTRACT_HASHED_BYTES
    jae .done
    movzx edx,byte [rdi+rcx]
    xor rax,rdx
    imul rax,r8
    inc ecx
    jmp .hash
.done:
    ret
.invalid:
    xor eax,eax
    ret

; rdi = contract, rsi = source length, rdx = start byte, rcx = end byte.
; Spans are half-open and zero-width spans are valid at source_length.
nebo_tooling_span_validate:
    push r12
    push r13
    push r14
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    call nebo_tooling_contract_validate
    test eax,eax
    jnz .span_done
    cmp r12,NEBO_TOOLING_MAX_SOURCE_BYTES
    ja .span_limit
    cmp r13,r14
    ja .span_error
    cmp r14,r12
    ja .span_error
    xor eax,eax
    jmp .span_done
.span_limit:
    mov eax,NEBO_TOOLING_ERROR_LIMIT
    jmp .span_done
.span_error:
    mov eax,NEBO_TOOLING_ERROR_SPAN
.span_done:
    pop r14
    pop r13
    pop r12
    ret

; rdi = contract, rsi = caller-owned workspace, rdx = byte capacity.
nebo_tooling_workspace_validate:
    push r12
    push r13
    push r14
    mov r12,rsi
    mov r13,rdx
    call nebo_tooling_contract_validate
    test eax,eax
    jnz .workspace_done
    test r12,r12
    jz .workspace_error
    test r12,15
    jnz .workspace_error
    test r13,r13
    jz .workspace_error
    cmp r13,NEBO_TOOLING_MAX_WORKSPACE_BYTES
    ja .workspace_limit
    xor eax,eax
    jmp .workspace_done
.workspace_limit:
    mov eax,NEBO_TOOLING_ERROR_LIMIT
    jmp .workspace_done
.workspace_error:
    mov eax,NEBO_TOOLING_ERROR_WORKSPACE
.workspace_done:
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
