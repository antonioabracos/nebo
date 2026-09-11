bits 64
default rel

%include "compiler/tokens/operator_registry_generated.inc"
%include "compiler/tokens/operator_token_metadata.inc"
extern neboc_operator_registry_entry_table
extern neboc_operator_registry_lexeme_table
extern neboc_operator_atom_metadata
extern neboc_operator_atom_metadata_abi
extern neboc_operator_lexeme_lookup

%macro CHECK_MATCH 7
 lea rdi,[rel %1]
 mov esi,%2
 call neboc_operator_lexeme_lookup
 cmp eax,1
 jne fail
 cmp edx,%3
 jne fail
 cmp ecx,%4
 jne fail
 cmp r8d,%5
 jne fail
 cmp r9d,%6
 jne fail
 cmp r10d,%7
 jne fail
%endmacro

section .rodata
dot: db '.'
arrow: db '->'
comment: db '//'
less_equal: db '<='
greater_equal: db '>='
dot_dot: db '..'
slash: db '/'
underscore: db '_'

section .text
global _start
_start:
 call neboc_operator_registry_entry_table
 test rax,rax
 jz fail
 cmp edx,11
 jne fail
 cmp ecx,1
 jne fail
 mov rbx,rax
 mov ecx,11
.entry_domain_loop:
 cmp qword [rbx+NEBOC_OPERATOR_ENTRY_DOMAIN_OFFSET],NEBOC_OPERATOR_DOMAIN_CORE
 jne fail
 add rbx,NEBOC_OPERATOR_ENTRY_SIZE
 loop .entry_domain_loop
 call neboc_operator_registry_lexeme_table
 test rax,rax
 jz fail
 cmp edx,15
 jne fail
 cmp ecx,1
 jne fail
 cmp qword [rax+NEBOC_OPERATOR_LEXEME_SIZE*5+NEBOC_OPERATOR_LEXEME_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_RESERVED
 jne fail
 cmp qword [rax+NEBOC_OPERATOR_LEXEME_SIZE*6+NEBOC_OPERATOR_LEXEME_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_RESERVED
 jne fail
 cmp qword [rax+NEBOC_OPERATOR_LEXEME_SIZE*11+NEBOC_OPERATOR_LEXEME_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_RESERVED
 jne fail
 cmp qword [rax+NEBOC_OPERATOR_LEXEME_SIZE*12+NEBOC_OPERATOR_LEXEME_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_RESERVED
 jne fail

 mov edi,NEBOC_OPERATOR_ATOM_ARROW
 mov esi,NEBOC_OPERATOR_CONTEXT_TYPE
 call neboc_operator_atom_metadata
 test rax,rax
 jz fail
 cmp edx,1
 jne fail
 cmp qword [rax],NEBOC_OPERATOR_REGISTRY_ARROW
 jne fail
 cmp qword [rax+8],NEBOC_OPERATOR_TOKEN_ARROW
 jne fail
 cmp qword [rax+OPERATOR_ATOM_META_DOMAIN_OFFSET],NEBOC_OPERATOR_DOMAIN_CORE
 jne fail
 call neboc_operator_atom_metadata_abi
 cmp eax,OPERATOR_ATOM_META_SIZE
 jne fail
 cmp edx,15
 jne fail
 cmp ecx,1
 jne fail
 mov edi,NEBOC_OPERATOR_ATOM_ARROW
 mov esi,NEBOC_OPERATOR_CONTEXT_LEXICAL
 call neboc_operator_atom_metadata
 test rax,rax
 jz fail
 test edx,edx
 jnz fail
 mov edi,NEBOC_OPERATOR_REGISTRY_LEXEME_COUNT
 mov esi,NEBOC_OPERATOR_CONTEXT_TYPE
 call neboc_operator_atom_metadata
 test rax,rax
 jnz fail

 CHECK_MATCH dot,1,NEBOC_OPERATOR_TOKEN_DOT,1,NEBOC_OPERATOR_ATOM_DOT,NEBOC_OPERATOR_REGISTRY_DOT,NEBOC_TOKEN_FLAG_NONE
 CHECK_MATCH arrow,2,NEBOC_OPERATOR_TOKEN_ARROW,2,NEBOC_OPERATOR_ATOM_ARROW,NEBOC_OPERATOR_REGISTRY_ARROW,NEBOC_TOKEN_FLAG_RESERVED
 CHECK_MATCH comment,2,NEBOC_OPERATOR_TOKEN_LINE_COMMENT,2,NEBOC_OPERATOR_ATOM_LINE_COMMENT,NEBOC_OPERATOR_REGISTRY_LINE_COMMENT,NEBOC_TOKEN_FLAG_NONE
 CHECK_MATCH underscore,1,NEBOC_OPERATOR_TOKEN_UNDERSCORE,1,NEBOC_OPERATOR_ATOM_UNDERSCORE,NEBOC_OPERATOR_REGISTRY_UNDERSCORE,NEBOC_TOKEN_FLAG_NONE

 lea rdi,[rel less_equal]
 mov esi,2
 call neboc_operator_lexeme_lookup
 test eax,eax
 jnz fail
 lea rdi,[rel greater_equal]
 mov esi,2
 call neboc_operator_lexeme_lookup
 test eax,eax
 jnz fail
 lea rdi,[rel dot_dot]
 mov esi,2
 call neboc_operator_lexeme_lookup
 test eax,eax
 jnz fail
 lea rdi,[rel slash]
 mov esi,1
 call neboc_operator_lexeme_lookup
 test eax,eax
 jnz fail
 xor edi,edi
 mov esi,1
 call neboc_operator_lexeme_lookup
 test eax,eax
 jnz fail

 mov eax,60
 xor edi,edi
 syscall
fail:
 mov eax,60
 mov edi,1
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
