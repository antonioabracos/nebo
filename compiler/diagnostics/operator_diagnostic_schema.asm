; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES single typed OperatorDiagnostic schema.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"

section .text
; operator_diagnostic_create(category, registry_id, token, start, end, out*)
NEBOC_ABI_FUNCTION neboc_operator_diagnostic_create
 test r9,r9
 jz .invalid
 test rdi,rdi
 jz .source
 cmp rdi,NEBOC_OPERATOR_DIAG_CATEGORY_MAX
 ja .source
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_OPERATOR_REGISTRY_ENTRY_COUNT
 ja .source
 cmp rcx,r8
 ja .source
 mov r10,NEBOC_OPERATOR_DIAG_NAMESPACE_BASE
 add r10,rdi
 mov r11d,NEBOC_OPERATOR_DIAG_SEVERITY_ERROR
 cmp rdi,NEBOC_OPERATOR_DIAG_CATEGORY_RESERVED
 jne .flags
 mov r11d,NEBOC_OPERATOR_DIAG_SEVERITY_WARNING
.flags:
 mov [r9+NEBOC_OPERATOR_DIAG_CODE_OFFSET],r10
 mov [r9+NEBOC_OPERATOR_DIAG_REGISTRY_ID_OFFSET],rsi
 mov [r9+NEBOC_OPERATOR_DIAG_TOKEN_OFFSET],rdx
 mov qword [r9+NEBOC_OPERATOR_DIAG_CODEPOINT_OFFSET],0
 mov [r9+NEBOC_OPERATOR_DIAG_START_OFFSET],rcx
 mov [r9+NEBOC_OPERATOR_DIAG_END_OFFSET],r8
 mov [r9+NEBOC_OPERATOR_DIAG_SEVERITY_OFFSET],r11
 mov [r9+NEBOC_OPERATOR_DIAG_CATEGORY_OFFSET],rdi
 mov qword [r9+NEBOC_OPERATOR_DIAG_FLAGS_OFFSET],NEBOC_OPERATOR_DIAG_FLAG_MACHINE_PARITY|NEBOC_OPERATOR_DIAG_FLAG_SOURCE_MAP
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
