; Nebo Assembly — deterministic FNV-1a 32-bit hashing
;
; Function:
;   neboc_hash_fnv1a32
;
; Purpose:
;   Compute a stable fixed-seed hash for internal string interning.
;
; Inputs:
;   RDI = byte pointer (may be null only when RSI is zero).
;   RSI = byte length.
;   RDX = non-null u64 out pointer.
;
; Outputs:
;   [RDX] = zero-extended FNV-1a 32-bit hash.
;
; Status:
;   OK or INVALID_ARGUMENT.
;
; Clobbers:
;   RAX, RCX, R8 and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   Unchanged; no red-zone dependency.
;
; Ownership:
;   Borrowed bytes; no memory is retained.
;
; Thread safety:
;   Reentrant and stateless.
;
; Errors:
;   A non-empty input requires a non-null byte pointer.
;
; Tests:
;   NEBO-MEM-DETERMINISM-007.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/hash/fnv1a.inc"

section .text

; hash_fnv1a32(bytes*, length, out_hash*)
NEBOC_ABI_FUNCTION neboc_hash_fnv1a32
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .invalid
.empty:
    mov eax, NEBOC_FNV1A32_OFFSET_BASIS
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .store
    movzx r8d, byte [rdi + rcx]
    xor eax, r8d
    imul eax, eax, NEBOC_FNV1A32_PRIME
    inc rcx
    jmp .loop
.store:
    mov [rdx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
