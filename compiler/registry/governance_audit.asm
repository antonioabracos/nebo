; G146 local governance, decision-register and approval audit.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

section .text

; governance_validate(rows*, count, provenance, authority-version, edition).
NEBOC_ABI_FUNCTION neboc_registry_governance_validate
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBOC_REGISTRY_MAX_MIGRATION_ROWS
    ja .limit
    test rdx,rdx
    jz .invalid
    cmp rcx,NEBOC_REGISTRY_AUTHORITY_VERSION
    jne .invalid
    cmp r8,NEBOC_REGISTRY_EDITION_LEGACY
    jb .invalid
    cmp r8,NEBOC_REGISTRY_EDITION_CURRENT
    ja .invalid
    xor r9d,r9d
    xor r10d,r10d
.row:
    mov rax,[rdi+NEBOC_REGISTRY_GOVERNANCE_SEQUENCE_OFFSET]
    test rax,rax
    jz .denied
    cmp rax,r10
    jbe .denied
    mov r10,rax
    cmp qword [rdi+NEBOC_REGISTRY_GOVERNANCE_DECISION_ID_OFFSET],0
    je .denied
    cmp qword [rdi+NEBOC_REGISTRY_GOVERNANCE_APPROVAL_ID_OFFSET],0
    je .denied
    cmp qword [rdi+NEBOC_REGISTRY_GOVERNANCE_ACTOR_ID_OFFSET],0
    je .denied
    cmp [rdi+NEBOC_REGISTRY_GOVERNANCE_AUTHORITY_VERSION_OFFSET],rcx
    jne .denied
    cmp [rdi+NEBOC_REGISTRY_GOVERNANCE_EDITION_OFFSET],r8
    jne .denied
    cmp [rdi+NEBOC_REGISTRY_GOVERNANCE_PROVENANCE_OFFSET],rdx
    jne .denied
    cmp qword [rdi+NEBOC_REGISTRY_GOVERNANCE_FLAGS_OFFSET],NEBOC_REGISTRY_GOVERNANCE_FLAG_ALL
    jne .denied
    add rdi,NEBOC_REGISTRY_GOVERNANCE_ROW_SIZE
    inc r9
    cmp r9,rsi
    jb .row
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Original monotonic-sequence wrapper retained with common status semantics.
NEBOC_ABI_FUNCTION nebo_registry_governance_audit
    test rdi,rdi
    jz .legacy_invalid
    test rsi,rsi
    jz .legacy_invalid
    mov rax,[rdi]
    test rax,rax
    jz .legacy_denied
    add rdi,8
    dec rsi
    jz .legacy_valid
.legacy_loop:
    mov rdx,[rdi]
    cmp rdx,rax
    jbe .legacy_denied
    mov rax,rdx
    add rdi,8
    dec rsi
    jnz .legacy_loop
.legacy_valid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.legacy_denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.legacy_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
