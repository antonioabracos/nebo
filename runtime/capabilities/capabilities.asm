; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F03 HMAC-authenticated, address-bound scoped capabilities.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crypto/sha256.inc"
%include "runtime/capabilities/capabilities.inc"

section .text

; rdi=authority, rsi=nonzero authority id, rdx=32-byte host secret.
NEBOC_ABI_FUNCTION nebo_capability_authority_init
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    test rsi,rsi
    jz .argument
    test rdx,rdx
    jz .argument
    xor ecx,ecx
    xor r8d,r8d
.secret_check:
    or r8b,[rdx+rcx]
    inc rcx
    cmp rcx,32
    jb .secret_check
    test r8b,r8b
    jz .argument
    mov rax,NEBO_AUTHORITY_MAGIC
    mov [rdi+NEBO_AUTHORITY_MAGIC_OFFSET],rax
    mov qword [rdi+NEBO_AUTHORITY_VERSION_OFFSET],NEBO_AUTHORITY_VERSION
    mov [rdi+NEBO_AUTHORITY_ID_OFFSET],rsi
    mov qword [rdi+NEBO_AUTHORITY_EPOCH_OFFSET],1
    xor ecx,ecx
.secret_copy:
    mov r8,[rdx+rcx]
    mov [rdi+NEBO_AUTHORITY_SECRET_OFFSET+rcx],r8
    add rcx,8
    cmp rcx,32
    jb .secret_copy
    mov qword [rdi+NEBO_AUTHORITY_STATE_OFFSET],NEBO_AUTHORITY_ACTIVE
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret

; rdi=authority. Incrementing the authenticated epoch revokes every grant.
NEBOC_ABI_FUNCTION nebo_capability_authority_revoke_all
    test rdi,rdi
    jz .revoke_argument
    test rdi,7
    jnz .revoke_argument
    mov rax,NEBO_AUTHORITY_MAGIC
    cmp [rdi+NEBO_AUTHORITY_MAGIC_OFFSET],rax
    jne .revoke_authority
    cmp qword [rdi+NEBO_AUTHORITY_VERSION_OFFSET],NEBO_AUTHORITY_VERSION
    jne .revoke_authority
    cmp qword [rdi+NEBO_AUTHORITY_STATE_OFFSET],NEBO_AUTHORITY_ACTIVE
    jne .revoke_authority
    cmp qword [rdi+NEBO_AUTHORITY_EPOCH_OFFSET],-1
    je .revoke_limit
    inc qword [rdi+NEBO_AUTHORITY_EPOCH_OFFSET]
    xor eax,eax
    ret
.revoke_argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret
.revoke_authority:
    mov eax,NEBO_CAPABILITY_STATUS_AUTHORITY
    ret
.revoke_limit:
    mov eax,NEBO_CAPABILITY_STATUS_LIMIT
    ret

; rdi=56-byte grant request.
NEBOC_ABI_FUNCTION nebo_capability_grant
    test rdi,rdi
    jz .grant_argument
    test rdi,7
    jnz .grant_argument
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,[r12+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET]
    mov r14,[r12+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET]
    test r13,r13
    jz .grant_argument_saved
    test r14,r14
    jz .grant_argument_saved
    test r13,7
    jnz .grant_argument_saved
    test r14,7
    jnz .grant_argument_saved
    cmp r13,r14
    je .grant_argument_saved
    mov rdi,r13
    call capability_authority_validate
    test eax,eax
    jnz .grant_done
    mov rbx,[r12+NEBO_CAPABILITY_GRANT_KIND_OFFSET]
    mov r15,[r12+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET]
    mov rdi,rbx
    call capability_kind_mask
    cmp rax,-1
    je .grant_denied
    test r15,r15
    jz .grant_denied
    mov rcx,r15
    not rax
    and rcx,rax
    jnz .grant_denied
    cmp qword [r12+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],0
    je .grant_argument_saved
    cmp qword [r12+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],0
    je .grant_argument_saved
    cmp qword [r12+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],0
    je .grant_argument_saved

    mov rax,NEBO_CAPABILITY_MAGIC
    mov [r14+NEBO_CAPABILITY_MAGIC_OFFSET],rax
    mov qword [r14+NEBO_CAPABILITY_VERSION_OFFSET],NEBO_CAPABILITY_VERSION
    mov rax,[r13+NEBO_AUTHORITY_ID_OFFSET]
    mov [r14+NEBO_CAPABILITY_AUTHORITY_ID_OFFSET],rax
    mov rax,[r13+NEBO_AUTHORITY_EPOCH_OFFSET]
    mov [r14+NEBO_CAPABILITY_EPOCH_OFFSET],rax
    mov [r14+NEBO_CAPABILITY_KIND_OFFSET],rbx
    mov [r14+NEBO_CAPABILITY_EFFECTS_OFFSET],r15
    mov rax,[r12+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET]
    mov [r14+NEBO_CAPABILITY_CONSTRAINT_OFFSET],rax
    mov rax,[r12+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET]
    mov [r14+NEBO_CAPABILITY_BUDGET_OFFSET],rax
    mov rax,[r12+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET]
    mov [r14+NEBO_CAPABILITY_SCOPE_OFFSET],rax
    mov qword [r14+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_ACTIVE
    mov [r14+NEBO_CAPABILITY_ADDRESS_OFFSET],r14
    mov qword [r14+NEBO_CAPABILITY_LINEAGE_OFFSET],0
    mov rdi,r13
    mov rsi,r14
    call capability_sign
    jmp .grant_done
.grant_denied:
    mov eax,NEBO_CAPABILITY_STATUS_DENIED
    jmp .grant_done
.grant_argument_saved:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
.grant_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.grant_argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret

; Same request layout as grant: authority, source, destination is supplied by
; placing source in AUTHORITY? No: attenuation uses AUTHORITY, DESTINATION and
; source via LINEAGE field would be ambiguous. Use rdi=request, rsi=source.
NEBOC_ABI_FUNCTION nebo_capability_attenuate
    test rdi,rdi
    jz .attenuate_argument
    test rsi,rsi
    jz .attenuate_argument
    test rdi,7
    jnz .attenuate_argument
    test rsi,7
    jnz .attenuate_argument
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r15,rsi
    mov r13,[r12+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET]
    mov r14,[r12+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET]
    test r13,r13
    jz .attenuate_argument_saved
    test r14,r14
    jz .attenuate_argument_saved
    test r14,7
    jnz .attenuate_argument_saved
    cmp r14,r15
    je .attenuate_argument_saved
    mov rdi,r13
    mov rsi,r15
    call capability_validate
    test eax,eax
    jnz .attenuate_done
    cmp qword [r15+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_ACTIVE
    jne .attenuate_revoked
    mov rax,[r15+NEBO_CAPABILITY_KIND_OFFSET]
    cmp rax,[r12+NEBO_CAPABILITY_GRANT_KIND_OFFSET]
    jne .attenuate_escalation
    mov rbx,[r12+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET]
    test rbx,rbx
    jz .attenuate_escalation
    mov rax,[r15+NEBO_CAPABILITY_EFFECTS_OFFSET]
    not rax
    mov rcx,rbx
    and rcx,rax
    jnz .attenuate_escalation
    mov rdx,[r12+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET]
    test rdx,rdx
    jz .attenuate_escalation
    mov rax,[r15+NEBO_CAPABILITY_CONSTRAINT_OFFSET]
    not rax
    mov rcx,rdx
    and rcx,rax
    jnz .attenuate_escalation
    mov r8,[r12+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET]
    test r8,r8
    jz .attenuate_escalation
    cmp r8,[r15+NEBO_CAPABILITY_BUDGET_OFFSET]
    ja .attenuate_escalation
    mov r9,[r15+NEBO_CAPABILITY_SCOPE_OFFSET]
    add r9,1
    jc .attenuate_limit
    cmp r9,[r12+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET]
    jne .attenuate_scope

    mov rax,NEBO_CAPABILITY_MAGIC
    mov [r14+NEBO_CAPABILITY_MAGIC_OFFSET],rax
    mov qword [r14+NEBO_CAPABILITY_VERSION_OFFSET],NEBO_CAPABILITY_VERSION
    mov rax,[r15+NEBO_CAPABILITY_AUTHORITY_ID_OFFSET]
    mov [r14+NEBO_CAPABILITY_AUTHORITY_ID_OFFSET],rax
    mov rax,[r15+NEBO_CAPABILITY_EPOCH_OFFSET]
    mov [r14+NEBO_CAPABILITY_EPOCH_OFFSET],rax
    mov rax,[r15+NEBO_CAPABILITY_KIND_OFFSET]
    mov [r14+NEBO_CAPABILITY_KIND_OFFSET],rax
    mov [r14+NEBO_CAPABILITY_EFFECTS_OFFSET],rbx
    mov [r14+NEBO_CAPABILITY_CONSTRAINT_OFFSET],rdx
    mov [r14+NEBO_CAPABILITY_BUDGET_OFFSET],r8
    mov [r14+NEBO_CAPABILITY_SCOPE_OFFSET],r9
    mov qword [r14+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_ACTIVE
    mov [r14+NEBO_CAPABILITY_ADDRESS_OFFSET],r14
    mov rax,[r15+NEBO_CAPABILITY_TAG_OFFSET]
    mov [r14+NEBO_CAPABILITY_LINEAGE_OFFSET],rax
    mov rdi,r13
    mov rsi,r14
    call capability_sign
    jmp .attenuate_done
.attenuate_revoked:
    mov eax,NEBO_CAPABILITY_STATUS_REVOKED
    jmp .attenuate_done
.attenuate_escalation:
    mov eax,NEBO_CAPABILITY_STATUS_ESCALATION
    jmp .attenuate_done
.attenuate_scope:
    mov eax,NEBO_CAPABILITY_STATUS_SCOPE
    jmp .attenuate_done
.attenuate_limit:
    mov eax,NEBO_CAPABILITY_STATUS_LIMIT
    jmp .attenuate_done
.attenuate_argument_saved:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
.attenuate_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.attenuate_argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret

; rdi=authority, rsi=capability.
NEBOC_ABI_FUNCTION nebo_capability_revoke
    test rdi,rdi
    jz .cap_revoke_argument
    test rsi,rsi
    jz .cap_revoke_argument
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call capability_validate
    test eax,eax
    jnz .cap_revoke_done
    cmp qword [r13+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_ACTIVE
    jne .cap_revoke_revoked
    mov qword [r13+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_REVOKED
    mov rdi,r12
    mov rsi,r13
    call capability_sign
    jmp .cap_revoke_done
.cap_revoke_revoked:
    mov eax,NEBO_CAPABILITY_STATUS_REVOKED
.cap_revoke_done:
    pop r13
    pop r12
    pop rbx
    ret
.cap_revoke_argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret

; rdi=authority, rsi=capability, rdx=required effects, rcx=required constraint,
; r8=current exact scope, r9=cost. Successful return consumes cost and re-MACs
; the record before the caller may perform its effect.
NEBOC_ABI_FUNCTION nebo_capability_precheck
    test rdi,rdi
    jz .precheck_argument
    test rsi,rsi
    jz .precheck_argument
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    push r9
    sub rsp,8
    call capability_validate
    test eax,eax
    jnz .precheck_done_stack
    cmp qword [r13+NEBO_CAPABILITY_STATE_OFFSET],NEBO_CAPABILITY_ACTIVE
    jne .precheck_revoked
    test r14,r14
    jz .precheck_denied
    mov rax,r14
    and rax,~NEBO_EFFECT_MASK
    jnz .precheck_denied
    mov rax,[r13+NEBO_CAPABILITY_EFFECTS_OFFSET]
    not rax
    and rax,r14
    jnz .precheck_denied
    mov rax,[r13+NEBO_CAPABILITY_CONSTRAINT_OFFSET]
    not rax
    mov rdx,r15
    and rdx,rax
    jnz .precheck_denied
    cmp rbx,[r13+NEBO_CAPABILITY_SCOPE_OFFSET]
    jne .precheck_scope
    mov r9,[rsp+8]
    test r9,r9
    jz .precheck_argument_stack
    cmp r9,[r13+NEBO_CAPABILITY_BUDGET_OFFSET]
    ja .precheck_budget
    sub [r13+NEBO_CAPABILITY_BUDGET_OFFSET],r9
    mov rdi,r12
    mov rsi,r13
    call capability_sign
    jmp .precheck_done_stack
.precheck_revoked:
    mov eax,NEBO_CAPABILITY_STATUS_REVOKED
    jmp .precheck_done_stack
.precheck_denied:
    mov eax,NEBO_CAPABILITY_STATUS_DENIED
    jmp .precheck_done_stack
.precheck_scope:
    mov eax,NEBO_CAPABILITY_STATUS_SCOPE
    jmp .precheck_done_stack
.precheck_budget:
    mov eax,NEBO_CAPABILITY_STATUS_BUDGET
    jmp .precheck_done_stack
.precheck_argument_stack:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
.precheck_done_stack:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.precheck_argument:
    mov eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    ret

; rdi=kind -> allowed effect mask, or UINT64_MAX.
capability_kind_mask:
    cmp rdi,NEBO_CAPABILITY_FILE
    je .kind_file
    cmp rdi,NEBO_CAPABILITY_NETWORK
    je .kind_network
    cmp rdi,NEBO_CAPABILITY_PROCESS
    je .kind_process
    cmp rdi,NEBO_CAPABILITY_ENTROPY
    je .kind_entropy
    cmp rdi,NEBO_CAPABILITY_CLOCK
    je .kind_clock
    cmp rdi,NEBO_CAPABILITY_CONSOLE
    je .kind_console
    mov rax,-1
    ret
.kind_file:
    mov eax,NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
    ret
.kind_network:
    mov eax,NEBO_EFFECT_NETWORK
    ret
.kind_process:
    mov eax,NEBO_EFFECT_PROCESS
    ret
.kind_entropy:
    mov eax,NEBO_EFFECT_RANDOM
    ret
.kind_clock:
    mov eax,NEBO_EFFECT_CLOCK
    ret
.kind_console:
    mov eax,NEBO_EFFECT_CONSOLE_READ | NEBO_EFFECT_CONSOLE_WRITE
    ret

; rdi=authority. eax=status.
capability_authority_validate:
    test rdi,rdi
    jz .authority_bad
    test rdi,7
    jnz .authority_bad
    mov rax,NEBO_AUTHORITY_MAGIC
    cmp [rdi+NEBO_AUTHORITY_MAGIC_OFFSET],rax
    jne .authority_bad
    cmp qword [rdi+NEBO_AUTHORITY_VERSION_OFFSET],NEBO_AUTHORITY_VERSION
    jne .authority_bad
    cmp qword [rdi+NEBO_AUTHORITY_ID_OFFSET],0
    je .authority_bad
    cmp qword [rdi+NEBO_AUTHORITY_EPOCH_OFFSET],0
    je .authority_bad
    cmp qword [rdi+NEBO_AUTHORITY_STATE_OFFSET],NEBO_AUTHORITY_ACTIVE
    jne .authority_bad
    xor eax,eax
    ret
.authority_bad:
    mov eax,NEBO_CAPABILITY_STATUS_AUTHORITY
    ret

; rdi=authority, rsi=capability. Authenticate all state, allowing the caller
; to distinguish a legitimately MACed revoked capability afterwards.
capability_validate:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    call capability_authority_validate
    test eax,eax
    jnz .validate_done
    test r13,r13
    jz .validate_forged
    test r13,7
    jnz .validate_forged
    cmp [r13+NEBO_CAPABILITY_ADDRESS_OFFSET],r13
    jne .validate_serialized
    mov rax,NEBO_CAPABILITY_MAGIC
    cmp [r13+NEBO_CAPABILITY_MAGIC_OFFSET],rax
    jne .validate_forged
    cmp qword [r13+NEBO_CAPABILITY_VERSION_OFFSET],NEBO_CAPABILITY_VERSION
    jne .validate_forged
    mov rax,[r12+NEBO_AUTHORITY_ID_OFFSET]
    cmp [r13+NEBO_CAPABILITY_AUTHORITY_ID_OFFSET],rax
    jne .validate_forged
    mov rax,[r12+NEBO_AUTHORITY_EPOCH_OFFSET]
    cmp [r13+NEBO_CAPABILITY_EPOCH_OFFSET],rax
    jne .validate_epoch
    mov rax,[r13+NEBO_CAPABILITY_STATE_OFFSET]
    cmp rax,NEBO_CAPABILITY_ACTIVE
    je .validate_mac
    cmp rax,NEBO_CAPABILITY_REVOKED
    jne .validate_forged
.validate_mac:
    sub rsp,32
    lea r8,[rsp]
    lea rdi,[r12+NEBO_AUTHORITY_SECRET_OFFSET]
    mov esi,32
    mov rdx,r13
    mov ecx,NEBO_CAPABILITY_SIGNED_BYTES
    call nebo_hmac_sha256
    test eax,eax
    jnz .validate_mac_error
    xor ebx,ebx
    xor ecx,ecx
.validate_compare:
    mov al,[rsp+rcx]
    xor al,[r13+NEBO_CAPABILITY_TAG_OFFSET+rcx]
    or bl,al
    inc rcx
    cmp rcx,32
    jb .validate_compare
    xor ecx,ecx
.validate_wipe:
    mov byte [rsp+rcx],0
    inc rcx
    cmp rcx,32
    jb .validate_wipe
    add rsp,32
    test bl,bl
    jnz .validate_forged
    xor eax,eax
    jmp .validate_done
.validate_mac_error:
    add rsp,32
.validate_forged:
    mov eax,NEBO_CAPABILITY_STATUS_FORGED
    jmp .validate_done
.validate_serialized:
    mov eax,NEBO_CAPABILITY_STATUS_SERIALIZED
    jmp .validate_done
.validate_epoch:
    mov eax,NEBO_CAPABILITY_STATUS_REVOKED
.validate_done:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=authority, rsi=capability. HMAC directly into the record tag.
capability_sign:
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    lea rdi,[r12+NEBO_AUTHORITY_SECRET_OFFSET]
    mov esi,32
    mov rdx,r13
    mov ecx,NEBO_CAPABILITY_SIGNED_BYTES
    lea r8,[r13+NEBO_CAPABILITY_TAG_OFFSET]
    call nebo_hmac_sha256
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
