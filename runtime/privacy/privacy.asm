; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F05 purpose-bound sensitive values and redaction-before-formatting.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crypto/sha256.inc"
%include "runtime/privacy/privacy.inc"

section .rodata
redacted_text: db '[REDACTED]'

section .text

; rdi=Sensitive, rsi=payload, rdx=len, rcx=classification, r8=purpose.
NEBOC_ABI_FUNCTION nebo_sensitive_init
    test rdi,rdi
    jz .sensitive_argument
    test rdi,7
    jnz .sensitive_argument
    test rsi,rsi
    jz .sensitive_argument
    test rdx,rdx
    jz .sensitive_argument
    test rcx,rcx
    jz .sensitive_argument
    mov rax,rcx
    and rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .sensitive_argument
    test r8,r8
    jz .sensitive_argument
    mov [rdi+NEBO_SENSITIVE_PAYLOAD_OFFSET],rsi
    mov [rdi+NEBO_SENSITIVE_LENGTH_OFFSET],rdx
    mov [rdi+NEBO_SENSITIVE_CLASS_OFFSET],rcx
    mov [rdi+NEBO_SENSITIVE_PURPOSE_OFFSET],r8
    mov qword [rdi+NEBO_SENSITIVE_STATE_OFFSET],NEBO_SENSITIVE_ACTIVE
    mov rax,NEBO_PRIVACY_FNV1A64_OFFSET_BASIS
    mov r9,NEBO_PRIVACY_FNV1A64_PRIME
    xor rax,rdx
    imul rax,r9
    xor rax,rcx
    imul rax,r9
    xor rax,r8
    imul rax,r9
    mov [rdi+NEBO_SENSITIVE_HASH_OFFSET],rax
    xor eax,eax
    ret
.sensitive_argument:
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    ret

; rdi=authority, rsi=RevealCapability, rdx=purpose, rcx=clearance, r8=scope.
NEBOC_ABI_FUNCTION nebo_reveal_capability_grant
    test rdi,rdi
    jz .grant_argument
    test rsi,rsi
    jz .grant_argument
    test rdi,7
    jnz .grant_argument
    test rsi,7
    jnz .grant_argument
    test rdx,rdx
    jz .grant_argument
    test rcx,rcx
    jz .grant_argument
    mov rax,rcx
    and rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .grant_argument
    test r8,r8
    jz .grant_argument
    mov rax,NEBO_AUTHORITY_MAGIC
    cmp [rdi+NEBO_AUTHORITY_MAGIC_OFFSET],rax
    jne .grant_argument
    cmp qword [rdi+NEBO_AUTHORITY_STATE_OFFSET],NEBO_AUTHORITY_ACTIVE
    jne .grant_argument
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    mov rax,NEBO_REVEAL_MAGIC
    mov [r13+NEBO_REVEAL_MAGIC_OFFSET],rax
    mov rax,[r12+NEBO_AUTHORITY_ID_OFFSET]
    mov [r13+NEBO_REVEAL_AUTHORITY_ID_OFFSET],rax
    mov rax,[r12+NEBO_AUTHORITY_EPOCH_OFFSET]
    mov [r13+NEBO_REVEAL_EPOCH_OFFSET],rax
    mov [r13+NEBO_REVEAL_PURPOSE_OFFSET],rdx
    mov [r13+NEBO_REVEAL_CLEARANCE_OFFSET],rcx
    mov [r13+NEBO_REVEAL_SCOPE_OFFSET],r8
    mov [r13+NEBO_REVEAL_ADDRESS_OFFSET],r13
    lea rdi,[r12+NEBO_AUTHORITY_SECRET_OFFSET]
    mov esi,32
    mov rdx,r13
    mov ecx,NEBO_REVEAL_SIGNED_BYTES
    lea r8,[r13+NEBO_REVEAL_TAG_OFFSET]
    call nebo_hmac_sha256
    pop r13
    pop r12
    pop rbx
    ret
.grant_argument:
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    ret

; rdi=64-byte reveal request. Outputs remain zero on every denied path.
NEBOC_ABI_FUNCTION nebo_sensitive_reveal
    test rdi,rdi
    jz .reveal_argument
    test rdi,7
    jnz .reveal_argument
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov qword [r12+NEBO_REVEAL_REQUEST_PAYLOAD_OFFSET],0
    mov qword [r12+NEBO_REVEAL_REQUEST_LENGTH_OFFSET],0
    mov qword [r12+NEBO_REVEAL_REQUEST_REASON_OFFSET],0
    mov qword [r12+NEBO_REVEAL_REQUEST_AUDIT_HASH_OFFSET],0
    mov r13,[r12+NEBO_REVEAL_REQUEST_AUTHORITY_OFFSET]
    mov rbx,[r12+NEBO_REVEAL_REQUEST_CAPABILITY_OFFSET]
    mov r11,[r12+NEBO_REVEAL_REQUEST_SENSITIVE_OFFSET]
    test r13,r13
    jz .reveal_argument_saved
    test rbx,rbx
    jz .reveal_argument_saved
    test r11,r11
    jz .reveal_argument_saved
    test r13,7
    jnz .reveal_argument_saved
    test rbx,7
    jnz .reveal_argument_saved
    test r11,7
    jnz .reveal_argument_saved
    cmp [rbx+NEBO_REVEAL_ADDRESS_OFFSET],rbx
    jne .reveal_forged
    mov rax,NEBO_REVEAL_MAGIC
    cmp [rbx+NEBO_REVEAL_MAGIC_OFFSET],rax
    jne .reveal_forged
    mov rax,[r13+NEBO_AUTHORITY_ID_OFFSET]
    cmp [rbx+NEBO_REVEAL_AUTHORITY_ID_OFFSET],rax
    jne .reveal_forged
    mov rax,[r13+NEBO_AUTHORITY_EPOCH_OFFSET]
    cmp [rbx+NEBO_REVEAL_EPOCH_OFFSET],rax
    jne .reveal_revoked
    sub rsp,32
    lea r8,[rsp]
    lea rdi,[r13+NEBO_AUTHORITY_SECRET_OFFSET]
    mov esi,32
    mov rdx,rbx
    mov ecx,NEBO_REVEAL_SIGNED_BYTES
    call nebo_hmac_sha256
    test eax,eax
    jnz .reveal_mac_fail
    xor ecx,ecx
    xor edx,edx
.reveal_compare:
    mov al,[rsp+rcx]
    xor al,[rbx+NEBO_REVEAL_TAG_OFFSET+rcx]
    or dl,al
    mov byte [rsp+rcx],0
    inc rcx
    cmp rcx,32
    jb .reveal_compare
    add rsp,32
    test dl,dl
    jnz .reveal_forged
    mov r11,[r12+NEBO_REVEAL_REQUEST_SENSITIVE_OFFSET]
    cmp qword [r11+NEBO_SENSITIVE_STATE_OFFSET],NEBO_SENSITIVE_ACTIVE
    jne .reveal_argument_saved
    mov rax,[r11+NEBO_SENSITIVE_PURPOSE_OFFSET]
    cmp rax,[rbx+NEBO_REVEAL_PURPOSE_OFFSET]
    jne .reveal_purpose
    mov rax,[r11+NEBO_SENSITIVE_CLASS_OFFSET]
    mov rcx,[rbx+NEBO_REVEAL_CLEARANCE_OFFSET]
    not rcx
    test rax,rcx
    jnz .reveal_clearance
    mov rax,[r12+NEBO_REVEAL_REQUEST_SCOPE_OFFSET]
    cmp rax,[rbx+NEBO_REVEAL_SCOPE_OFFSET]
    jne .reveal_scope
    mov rax,[r11+NEBO_SENSITIVE_PAYLOAD_OFFSET]
    mov [r12+NEBO_REVEAL_REQUEST_PAYLOAD_OFFSET],rax
    mov rax,[r11+NEBO_SENSITIVE_LENGTH_OFFSET]
    mov [r12+NEBO_REVEAL_REQUEST_LENGTH_OFFSET],rax
    mov rax,[r11+NEBO_SENSITIVE_HASH_OFFSET]
    xor rax,[rbx+NEBO_REVEAL_PURPOSE_OFFSET]
    mov [r12+NEBO_REVEAL_REQUEST_AUDIT_HASH_OFFSET],rax
    xor eax,eax
    jmp .reveal_done
.reveal_mac_fail:
    add rsp,32
.reveal_forged:
    mov edx,NEBO_PRIVACY_REASON_FORGED
    jmp .reveal_deny
.reveal_revoked:
    mov edx,NEBO_PRIVACY_REASON_REVOKED
    jmp .reveal_deny
.reveal_purpose:
    mov edx,NEBO_PRIVACY_REASON_PURPOSE
    jmp .reveal_deny
.reveal_clearance:
    mov edx,NEBO_PRIVACY_REASON_CLEARANCE
    jmp .reveal_deny
.reveal_scope:
    mov edx,NEBO_PRIVACY_REASON_SCOPE
.reveal_deny:
    mov [r12+NEBO_REVEAL_REQUEST_REASON_OFFSET],rdx
    mov eax,NEBO_PRIVACY_STATUS_DENIED
    jmp .reveal_done
.reveal_argument_saved:
    mov qword [r12+NEBO_REVEAL_REQUEST_REASON_OFFSET],NEBO_PRIVACY_REASON_ARGUMENT
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
.reveal_done:
    pop r13
    pop r12
    pop rbx
    ret
.reveal_argument:
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    ret

; rdi=32-byte redact request. Payload bytes are deliberately never read.
NEBOC_ABI_FUNCTION nebo_sensitive_redact
    test rdi,rdi
    jz .redact_argument
    mov r10,rdi
    mov qword [rdi+NEBO_REDACT_LENGTH_OFFSET],0
    mov r8,[rdi+NEBO_REDACT_SENSITIVE_OFFSET]
    mov r9,[rdi+NEBO_REDACT_OUTPUT_OFFSET]
    test r8,r8
    jz .redact_argument
    test r9,r9
    jz .redact_argument
    cmp qword [r8+NEBO_SENSITIVE_STATE_OFFSET],NEBO_SENSITIVE_ACTIVE
    jne .redact_argument
    cmp qword [rdi+NEBO_REDACT_CAPACITY_OFFSET],NEBO_REDACTED_BYTES
    jb .redact_limit
    lea rsi,[rel redacted_text]
    mov rcx,NEBO_REDACTED_BYTES
    mov rdi,r9
    rep movsb
    mov qword [r10+NEBO_REDACT_LENGTH_OFFSET],NEBO_REDACTED_BYTES
    xor eax,eax
    ret
.redact_argument:
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    ret
.redact_limit:
    mov eax,NEBO_PRIVACY_STATUS_LIMIT
    ret

; rdi=56-byte flow request.
NEBOC_ABI_FUNCTION nebo_privacy_flow_check
    test rdi,rdi
    jz .flow_argument
    mov qword [rdi+NEBO_FLOW_REJECTED_OFFSET],0
    mov qword [rdi+NEBO_FLOW_DECISION_OFFSET],0
    mov rax,[rdi+NEBO_FLOW_LABELS_OFFSET]
    or rax,[rdi+NEBO_FLOW_CLEARANCE_OFFSET]
    test rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .flow_argument
    cmp qword [rdi+NEBO_FLOW_REDACTED_OFFSET],1
    ja .flow_argument
    cmp qword [rdi+NEBO_FLOW_VALUE_PURPOSE_OFFSET],0
    je .flow_deny
    mov rax,[rdi+NEBO_FLOW_VALUE_PURPOSE_OFFSET]
    cmp rax,[rdi+NEBO_FLOW_SINK_PURPOSE_OFFSET]
    jne .flow_deny
    cmp qword [rdi+NEBO_FLOW_REDACTED_OFFSET],1
    je .flow_permit
    mov rax,[rdi+NEBO_FLOW_CLEARANCE_OFFSET]
    not rax
    and rax,[rdi+NEBO_FLOW_LABELS_OFFSET]
    mov [rdi+NEBO_FLOW_REJECTED_OFFSET],rax
    test rax,rax
    jnz .flow_deny
.flow_permit:
    mov qword [rdi+NEBO_FLOW_DECISION_OFFSET],1
    xor eax,eax
    ret
.flow_deny:
    mov eax,NEBO_PRIVACY_STATUS_DENIED
    ret
.flow_argument:
    mov eax,NEBO_PRIVACY_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
