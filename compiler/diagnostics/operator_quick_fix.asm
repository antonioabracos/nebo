; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES explicit safe suggestions for RESERVED/REJECTED spellings.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"

section .text
; operator_quick_fix(category, registry_id, offending_cp, replacement_token, out*)
NEBOC_ABI_FUNCTION neboc_operator_quick_fix
 test r8,r8
 jz .invalid
 cmp rdi,NEBOC_OPERATOR_DIAG_CATEGORY_RESERVED
 je .reserved
 cmp rdi,NEBOC_OPERATOR_DIAG_CATEGORY_REJECTED
 jne .source
.rejected:
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST
 jbe .source
 jmp .eligible
.reserved:
 cmp rsi,NEBOC_OPERATOR_CATALOG_DOMAIN_LAST
 jbe .source
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST
 ja .source
.eligible:
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_OPERATOR_CATALOG_ENTRY_COUNT
 ja .source
 test rcx,rcx
 jz .source
 mov qword [r8+NEBOC_OPERATOR_FIX_KIND_OFFSET],NEBOC_OPERATOR_FIX_KIND_REPLACE_SPELLING
 ; Replacement text is never automatic.  G145 marks only five exact spelling
 ; substitutions as semantically safe; contextual or intent-changing guidance
 ; remains explicitly manual.
 xor eax,eax
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST+3
 je .safe
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST+12
 je .safe
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST+13
 je .safe
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST+15
 je .safe
 cmp rsi,NEBOC_OPERATOR_CATALOG_RESERVED_LAST+25
 jne .safe_ready
.safe:
 mov eax,1
.safe_ready:
 mov [r8+NEBOC_OPERATOR_FIX_SAFE_OFFSET],rax
 mov qword [r8+NEBOC_OPERATOR_FIX_AUTOMATIC_OFFSET],0
 mov [r8+NEBOC_OPERATOR_FIX_REGISTRY_ID_OFFSET],rsi
 mov [r8+NEBOC_OPERATOR_FIX_OFFENDING_CODEPOINT_OFFSET],rdx
 mov [r8+NEBOC_OPERATOR_FIX_REPLACEMENT_TOKEN_OFFSET],rcx
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
