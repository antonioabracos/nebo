; Nebo Assembly — stable MF032 codegen diagnostics
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/diagnostics/codegen_diagnostics.inc"

section .rodata
bad_argument: db 'invalid-codegen-argument'
target_mismatch: db 'codegen-target-mismatch'
writer_not_ready: db 'assembly-writer-not-ready'
lowering_not_frozen: db 'lowering-table-not-frozen'
unresolved_node: db 'unresolved-node-before-codegen'
bad_module_state: db 'invalid-codegen-state'
invalid_label_id: db 'invalid-codegen-label-id'
unsafe_text: db 'unsafe-text-input'
writer_limit: db 'assembly-writer-limit'
unsupported_operation: db 'unsupported-lowering-operation'

section .text
; codegen_diagnostic_name(error_code, out_ptr*, out_len*)
NEBOC_ABI_FUNCTION neboc_codegen_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp edi,NEBOC_CODEGEN_ERROR_BAD_ARGUMENT
 je .bad_argument
 cmp edi,NEBOC_CODEGEN_ERROR_TARGET_MISMATCH
 je .target_mismatch
 cmp edi,NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 je .writer_not_ready
 cmp edi,NEBOC_CODEGEN_ERROR_LOWERING_NOT_FROZEN
 je .lowering_not_frozen
 cmp edi,NEBOC_CODEGEN_ERROR_UNRESOLVED_NODE
 je .unresolved_node
 cmp edi,NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 je .bad_module_state
 cmp edi,NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 je .invalid_label_id
 cmp edi,NEBOC_CODEGEN_ERROR_UNSAFE_TEXT
 je .unsafe_text
 cmp edi,NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 je .writer_limit
 cmp edi,NEBOC_CODEGEN_ERROR_UNSUPPORTED_LOWERING_OPERATION
 je .unsupported_operation
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.bad_argument:
 lea rax,[rel bad_argument]
 mov ecx,NEBOC_CODEGEN_DIAG_BAD_ARGUMENT_LENGTH
 jmp .store
.target_mismatch:
 lea rax,[rel target_mismatch]
 mov ecx,NEBOC_CODEGEN_DIAG_TARGET_MISMATCH_LENGTH
 jmp .store
.writer_not_ready:
 lea rax,[rel writer_not_ready]
 mov ecx,NEBOC_CODEGEN_DIAG_WRITER_NOT_READY_LENGTH
 jmp .store
.lowering_not_frozen:
 lea rax,[rel lowering_not_frozen]
 mov ecx,NEBOC_CODEGEN_DIAG_LOWERING_NOT_FROZEN_LENGTH
 jmp .store
.unresolved_node:
 lea rax,[rel unresolved_node]
 mov ecx,NEBOC_CODEGEN_DIAG_UNRESOLVED_NODE_LENGTH
 jmp .store
.bad_module_state:
 lea rax,[rel bad_module_state]
 mov ecx,NEBOC_CODEGEN_DIAG_BAD_MODULE_STATE_LENGTH
 jmp .store
.invalid_label_id:
 lea rax,[rel invalid_label_id]
 mov ecx,NEBOC_CODEGEN_DIAG_INVALID_LABEL_ID_LENGTH
 jmp .store
.unsafe_text:
 lea rax,[rel unsafe_text]
 mov ecx,NEBOC_CODEGEN_DIAG_UNSAFE_TEXT_LENGTH
 jmp .store
.writer_limit:
 lea rax,[rel writer_limit]
 mov ecx,NEBOC_CODEGEN_DIAG_WRITER_LIMIT_LENGTH
 jmp .store
.unsupported_operation:
 lea rax,[rel unsupported_operation]
 mov ecx,NEBOC_CODEGEN_DIAG_UNSUPPORTED_OPERATION_LENGTH
.store:
 mov [rsi],rax
 mov [rdx],rcx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
