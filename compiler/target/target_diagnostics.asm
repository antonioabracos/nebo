; Nebo Assembly — MF031 target diagnostic names
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_context.inc"
%include "compiler/target/target_diagnostics.inc"

section .rodata
diag_bad_request: db 'invalid-target-request'
diag_incomplete_tuple: db 'incomplete-target-tuple'
diag_unsupported_target_id: db 'unsupported-target-id'
diag_unsupported_isa: db 'unsupported-instruction-set'
diag_unsupported_abi: db 'unsupported-target-abi'
diag_unsupported_format: db 'unsupported-object-format'
diag_unsupported_environment: db 'unsupported-operating-environment'
diag_unsupported_runtime: db 'unsupported-runtime-profile'
diag_unsupported_console_runtime: db 'unsupported-console-runtime-profile'
diag_unsupported_toolchain: db 'unsupported-toolchain-profile'
diag_unsupported_features: db 'unsupported-target-features'
diag_invalid_layout: db 'incompatible-data-layout'
diag_context_not_frozen: db 'target-context-not-frozen'

section .text

; target_diagnostic_name(error_code, out_text_ptr*, out_length*)
NEBOC_ABI_FUNCTION neboc_target_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp rdi,NEBOC_TARGET_ERROR_BAD_REQUEST
 je .bad_request
 cmp rdi,NEBOC_TARGET_ERROR_INCOMPLETE_TUPLE
 je .incomplete
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_TARGET_ID
 je .target_id
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_ISA
 je .isa
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_ABI
 je .abi
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_FORMAT
 je .format
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_ENVIRONMENT
 je .environment
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_RUNTIME
 je .runtime
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_CONSOLE_RUNTIME
 je .console_runtime
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_TOOLCHAIN
 je .toolchain
 cmp rdi,NEBOC_TARGET_ERROR_UNSUPPORTED_FEATURES
 je .features
 cmp rdi,NEBOC_TARGET_ERROR_INVALID_DATA_LAYOUT
 je .layout
 cmp rdi,NEBOC_TARGET_ERROR_CONTEXT_NOT_FROZEN
 je .not_frozen
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bad_request:
 lea rax,[rel diag_bad_request]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_BAD_REQUEST_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.incomplete:
 lea rax,[rel diag_incomplete_tuple]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_INCOMPLETE_TUPLE_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.target_id:
 lea rax,[rel diag_unsupported_target_id]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_TARGET_ID_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.isa:
 lea rax,[rel diag_unsupported_isa]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_ISA_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.abi:
 lea rax,[rel diag_unsupported_abi]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_ABI_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.format:
 lea rax,[rel diag_unsupported_format]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_FORMAT_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.environment:
 lea rax,[rel diag_unsupported_environment]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_ENVIRONMENT_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.runtime:
 lea rax,[rel diag_unsupported_runtime]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_RUNTIME_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.console_runtime:
 lea rax,[rel diag_unsupported_console_runtime]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_CONSOLE_RUNTIME_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.toolchain:
 lea rax,[rel diag_unsupported_toolchain]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_TOOLCHAIN_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.features:
 lea rax,[rel diag_unsupported_features]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_UNSUPPORTED_FEATURES_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.layout:
 lea rax,[rel diag_invalid_layout]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_INVALID_DATA_LAYOUT_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.not_frozen:
 lea rax,[rel diag_context_not_frozen]
 mov [rsi],rax
 mov qword [rdx],NEBOC_TARGET_DIAG_CONTEXT_NOT_FROZEN_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
