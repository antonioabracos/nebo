; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F08 append-only metadata audit chain and bounded explanation API.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crypto/sha256.inc"
%include "runtime/security/audit.inc"

section .text
audit_sha256_hash:
    jmp nebo_sha256_hash

audit_digest_nonzero:
    mov rax,[rdi]
    or rax,[rdi+8]
    or rax,[rdi+16]
    or rax,[rdi+24]
    setnz al
    movzx eax,al
    ret

audit_digest_equal:
    mov rax,[rdi]
    xor rax,[rsi]
    mov r10,[rdi+8]
    xor r10,[rsi+8]
    or rax,r10
    mov r10,[rdi+16]
    xor r10,[rsi+16]
    or rax,r10
    mov r10,[rdi+24]
    xor r10,[rsi+24]
    or rax,r10
    sete al
    movzx eax,al
    ret

NEBOC_ABI_FUNCTION nebo_audit_init
    test rdi,rdi
    jz .init_invalid
    test rdi,7
    jnz .init_invalid
    mov r10,[rdi+NEBO_AUDIT_INIT_STATE]
    test r10,r10
    jz .init_invalid
    test r10,7
    jnz .init_invalid
    mov r11,[rdi+NEBO_AUDIT_INIT_RECORDS]
    test r11,r11
    jz .init_invalid
    test r11,7
    jnz .init_invalid
    mov rax,[rdi+NEBO_AUDIT_INIT_CAPACITY]
    test rax,rax
    jz .init_invalid
    cmp rax,NEBO_AUDIT_MAX_RECORDS
    ja .init_limit
    cmp qword [rdi+NEBO_AUDIT_INIT_AUTHORITY],0
    je .init_invalid
    cmp qword [rdi+NEBO_AUDIT_INIT_SCOPE],0
    je .init_invalid
    cmp qword [rdi+NEBO_AUDIT_INIT_WRITE_BUDGET],0
    je .init_invalid
    cmp qword [rdi+NEBO_AUDIT_INIT_QUERY_BUDGET],0
    je .init_invalid
    push rdi
    mov rdi,r10
    mov ecx,NEBO_AUDIT_STATE_SIZE/8
    xor eax,eax
    rep stosq
    pop rdi
    mov rax,NEBO_AUDIT_MAGIC
    mov [r10+NEBO_AUDIT_STATE_MAGIC],rax
    mov [r10+NEBO_AUDIT_STATE_RECORDS],r11
    mov rax,[rdi+NEBO_AUDIT_INIT_CAPACITY]
    mov [r10+NEBO_AUDIT_STATE_CAPACITY],rax
    mov rax,[rdi+NEBO_AUDIT_INIT_AUTHORITY]
    mov [r10+NEBO_AUDIT_STATE_AUTHORITY],rax
    mov rax,[rdi+NEBO_AUDIT_INIT_SCOPE]
    mov [r10+NEBO_AUDIT_STATE_SCOPE],rax
    mov rax,[rdi+NEBO_AUDIT_INIT_WRITE_BUDGET]
    mov [r10+NEBO_AUDIT_STATE_WRITE_BUDGET],rax
    mov rax,[rdi+NEBO_AUDIT_INIT_QUERY_BUDGET]
    mov [r10+NEBO_AUDIT_STATE_QUERY_BUDGET],rax
    xor eax,eax
    ret
.init_limit:
    mov eax,NEBO_AUDIT_STATUS_LIMIT
    ret
.init_invalid:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_audit_append
    test rdi,rdi
    jz .append_invalid
    test rdi,7
    jnz .append_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov qword [r12+NEBO_AUDIT_APPEND_INDEX],0
    mov r13,[r12+NEBO_AUDIT_APPEND_STATE]
    test r13,r13
    jz .append_invalid_saved
    mov rax,NEBO_AUDIT_MAGIC
    cmp [r13+NEBO_AUDIT_STATE_MAGIC],rax
    jne .append_invalid_saved
    mov rax,[r12+NEBO_AUDIT_APPEND_AUTHORITY]
    test rax,rax
    jz .append_authority
    cmp rax,[r13+NEBO_AUDIT_STATE_AUTHORITY]
    jne .append_authority
    mov rax,[r12+NEBO_AUDIT_APPEND_SCOPE]
    cmp rax,[r13+NEBO_AUDIT_STATE_SCOPE]
    jne .append_scope
    cmp qword [r13+NEBO_AUDIT_STATE_WRITE_BUDGET],0
    je .append_budget
    mov rax,[r13+NEBO_AUDIT_STATE_COUNT]
    cmp rax,[r13+NEBO_AUDIT_STATE_CAPACITY]
    jae .append_limit
    mov rax,[r12+NEBO_AUDIT_APPEND_EVENT_KIND]
    test rax,rax
    jz .append_invalid_saved
    cmp rax,NEBO_AUDIT_MAX_EVENT_KIND
    ja .append_limit
    mov rax,[r12+NEBO_AUDIT_APPEND_EFFECT_MASK]
    test rax,rax
    jz .append_effect
    mov rcx,rax
    and rcx,0xffffffffffffc000
    jnz .append_effect
    mov rax,[r12+NEBO_AUDIT_APPEND_CAPABILITY_KIND]
    test rax,rax
    jz .append_capability
    cmp rax,NEBO_AUDIT_MAX_CAPABILITY_KIND
    ja .append_capability
    mov r14,[r12+NEBO_AUDIT_APPEND_DECISION]
    test r14,r14
    jz .append_decision
    cmp r14,NEBO_AUDIT_DECISION_ERROR
    ja .append_decision
    mov rax,[r12+NEBO_AUDIT_APPEND_ERROR_CLASS]
    cmp rax,NEBO_AUDIT_MAX_ERROR_CLASS
    ja .append_error
    cmp r14,NEBO_AUDIT_DECISION_ALLOW
    jne .append_error_required
    test rax,rax
    jnz .append_error
    jmp .append_error_ok
.append_error_required:
    test rax,rax
    jz .append_error
.append_error_ok:
    cmp qword [r12+NEBO_AUDIT_APPEND_POLICY_ID],0
    je .append_invalid_saved
    cmp qword [r12+NEBO_AUDIT_APPEND_PURPOSE_ID],0
    je .append_invalid_saved
    cmp qword [r12+NEBO_AUDIT_APPEND_DIGEST],0
    je .append_invalid_saved
    mov rdi,[r12+NEBO_AUDIT_APPEND_SUBJECT_DIGEST]
    test rdi,rdi
    jz .append_missing
    call audit_digest_nonzero
    test eax,eax
    jz .append_missing
    mov rax,[r13+NEBO_AUDIT_STATE_COUNT]
    imul rax,NEBO_AUDIT_RECORD_SIZE
    mov r15,[r13+NEBO_AUDIT_STATE_RECORDS]
    add r15,rax
    mov rdi,r15
    mov ecx,NEBO_AUDIT_RECORD_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,NEBO_AUDIT_MAGIC
    mov [r15+NEBO_AUDIT_RECORD_MAGIC],rax
    mov qword [r15+NEBO_AUDIT_RECORD_VERSION],NEBO_AUDIT_VERSION
    mov rax,[r13+NEBO_AUDIT_STATE_COUNT]
    inc rax
    mov [r15+NEBO_AUDIT_RECORD_INDEX],rax
    mov [r12+NEBO_AUDIT_APPEND_INDEX],rax
    mov rax,[r12+NEBO_AUDIT_APPEND_EVENT_KIND]
    mov [r15+NEBO_AUDIT_RECORD_EVENT_KIND],rax
    mov rax,[r12+NEBO_AUDIT_APPEND_EFFECT_MASK]
    mov [r15+NEBO_AUDIT_RECORD_EFFECT_MASK],rax
    mov rax,[r12+NEBO_AUDIT_APPEND_CAPABILITY_KIND]
    mov [r15+NEBO_AUDIT_RECORD_CAPABILITY_KIND],rax
    mov [r15+NEBO_AUDIT_RECORD_DECISION],r14
    mov rax,[r12+NEBO_AUDIT_APPEND_ERROR_CLASS]
    mov [r15+NEBO_AUDIT_RECORD_ERROR_CLASS],rax
    mov rax,[r12+NEBO_AUDIT_APPEND_POLICY_ID]
    mov [r15+NEBO_AUDIT_RECORD_POLICY_ID],rax
    mov rax,[r12+NEBO_AUDIT_APPEND_PURPOSE_ID]
    mov [r15+NEBO_AUDIT_RECORD_PURPOSE_ID],rax
    mov rsi,[r12+NEBO_AUDIT_APPEND_SUBJECT_DIGEST]
    lea rdi,[r15+NEBO_AUDIT_RECORD_SUBJECT_DIGEST]
    mov ecx,4
    rep movsq
    lea rsi,[r13+NEBO_AUDIT_STATE_CHAIN_DIGEST]
    lea rdi,[r15+NEBO_AUDIT_RECORD_PREVIOUS_DIGEST]
    mov ecx,4
    rep movsq
    mov rdi,r15
    mov esi,NEBO_AUDIT_RECORD_HASHED_BYTES
    lea rdx,[r15+NEBO_AUDIT_RECORD_DIGEST]
    call audit_sha256_hash
    test eax,eax
    jnz .append_hash_failure
    mov qword [r15+NEBO_AUDIT_RECORD_STATE],NEBO_AUDIT_RECORD_IMMUTABLE
    lea rsi,[r15+NEBO_AUDIT_RECORD_DIGEST]
    lea rdi,[r13+NEBO_AUDIT_STATE_CHAIN_DIGEST]
    mov ecx,4
    rep movsq
    lea rsi,[r15+NEBO_AUDIT_RECORD_DIGEST]
    mov rdi,[r12+NEBO_AUDIT_APPEND_DIGEST]
    mov ecx,4
    rep movsq
    inc qword [r13+NEBO_AUDIT_STATE_COUNT]
    dec qword [r13+NEBO_AUDIT_STATE_WRITE_BUDGET]
    xor eax,eax
    jmp .append_done
.append_hash_failure:
    mov rdi,r15
    mov ecx,NEBO_AUDIT_RECORD_SIZE/8
    xor eax,eax
    rep stosq
    mov qword [r12+NEBO_AUDIT_APPEND_INDEX],0
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
    jmp .append_done
.append_missing:
    mov eax,NEBO_AUDIT_STATUS_MISSING_DIGEST
    jmp .append_done
.append_limit:
    mov eax,NEBO_AUDIT_STATUS_LIMIT
    jmp .append_done
.append_authority:
    mov eax,NEBO_AUDIT_STATUS_AUTHORITY
    jmp .append_done
.append_scope:
    mov eax,NEBO_AUDIT_STATUS_SCOPE
    jmp .append_done
.append_effect:
    mov eax,NEBO_AUDIT_STATUS_EFFECT
    jmp .append_done
.append_capability:
    mov eax,NEBO_AUDIT_STATUS_CAPABILITY
    jmp .append_done
.append_decision:
    mov eax,NEBO_AUDIT_STATUS_DECISION
    jmp .append_done
.append_error:
    mov eax,NEBO_AUDIT_STATUS_ERROR_CLASS
    jmp .append_done
.append_budget:
    mov eax,NEBO_AUDIT_STATUS_BUDGET
    jmp .append_done
.append_invalid_saved:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
.append_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.append_invalid:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_audit_verify
    test rdi,rdi
    jz .verify_invalid
    test rdi,7
    jnz .verify_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov qword [r12+NEBO_AUDIT_VERIFY_REASON],0
    mov r13,[r12+NEBO_AUDIT_VERIFY_STATE]
    test r13,r13
    jz .verify_invalid_saved
    mov rax,NEBO_AUDIT_MAGIC
    cmp [r13+NEBO_AUDIT_STATE_MAGIC],rax
    jne .verify_invalid_saved
    cmp qword [r12+NEBO_AUDIT_VERIFY_DIGEST],0
    je .verify_invalid_saved
    mov r14,[r12+NEBO_AUDIT_VERIFY_INDEX]
    test r14,r14
    jz .verify_not_found
    cmp r14,[r13+NEBO_AUDIT_STATE_COUNT]
    ja .verify_not_found
    mov rax,r14
    dec rax
    imul rax,NEBO_AUDIT_RECORD_SIZE
    mov r15,[r13+NEBO_AUDIT_STATE_RECORDS]
    add r15,rax
    mov rax,NEBO_AUDIT_MAGIC
    cmp [r15+NEBO_AUDIT_RECORD_MAGIC],rax
    jne .verify_version
    cmp qword [r15+NEBO_AUDIT_RECORD_VERSION],NEBO_AUDIT_VERSION
    jne .verify_version
    cmp [r15+NEBO_AUDIT_RECORD_INDEX],r14
    jne .verify_chain
    cmp qword [r15+NEBO_AUDIT_RECORD_STATE],NEBO_AUDIT_RECORD_IMMUTABLE
    jne .verify_immutable
    cmp r14,1
    jne .verify_previous
    lea rdi,[r15+NEBO_AUDIT_RECORD_PREVIOUS_DIGEST]
    call audit_digest_nonzero
    test eax,eax
    jnz .verify_chain
    jmp .verify_hash
.verify_previous:
    lea rsi,[r15-NEBO_AUDIT_RECORD_SIZE+NEBO_AUDIT_RECORD_DIGEST]
    lea rdi,[r15+NEBO_AUDIT_RECORD_PREVIOUS_DIGEST]
    call audit_digest_equal
    test eax,eax
    jz .verify_chain
.verify_hash:
    mov rdi,r15
    mov esi,NEBO_AUDIT_RECORD_HASHED_BYTES
    mov rdx,rsp
    call audit_sha256_hash
    test eax,eax
    jnz .verify_invalid_saved
    mov rdi,rsp
    lea rsi,[r15+NEBO_AUDIT_RECORD_DIGEST]
    call audit_digest_equal
    test eax,eax
    jz .verify_chain
    mov rsi,rsp
    mov rdi,[r12+NEBO_AUDIT_VERIFY_DIGEST]
    mov ecx,4
    rep movsq
    xor eax,eax
    jmp .verify_done
.verify_version:
    mov eax,NEBO_AUDIT_STATUS_VERSION
    jmp .verify_reason
.verify_immutable:
    mov eax,NEBO_AUDIT_STATUS_IMMUTABLE
    jmp .verify_reason
.verify_chain:
    mov eax,NEBO_AUDIT_STATUS_CHAIN
    jmp .verify_reason
.verify_not_found:
    mov eax,NEBO_AUDIT_STATUS_NOT_FOUND
    jmp .verify_reason
.verify_invalid_saved:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
.verify_reason:
    mov [r12+NEBO_AUDIT_VERIFY_REASON],rax
.verify_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.verify_invalid:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_audit_query_explain
    test rdi,rdi
    jz .query_invalid
    test rdi,7
    jnz .query_invalid
    mov r10,[rdi+NEBO_AUDIT_QUERY_STATE]
    test r10,r10
    jz .query_invalid
    mov rax,NEBO_AUDIT_MAGIC
    cmp [r10+NEBO_AUDIT_STATE_MAGIC],rax
    jne .query_invalid
    mov rax,[rdi+NEBO_AUDIT_QUERY_AUTHORITY]
    test rax,rax
    jz .query_authority
    cmp rax,[r10+NEBO_AUDIT_STATE_AUTHORITY]
    jne .query_authority
    mov rax,[rdi+NEBO_AUDIT_QUERY_SCOPE]
    cmp rax,[r10+NEBO_AUDIT_STATE_SCOPE]
    jne .query_scope
    cmp qword [r10+NEBO_AUDIT_STATE_QUERY_BUDGET],0
    je .query_budget
    mov rcx,[rdi+NEBO_AUDIT_QUERY_INDEX]
    test rcx,rcx
    jz .query_not_found
    cmp rcx,[r10+NEBO_AUDIT_STATE_COUNT]
    ja .query_not_found
    mov r11,[rdi+NEBO_AUDIT_QUERY_OUTPUT]
    test r11,r11
    jz .query_invalid
    test r11,7
    jnz .query_invalid
    dec rcx
    imul rcx,NEBO_AUDIT_RECORD_SIZE
    add rcx,[r10+NEBO_AUDIT_STATE_RECORDS]
    cmp qword [rcx+NEBO_AUDIT_RECORD_STATE],NEBO_AUDIT_RECORD_IMMUTABLE
    jne .query_immutable
    mov rax,[rcx+NEBO_AUDIT_RECORD_EVENT_KIND]
    mov [r11+NEBO_AUDIT_EXPLAIN_EVENT_KIND],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_EFFECT_MASK]
    mov [r11+NEBO_AUDIT_EXPLAIN_EFFECT_MASK],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_CAPABILITY_KIND]
    mov [r11+NEBO_AUDIT_EXPLAIN_CAPABILITY_KIND],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_DECISION]
    mov [r11+NEBO_AUDIT_EXPLAIN_DECISION],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_ERROR_CLASS]
    mov [r11+NEBO_AUDIT_EXPLAIN_ERROR_CLASS],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_POLICY_ID]
    mov [r11+NEBO_AUDIT_EXPLAIN_POLICY_ID],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_PURPOSE_ID]
    mov [r11+NEBO_AUDIT_EXPLAIN_PURPOSE_ID],rax
    mov rax,[rcx+NEBO_AUDIT_RECORD_SUBJECT_DIGEST]
    mov [r11+NEBO_AUDIT_EXPLAIN_SUBJECT_PREFIX],rax
    dec qword [r10+NEBO_AUDIT_STATE_QUERY_BUDGET]
    xor eax,eax
    ret
.query_authority:
    mov eax,NEBO_AUDIT_STATUS_AUTHORITY
    ret
.query_scope:
    mov eax,NEBO_AUDIT_STATUS_SCOPE
    ret
.query_budget:
    mov eax,NEBO_AUDIT_STATUS_BUDGET
    ret
.query_not_found:
    mov eax,NEBO_AUDIT_STATUS_NOT_FOUND
    ret
.query_immutable:
    mov eax,NEBO_AUDIT_STATUS_IMMUTABLE
    ret
.query_invalid:
    mov eax,NEBO_AUDIT_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
