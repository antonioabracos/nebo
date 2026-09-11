bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
%include "compiler/parser/selective_import_parser.inc"

extern neboc_import_decl_parse

section .text
; SelectiveImport.parse(source, length, out ImportAstNode) delegates to the
; single canonical import parser and only accepts the G152 selective form.
NEBOC_ABI_FUNCTION neboc_selective_parse
 test rdx,rdx
 jz .arg
 push rbx
 mov rbx,rdx
 call neboc_import_decl_parse
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 je .ok
 mov rdi,rbx
 mov ecx,NEBOC_IMPORT_AST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rbx+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_SELECTIVE_DIAG_SYNTAX
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 pop rbx
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
