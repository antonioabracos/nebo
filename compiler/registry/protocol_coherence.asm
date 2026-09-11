; G146 compatibility and protocol coherence across editions and targets.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

extern neboc_registry_edition_validate

section .text

; validateRegistryCompatibility(request*, out*).  A well-formed comparison
; always returns OK and records compatible/reasons explicitly.  Malformed
; inputs return a status and preserve out byte-for-byte.
NEBOC_ABI_FUNCTION neboc_registry_validate_compatibility
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdi,7
    jnz .invalid
    test rsi,7
    jnz .invalid
    ; The report is an independent publication and may not overwrite its
    ; request while validation is still reading pointer/count fields.
    mov rax,rdi
    add rax,NEBOC_REGISTRY_COMPAT_REQUEST_SIZE
    jc .invalid
    cmp rsi,rax
    jae .request_disjoint
    mov rax,rsi
    add rax,NEBOC_REGISTRY_COMPAT_RESULT_SIZE
    jc .invalid
    cmp rdi,rax
    jb .invalid
.request_disjoint:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov r12,rdi
    mov r13,rsi
    mov rax,r13
    add rax,NEBOC_REGISTRY_COMPAT_RESULT_SIZE
    jc .invalid_saved
    mov [rsp+8],rax
    mov r14,[r12+NEBOC_REGISTRY_COMPAT_FROM_SNAPSHOT_OFFSET]
    mov r15,[r12+NEBOC_REGISTRY_COMPAT_TO_SNAPSHOT_OFFSET]
    test r14,r14
    jz .invalid_saved
    test r15,r15
    jz .invalid_saved
    test r14,7
    jnz .invalid_saved
    test r15,7
    jnz .invalid_saved
    mov rax,r14
    add rax,NEBOC_REGISTRY_SNAPSHOT_SIZE
    jc .invalid_saved
    cmp r13,rax
    jae .from_snapshot_disjoint
    mov rax,[rsp+8]
    cmp r14,rax
    jb .invalid_saved
.from_snapshot_disjoint:
    mov rax,r15
    add rax,NEBOC_REGISTRY_SNAPSHOT_SIZE
    jc .invalid_saved
    cmp r13,rax
    jae .to_snapshot_disjoint
    mov rax,[rsp+8]
    cmp r15,rax
    jb .invalid_saved
.to_snapshot_disjoint:
    cmp qword [r14+NEBOC_REGISTRY_SNAPSHOT_SCHEMA_OFFSET],NEBOC_REGISTRY_LIFECYCLE_SCHEMA_VERSION
    jne .invalid_saved
    cmp qword [r15+NEBOC_REGISTRY_SNAPSHOT_SCHEMA_OFFSET],NEBOC_REGISTRY_LIFECYCLE_SCHEMA_VERSION
    jne .invalid_saved
    cmp qword [r14+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET],NEBOC_REGISTRY_AUTHORITY_VERSION
    jne .invalid_saved
    cmp qword [r15+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET],NEBOC_REGISTRY_AUTHORITY_VERSION
    jne .invalid_saved
    mov rax,[r14+NEBOC_REGISTRY_SNAPSHOT_MATERIAL_LENGTH_OFFSET]
    test rax,rax
    jz .invalid_saved
    cmp rax,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .limit_saved
    mov rax,[r15+NEBOC_REGISTRY_SNAPSHOT_MATERIAL_LENGTH_OFFSET]
    test rax,rax
    jz .invalid_saved
    cmp rax,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .limit_saved
    mov rbx,[r12+NEBOC_REGISTRY_COMPAT_FROM_EDITION_OFFSET]
    test rbx,rbx
    jz .invalid_saved
    test rbx,7
    jnz .invalid_saved
    mov rax,rbx
    add rax,NEBOC_REGISTRY_EDITION_SIZE
    jc .invalid_saved
    cmp r13,rax
    jae .from_edition_disjoint
    mov rax,[rsp+8]
    cmp rbx,rax
    jb .invalid_saved
.from_edition_disjoint:
    mov rdi,rbx
    call neboc_registry_edition_validate
    test eax,eax
    jne .invalid_saved
    mov rax,[r14+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET]
    cmp rax,[rbx+NEBOC_REGISTRY_EDITION_VERSION_OFFSET]
    jne .invalid_saved
    mov rax,[r14+NEBOC_REGISTRY_SNAPSHOT_EDITION_OFFSET]
    cmp rax,[rbx+NEBOC_REGISTRY_EDITION_ID_OFFSET]
    jne .invalid_saved
    mov rdx,[r12+NEBOC_REGISTRY_COMPAT_TO_EDITION_OFFSET]
    test rdx,rdx
    jz .invalid_saved
    test rdx,7
    jnz .invalid_saved
    mov rax,rdx
    add rax,NEBOC_REGISTRY_EDITION_SIZE
    jc .invalid_saved
    cmp r13,rax
    jae .to_edition_disjoint
    mov rax,[rsp+8]
    cmp rdx,rax
    jb .invalid_saved
.to_edition_disjoint:
    mov [rsp],rdx
    mov rdi,rdx
    call neboc_registry_edition_validate
    test eax,eax
    jne .invalid_saved
    mov rdx,[rsp]
    mov rax,[r15+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET]
    cmp rax,[rdx+NEBOC_REGISTRY_EDITION_VERSION_OFFSET]
    jne .invalid_saved
    mov rax,[r15+NEBOC_REGISTRY_SNAPSHOT_EDITION_OFFSET]
    cmp rax,[rdx+NEBOC_REGISTRY_EDITION_ID_OFFSET]
    jne .invalid_saved
    mov r8,[r12+NEBOC_REGISTRY_COMPAT_BREAKING_COUNT_OFFSET]
    mov r9,[r12+NEBOC_REGISTRY_COMPAT_MANUAL_COUNT_OFFSET]
    cmp r8,NEBOC_REGISTRY_MAX_MIGRATION_ROWS
    ja .limit_saved
    cmp r9,NEBOC_REGISTRY_MAX_MIGRATION_ROWS
    ja .limit_saved
    xor r10d,r10d                 ; reason bits
    mov r11d,1                    ; compatible
    xor ecx,ecx                   ; migration required
    ; Only same-version or immediately-next-version comparisons are bounded.
    mov rax,[r14+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET]
    cmp rax,[r15+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET]
    je .edition_check
    inc rax
    cmp rax,[r15+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET]
    je .version_migration
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_VERSION
    xor r11d,r11d
    jmp .edition_check
.version_migration:
    mov ecx,1
.edition_check:
    mov rax,[rbx+NEBOC_REGISTRY_EDITION_ID_OFFSET]
    cmp rax,[rdx+NEBOC_REGISTRY_EDITION_ID_OFFSET]
    je .digest_check
    ja .edition_incompatible
    mov ecx,1
    jmp .digest_check
.edition_incompatible:
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_EDITION
    xor r11d,r11d
.digest_check:
    xor eax,eax
    mov edi,NEBOC_REGISTRY_SNAPSHOT_HASH0_OFFSET
.digest_loop:
    mov rsi,[r14+rdi]
    xor rsi,[r15+rdi]
    or rax,rsi
    add edi,8
    cmp edi,NEBOC_REGISTRY_SNAPSHOT_PROVENANCE_OFFSET
    jb .digest_loop
    test rax,rax
    jz .protocol_check
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_DIGEST
    mov ecx,1
.protocol_check:
    mov rax,[rbx+NEBOC_REGISTRY_EDITION_PROTOCOL_OFFSET]
    cmp rax,[rdx+NEBOC_REGISTRY_EDITION_PROTOCOL_OFFSET]
    je .target_check
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_PROTOCOL
    xor r11d,r11d
.target_check:
    mov rax,[rbx+NEBOC_REGISTRY_EDITION_TARGET_MASK_OFFSET]
    mov rsi,[rdx+NEBOC_REGISTRY_EDITION_TARGET_MASK_OFFSET]
    mov rdi,rax
    not rsi
    and rdi,rsi
    jz .breaking_check
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_TARGET
    xor r11d,r11d
.breaking_check:
    test r8,r8
    jz .manual_check
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_BREAKING
    xor r11d,r11d
    mov ecx,1
    mov r9,r8
.manual_check:
    test r9,r9
    jz .publish
    or r10d,NEBOC_REGISTRY_COMPAT_REASON_MANUAL
    xor r11d,r11d
    mov ecx,1
.publish:
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_COMPATIBLE_OFFSET],r11
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_REASONS_OFFSET],r10
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_MIGRATION_OFFSET],rcx
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_MANUAL_OFFSET],r9
    mov rax,[r14+NEBOC_REGISTRY_SNAPSHOT_PROVENANCE_OFFSET]
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_FROM_PROVENANCE_OFFSET],rax
    mov rax,[r15+NEBOC_REGISTRY_SNAPSHOT_PROVENANCE_OFFSET]
    mov [r13+NEBOC_REGISTRY_COMPAT_RESULT_TO_PROVENANCE_OFFSET],rax
    xor eax,eax
    jmp .finish
.limit_saved:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    jmp .finish
.invalid_saved:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.finish:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Compatibility wrapper for exact edition/protocol matching.
NEBOC_ABI_FUNCTION nebo_registry_protocol_coherent
    test edi,edi
    jz .legacy_invalid
    test esi,esi
    jz .legacy_invalid
    test edx,edx
    jz .legacy_invalid
    cmp esi,edx
    jne .legacy_denied
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.legacy_denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.legacy_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
