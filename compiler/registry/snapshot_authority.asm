; G146 deterministic local authority snapshot and exact digest validator.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/lifecycle.inc"

section .text

; signRegistrySnapshot(material*, length, authority-version, edition, out*).
; The complete record is published only after every input has been validated
; and all four identity lanes have been computed.
NEBOC_ABI_FUNCTION neboc_registry_snapshot_sign
    test rdi,rdi
    jz .sign_invalid
    test rsi,rsi
    jz .sign_invalid
    cmp rsi,NEBOC_REGISTRY_MAX_MATERIAL_BYTES
    ja .sign_limit
    cmp rdx,NEBOC_REGISTRY_AUTHORITY_VERSION
    jne .sign_invalid
    cmp rcx,NEBOC_REGISTRY_EDITION_LEGACY
    jb .sign_invalid
    cmp rcx,NEBOC_REGISTRY_EDITION_CURRENT
    ja .sign_invalid
    test r8,r8
    jz .sign_invalid
    test r8,7
    jnz .sign_invalid
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
    mov rax,0xcbf29ce484222325
    mov r9,0x84222325cbf29ce4
    mov r10,0x9e3779b185ebca87
    mov r11,0xd6e8feb86659fd93
    mov rsi,1099511628211
    xor ecx,ecx
.sign_hash:
    movzx edx,byte [r12+rcx]
    xor rax,rdx
    imul rax,rsi
    xor r9,rdx
    imul r9,rsi
    xor r10,rdx
    imul r10,rsi
    xor r11,rdx
    imul r11,rsi
    inc rcx
    cmp rcx,r13
    jb .sign_hash
    mov qword [rbx+NEBOC_REGISTRY_SNAPSHOT_SCHEMA_OFFSET],NEBOC_REGISTRY_LIFECYCLE_SCHEMA_VERSION
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_AUTHORITY_VERSION_OFFSET],r14
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_EDITION_OFFSET],r15
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_MATERIAL_LENGTH_OFFSET],r13
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_HASH0_OFFSET],rax
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_HASH1_OFFSET],r9
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_HASH2_OFFSET],r10
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_HASH3_OFFSET],r11
    xor rax,r9
    xor rax,r10
    xor rax,r11
    xor rax,r14
    rol r15,17
    xor rax,r15
    xor rax,r13
    mov [rbx+NEBOC_REGISTRY_SNAPSHOT_PROVENANCE_OFFSET],rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.sign_limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.sign_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Exact 32-byte digest comparison used by compatibility and external tooling.
; A mismatch is a policy failure, not a successful boolean result.
NEBOC_ABI_FUNCTION nebo_registry_snapshot_valid
    test rdi,rdi
    jz .valid_invalid
    test rsi,rsi
    jz .valid_invalid
    cmp edx,32
    jne .valid_invalid
    xor eax,eax
    xor ecx,ecx
.valid_loop:
    mov r8b,[rdi+rcx]
    xor r8b,[rsi+rcx]
    or al,r8b
    inc ecx
    cmp ecx,32
    jb .valid_loop
    test al,al
    jnz .valid_different
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.valid_different:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.valid_invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
