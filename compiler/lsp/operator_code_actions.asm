; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES explicit safe operator code actions and migrations.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"
%include "compiler/lsp/operator_metadata.inc"

section .text
; operator_code_action(kind, registry_id, from_token, to_token, equivalent, out*)
NEBOC_ABI_FUNCTION neboc_operator_code_action
 test r9,r9
 jz .invalid
 test rdi,rdi
 jz .source
 cmp rdi,NEBOC_OPERATOR_ACTION_MAX
 ja .source
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_OPERATOR_REGISTRY_ENTRY_COUNT
 ja .source
 cmp r8,1
 jne .source
 cmp rdi,NEBOC_OPERATOR_ACTION_REPLACE_SPELLING
 jne .store
 test rcx,rcx
 jz .source
.store:
 mov [r9+NEBOC_OPERATOR_ACTION_KIND_OFFSET],rdi
 mov qword [r9+NEBOC_OPERATOR_ACTION_SAFE_OFFSET],1
 mov qword [r9+NEBOC_OPERATOR_ACTION_AUTOMATIC_OFFSET],0
 mov [r9+NEBOC_OPERATOR_ACTION_REGISTRY_ID_OFFSET],rsi
 mov [r9+NEBOC_OPERATOR_ACTION_FROM_TOKEN_OFFSET],rdx
 mov [r9+NEBOC_OPERATOR_ACTION_TO_TOKEN_OFFSET],rcx
 mov [r9+NEBOC_OPERATOR_ACTION_EQUIVALENCE_OFFSET],r8
 mov qword [r9+NEBOC_OPERATOR_ACTION_SOURCE_MAP_OFFSET],1
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
