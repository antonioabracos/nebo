; Nebo Assembly — MF030 controlled continuation/lowering diagnostics
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/continuation/continuation_table.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/lowering/lowering_diagnostics.inc"

section .rodata
duplicate_resolution: db 'duplicate-pending-resolution-error'
orphan_pending: db 'orphan-pending-at-exit'

section .text

; lowering_diagnostic_name(error_code, out_ptr*, out_length*)
NEBOC_ABI_FUNCTION neboc_lowering_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp edi,NEBOC_CONTINUATION_ERROR_DUPLICATE_RESOLUTION
 je .duplicate
 cmp edi,NEBOC_LOWERING_ERROR_ORPHAN_PENDING_AT_EXIT
 je .orphan
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.duplicate:
 lea rax,[rel duplicate_resolution]
 mov [rsi],rax
 mov qword [rdx],NEBOC_LOWERING_DIAGNOSTIC_DUPLICATE_RESOLUTION_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.orphan:
 lea rax,[rel orphan_pending]
 mov [rsi],rax
 mov qword [rdx],NEBOC_LOWERING_DIAGNOSTIC_ORPHAN_PENDING_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
