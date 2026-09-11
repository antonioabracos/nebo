; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES Registry-backed hover/signature/semantic-token metadata.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"
%include "compiler/lsp/operator_metadata.inc"

section .text
; operator_lsp_metadata(registry_id, token, registry_class, out_metadata*)
NEBOC_ABI_FUNCTION neboc_operator_lsp_metadata
 test rcx,rcx
 jz .invalid
 test rdi,rdi
 jz .source
 cmp rdi,NEBOC_OPERATOR_CATALOG_ENTRY_COUNT
 ja .source
 test rdx,rdx
 jz .source
 cmp rdx,NEBOC_OPERATOR_LSP_CLASS_MAX
 ja .source
 mov eax,NEBOC_OPERATOR_LSP_CLASS_CORE
 cmp rdi,NEBOC_OPERATOR_CATALOG_CORE_LAST
 jbe .class_ready
 inc eax
 cmp rdi,NEBOC_OPERATOR_CATALOG_ALIAS_LAST
 jbe .class_ready
 inc eax
 cmp rdi,NEBOC_OPERATOR_CATALOG_DOMAIN_LAST
 jbe .class_ready
 inc eax
 cmp rdi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST
 jbe .class_ready
 inc eax
.class_ready:
 cmp rdx,rax
 jne .source
 xor r8d,r8d
 cmp rdx,NEBOC_OPERATOR_LSP_CLASS_UNICODE_ALIAS
 jne .domain
 or r8d,NEBOC_OPERATOR_LSP_MODIFIER_ALIAS
.domain:
 cmp rdx,NEBOC_OPERATOR_LSP_CLASS_DOMAIN_GATED
 jne .inactive
 or r8d,NEBOC_OPERATOR_LSP_MODIFIER_DOMAIN
.inactive:
 cmp rdx,NEBOC_OPERATOR_LSP_CLASS_RESERVED
 jb .store
 or r8d,NEBOC_OPERATOR_LSP_MODIFIER_INACTIVE
.store:
 mov [rcx+NEBOC_OPERATOR_LSP_REGISTRY_ID_OFFSET],rdi
 mov [rcx+NEBOC_OPERATOR_LSP_TOKEN_OFFSET],rsi
 mov [rcx+NEBOC_OPERATOR_LSP_HOVER_ID_OFFSET],rdi
 mov [rcx+NEBOC_OPERATOR_LSP_SIGNATURE_ID_OFFSET],rsi
 mov qword [rcx+NEBOC_OPERATOR_LSP_SEMANTIC_TYPE_OFFSET],NEBOC_OPERATOR_LSP_SEMANTIC_TYPE_OPERATOR
 mov [rcx+NEBOC_OPERATOR_LSP_MODIFIERS_OFFSET],r8
 mov [rcx+NEBOC_OPERATOR_LSP_GOTO_ROW_OFFSET],rdi
 mov [rcx+NEBOC_OPERATOR_LSP_CLASS_OFFSET],rdx
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
