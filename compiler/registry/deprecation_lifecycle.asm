; G146 explicit OperatorDeprecation timeline and compatibility window.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

section .text

; OperatorDeprecation(request*, out*).  Warning/migration/removal authority is
; mandatory before a deprecated or removed state can be published.
NEBOC_ABI_FUNCTION neboc_registry_deprecation_evaluate
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdi,7
    jnz .invalid
    test rsi,7
    jnz .invalid
    ; Request and result have different layouts, so every overlap is invalid.
    mov rax,rdi
    add rax,NEBOC_REGISTRY_DEPRECATION_SIZE
    jc .invalid
    cmp rsi,rax
    jae .buffers_valid
    mov rax,rsi
    add rax,NEBOC_REGISTRY_DEPRECATION_RESULT_SIZE
    jc .invalid
    cmp rdi,rax
    jb .invalid
.buffers_valid:
    mov r8,[rdi+NEBOC_REGISTRY_DEPRECATION_CURRENT_EDITION_OFFSET]
    mov r9,[rdi+NEBOC_REGISTRY_DEPRECATION_INTRODUCED_EDITION_OFFSET]
    test r8,r8
    jz .invalid
    test r9,r9
    jz .invalid
    cmp r8,r9
    jb .invalid
    mov r10,[rdi+NEBOC_REGISTRY_DEPRECATION_DEPRECATED_EDITION_OFFSET]
    mov r11,[rdi+NEBOC_REGISTRY_DEPRECATION_REMOVAL_EDITION_OFFSET]
    test r10,r10
    jz .never_deprecated
    cmp r10,r9
    jbe .invalid
    cmp r11,r10
    jbe .invalid
    ; At least one complete edition remains available after deprecation.
    mov rax,r10
    add rax,2
    jc .denied
    cmp r11,rax
    jb .denied
    cmp qword [rdi+NEBOC_REGISTRY_DEPRECATION_WARNING_ID_OFFSET],0
    je .denied
    cmp qword [rdi+NEBOC_REGISTRY_DEPRECATION_MIGRATION_ID_OFFSET],0
    je .denied
    mov rax,[rdi+NEBOC_REGISTRY_DEPRECATION_FLAGS_OFFSET]
    test rax,~NEBOC_REGISTRY_DEPRECATION_FLAG_ALL
    jnz .invalid
    test rax,NEBOC_REGISTRY_DEPRECATION_FLAG_WARN
    jz .denied
    test rax,NEBOC_REGISTRY_DEPRECATION_FLAG_MIGRATION
    jz .denied
    test rax,NEBOC_REGISTRY_DEPRECATION_FLAG_REMOVAL_APPROVED
    jz .denied
    mov ecx,NEBOC_REGISTRY_LIFECYCLE_ACTIVE
    xor edx,edx
    cmp r8,r10
    jb .publish
    mov ecx,NEBOC_REGISTRY_LIFECYCLE_DEPRECATED
    mov rdx,r11
    sub rdx,r8
    cmp r8,r11
    jb .publish
    mov ecx,NEBOC_REGISTRY_LIFECYCLE_REMOVED
    xor edx,edx
    jmp .publish
.never_deprecated:
    test r11,r11
    jnz .invalid
    cmp qword [rdi+NEBOC_REGISTRY_DEPRECATION_WARNING_ID_OFFSET],0
    jne .invalid
    cmp qword [rdi+NEBOC_REGISTRY_DEPRECATION_MIGRATION_ID_OFFSET],0
    jne .invalid
    cmp qword [rdi+NEBOC_REGISTRY_DEPRECATION_FLAGS_OFFSET],0
    jne .invalid
    mov ecx,NEBOC_REGISTRY_LIFECYCLE_ACTIVE
    xor edx,edx
.publish:
    mov [rsi+NEBOC_REGISTRY_DEPRECATION_RESULT_STATE_OFFSET],rcx
    mov [rsi+NEBOC_REGISTRY_DEPRECATION_RESULT_REMAINING_OFFSET],rdx
    mov rax,[rdi+NEBOC_REGISTRY_DEPRECATION_WARNING_ID_OFFSET]
    mov [rsi+NEBOC_REGISTRY_DEPRECATION_RESULT_WARNING_ID_OFFSET],rax
    mov rax,[rdi+NEBOC_REGISTRY_DEPRECATION_MIGRATION_ID_OFFSET]
    mov [rsi+NEBOC_REGISTRY_DEPRECATION_RESULT_MIGRATION_ID_OFFSET],rax
    mov rax,[rdi+NEBOC_REGISTRY_DEPRECATION_FLAGS_OFFSET]
    mov [rsi+NEBOC_REGISTRY_DEPRECATION_RESULT_FLAGS_OFFSET],rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Compatibility wrapper for the original scalar lifecycle query.
NEBOC_ABI_FUNCTION nebo_registry_deprecation_state
    test rcx,rcx
    jz .legacy_invalid
    test edi,edi
    jz .legacy_invalid
    test esi,esi
    jz .legacy_invalid
    cmp edx,esi
    jbe .legacy_invalid
    mov r8d,NEBOC_REGISTRY_LIFECYCLE_ACTIVE
    cmp edi,esi
    jb .legacy_publish
    mov r8d,NEBOC_REGISTRY_LIFECYCLE_DEPRECATED
    cmp edi,edx
    jb .legacy_publish
    mov r8d,NEBOC_REGISTRY_LIFECYCLE_REMOVED
.legacy_publish:
    mov [rcx],r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.legacy_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
