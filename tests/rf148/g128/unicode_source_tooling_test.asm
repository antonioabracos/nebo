; DIAGNOSTICS-LSP-E-MIGRACAO-DE-OPERADORES native diagnostics/LSP/tooling conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"
%include "compiler/lsp/operator_metadata.inc"

extern neboc_operator_diagnostic_create
extern neboc_operator_precedence_explain
extern neboc_operator_diagnostic_classify
extern neboc_operator_quick_fix
extern neboc_operator_lsp_metadata
extern neboc_operator_code_action
extern neboc_operator_machine_parity

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .bss align=16
diagnostic: resb NEBOC_OPERATOR_DIAG_SIZE
explanation: resb NEBOC_OPERATOR_EXPLAIN_SIZE
classification: resb NEBOC_OPERATOR_CLASSIFY_SIZE
fix: resb NEBOC_OPERATOR_FIX_SIZE
metadata: resb NEBOC_OPERATOR_LSP_SIZE
action: resb NEBOC_OPERATOR_ACTION_SIZE
render: resb NEBOC_OPERATOR_RENDER_SIZE

section .text
global _start
_start:
 mov ebx,1
 mov edi,NEBOC_OPERATOR_DIAG_CATEGORY_TYPE
 mov esi,1
 mov edx,NEBOC_TOKEN_XOR
 mov ecx,10
 mov r8d,13
 lea r9,[rel diagnostic]
 call neboc_operator_diagnostic_create
 test eax,eax
 jnz fail
 cmp qword [rel diagnostic+NEBOC_OPERATOR_DIAG_CODE_OFFSET],NEBOC_OPERATOR_DIAG_NAMESPACE_BASE+NEBOC_OPERATOR_DIAG_CATEGORY_TYPE
 jne fail
 cmp qword [rel diagnostic+NEBOC_OPERATOR_DIAG_START_OFFSET],10
 jne fail
 cmp qword [rel diagnostic+NEBOC_OPERATOR_DIAG_CLASS_OFFSET],NEBOC_OPERATOR_LSP_CLASS_CORE
 jne fail
 mov rax,SENTINEL
 mov [rel fix],rax
 mov edi,NEBOC_OPERATOR_DIAG_CATEGORY_TYPE
 xor esi,esi
 mov edx,NEBOC_TOKEN_XOR
 xor ecx,ecx
 mov r8d,1
 lea r9,[rel fix]
 call neboc_operator_diagnostic_create
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel fix],rax
 jne fail

 mov ebx,2
 mov edi,NEBOC_TOKEN_XOR
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 mov edx,NEBOC_OPERATOR_BP_EQUALITY
 lea rcx,[rel explanation]
 call neboc_operator_precedence_explain
 test eax,eax
 jnz fail
 cmp qword [rel explanation+NEBOC_OPERATOR_EXPLAIN_LEFT_BP_OFFSET],NEBOC_OPERATOR_BP_XOR
 jne fail
 cmp qword [rel explanation+NEBOC_OPERATOR_EXPLAIN_ASSOC_OFFSET],NEBOC_OPERATOR_PARSE_ASSOC_LEFT
 jne fail
 cmp qword [rel explanation+NEBOC_OPERATOR_EXPLAIN_PARENTHESIZE_OFFSET],1
 jne fail

 mov ebx,3
 mov edi,NEBOC_OPERATOR_FAULT_TYPE|NEBOC_OPERATOR_FAULT_CAPABILITY
 mov esi,1
 lea rdx,[rel classification]
 call neboc_operator_diagnostic_classify
 test eax,eax
 jnz fail
 cmp qword [rel classification+NEBOC_OPERATOR_CLASSIFY_CATEGORY_OFFSET],NEBOC_OPERATOR_DIAG_CATEGORY_TYPE
 jne fail

 mov ebx,4
 mov edi,NEBOC_OPERATOR_DIAG_CATEGORY_REJECTED
 mov esi,180
 mov edx,0xff0d
 mov ecx,NEBOC_TOKEN_MINUS
 lea r8,[rel fix]
 call neboc_operator_quick_fix
 test eax,eax
 jnz fail
 cmp qword [rel fix+NEBOC_OPERATOR_FIX_SAFE_OFFSET],0
 jne fail
 cmp qword [rel fix+NEBOC_OPERATOR_FIX_AUTOMATIC_OFFSET],0
 jne fail

 mov ebx,5
 mov edi,48
 mov esi,NEBOC_TOKEN_MINUS
 mov edx,NEBOC_OPERATOR_LSP_CLASS_UNICODE_ALIAS
 lea rcx,[rel metadata]
 call neboc_operator_lsp_metadata
 test eax,eax
 jnz fail
 test qword [rel metadata+NEBOC_OPERATOR_LSP_MODIFIERS_OFFSET],NEBOC_OPERATOR_LSP_MODIFIER_ALIAS
 jz fail
 cmp qword [rel metadata+NEBOC_OPERATOR_LSP_GOTO_ROW_OFFSET],48
 jne fail
 mov rax,SENTINEL
 mov [rel metadata],rax
 mov edi,48
 mov esi,NEBOC_TOKEN_MINUS
 mov edx,NEBOC_OPERATOR_LSP_CLASS_CORE
 lea rcx,[rel metadata]
 call neboc_operator_lsp_metadata
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel metadata],rax
 jne fail

 mov ebx,6
 mov edi,NEBOC_OPERATOR_ACTION_REPLACE_SPELLING
 mov esi,48
 mov edx,NEBOC_TOKEN_MINUS
 mov ecx,NEBOC_TOKEN_MINUS
 mov r8d,1
 lea r9,[rel action]
 call neboc_operator_code_action
 test eax,eax
 jnz fail
 cmp qword [rel action+NEBOC_OPERATOR_ACTION_SAFE_OFFSET],1
 jne fail
 cmp qword [rel action+NEBOC_OPERATOR_ACTION_AUTOMATIC_OFFSET],0
 jne fail

 mov ebx,7
 xor r12d,r12d
 xor r13d,r13d
.format_loop:
 cmp r12d,5
 jae .formats_done
 lea rdi,[rel diagnostic]
 mov rsi,r12
 lea rdx,[rel render]
 call neboc_operator_machine_parity
 test eax,eax
 jnz fail
 mov rax,[rel render+NEBOC_OPERATOR_RENDER_FACT_HASH_OFFSET]
 test r12d,r12d
 jnz .compare_hash
 mov r13,rax
 jmp .next_format
.compare_hash:
 cmp rax,r13
 jne fail
.next_format:
 inc r12d
 jmp .format_loop
.formats_done:
 cmp qword [rel render+NEBOC_OPERATOR_RENDER_FIELD_COUNT_OFFSET],11
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
