; G146 frozen RegistryEdition manifest validation.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

section .text

NEBOC_ABI_FUNCTION neboc_registry_edition_validate
    test rdi,rdi
    jz .invalid
    test rdi,7
    jnz .invalid
    cmp qword [rdi+NEBOC_REGISTRY_EDITION_VERSION_OFFSET],NEBOC_REGISTRY_AUTHORITY_VERSION
    jne .invalid
    mov rax,[rdi+NEBOC_REGISTRY_EDITION_ID_OFFSET]
    cmp rax,NEBOC_REGISTRY_EDITION_LEGACY
    jb .invalid
    cmp rax,NEBOC_REGISTRY_EDITION_CURRENT
    ja .invalid
    mov rax,[rdi+NEBOC_REGISTRY_EDITION_FEATURE_PROFILE_OFFSET]
    test rax,~NEBOC_REGISTRY_FEATURE_MASK
    jnz .invalid
    mov rcx,[rdi+NEBOC_REGISTRY_EDITION_REQUIRED_GATES_OFFSET]
    test rcx,~NEBOC_REGISTRY_FEATURE_MASK
    jnz .invalid
    mov rdx,[rdi+NEBOC_REGISTRY_EDITION_ENABLED_GATES_OFFSET]
    test rdx,~NEBOC_REGISTRY_FEATURE_MASK
    jnz .invalid
    mov r8,rcx
    not rdx
    and r8,rdx
    jnz .denied
    mov rdx,[rdi+NEBOC_REGISTRY_EDITION_ENABLED_GATES_OFFSET]
    not rax
    and rdx,rax
    jnz .denied
    cmp qword [rdi+NEBOC_REGISTRY_EDITION_TARGET_MASK_OFFSET],0
    je .invalid
    cmp qword [rdi+NEBOC_REGISTRY_EDITION_PROTOCOL_OFFSET],0
    je .invalid
    cmp qword [rdi+NEBOC_REGISTRY_EDITION_FLAGS_OFFSET],NEBOC_REGISTRY_EDITION_FLAG_FROZEN
    jne .denied
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; edition/profile compatibility wrapper: required gates must all be enabled.
NEBOC_ABI_FUNCTION nebo_registry_edition_profile
    cmp edi,NEBOC_REGISTRY_EDITION_LEGACY
    jb .legacy_invalid
    cmp edi,NEBOC_REGISTRY_EDITION_CURRENT
    ja .legacy_invalid
    test esi,~NEBOC_REGISTRY_FEATURE_MASK
    jnz .legacy_invalid
    test edx,~NEBOC_REGISTRY_FEATURE_MASK
    jnz .legacy_invalid
    mov eax,edx
    not esi
    and eax,esi
    jnz .legacy_denied
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.legacy_denied:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.legacy_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
