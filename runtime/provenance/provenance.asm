; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F07 immutable versioned SHA-256 provenance records.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/crypto/sha256.inc"
%include "runtime/provenance/provenance.inc"

extern nebo_capability_precheck

section .text

; Local tail bridges keep the internal call graph explicit for the ABI audit.
provenance_capability_precheck:
    jmp nebo_capability_precheck

provenance_sha256_hash:
    jmp nebo_sha256_hash

; rdi=32-byte digest -> eax=1 if nonzero.
provenance_digest_nonzero:
    mov rax,[rdi]
    or rax,[rdi+8]
    or rax,[rdi+16]
    or rax,[rdi+24]
    setnz al
    movzx eax,al
    ret

; rdi/rsi=32-byte digests -> eax=1 if equal, constant work.
provenance_digest_equal:
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

NEBOC_ABI_FUNCTION nebo_provenance_init
    test rdi,rdi
    jz .init_invalid
    test rdi,7
    jnz .init_invalid
    push r12
    push r13
    mov r12,rdi
    mov r13,[r12+NEBO_PROVENANCE_INIT_STATE]
    test r13,r13
    jz .init_invalid_saved
    test r13,7
    jnz .init_invalid_saved
    cmp qword [r12+NEBO_PROVENANCE_INIT_RECORDS],0
    je .init_invalid_saved
    mov rax,[r12+NEBO_PROVENANCE_INIT_CAPACITY]
    test rax,rax
    jz .init_invalid_saved
    cmp rax,NEBO_PROVENANCE_MAX_RECORDS
    ja .init_limit
    cmp qword [r12+NEBO_PROVENANCE_INIT_AUTHORITY],0
    je .init_invalid_saved
    cmp qword [r12+NEBO_PROVENANCE_INIT_CAPABILITY],0
    je .init_invalid_saved
    mov rdi,r13
    mov ecx,NEBO_PROVENANCE_STATE_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,NEBO_PROVENANCE_MAGIC
    mov [r13+NEBO_PROVENANCE_STATE_MAGIC],rax
    mov rax,[r12+NEBO_PROVENANCE_INIT_RECORDS]
    mov [r13+NEBO_PROVENANCE_STATE_RECORDS],rax
    mov rax,[r12+NEBO_PROVENANCE_INIT_CAPACITY]
    mov [r13+NEBO_PROVENANCE_STATE_CAPACITY],rax
    mov rax,[r12+NEBO_PROVENANCE_INIT_AUTHORITY]
    mov [r13+NEBO_PROVENANCE_STATE_AUTHORITY],rax
    mov rax,[r12+NEBO_PROVENANCE_INIT_CAPABILITY]
    mov [r13+NEBO_PROVENANCE_STATE_CAPABILITY],rax
    mov rax,[r12+NEBO_PROVENANCE_INIT_SCOPE]
    mov [r13+NEBO_PROVENANCE_STATE_SCOPE],rax
    xor eax,eax
    jmp .init_done
.init_limit:
    mov eax,NEBO_PROVENANCE_STATUS_LIMIT
    jmp .init_done
.init_invalid_saved:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
.init_done:
    pop r13
    pop r12
    ret
.init_invalid:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
    ret

; rdi=80-byte create request. Parents must already exist, making the graph a DAG.
NEBOC_ABI_FUNCTION nebo_provenance_record_create
    test rdi,rdi
    jz .create_invalid
    test rdi,7
    jnz .create_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov qword [r12+NEBO_PROVENANCE_CREATE_INDEX],0
    mov r13,[r12+NEBO_PROVENANCE_CREATE_STATE]
    test r13,r13
    jz .create_invalid_saved
    mov rax,NEBO_PROVENANCE_MAGIC
    cmp [r13+NEBO_PROVENANCE_STATE_MAGIC],rax
    jne .create_invalid_saved
    cmp qword [r12+NEBO_PROVENANCE_CREATE_DIGEST],0
    je .create_invalid_saved
    mov rdi,[r12+NEBO_PROVENANCE_CREATE_SOURCE]
    test rdi,rdi
    jz .create_missing
    call provenance_digest_nonzero
    test eax,eax
    jz .create_missing
    mov rdi,[r12+NEBO_PROVENANCE_CREATE_TRANSFORM]
    test rdi,rdi
    jz .create_missing
    call provenance_digest_nonzero
    test eax,eax
    jz .create_missing
    mov rdi,[r12+NEBO_PROVENANCE_CREATE_ARTIFACT]
    test rdi,rdi
    jz .create_missing
    call provenance_digest_nonzero
    test eax,eax
    jz .create_missing
    cmp qword [r12+NEBO_PROVENANCE_CREATE_POLICY],0
    je .create_invalid_saved
    cmp qword [r12+NEBO_PROVENANCE_CREATE_QUALITY],NEBO_PROVENANCE_QUALITY_SCALE
    ja .create_quality
    mov r14,[r12+NEBO_PROVENANCE_CREATE_PARENT_COUNT]
    cmp r14,NEBO_PROVENANCE_MAX_PARENTS
    ja .create_limit
    test r14,r14
    jz .create_parents_ok
    cmp qword [r12+NEBO_PROVENANCE_CREATE_PARENTS],0
    je .create_invalid_saved
    xor ebx,ebx
.create_parent_outer:
    mov r15,[r12+NEBO_PROVENANCE_CREATE_PARENTS]
    mov rax,rbx
    shl rax,5
    add r15,rax
    mov rdi,r15
    call provenance_digest_nonzero
    test eax,eax
    jz .create_missing
    ; Reject duplicate parent digests.
    xor ecx,ecx
.create_duplicate_scan:
    cmp rcx,rbx
    jae .create_find_existing
    mov rsi,[r12+NEBO_PROVENANCE_CREATE_PARENTS]
    mov rax,rcx
    shl rax,5
    add rsi,rax
    mov rdi,r15
    call provenance_digest_equal
    test eax,eax
    jnz .create_duplicate
    inc rcx
    jmp .create_duplicate_scan
.create_find_existing:
    xor ecx,ecx
    mov rdx,[r13+NEBO_PROVENANCE_STATE_RECORDS]
.create_existing_scan:
    cmp rcx,[r13+NEBO_PROVENANCE_STATE_COUNT]
    jae .create_cycle
    mov rax,rcx
    imul rax,NEBO_PROVENANCE_RECORD_SIZE
    lea rsi,[rdx+rax+NEBO_PROVENANCE_RECORD_DIGEST]
    mov rdi,r15
    call provenance_digest_equal
    test eax,eax
    jnz .create_parent_found
    inc rcx
    jmp .create_existing_scan
.create_parent_found:
    inc rbx
    cmp rbx,r14
    jb .create_parent_outer
.create_parents_ok:
    mov rax,[r13+NEBO_PROVENANCE_STATE_COUNT]
    cmp rax,[r13+NEBO_PROVENANCE_STATE_CAPACITY]
    jae .create_limit
    ; Consume File-write authority only after every graph and shape check.
    mov rdi,[r13+NEBO_PROVENANCE_STATE_AUTHORITY]
    mov rsi,[r13+NEBO_PROVENANCE_STATE_CAPABILITY]
    mov edx,NEBO_EFFECT_FILE_WRITE
    mov ecx,1
    mov r8,[r13+NEBO_PROVENANCE_STATE_SCOPE]
    mov r9d,1
    call provenance_capability_precheck
    test eax,eax
    jnz .create_capability
    mov rax,[r13+NEBO_PROVENANCE_STATE_COUNT]
    imul rax,NEBO_PROVENANCE_RECORD_SIZE
    mov r15,[r13+NEBO_PROVENANCE_STATE_RECORDS]
    add r15,rax
    mov rdi,r15
    mov ecx,NEBO_PROVENANCE_RECORD_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,NEBO_PROVENANCE_MAGIC
    mov [r15+NEBO_PROVENANCE_RECORD_MAGIC],rax
    mov qword [r15+NEBO_PROVENANCE_RECORD_VERSION],NEBO_PROVENANCE_VERSION
    mov rax,[r13+NEBO_PROVENANCE_STATE_COUNT]
    inc rax
    mov [r15+NEBO_PROVENANCE_RECORD_INDEX],rax
    mov [r12+NEBO_PROVENANCE_CREATE_INDEX],rax
    mov rax,[r12+NEBO_PROVENANCE_CREATE_POLICY]
    mov [r15+NEBO_PROVENANCE_RECORD_POLICY],rax
    mov rax,[r12+NEBO_PROVENANCE_CREATE_QUALITY]
    mov [r15+NEBO_PROVENANCE_RECORD_QUALITY],rax
    mov [r15+NEBO_PROVENANCE_RECORD_PARENT_COUNT],r14
    mov rsi,[r12+NEBO_PROVENANCE_CREATE_SOURCE]
    lea rdi,[r15+NEBO_PROVENANCE_RECORD_SOURCE]
    mov ecx,4
    rep movsq
    mov rsi,[r12+NEBO_PROVENANCE_CREATE_TRANSFORM]
    lea rdi,[r15+NEBO_PROVENANCE_RECORD_TRANSFORM]
    mov ecx,4
    rep movsq
    mov rsi,[r12+NEBO_PROVENANCE_CREATE_ARTIFACT]
    lea rdi,[r15+NEBO_PROVENANCE_RECORD_ARTIFACT]
    mov ecx,4
    rep movsq
    test r14,r14
    jz .create_hash
    mov rsi,[r12+NEBO_PROVENANCE_CREATE_PARENTS]
    lea rdi,[r15+NEBO_PROVENANCE_RECORD_PARENTS]
    mov rcx,r14
    shl rcx,2
    rep movsq
.create_hash:
    mov rdi,r15
    mov esi,NEBO_PROVENANCE_RECORD_HASHED_BYTES
    lea rdx,[r15+NEBO_PROVENANCE_RECORD_DIGEST]
    call provenance_sha256_hash
    test eax,eax
    jnz .create_invalid_saved
    mov qword [r15+NEBO_PROVENANCE_RECORD_STATE],NEBO_PROVENANCE_RECORD_IMMUTABLE
    lea rsi,[r15+NEBO_PROVENANCE_RECORD_DIGEST]
    lea rdi,[r13+NEBO_PROVENANCE_STATE_CHAIN_DIGEST]
    mov ecx,4
    rep movsq
    lea rsi,[r15+NEBO_PROVENANCE_RECORD_DIGEST]
    mov rdi,[r12+NEBO_PROVENANCE_CREATE_DIGEST]
    mov ecx,4
    rep movsq
    inc qword [r13+NEBO_PROVENANCE_STATE_COUNT]
    xor eax,eax
    jmp .create_done
.create_missing:
    mov eax,NEBO_PROVENANCE_STATUS_MISSING_DIGEST
    jmp .create_done
.create_duplicate:
    mov eax,NEBO_PROVENANCE_STATUS_DUPLICATE_PARENT
    jmp .create_done
.create_cycle:
    mov eax,NEBO_PROVENANCE_STATUS_CYCLE
    jmp .create_done
.create_quality:
    mov eax,NEBO_PROVENANCE_STATUS_QUALITY
    jmp .create_done
.create_limit:
    mov eax,NEBO_PROVENANCE_STATUS_LIMIT
    jmp .create_done
.create_capability:
    mov eax,NEBO_PROVENANCE_STATUS_CAPABILITY
    jmp .create_done
.create_invalid_saved:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
.create_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.create_invalid:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
    ret

; rdi=32-byte verify request. Recomputes record and validates earlier parents.
NEBOC_ABI_FUNCTION nebo_provenance_verify
    test rdi,rdi
    jz .verify_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,32
    mov r12,rdi
    mov qword [r12+NEBO_PROVENANCE_VERIFY_REASON],0
    mov r13,[r12+NEBO_PROVENANCE_VERIFY_STATE]
    test r13,r13
    jz .verify_invalid_saved
    mov rax,NEBO_PROVENANCE_MAGIC
    cmp [r13+NEBO_PROVENANCE_STATE_MAGIC],rax
    jne .verify_invalid_saved
    mov r14,[r12+NEBO_PROVENANCE_VERIFY_INDEX]
    test r14,r14
    jz .verify_invalid_saved
    cmp r14,[r13+NEBO_PROVENANCE_STATE_COUNT]
    ja .verify_invalid_saved
    dec r14
    mov rax,r14
    imul rax,NEBO_PROVENANCE_RECORD_SIZE
    mov r15,[r13+NEBO_PROVENANCE_STATE_RECORDS]
    add r15,rax
    mov rax,NEBO_PROVENANCE_MAGIC
    cmp [r15+NEBO_PROVENANCE_RECORD_MAGIC],rax
    jne .verify_immutable
    cmp qword [r15+NEBO_PROVENANCE_RECORD_VERSION],NEBO_PROVENANCE_VERSION
    jne .verify_immutable
    cmp qword [r15+NEBO_PROVENANCE_RECORD_STATE],NEBO_PROVENANCE_RECORD_IMMUTABLE
    jne .verify_immutable
    mov rbx,[r15+NEBO_PROVENANCE_RECORD_PARENT_COUNT]
    cmp rbx,NEBO_PROVENANCE_MAX_PARENTS
    ja .verify_immutable
    xor ecx,ecx
.verify_parent_outer:
    cmp rcx,rbx
    jae .verify_hash
    lea rdi,[r15+NEBO_PROVENANCE_RECORD_PARENTS]
    mov rax,rcx
    shl rax,5
    add rdi,rax
    xor edx,edx
    mov r8,[r13+NEBO_PROVENANCE_STATE_RECORDS]
.verify_parent_scan:
    cmp rdx,r14
    jae .verify_cycle
    mov rax,rdx
    imul rax,NEBO_PROVENANCE_RECORD_SIZE
    lea rsi,[r8+rax+NEBO_PROVENANCE_RECORD_DIGEST]
    call provenance_digest_equal
    test eax,eax
    jnz .verify_parent_found
    inc rdx
    jmp .verify_parent_scan
.verify_parent_found:
    inc rcx
    jmp .verify_parent_outer
.verify_hash:
    mov rdi,r15
    mov esi,NEBO_PROVENANCE_RECORD_HASHED_BYTES
    mov rdx,rsp
    call provenance_sha256_hash
    test eax,eax
    jnz .verify_invalid_saved
    mov rdi,rsp
    lea rsi,[r15+NEBO_PROVENANCE_RECORD_DIGEST]
    call provenance_digest_equal
    test eax,eax
    jz .verify_immutable
    mov rdi,[r12+NEBO_PROVENANCE_VERIFY_DIGEST]
    test rdi,rdi
    jz .verify_success
    lea rsi,[r15+NEBO_PROVENANCE_RECORD_DIGEST]
    mov ecx,4
    rep movsq
.verify_success:
    xor eax,eax
    jmp .verify_done
.verify_cycle:
    mov qword [r12+NEBO_PROVENANCE_VERIFY_REASON],NEBO_PROVENANCE_STATUS_CYCLE
    mov eax,NEBO_PROVENANCE_STATUS_CYCLE
    jmp .verify_done
.verify_immutable:
    mov qword [r12+NEBO_PROVENANCE_VERIFY_REASON],NEBO_PROVENANCE_STATUS_IMMUTABLE
    mov eax,NEBO_PROVENANCE_STATUS_IMMUTABLE
    jmp .verify_done
.verify_invalid_saved:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
.verify_done:
    add rsp,32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.verify_invalid:
    mov eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
