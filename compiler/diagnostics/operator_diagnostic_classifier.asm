; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES deterministic context/domain/type/effect/capability classifier.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"

section .text
; operator_diagnostic_classify(fault_mask, registry_id, out_classification*)
NEBOC_ABI_FUNCTION neboc_operator_diagnostic_classify
 test rdx,rdx
 jz .invalid
 test rdi,rdi
 jz .source
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_OPERATOR_REGISTRY_ENTRY_COUNT
 ja .source
 mov eax,NEBOC_OPERATOR_DIAG_CATEGORY_CONTEXT
 test rdi,NEBOC_OPERATOR_FAULT_CONTEXT
 jnz .store
 mov eax,NEBOC_OPERATOR_DIAG_CATEGORY_DOMAIN
 test rdi,NEBOC_OPERATOR_FAULT_DOMAIN
 jnz .store
 mov eax,NEBOC_OPERATOR_DIAG_CATEGORY_TYPE
 test rdi,NEBOC_OPERATOR_FAULT_TYPE
 jnz .store
 mov eax,NEBOC_OPERATOR_DIAG_CATEGORY_EFFECT
 test rdi,NEBOC_OPERATOR_FAULT_EFFECT
 jnz .store
 mov eax,NEBOC_OPERATOR_DIAG_CATEGORY_CAPABILITY
 test rdi,NEBOC_OPERATOR_FAULT_CAPABILITY
 jz .source
.store:
 mov r8,NEBOC_OPERATOR_DIAG_NAMESPACE_BASE
 add r8,rax
 mov [rdx+NEBOC_OPERATOR_CLASSIFY_CATEGORY_OFFSET],rax
 mov [rdx+NEBOC_OPERATOR_CLASSIFY_CODE_OFFSET],r8
 mov [rdx+NEBOC_OPERATOR_CLASSIFY_REGISTRY_ID_OFFSET],rsi
 mov [rdx+NEBOC_OPERATOR_CLASSIFY_FAULTS_OFFSET],rdi
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
