; Nebo Assembly — deterministic CompilationSession statistics v0
;
; Purpose:
;   Zero and snapshot fixed-layout session counters without host data.
;
; Inputs:
;   RDI = statistics pointer; RSI = destination for snapshot when applicable.
;
; Outputs:
;   StatusCode in EAX.
;
; Status:
;   OK or INVALID_ARGUMENT.
;
; Clobbers:
;   RAX, RCX, RDI, RSI and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   Unchanged; no red-zone dependency.
;
; Ownership:
;   Caller-owned fixed blocks.
;
; Thread safety:
;   Session layer is single-writer in v0.1.
;
; Errors:
;   Null pointers are rejected.
;
; Tests:
;   MF010 session contract suite and TR02 exit gate.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/statistics/session_statistics.inc"

section .text

NEBOC_ABI_FUNCTION neboc_session_statistics_zero
    test rdi, rdi
    jz .invalid
    xor eax, eax
    mov ecx, NEBOC_SESSION_STATISTICS_QWORDS
    rep stosq
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_session_statistics_snapshot
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rcx, NEBOC_SESSION_STATISTICS_QWORDS
    rep movsq
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
