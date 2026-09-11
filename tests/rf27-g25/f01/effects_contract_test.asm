; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F01 native lattice, diagnostic and failure-atomicity tests.
bits 64
default rel
%include "compiler/semantic/effects/effects_contract.inc"

%if NEBO_EFFECT_ATOM_COUNT != 14
    %error "cli_driver effect atom count must remain fourteen"
%endif
%if NEBO_EFFECT_MASK != 0x3fff
    %error "cli_driver effect mask must remain bits 0..13"
%endif
%if NEBO_EFFECT_REQUEST_SIZE != 80
    %error "cli_driver effect request must remain 80 bytes"
%endif

extern nebo_effect_contract_evaluate

section .bss
align 16
request resb NEBO_EFFECT_REQUEST_SIZE
request_copy resb NEBO_EFFECT_REQUEST_SIZE

section .text
clear_request:
    lea rdi,[request]
    mov ecx,NEBO_EFFECT_REQUEST_QWORDS
    xor eax,eax
    rep stosq
    ret

evaluate:
    lea rdi,[request]
    jmp nebo_effect_contract_evaluate

global _start
_start:
    ; 1-2. Invalid addresses are rejected without touching aligned storage.
    xor edi,edi
    call nebo_effect_contract_evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_ARGUMENT
    jne .fail1
    call clear_request
    mov qword [request+NEBO_EFFECT_REQUEST_HASH_OFFSET],0x4455
    lea rdi,[request+1]
    call nebo_effect_contract_evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_ARGUMENT
    jne .fail2
    cmp qword [request+NEBO_EFFECT_REQUEST_HASH_OFFSET],0x4455
    jne .fail2

    ; 3-5. Pure is bottom and validates with zero cardinality.
    call clear_request
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_VALIDATE
    call evaluate
    test eax,eax
    jnz .fail3
    cmp qword [request+NEBO_EFFECT_REQUEST_RESULT_OFFSET],NEBO_EFFECT_PURE
    jne .fail4
    cmp qword [request+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],0
    jne .fail5

    ; 6-8. Join composes direct/callee sets and counts distinct atoms.
    call clear_request
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_UNION
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_FILE_READ
    mov qword [request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_NETWORK
    call evaluate
    test eax,eax
    jnz .fail6
    cmp qword [request+NEBO_EFFECT_REQUEST_RESULT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_FILE_READ | NEBO_EFFECT_NETWORK
    jne .fail7
    cmp qword [request+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],3
    jne .fail8

    ; 9-10. Meet is intersection and reports its explanation rule.
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_INTERSECT
    call evaluate
    test eax,eax
    jnz .fail9
    cmp qword [request+NEBO_EFFECT_REQUEST_RESULT_OFFSET],NEBO_EFFECT_FILE_READ
    jne .fail10
    cmp qword [request+NEBO_EFFECT_REQUEST_EXPLAIN_OFFSET],NEBO_EFFECT_EXPLAIN_INTERSECT
    jne .fail10

    ; 11-12. Subtyping is exact set inclusion.
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_SUBTYPE
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
    call evaluate
    test eax,eax
    jnz .fail11
    cmp qword [request+NEBO_EFFECT_REQUEST_COMPATIBLE_OFFSET],1
    jne .fail12

    ; 13-15. An invalid subtype exposes precisely the missing atom.
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_NETWORK
    call evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jne .fail13
    cmp qword [request+NEBO_EFFECT_REQUEST_MISSING_OFFSET],NEBO_EFFECT_NETWORK
    jne .fail14
    cmp qword [request+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_INVALID_SUBTYPE
    jne .fail15

    ; 16-18. Calls cannot hide effects absent from the caller declaration.
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_CALL
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_PROCESS | NEBO_EFFECT_RANDOM
    mov qword [request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],NEBO_EFFECT_PROCESS
    call evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jne .fail16
    cmp qword [request+NEBO_EFFECT_REQUEST_MISSING_OFFSET],NEBO_EFFECT_RANDOM
    jne .fail17
    cmp qword [request+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_HIDDEN_EFFECT
    jne .fail18

    ; 19-20. Unknown atoms never enter a result and remain explainable.
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_UNION
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],0x4000
    mov qword [request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],0
    call evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jne .fail19
    cmp qword [request+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_UNKNOWN_EFFECT
    jne .fail20
    cmp qword [request+NEBO_EFFECT_REQUEST_MISSING_OFFSET],0x4000
    jne .fail20

    ; 21. Invalid operations are typed and hashed, not silently accepted.
    call clear_request
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],99
    call evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jne .fail21
    cmp qword [request+NEBO_EFFECT_REQUEST_DIAGNOSTIC_OFFSET],NEBO_EFFECT_DIAG_INVALID_OPERATION
    jne .fail21
    cmp qword [request+NEBO_EFFECT_REQUEST_HASH_OFFSET],0
    je .fail21

    ; 22-23. Equal inputs produce byte-identical deterministic outputs.
    lea rsi,[request]
    lea rdi,[request_copy]
    mov ecx,NEBO_EFFECT_REQUEST_QWORDS
    rep movsq
    lea rdi,[request_copy]
    call nebo_effect_contract_evaluate
    cmp eax,NEBO_EFFECT_STATUS_INVALID_SOURCE
    jne .fail22
    lea rsi,[request]
    lea rdi,[request_copy]
    mov ecx,NEBO_EFFECT_REQUEST_QWORDS
    repe cmpsq
    jne .fail23

    ; 24-25. The complete top has fourteen atoms and accepts every call set.
    call clear_request
    mov qword [request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_CALL
    mov qword [request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_MASK
    mov qword [request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],NEBO_EFFECT_MASK
    call evaluate
    test eax,eax
    jnz .fail24
    cmp qword [request+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],14
    jne .fail25

    xor edi,edi
    jmp .exit
%assign i 1
%rep 25
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
