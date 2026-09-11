; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F07 immutable provenance graph tests.
bits 64
default rel
%include "runtime/provenance/provenance.inc"

extern nebo_capability_authority_init
extern nebo_capability_grant
extern nebo_provenance_init
extern nebo_provenance_record_create
extern nebo_provenance_verify

section .rodata
secret: times 32 db 0x73
source_digest: times 32 db 0x11
transform_digest: times 32 db 0x22
artifact_digest: times 32 db 0x33
missing_digest: times 32 db 0x99
zero_digest: times 32 db 0

section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
capability resb NEBO_CAPABILITY_SIZE
grant_request resb NEBO_CAPABILITY_GRANT_SIZE
init_request resb NEBO_PROVENANCE_INIT_SIZE
state resb NEBO_PROVENANCE_STATE_SIZE
records resb NEBO_PROVENANCE_RECORD_SIZE*4
create_request resb NEBO_PROVENANCE_CREATE_SIZE
verify_request resb NEBO_PROVENANCE_VERIFY_SIZE
root_digest resb 32
child_digest resb 32
verify_digest resb 32
parents resb 64

section .text
grant_file:
    lea rdi,[grant_request]
    mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[authority]
    mov [grant_request+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
    lea rax,[capability]
    mov [grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_FILE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_FILE_WRITE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],1
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],20
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],7
    lea rdi,[grant_request]
    jmp nebo_capability_grant

prepare_init:
    lea rdi,[init_request]
    mov ecx,NEBO_PROVENANCE_INIT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [init_request+NEBO_PROVENANCE_INIT_STATE],rax
    lea rax,[records]
    mov [init_request+NEBO_PROVENANCE_INIT_RECORDS],rax
    mov qword [init_request+NEBO_PROVENANCE_INIT_CAPACITY],4
    lea rax,[authority]
    mov [init_request+NEBO_PROVENANCE_INIT_AUTHORITY],rax
    lea rax,[capability]
    mov [init_request+NEBO_PROVENANCE_INIT_CAPABILITY],rax
    mov qword [init_request+NEBO_PROVENANCE_INIT_SCOPE],7
    ret

prepare_create:
    lea rdi,[create_request]
    mov ecx,NEBO_PROVENANCE_CREATE_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [create_request+NEBO_PROVENANCE_CREATE_STATE],rax
    lea rax,[source_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_SOURCE],rax
    lea rax,[transform_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_TRANSFORM],rax
    lea rax,[artifact_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_ARTIFACT],rax
    mov qword [create_request+NEBO_PROVENANCE_CREATE_POLICY],0x7001
    mov qword [create_request+NEBO_PROVENANCE_CREATE_QUALITY],900000
    lea rax,[root_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_DIGEST],rax
    ret

prepare_verify:
    lea rdi,[verify_request]
    mov ecx,NEBO_PROVENANCE_VERIFY_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [verify_request+NEBO_PROVENANCE_VERIFY_STATE],rax
    mov qword [verify_request+NEBO_PROVENANCE_VERIFY_INDEX],1
    lea rax,[verify_digest]
    mov [verify_request+NEBO_PROVENANCE_VERIFY_DIGEST],rax
    ret

global _start
_start:
    ; 1-4. Initialize authenticated bounded record storage.
    lea rdi,[authority]
    mov esi,0x2507
    lea rdx,[secret]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail1
    call grant_file
    test eax,eax
    jnz .fail2
    call prepare_init
    lea rdi,[init_request]
    call nebo_provenance_init
    test eax,eax
    jnz .fail3
    mov rax,NEBO_PROVENANCE_MAGIC
    cmp [state+NEBO_PROVENANCE_STATE_MAGIC],rax
    jne .fail4

    ; 5-10. Root record binds exact digests, policy, quality and capability.
    call prepare_create
    lea rdi,[create_request]
    call nebo_provenance_record_create
    test eax,eax
    jnz .fail5
    cmp qword [create_request+NEBO_PROVENANCE_CREATE_INDEX],1
    jne .fail6
    cmp qword [root_digest],0
    je .fail7
    cmp qword [records+NEBO_PROVENANCE_RECORD_STATE],NEBO_PROVENANCE_RECORD_IMMUTABLE
    jne .fail8
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],19
    jne .fail9
    cmp qword [state+NEBO_PROVENANCE_STATE_COUNT],1
    jne .fail10

    ; 11-13. Verification recomputes the full stable record digest.
    call prepare_verify
    lea rdi,[verify_request]
    call nebo_provenance_verify
    test eax,eax
    jnz .fail11
    mov rax,[root_digest]
    cmp [verify_digest],rax
    jne .fail12
    mov rax,[root_digest+24]
    cmp [state+NEBO_PROVENANCE_STATE_CHAIN_DIGEST+24],rax
    jne .fail13

    ; 14-17. A child may reference only an existing exact parent digest.
    lea rsi,[root_digest]
    lea rdi,[parents]
    mov ecx,4
    rep movsq
    call prepare_create
    lea rax,[parents]
    mov [create_request+NEBO_PROVENANCE_CREATE_PARENTS],rax
    mov qword [create_request+NEBO_PROVENANCE_CREATE_PARENT_COUNT],1
    lea rax,[child_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_DIGEST],rax
    lea rdi,[create_request]
    call nebo_provenance_record_create
    test eax,eax
    jnz .fail14
    cmp qword [create_request+NEBO_PROVENANCE_CREATE_INDEX],2
    jne .fail15
    call prepare_verify
    mov qword [verify_request+NEBO_PROVENANCE_VERIFY_INDEX],2
    lea rdi,[verify_request]
    call nebo_provenance_verify
    test eax,eax
    jnz .fail16
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],18
    jne .fail17

    ; 18-22. Duplicate, missing, cyclic and excessive quality inputs are atomic.
    lea rsi,[root_digest]
    lea rdi,[parents+32]
    mov ecx,4
    rep movsq
    call prepare_create
    lea rax,[parents]
    mov [create_request+NEBO_PROVENANCE_CREATE_PARENTS],rax
    mov qword [create_request+NEBO_PROVENANCE_CREATE_PARENT_COUNT],2
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_DUPLICATE_PARENT
    jne .fail18
    call prepare_create
    lea rax,[zero_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_SOURCE],rax
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_MISSING_DIGEST
    jne .fail19
    call prepare_create
    lea rax,[missing_digest]
    mov [create_request+NEBO_PROVENANCE_CREATE_PARENTS],rax
    mov qword [create_request+NEBO_PROVENANCE_CREATE_PARENT_COUNT],1
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_CYCLE
    jne .fail20
    call prepare_create
    mov qword [create_request+NEBO_PROVENANCE_CREATE_QUALITY],1000001
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_QUALITY
    jne .fail21
    cmp qword [state+NEBO_PROVENANCE_STATE_COUNT],2
    jne .fail22

    ; 23-25. Rewrites and parent tampering are detected by verification.
    xor qword [records+NEBO_PROVENANCE_RECORD_POLICY],1
    call prepare_verify
    lea rdi,[verify_request]
    call nebo_provenance_verify
    cmp eax,NEBO_PROVENANCE_STATUS_IMMUTABLE
    jne .fail23
    xor qword [records+NEBO_PROVENANCE_RECORD_POLICY],1
    xor byte [records+NEBO_PROVENANCE_RECORD_SIZE+NEBO_PROVENANCE_RECORD_PARENTS],1
    call prepare_verify
    mov qword [verify_request+NEBO_PROVENANCE_VERIFY_INDEX],2
    lea rdi,[verify_request]
    call nebo_provenance_verify
    cmp eax,NEBO_PROVENANCE_STATUS_CYCLE
    jne .fail24
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],18
    jne .fail25

    ; 26-29. Storage and capability limits refuse before publication.
    xor byte [records+NEBO_PROVENANCE_RECORD_SIZE+NEBO_PROVENANCE_RECORD_PARENTS],1
    mov qword [state+NEBO_PROVENANCE_STATE_COUNT],4
    call prepare_create
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_LIMIT
    jne .fail26
    mov qword [state+NEBO_PROVENANCE_STATE_COUNT],2
    mov qword [state+NEBO_PROVENANCE_STATE_SCOPE],8
    lea rdi,[create_request]
    call nebo_provenance_record_create
    cmp eax,NEBO_PROVENANCE_STATUS_CAPABILITY
    jne .fail27
    cmp qword [state+NEBO_PROVENANCE_STATE_COUNT],2
    jne .fail28
    xor edi,edi
    call nebo_provenance_verify
    cmp eax,NEBO_PROVENANCE_STATUS_INVALID_ARGUMENT
    jne .fail29

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
%rep 29
FAIL_LABEL i
%assign i i+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
