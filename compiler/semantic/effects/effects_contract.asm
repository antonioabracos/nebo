; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F01 finite, allocation-free effect lattice contract.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/effects/effects_contract.inc"

section .text

; rdi = aligned pointer to NEBO_EFFECT_REQUEST_SIZE bytes.
; eax = NEBO_cli_driver_EFFECT_STATUS_*. Null/misaligned inputs are not mutated.
NEBOC_ABI_FUNCTION nebo_effect_contract_evaluate
    test rdi,rdi
    jz .invalid_argument
    test rdi,NEBO_EFFECT_REQUEST_ALIGNMENT-1
    jnz .invalid_argument
    mov r10,rdi

    mov qword [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_MISSING_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],0
    mov qword [r10+NEBO_EFFECT_REQUEST_HASH_OFFSET],0

    ; Unknown atoms remain visible in `missing` and are rejected before any
    ; lattice operation.  There is no ambient or edition-dependent widening.
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    or rax,[r10+NEBO_EFFECT_REQUEST_RIGHT_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_EFFECT_MASK
    jnz .unknown_effect

    mov rax,[r10+NEBO_EFFECT_REQUEST_OPERATION_OFFSET]
    cmp rax,NEBO_EFFECT_OP_VALIDATE
    je .validate
    cmp rax,NEBO_EFFECT_OP_UNION
    je .join
    cmp rax,NEBO_EFFECT_OP_INTERSECT
    je .meet
    cmp rax,NEBO_EFFECT_OP_SUBTYPE
    je .subtype
    cmp rax,NEBO_EFFECT_OP_CALL
    je .call
    mov qword [r10+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_INVALID_OPERATION
    mov esi,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jmp .hash

.validate:
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    mov [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],rax
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_VALIDATE
    xor esi,esi
    jmp .cardinality

.join:
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    or rax,[r10+NEBO_EFFECT_REQUEST_RIGHT_OFFSET]
    mov [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],rax
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_UNION
    xor esi,esi
    jmp .cardinality

.meet:
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    and rax,[r10+NEBO_EFFECT_REQUEST_RIGHT_OFFSET]
    mov [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],rax
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_INTERSECT
    xor esi,esi
    jmp .cardinality

.subtype:
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_SUBTYPE
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    mov [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],rax
    mov rcx,[r10+NEBO_EFFECT_REQUEST_RIGHT_OFFSET]
    not rcx
    and rax,rcx
    mov [r10+NEBO_EFFECT_REQUEST_MISSING_OFFSET],rax
    test rax,rax
    jnz .invalid_subtype
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    xor esi,esi
    jmp .cardinality

.call:
    mov qword [r10+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_CALL
    mov rax,[r10+NEBO_EFFECT_REQUEST_LEFT_OFFSET]
    mov [r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET],rax
    mov rcx,[r10+NEBO_EFFECT_REQUEST_RIGHT_OFFSET]
    not rcx
    and rax,rcx
    mov [r10+NEBO_EFFECT_REQUEST_MISSING_OFFSET],rax
    test rax,rax
    jnz .hidden_effect
    mov qword [r10+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    xor esi,esi
    jmp .cardinality

.invalid_subtype:
    mov qword [r10+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_INVALID_SUBTYPE
    mov esi,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jmp .cardinality

.hidden_effect:
    mov qword [r10+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_HIDDEN_EFFECT
    mov esi,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jmp .cardinality

.unknown_effect:
    mov [r10+NEBO_EFFECT_REQUEST_MISSING_OFFSET],rcx
    mov qword [r10+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_UNKNOWN_EFFECT
    mov esi,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jmp .hash

.cardinality:
    mov rax,[r10+NEBO_EFFECT_REQUEST_RESULT_OFFSET]
    xor ecx,ecx
.cardinality_loop:
    test rax,rax
    jz .cardinality_done
    lea rdx,[rax-1]
    and rax,rdx
    inc rcx
    jmp .cardinality_loop
.cardinality_done:
    mov [r10+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],rcx

.hash:
    mov rax,NEBO_EFFECT_FNV1A64_OFFSET_BASIS
    mov r8,NEBO_EFFECT_FNV1A64_PRIME
    xor ecx,ecx
.hash_loop:
    cmp rcx,NEBO_EFFECT_REQUEST_HASHED_BYTES
    jae .hash_done
    movzx edx,byte [r10+rcx]
    xor rax,rdx
    imul rax,r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r10+NEBO_EFFECT_REQUEST_HASH_OFFSET],rax
    mov eax,esi
    cld
    ret

.invalid_argument:
    mov eax,NEBO_EFFECT_STATUS_INVALID_ARGUMENT
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
