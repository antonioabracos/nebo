; Nebo Assembly — deterministic typed IDs v0
;
; Purpose:
;   Construct and validate IDs whose value is independent of memory pointers.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit u64 out values.
;
; Status:
;   OK or INVALID_ARGUMENT/LIMIT_EXCEEDED.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   Unchanged; no red-zone dependency.
;
; Ownership:
;   IDs are scalar values and own no memory.
;
; Thread safety:
;   Reentrant and stateless.
;
; Errors:
;   Kind zero/unknown, ordinal zero or ordinal overflow are rejected.
;
; Tests:
;   NEBO-MEM-DETERMINISM-007.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/id/typed_id.inc"

section .text

; typed_id_make(kind, ordinal, out_id*)
NEBOC_ABI_FUNCTION neboc_typed_id_make
    test rdx, rdx
    jz .invalid
    mov qword [rdx], NEBOC_ID_INVALID
    cmp rdi, NEBOC_ID_KIND_STRING
    je .kind_ok
    cmp rdi, NEBOC_ID_KIND_IDENTIFIER
    jne .invalid
.kind_ok:
    test rsi, rsi
    jz .invalid
    mov rax, NEBOC_TYPED_ID_ORDINAL_MASK
    cmp rsi, rax
    ja .limit
    mov rax, rdi
    shl rax, NEBOC_TYPED_ID_KIND_SHIFT
    or rax, rsi
    mov [rdx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; typed_id_validate(id, expected_kind, out_ordinal*)
NEBOC_ABI_FUNCTION neboc_typed_id_validate
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    test rdi, rdi
    jz .invalid
    cmp rsi, NEBOC_ID_KIND_STRING
    je .kind_ok
    cmp rsi, NEBOC_ID_KIND_IDENTIFIER
    jne .invalid
.kind_ok:
    mov rax, rdi
    shr rax, NEBOC_TYPED_ID_KIND_SHIFT
    cmp rax, rsi
    jne .invalid
    mov rcx, NEBOC_TYPED_ID_ORDINAL_MASK
    mov rax, rdi
    and rax, rcx
    test rax, rax
    jz .invalid
    mov [rdx], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
