; Nebo Assembly — internal ABI executable contract canary
;
; Function:
;   neboc_abi_contract_store_u64
;
; Purpose:
;   Prove the physical NEBOC_INTERNAL_ABI_v0 contract without implementing
;   compiler semantics.
;
; Inputs:
;   RDI = non-null pointer to writable u64 output.
;   RSI = u64 value to store.
;
; Outputs:
;   [RDI] = RSI when status is NEBOC_STATUS_OK.
;
; Status:
;   EAX = NEBOC_STATUS_OK on success.
;   EAX = NEBOC_STATUS_INVALID_ARGUMENT when RDI is null.
;   EAX = NEBOC_STATUS_INTERNAL_ERROR when caller alignment is invalid.
;
; Clobbers:
;   RAX and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15, RSP.
;
; Stack:
;   No local frame. Requires 16-byte alignment before CALL. Uses no red zone.
;
; Ownership:
;   The caller owns the output pointer and stored value.
;
; Thread safety:
;   Reentrant. No global mutable state.
;
; Errors:
;   Invalid pointer and invalid entry alignment are returned as StatusCode.
;
; Tests:
;   tests/abi/internal/mf004_contract_test.asm
;   scripts/mf004/validate.sh

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text

NEBOC_ABI_FUNCTION neboc_abi_contract_store_u64
    NEBOC_ABI_CHECK_ENTRY_ALIGNMENT .alignment_error

    test NEBOC_ABI_ARG0, NEBOC_ABI_ARG0
    jz .invalid_argument

    mov [NEBOC_ABI_ARG0], NEBOC_ABI_ARG1
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

.alignment_error:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INTERNAL_ERROR

section .note.GNU-stack noalloc noexec nowrite progbits
