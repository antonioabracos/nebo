; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F08 append-only audit and explainability tests.
bits 64
default rel
%include "runtime/security/audit.inc"

extern nebo_audit_init
extern nebo_audit_append
extern nebo_audit_verify
extern nebo_audit_query_explain

section .rodata
subject_a: times 32 db 0x21
subject_b: times 32 db 0x42
zero_digest: times 32 db 0

section .bss
align 16
state resb NEBO_AUDIT_STATE_SIZE
records resb NEBO_AUDIT_RECORD_SIZE*4
init_request resb NEBO_AUDIT_INIT_SIZE
append_request resb NEBO_AUDIT_APPEND_SIZE
verify_request resb NEBO_AUDIT_VERIFY_SIZE
query_request resb NEBO_AUDIT_QUERY_SIZE
explanation resb NEBO_AUDIT_EXPLAIN_SIZE
digest_a resb 32
digest_b resb 32
verify_digest resb 32

section .text
prepare_init:
    lea rdi,[init_request]
    mov ecx,NEBO_AUDIT_INIT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [init_request+NEBO_AUDIT_INIT_STATE],rax
    lea rax,[records]
    mov [init_request+NEBO_AUDIT_INIT_RECORDS],rax
    mov qword [init_request+NEBO_AUDIT_INIT_CAPACITY],4
    mov qword [init_request+NEBO_AUDIT_INIT_AUTHORITY],0xa817
    mov qword [init_request+NEBO_AUDIT_INIT_SCOPE],0x25
    mov qword [init_request+NEBO_AUDIT_INIT_WRITE_BUDGET],4
    mov qword [init_request+NEBO_AUDIT_INIT_QUERY_BUDGET],3
    ret

prepare_append:
    lea rdi,[append_request]
    mov ecx,NEBO_AUDIT_APPEND_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [append_request+NEBO_AUDIT_APPEND_STATE],rax
    mov qword [append_request+NEBO_AUDIT_APPEND_AUTHORITY],0xa817
    mov qword [append_request+NEBO_AUDIT_APPEND_SCOPE],0x25
    mov qword [append_request+NEBO_AUDIT_APPEND_EVENT_KIND],3
    mov qword [append_request+NEBO_AUDIT_APPEND_EFFECT_MASK],0x21
    mov qword [append_request+NEBO_AUDIT_APPEND_CAPABILITY_KIND],1
    mov qword [append_request+NEBO_AUDIT_APPEND_DECISION],NEBO_AUDIT_DECISION_ALLOW
    mov qword [append_request+NEBO_AUDIT_APPEND_POLICY_ID],0x2508
    mov qword [append_request+NEBO_AUDIT_APPEND_PURPOSE_ID],7
    lea rax,[subject_a]
    mov [append_request+NEBO_AUDIT_APPEND_SUBJECT_DIGEST],rax
    lea rax,[digest_a]
    mov [append_request+NEBO_AUDIT_APPEND_DIGEST],rax
    ret

prepare_verify:
    lea rdi,[verify_request]
    mov ecx,NEBO_AUDIT_VERIFY_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [verify_request+NEBO_AUDIT_VERIFY_STATE],rax
    mov qword [verify_request+NEBO_AUDIT_VERIFY_INDEX],2
    lea rax,[verify_digest]
    mov [verify_request+NEBO_AUDIT_VERIFY_DIGEST],rax
    ret

prepare_query:
    lea rdi,[query_request]
    mov ecx,NEBO_AUDIT_QUERY_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [query_request+NEBO_AUDIT_QUERY_STATE],rax
    mov qword [query_request+NEBO_AUDIT_QUERY_AUTHORITY],0xa817
    mov qword [query_request+NEBO_AUDIT_QUERY_SCOPE],0x25
    mov qword [query_request+NEBO_AUDIT_QUERY_INDEX],2
    lea rax,[explanation]
    mov [query_request+NEBO_AUDIT_QUERY_OUTPUT],rax
    ret

global _start
_start:
    call prepare_init
    lea rdi,[init_request]
    call nebo_audit_init
    test eax,eax
    jnz .fail1
    mov rax,NEBO_AUDIT_MAGIC
    cmp [state+NEBO_AUDIT_STATE_MAGIC],rax
    jne .fail2
    cmp qword [state+NEBO_AUDIT_STATE_WRITE_BUDGET],4
    jne .fail3

    call prepare_append
    lea rdi,[append_request]
    call nebo_audit_append
    test eax,eax
    jnz .fail4
    cmp qword [append_request+NEBO_AUDIT_APPEND_INDEX],1
    jne .fail5
    cmp qword [state+NEBO_AUDIT_STATE_COUNT],1
    jne .fail6
    cmp qword [state+NEBO_AUDIT_STATE_WRITE_BUDGET],3
    jne .fail7
    cmp qword [digest_a],0
    je .fail8
    cmp qword [records+NEBO_AUDIT_RECORD_STATE],NEBO_AUDIT_RECORD_IMMUTABLE
    jne .fail9

    call prepare_append
    mov qword [append_request+NEBO_AUDIT_APPEND_EVENT_KIND],6
    mov qword [append_request+NEBO_AUDIT_APPEND_EFFECT_MASK],0x80
    mov qword [append_request+NEBO_AUDIT_APPEND_CAPABILITY_KIND],6
    mov qword [append_request+NEBO_AUDIT_APPEND_DECISION],NEBO_AUDIT_DECISION_DENY
    mov qword [append_request+NEBO_AUDIT_APPEND_ERROR_CLASS],4
    lea rax,[subject_b]
    mov [append_request+NEBO_AUDIT_APPEND_SUBJECT_DIGEST],rax
    lea rax,[digest_b]
    mov [append_request+NEBO_AUDIT_APPEND_DIGEST],rax
    lea rdi,[append_request]
    call nebo_audit_append
    test eax,eax
    jnz .fail10
    cmp qword [append_request+NEBO_AUDIT_APPEND_INDEX],2
    jne .fail11
    mov rax,[digest_a]
    cmp [records+NEBO_AUDIT_RECORD_SIZE+NEBO_AUDIT_RECORD_PREVIOUS_DIGEST],rax
    jne .fail12

    call prepare_verify
    lea rdi,[verify_request]
    call nebo_audit_verify
    test eax,eax
    jnz .fail13
    mov rax,[digest_b]
    cmp [verify_digest],rax
    jne .fail14

    call prepare_query
    lea rdi,[query_request]
    call nebo_audit_query_explain
    test eax,eax
    jnz .fail15
    cmp qword [explanation+NEBO_AUDIT_EXPLAIN_DECISION],NEBO_AUDIT_DECISION_DENY
    jne .fail16
    cmp qword [explanation+NEBO_AUDIT_EXPLAIN_ERROR_CLASS],4
    jne .fail17
    mov rax,[subject_b]
    cmp [explanation+NEBO_AUDIT_EXPLAIN_SUBJECT_PREFIX],rax
    jne .fail18
    cmp qword [state+NEBO_AUDIT_STATE_QUERY_BUDGET],2
    jne .fail19

    call prepare_query
    mov qword [query_request+NEBO_AUDIT_QUERY_AUTHORITY],0xa818
    lea rdi,[query_request]
    call nebo_audit_query_explain
    cmp eax,NEBO_AUDIT_STATUS_AUTHORITY
    jne .fail20
    cmp qword [state+NEBO_AUDIT_STATE_QUERY_BUDGET],2
    jne .fail21
    call prepare_query
    mov qword [query_request+NEBO_AUDIT_QUERY_SCOPE],0x26
    lea rdi,[query_request]
    call nebo_audit_query_explain
    cmp eax,NEBO_AUDIT_STATUS_SCOPE
    jne .fail22

    call prepare_append
    lea rax,[zero_digest]
    mov [append_request+NEBO_AUDIT_APPEND_SUBJECT_DIGEST],rax
    lea rdi,[append_request]
    call nebo_audit_append
    cmp eax,NEBO_AUDIT_STATUS_MISSING_DIGEST
    jne .fail23
    cmp qword [state+NEBO_AUDIT_STATE_COUNT],2
    jne .fail24
    call prepare_append
    mov qword [append_request+NEBO_AUDIT_APPEND_EFFECT_MASK],0x4000
    lea rdi,[append_request]
    call nebo_audit_append
    cmp eax,NEBO_AUDIT_STATUS_EFFECT
    jne .fail25
    call prepare_append
    mov qword [append_request+NEBO_AUDIT_APPEND_CAPABILITY_KIND],7
    lea rdi,[append_request]
    call nebo_audit_append
    cmp eax,NEBO_AUDIT_STATUS_CAPABILITY
    jne .fail26
    call prepare_append
    mov qword [append_request+NEBO_AUDIT_APPEND_ERROR_CLASS],1
    lea rdi,[append_request]
    call nebo_audit_append
    cmp eax,NEBO_AUDIT_STATUS_ERROR_CLASS
    jne .fail27

    xor qword [records+NEBO_AUDIT_RECORD_POLICY_ID],1
    call prepare_verify
    mov qword [verify_request+NEBO_AUDIT_VERIFY_INDEX],1
    lea rdi,[verify_request]
    call nebo_audit_verify
    cmp eax,NEBO_AUDIT_STATUS_CHAIN
    jne .fail28
    xor qword [records+NEBO_AUDIT_RECORD_POLICY_ID],1
    mov qword [records+NEBO_AUDIT_RECORD_STATE],0
    lea rdi,[verify_request]
    call nebo_audit_verify
    cmp eax,NEBO_AUDIT_STATUS_IMMUTABLE
    jne .fail29
    mov qword [records+NEBO_AUDIT_RECORD_STATE],NEBO_AUDIT_RECORD_IMMUTABLE
    xor byte [records+NEBO_AUDIT_RECORD_SIZE+NEBO_AUDIT_RECORD_PREVIOUS_DIGEST],1
    call prepare_verify
    lea rdi,[verify_request]
    call nebo_audit_verify
    cmp eax,NEBO_AUDIT_STATUS_CHAIN
    jne .fail30

    xor edi,edi
    mov eax,60
    syscall

%macro FAIL_LABEL 1
.fail%1:
    mov edi,%1
    mov eax,60
    syscall
%endmacro
%assign i 1
%rep 30
FAIL_LABEL i
%assign i i+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
