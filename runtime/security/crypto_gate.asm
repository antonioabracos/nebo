; Metadata-only fail-closed algorithm gate. No key bytes are accepted.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/security/crypto_gate.inc"
section .text
; rdi=algorithm numeric ID, rsi=version, rdx=24-byte report
NEBOC_ABI_FUNCTION nebo_crypto_algorithm_lookup
    test rdx,rdx
    jz .invalid
    cmp rsi,1
    jne .unavailable
    cmp rdi,NEBO_CRYPTO_ALGORITHM_SHA256_V1
    je .approved
    cmp rdi,4402
    je .unavailable
    cmp rdi,4403
    je .unavailable
    cmp rdi,4404
    je .unavailable
    cmp rdi,4405
    je .unavailable
    mov eax,NEBO_CRYPTO_STATUS_FORBIDDEN
    ret
.approved:
    mov qword [rdx+NEBO_CRYPTO_REPORT_STATUS],NEBO_CRYPTO_STATUS_OK
    mov [rdx+NEBO_CRYPTO_REPORT_ALGORITHM],rdi
    mov [rdx+NEBO_CRYPTO_REPORT_VERSION],rsi
    xor eax,eax
    ret
.unavailable:
    mov eax,NEBO_CRYPTO_STATUS_UNAVAILABLE
    ret
.invalid:
    mov eax,NEBO_CRYPTO_STATUS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
