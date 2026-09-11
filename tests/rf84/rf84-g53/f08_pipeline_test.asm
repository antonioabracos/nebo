bits 64
default rel
%include "compiler/lexer/text_literals.inc"
%include "compiler/parser/text_contract.inc"
%include "compiler/semantic/types/text_semantic.inc"
%include "compiler/lowering/textual/text_ir.inc"
%include "compiler/codegen/textual/x86_64/text_codegen.inc"
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"

extern neboc_text_literal_token
extern neboc_text_parse_contract
extern neboc_text_literal_expr
extern neboc_text_type_info
extern neboc_text_lower
extern neboc_text_plan
extern neboc_text_codegen
extern neboc_text_codegen_plan
extern neboc_runtime_text_contract

section .rodata
literal: db '"','N',0xc3,0xa9,'"'

section .bss
align 8
token: resb NEBO_TEXT_LITERAL_TOKEN_SIZE
expr: resb NEBO_TEXT_LITERAL_EXPR_SIZE
info: resb NEBO_TEXT_TYPE_INFO_SIZE
plan: resb NEBO_TEXT_PLAN_SIZE

section .text
global _start
_start:
 lea rdi,[rel literal]
 mov esi,5
 mov edx,100
 lea rcx,[rel token]
 call neboc_text_literal_token
 test eax,eax
 jnz fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_DECODED_LENGTH_OFFSET],3
 jne fail

 mov edi,NEBO_TOKEN_TEXT_SIMPLE
 mov esi,100
 mov edx,105
 lea rcx,[rel expr]
 call neboc_text_literal_expr
 cmp eax,NEBO_AST_TEXT_LITERAL_EXPR
 jne fail

 mov edi,NEBO_TEXT_CORE_TYPE_STATIC_TEXT
 mov esi,NEBO_TEXT_STORAGE_STATIC
 mov edx,NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_VALID_UTF8
 lea rcx,[rel info]
 call neboc_text_type_info
 test eax,eax
 jnz fail
 cmp qword [rel info+NEBO_TEXT_TYPE_INFO_ENCODING_OFFSET],NEBO_TEXT_ENCODING_UTF8
 jne fail

 mov edi,NEBO_AST_TEXT_LITERAL_EXPR
 mov esi,3
 xor edx,edx
 lea rcx,[rel plan]
 call neboc_text_plan
 cmp eax,NEBO_HIR_TEXT_PLAN
 jne fail
 cmp qword [rel plan+NEBO_TEXT_PLAN_BYTE_LENGTH_OFFSET],3
 jne fail

 lea rdi,[rel plan]
 call neboc_text_codegen_plan
 cmp eax,NEBO_CODEGEN_STATIC_DESCRIPTOR
 jne fail
 cmp edx,NEBO_CODEGEN_TEXT_RUNTIME_CONTRACT
 jne fail

 call neboc_runtime_text_contract
 cmp eax,NEBO_RUNTIME_TEXT_ABI_VERSION
 jne fail
 cmp edx,NEBO_TEXT_CHAR_BYTES_RUNTIME_TEXT_DESCRIPTOR_SIZE
 jne fail
 cmp ecx,NEBO_RUNTIME_TEXT_ENCODING_UTF8
 jne fail
 cmp r8d,NEBO_RUNTIME_TEXT_FLAGS_LITERAL
 jne fail

 mov edi,NEBO_TOKEN_TEXT_SIMPLE
 call neboc_text_parse_contract
 cmp eax,NEBO_AST_TEXT_LITERAL
 jne fail
 mov edi,eax
 call neboc_text_lower
 cmp eax,NEBO_LIR_TEXT_DESCRIPTOR
 jne fail
 mov edi,eax
 call neboc_text_codegen
 cmp eax,NEBO_CODEGEN_STATIC_DESCRIPTOR
 jne fail

 mov qword [rel plan+NEBO_TEXT_PLAN_RUNTIME_CONTRACT_OFFSET],99
 lea rdi,[rel plan]
 call neboc_text_codegen_plan
 cmp eax,NEBO_CODEGEN_ERROR
 jne fail

 mov edi,NEBO_TOKEN_TEXT_RAW
 call neboc_text_parse_contract
 cmp eax,NEBO_AST_RAW_TEXT_LITERAL
 jne fail
 mov edi,NEBO_TOKEN_TEXT_RAW
 xor esi,esi
 mov edx,6
 lea rcx,[rel expr]
 call neboc_text_literal_expr
 ; G063 promotes the G053 internal raw node to the public expression path.
 cmp eax,NEBO_AST_RAW_TEXT_LITERAL
 jne fail
 cmp qword [rel expr+NEBO_TEXT_LITERAL_EXPR_START_OFFSET],0
 jne fail
 cmp qword [rel expr+NEBO_TEXT_LITERAL_EXPR_END_OFFSET],6
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,8
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
