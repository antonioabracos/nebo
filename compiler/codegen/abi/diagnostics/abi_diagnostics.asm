; Nebo Assembly — MF033 stable ABI Adapter diagnostics
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/abi/diagnostics/abi_diagnostics.inc"
section .rodata
bad_request: db 'invalid-abi-request'
internal_version: db 'internal-abi-version-mismatch'
runtime_version: db 'runtime-abi-version-mismatch'
target_mismatch: db 'abi-target-mismatch'
backend_not_ready: db 'abi-backend-not-ready'
writer_not_ready: db 'abi-writer-not-ready'
signature_invalid: db 'invalid-abi-signature'
bad_state: db 'invalid-abi-state'
parameter_limit: db 'abi-parameter-limit'
stack_slot: db 'invalid-abi-stack-slot'
call_invalid: db 'invalid-abi-call'
function_mismatch: db 'abi-function-mismatch'
writer_limit: db 'abi-writer-limit'
section .text
NEBOC_ABI_FUNCTION neboc_abi_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp edi,NEBOC_ABI_ERROR_BAD_REQUEST
 je .bad_request
 cmp edi,NEBOC_ABI_ERROR_INTERNAL_VERSION_MISMATCH
 je .internal_version
 cmp edi,NEBOC_ABI_ERROR_RUNTIME_VERSION_MISMATCH
 je .runtime_version
 cmp edi,NEBOC_ABI_ERROR_TARGET_MISMATCH
 je .target_mismatch
 cmp edi,NEBOC_ABI_ERROR_BACKEND_NOT_READY
 je .backend
 cmp edi,NEBOC_ABI_ERROR_WRITER_NOT_READY
 je .writer
 cmp edi,NEBOC_ABI_ERROR_SIGNATURE_INVALID
 je .signature
 cmp edi,NEBOC_ABI_ERROR_BAD_STATE
 je .state
 cmp edi,NEBOC_ABI_ERROR_PARAMETER_LIMIT
 je .parameter
 cmp edi,NEBOC_ABI_ERROR_STACK_SLOT_INVALID
 je .slot
 cmp edi,NEBOC_ABI_ERROR_CALL_INVALID
 je .call
 cmp edi,NEBOC_ABI_ERROR_FUNCTION_MISMATCH
 je .function
 cmp edi,NEBOC_ABI_ERROR_WRITER_LIMIT
 je .limit
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bad_request: lea rax,[rel bad_request]
 mov ecx,NEBOC_ABI_DIAG_BAD_REQUEST_LENGTH
 jmp .store
.internal_version: lea rax,[rel internal_version]
 mov ecx,NEBOC_ABI_DIAG_INTERNAL_VERSION_LENGTH
 jmp .store
.runtime_version: lea rax,[rel runtime_version]
 mov ecx,NEBOC_ABI_DIAG_RUNTIME_VERSION_LENGTH
 jmp .store
.target_mismatch: lea rax,[rel target_mismatch]
 mov ecx,NEBOC_ABI_DIAG_TARGET_MISMATCH_LENGTH
 jmp .store
.backend: lea rax,[rel backend_not_ready]
 mov ecx,NEBOC_ABI_DIAG_BACKEND_NOT_READY_LENGTH
 jmp .store
.writer: lea rax,[rel writer_not_ready]
 mov ecx,NEBOC_ABI_DIAG_WRITER_NOT_READY_LENGTH
 jmp .store
.signature: lea rax,[rel signature_invalid]
 mov ecx,NEBOC_ABI_DIAG_SIGNATURE_INVALID_LENGTH
 jmp .store
.state: lea rax,[rel bad_state]
 mov ecx,NEBOC_ABI_DIAG_BAD_STATE_LENGTH
 jmp .store
.parameter: lea rax,[rel parameter_limit]
 mov ecx,NEBOC_ABI_DIAG_PARAMETER_LIMIT_LENGTH
 jmp .store
.slot: lea rax,[rel stack_slot]
 mov ecx,NEBOC_ABI_DIAG_STACK_SLOT_LENGTH
 jmp .store
.call: lea rax,[rel call_invalid]
 mov ecx,NEBOC_ABI_DIAG_CALL_INVALID_LENGTH
 jmp .store
.function: lea rax,[rel function_mismatch]
 mov ecx,NEBOC_ABI_DIAG_FUNCTION_MISMATCH_LENGTH
 jmp .store
.limit: lea rax,[rel writer_limit]
 mov ecx,NEBOC_ABI_DIAG_WRITER_LIMIT_LENGTH
.store:
 mov [rsi],rax
 mov [rdx],rcx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
