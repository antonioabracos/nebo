; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES precedence, associativity and parse-tree explanation.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"

extern neboc_operator_precedence_lookup

section .text
; operator_precedence_explain(token, fixity, parent_bp, out_explanation*)
NEBOC_ABI_FUNCTION neboc_operator_precedence_explain
 test rcx,rcx
 jz .invalid
 push rbx
 sub rsp,16
 mov rbx,rcx
 mov [rsp],rdx
 call neboc_operator_precedence_lookup
 test rax,rax
 jz .source
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_TOKEN_OFFSET],rdi
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_FIXITY_OFFSET],rsi
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_LEFT_BP_OFFSET],rdx
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_RIGHT_BP_OFFSET],rcx
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_ASSOC_OFFSET],r8
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_FAMILY_OFFSET],r9
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_FLAGS_OFFSET],r10
 mov rax,[rsp]
 xor r11d,r11d
 cmp rax,rdx
 seta r11b
 mov [rbx+NEBOC_OPERATOR_EXPLAIN_PARENTHESIZE_OFFSET],r11
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Tooling-facing name for the same bounded parse grouping explanation.
NEBOC_ABI_FUNCTION neboc_explain_parse_tree
 jmp neboc_operator_precedence_explain

section .note.GNU-stack noalloc noexec nowrite progbits
