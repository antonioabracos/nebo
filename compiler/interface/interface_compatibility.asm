; API/ABI/behavior compatibility classification for one target.
;
; Request V1 (72 bytes):
;   +00 old API fingerprint       qword
;   +08 new API fingerprint       qword
;   +16 old ABI fingerprint       qword
;   +24 new ABI fingerprint       qword
;   +32 old behavior fingerprint  qword (effects/capabilities/ownership)
;   +40 new behavior fingerprint  qword
;   +48 old target digest         qword
;   +56 new target digest         qword
;   +64 proof flags               qword (API_ADDITIVE=1, DOC_ONLY=2)
;
; Result V1 (40 bytes): class, api_changed, abi_changed, behavior_changed,
; accepted proof flags.  Class values come from rf166_interface_v1.inc.
; rdi=request, rsi=caller-owned result. Result is failure atomic.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"

%define COMPAT_PROOF_API_ADDITIVE 1
%define COMPAT_PROOF_DOC_ONLY     2
%define COMPAT_PROOF_MASK         3

%define COMPAT_DIAG_ARGUMENT      1
%define COMPAT_DIAG_FINGERPRINT   2
%define COMPAT_DIAG_TARGET        3
%define COMPAT_DIAG_PROOF         4

section .text

NEBOC_ABI_FUNCTION neboc_interface_compatibility
    test rdi, rdi
    jz .argument
    test rsi, rsi
    jz .argument
    test rdi, 7
    jnz .argument
    test rsi, 7
    jnz .argument
    cmp qword [rdi], 0
    je .fingerprint
    cmp qword [rdi + 8], 0
    je .fingerprint
    cmp qword [rdi + 16], 0
    je .fingerprint
    cmp qword [rdi + 24], 0
    je .fingerprint
    cmp qword [rdi + 32], 0
    je .fingerprint
    cmp qword [rdi + 40], 0
    je .fingerprint
    cmp qword [rdi + 48], 0
    je .fingerprint
    cmp qword [rdi + 56], 0
    je .fingerprint

    mov rax, qword [rdi + 48]
    cmp rax, qword [rdi + 56]
    jne .target
    mov r8, qword [rdi + 64]
    mov rax, r8
    and rax, ~COMPAT_PROOF_MASK
    jnz .proof

    xor r9d, r9d                      ; API changed
    xor r10d, r10d                    ; ABI changed
    xor r11d, r11d                    ; behavior changed
    mov rax, qword [rdi]
    cmp rax, qword [rdi + 8]
    sete r9b
    xor r9b, 1
    mov rax, qword [rdi + 16]
    cmp rax, qword [rdi + 24]
    sete r10b
    xor r10b, 1
    mov rax, qword [rdi + 32]
    cmp rax, qword [rdi + 40]
    sete r11b
    xor r11b, 1

    test r8, COMPAT_PROOF_API_ADDITIVE
    jz .api_proof_done
    test r9b, r9b
    jz .proof
.api_proof_done:
    test r8, COMPAT_PROOF_DOC_ONLY
    jz .doc_proof_done
    test r11b, r11b
    jz .proof
.doc_proof_done:

    mov ecx, NEBOC_NI_COMPAT_IDENTICAL
    test r11b, r11b
    jz .classify_api
    test r8, COMPAT_PROOF_DOC_ONLY
    jnz .behavior_source
    mov ecx, NEBOC_NI_COMPAT_BREAKING
    jmp .classify_api
.behavior_source:
    mov ecx, NEBOC_NI_COMPAT_SOURCE

.classify_api:
    test r9b, r9b
    jz .classify_abi
    test r8, COMPAT_PROOF_API_ADDITIVE
    jnz .api_source
    mov ecx, NEBOC_NI_COMPAT_BREAKING
    jmp .classify_abi
.api_source:
    cmp ecx, NEBOC_NI_COMPAT_BREAKING
    je .classify_abi
    mov ecx, NEBOC_NI_COMPAT_SOURCE

.classify_abi:
    test r10b, r10b
    jz .publish
    cmp ecx, NEBOC_NI_COMPAT_BREAKING
    je .publish
    mov ecx, NEBOC_NI_COMPAT_RECOMPILE

.publish:
    mov qword [rsi], rcx
    movzx rax, r9b
    mov qword [rsi + 8], rax
    movzx rax, r10b
    mov qword [rsi + 16], rax
    movzx rax, r11b
    mov qword [rsi + 24], rax
    mov qword [rsi + 32], r8
    xor eax, eax
    xor edx, edx
    ret

.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, COMPAT_DIAG_ARGUMENT
    ret
.fingerprint:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, COMPAT_DIAG_FINGERPRINT
    ret
.target:
    mov eax, NEBOC_STATUS_UNSUPPORTED_TARGET
    mov edx, COMPAT_DIAG_TARGET
    ret
.proof:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, COMPAT_DIAG_PROOF
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
