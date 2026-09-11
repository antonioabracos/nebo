bits 64
default rel
%include "compiler/parser/import_parser.inc"

global _start
extern neboc_import_decl_parse
extern neboc_import_parse
extern neboc_import_resolve_alias
extern neboc_import_alias_bind
extern neboc_import_resolve
extern neboc_import_detect_collisions
extern neboc_import_modules
extern neboc_import_explain
extern neboc_import_qualify
extern neboc_named_capsule
extern neboc_anonymous_capsule
extern neboc_import_diagnostic
extern neboc_import_format

section .rodata
simple: db 'import "project.core".kernel;'
simple_len equ $-simple
named: db 'import { import "project.core".left; import "project.util".right; }.identity;'
named_len equ $-named
anonymous: db 'import { import "project.core".left; import "project.util".right; };'
anonymous_len equ $-anonymous
wildcard: db 'import "project.core".*;'
wildcard_len equ $-wildcard
reserved: db 'import "project.core".kernel::value;'
reserved_len equ $-reserved
dynamic: db 'import dynamic "project.core".kernel;'
dynamic_len equ $-dynamic
missing_alias: db 'import "project.core";'
missing_alias_len equ $-missing_alias
selective: db 'import { value };'
selective_len equ $-selective

section .bss
align 16
ast0: resb NEBOC_IMPORT_AST_SIZE
ast1: resb NEBOC_IMPORT_AST_SIZE
ast2: resb NEBOC_IMPORT_AST_SIZE
formatted: resb NEBOC_IMPORT_MAX_BYTES
out_form: resq 1
out_scalar: resq 1
out_length: resq 1
out_modules: resq 2
out_trace: resq 4
pairs: resq 4
entries: resq 2

section .text
_start:
 ; S01: the compatibility surface delegates to the canonical AST parser.
 lea rdi,[rel simple]
 mov esi,simple_len
 lea rdx,[rel out_form]
 call neboc_import_parse
 test eax,eax
 jnz fail_1
 cmp qword [rel out_form],NEBOC_IMPORT_FORM_SIMPLE
 jne fail_2
 lea rdi,[rel simple]
 mov esi,simple_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 test eax,eax
 jnz fail_3
 cmp qword [rel ast0+NEBOC_IMPORT_AST_COUNT_OFFSET],1
 jne fail_4
 cmp qword [rel ast0+NEBOC_IMPORT_AST_CONSUMED_OFFSET],simple_len
 jne fail_5
 cmp qword [rel ast0+NEBOC_IMPORT_AST_TRACE_HASH_OFFSET],0
 je fail_6

 ; S02/S03: one SymbolId binds and resolves the alias namespace.
 mov rdx,[rel ast0+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 mov rcx,[rel ast0+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 lea rdi,[rel ast0]
 xor esi,esi
 call neboc_import_alias_bind
 test eax,eax
 jnz fail_7
 lea rdi,[rel ast0]
 mov rsi,[rel ast0+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 lea rdx,[rel out_scalar]
 call neboc_import_resolve
 test eax,eax
 jnz fail_8
 mov rax,[rel ast0+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 cmp rax,[rel out_scalar]
 jne fail_9
 lea rdi,[rel ast0]
 mov rsi,[rel ast0+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 mov rdx,0x45454545
 lea r8,[rel out_trace]
 call neboc_import_explain
 test eax,eax
 jnz fail_10
 cmp qword [rel out_trace],NEBOC_IMPORT_FORM_SIMPLE
 jne fail_11
 cmp qword [rel out_trace+16],0x45454545
 jne fail_12

 ; S04: named capsules are compile-time records with an explicit namespace.
 lea rdi,[rel named]
 mov esi,named_len
 lea rdx,[rel ast1]
 call neboc_import_decl_parse
 test eax,eax
 jnz fail_13
 cmp qword [rel ast1+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jne fail_14
 cmp qword [rel ast1+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jne fail_15
 cmp qword [rel ast1+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET],0
 je fail_16
 lea rdi,[rel ast1]
 mov rsi,[rel ast1+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET]
 lea rdx,[rel out_scalar]
 call neboc_import_resolve
 cmp eax,NEBOC_IMPORT_DIAG_AMBIGUOUS_SYMBOL
 jne fail_17
 mov rdi,[rel ast1+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET]
 lea rsi,[rel entries]
 mov rax,[rel ast1+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 mov [rel entries],rax
 mov rax,[rel ast1+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 mov [rel entries+8],rax
 mov edx,2
 lea rcx,[rel out_scalar]
 call neboc_named_capsule
 test eax,eax
 jnz fail_18

 ; S05: anonymous capsules expose distinct selected aliases only.
 lea rdi,[rel anonymous]
 mov esi,anonymous_len
 lea rdx,[rel ast2]
 call neboc_import_decl_parse
 test eax,eax
 jnz fail_19
 cmp qword [rel ast2+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_ANONYMOUS_CAPSULE
 jne fail_20
 mov rax,[rel ast2+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 mov [rel entries],rax
 mov rax,[rel ast2+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 mov [rel entries+8],rax
 lea rdi,[rel entries]
 mov esi,2
 lea rdx,[rel out_scalar]
 call neboc_anonymous_capsule
 test eax,eax
 jnz fail_21
 cmp qword [rel out_scalar],3
 jne fail_22

 ; S06: collisions and identical duplicate bindings are order-independent.
 lea rdi,[rel ast2]
 lea rsi,[rel out_scalar]
 call neboc_import_detect_collisions
 test eax,eax
 jnz fail_23
 mov rax,[rel ast2+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 xchg rax,[rel ast2+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 mov [rel out_length],rax
 lea rdi,[rel ast2]
 lea rsi,[rel out_scalar]
 call neboc_import_detect_collisions
 cmp eax,4
 jne fail_24
 cmp qword [rel out_scalar],NEBOC_IMPORT_DIAG_ALIAS_COLLISION
 jne fail_25
 mov rax,[rel out_length]
 mov [rel ast2+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET],rax
 mov rax,[rel ast0+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 mov [rel pairs],rax
 mov [rel pairs+16],rax
 mov rax,[rel ast0+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 mov [rel pairs+8],rax
 mov [rel pairs+24],rax
 lea rdi,[rel pairs]
 mov esi,2
 mov rdx,[rel pairs]
 lea r8,[rel out_scalar]
 call neboc_import_resolve_alias
 test eax,eax
 jnz fail_26

 ; S07: formatter, module inventory and diagnostic registry share the AST.
 lea rdi,[rel simple]
 mov esi,simple_len
 lea rdx,[rel formatted]
 mov ecx,NEBOC_IMPORT_MAX_BYTES
 lea r8,[rel out_length]
 call neboc_import_format
 test eax,eax
 jnz fail_27
 cmp qword [rel out_length],simple_len
 jne fail_28
 lea rsi,[rel simple]
 lea rdi,[rel formatted]
 mov ecx,simple_len
 repe cmpsb
 jne fail_29
 lea rdi,[rel ast1]
 lea rsi,[rel out_modules]
 mov edx,2
 lea rcx,[rel out_length]
 call neboc_import_modules
 test eax,eax
 jnz fail_30
 cmp qword [rel out_length],2
 jne fail_31
 mov edi,10
 lea rsi,[rel out_scalar]
 call neboc_import_diagnostic
 test eax,eax
 jnz fail_32
 cmp qword [rel out_scalar],NEBOC_IMPORT_DIAG_AMBIGUOUS_SYMBOL
 jne fail_33
 mov rdi,[rel ast0+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 mov rsi,0x98989898
 lea rdx,[rel out_scalar]
 call neboc_import_qualify
 test eax,eax
 jnz fail_34
 cmp qword [rel out_scalar],0
 je fail_35

 ; S08: closed grammar failures publish only their stable diagnostic.
 lea rdi,[rel wildcard]
 mov esi,wildcard_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 cmp eax,4
 jne fail_36
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_WILDCARD
 jne fail_37
 cmp qword [rel ast0+NEBOC_IMPORT_AST_FORM_OFFSET],0
 jne fail_38
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_SPAN_OFFSET],0
 je fail_43
 lea rdi,[rel reserved]
 mov esi,reserved_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_RESERVED_QUALIFIER
 jne fail_39
 lea rdi,[rel dynamic]
 mov esi,dynamic_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_DYNAMIC_IMPORT
 jne fail_40
 lea rdi,[rel missing_alias]
 mov esi,missing_alias_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_ALIAS_REQUIRED
 jne fail_41
 lea rdi,[rel selective]
 mov esi,selective_len
 lea rdx,[rel ast0]
 call neboc_import_decl_parse
 cmp qword [rel ast0+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_SELECTIVE_DEFERRED
 jne fail_42

 xor edi,edi
 jmp exit
%assign n 1
%rep 43
fail_%+n:
 mov edi,n
 jmp exit
%assign n n+1
%endrep
exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
