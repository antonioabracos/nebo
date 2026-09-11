; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F05 sensitive reveal, redaction and flow tests.
bits 64
default rel
%include "runtime/privacy/privacy.inc"

extern nebo_capability_authority_init
extern nebo_capability_authority_revoke_all
extern nebo_sensitive_init
extern nebo_reveal_capability_grant
extern nebo_sensitive_reveal
extern nebo_sensitive_redact
extern nebo_privacy_flow_check

section .rodata
secret_key: times 32 db 0x71
payload: db 'api-key-12345'
payload_len equ $-payload
redacted_expected: db '[REDACTED]'

section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
sensitive resb NEBO_SENSITIVE_SIZE
reveal_cap resb NEBO_REVEAL_SIZE
reveal_copy resb NEBO_REVEAL_SIZE
reveal_request resb NEBO_REVEAL_REQUEST_SIZE
redact_request resb NEBO_REDACT_SIZE
flow resb NEBO_FLOW_SIZE
output resb 32

section .text
grant_secret:
    lea rdi,[authority]
    lea rsi,[reveal_cap]
    mov edx,42
    mov ecx,nebo_privacy_PRIVACY_SECRET
    mov r8d,7
    jmp nebo_reveal_capability_grant

prepare_reveal:
    lea rdi,[reveal_request]
    mov ecx,NEBO_REVEAL_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[authority]
    mov [reveal_request+NEBO_REVEAL_REQUEST_AUTHORITY_OFFSET],rax
    lea rax,[reveal_cap]
    mov [reveal_request+NEBO_REVEAL_REQUEST_CAPABILITY_OFFSET],rax
    lea rax,[sensitive]
    mov [reveal_request+NEBO_REVEAL_REQUEST_SENSITIVE_OFFSET],rax
    mov qword [reveal_request+NEBO_REVEAL_REQUEST_SCOPE_OFFSET],7
    ret

global _start
_start:
    ; 1-4. Initialize authority, classified value and purpose-bound grant.
    lea rdi,[authority]
    mov esi,0x2505
    lea rdx,[secret_key]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail1
    lea rdi,[sensitive]
    lea rsi,[payload]
    mov edx,payload_len
    mov ecx,nebo_privacy_PRIVACY_SECRET
    mov r8d,42
    call nebo_sensitive_init
    test eax,eax
    jnz .fail2
    call grant_secret
    test eax,eax
    jnz .fail3
    cmp qword [reveal_cap+NEBO_REVEAL_TAG_OFFSET],0
    je .fail4

    ; 5-7. Authorized reveal publishes the original view and redacted audit hash.
    call prepare_reveal
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    test eax,eax
    jnz .fail5
    lea rax,[payload]
    cmp [reveal_request+NEBO_REVEAL_REQUEST_PAYLOAD_OFFSET],rax
    jne .fail6
    cmp qword [reveal_request+NEBO_REVEAL_REQUEST_LENGTH_OFFSET],payload_len
    jne .fail7

    ; 8-10. Wrong purpose, clearance and scope never publish raw output.
    lea rdi,[authority]
    lea rsi,[reveal_cap]
    mov edx,43
    mov ecx,nebo_privacy_PRIVACY_SECRET
    mov r8d,7
    call nebo_reveal_capability_grant
    call prepare_reveal
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail8
    cmp qword [reveal_request+NEBO_REVEAL_REQUEST_PAYLOAD_OFFSET],0
    jne .fail8
    lea rdi,[authority]
    lea rsi,[reveal_cap]
    mov edx,42
    mov ecx,NEBO_PRIVACY_PERSONAL
    mov r8d,7
    call nebo_reveal_capability_grant
    call prepare_reveal
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail9
    call grant_secret
    call prepare_reveal
    mov qword [reveal_request+NEBO_REVEAL_REQUEST_SCOPE_OFFSET],8
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail10

    ; 11-12. Serialized and forged reveal capabilities are rejected.
    lea rsi,[reveal_cap]
    lea rdi,[reveal_copy]
    mov ecx,NEBO_REVEAL_SIZE/8
    rep movsq
    call prepare_reveal
    lea rax,[reveal_copy]
    mov [reveal_request+NEBO_REVEAL_REQUEST_CAPABILITY_OFFSET],rax
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail11
    xor byte [reveal_cap+NEBO_REVEAL_TAG_OFFSET],1
    call prepare_reveal
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail12

    ; 13. Authority epoch revocation invalidates the reveal grant.
    call grant_secret
    lea rdi,[authority]
    call nebo_capability_authority_revoke_all
    call prepare_reveal
    lea rdi,[reveal_request]
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail13

    ; 14-18. Redaction emits fixed text without reading or copying payload.
    lea rdi,[redact_request]
    mov ecx,NEBO_REDACT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[sensitive]
    mov [redact_request+NEBO_REDACT_SENSITIVE_OFFSET],rax
    lea rax,[output]
    mov [redact_request+NEBO_REDACT_OUTPUT_OFFSET],rax
    mov qword [redact_request+NEBO_REDACT_CAPACITY_OFFSET],32
    lea rdi,[redact_request]
    call nebo_sensitive_redact
    test eax,eax
    jnz .fail14
    cmp qword [redact_request+NEBO_REDACT_LENGTH_OFFSET],10
    jne .fail15
    lea rsi,[output]
    lea rdi,[redacted_expected]
    mov ecx,10
    repe cmpsb
    jne .fail16
    lea rsi,[output]
    lea rdi,[payload]
    mov ecx,10
    repe cmpsb
    je .fail17
    mov qword [redact_request+NEBO_REDACT_CAPACITY_OFFSET],9
    lea rdi,[redact_request]
    call nebo_sensitive_redact
    cmp eax,NEBO_PRIVACY_STATUS_LIMIT
    jne .fail18

    ; 19-24. Flow requires matching purpose and clearance unless already redacted.
    lea rdi,[flow]
    mov ecx,NEBO_FLOW_SIZE/8
    xor eax,eax
    rep stosq
    mov qword [flow+NEBO_FLOW_LABELS_OFFSET],nebo_privacy_PRIVACY_SECRET
    mov qword [flow+NEBO_FLOW_CLEARANCE_OFFSET],nebo_privacy_PRIVACY_SECRET
    mov qword [flow+NEBO_FLOW_VALUE_PURPOSE_OFFSET],42
    mov qword [flow+NEBO_FLOW_SINK_PURPOSE_OFFSET],42
    lea rdi,[flow]
    call nebo_privacy_flow_check
    test eax,eax
    jnz .fail19
    cmp qword [flow+NEBO_FLOW_DECISION_OFFSET],1
    jne .fail20
    mov qword [flow+NEBO_FLOW_CLEARANCE_OFFSET],NEBO_PRIVACY_PERSONAL
    lea rdi,[flow]
    call nebo_privacy_flow_check
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail21
    cmp qword [flow+NEBO_FLOW_REJECTED_OFFSET],nebo_privacy_PRIVACY_SECRET
    jne .fail22
    mov qword [flow+NEBO_FLOW_SINK_PURPOSE_OFFSET],43
    lea rdi,[flow]
    call nebo_privacy_flow_check
    cmp eax,NEBO_PRIVACY_STATUS_DENIED
    jne .fail23
    mov qword [flow+NEBO_FLOW_SINK_PURPOSE_OFFSET],42
    mov qword [flow+NEBO_FLOW_REDACTED_OFFSET],1
    lea rdi,[flow]
    call nebo_privacy_flow_check
    test eax,eax
    jnz .fail24

    ; 25-26. Unknown classifications and null records are typed.
    mov qword [flow+NEBO_FLOW_LABELS_OFFSET],0x10
    lea rdi,[flow]
    call nebo_privacy_flow_check
    cmp eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    jne .fail25
    xor edi,edi
    call nebo_sensitive_reveal
    cmp eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    jne .fail26

    xor edi,edi
    jmp .exit
%assign i 1
%rep 26
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
