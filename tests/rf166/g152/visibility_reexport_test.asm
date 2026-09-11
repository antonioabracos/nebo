bits 64
default rel

%include "compiler/parser/import_parser.inc"
%include "compiler/parser/selective_import_parser.inc"

global _start
extern neboc_selective_parse
extern neboc_selective_resolve
extern neboc_imports_unused
extern neboc_imports_ambiguous
extern neboc_visibility_check
extern neboc_reexport_graph_init
extern neboc_reexport_graph_add
extern neboc_imports_public_api_impact
extern neboc_selective_diagnostic_record
extern neboc_auto_import_plan
extern neboc_auto_import_plan_set_edit
extern neboc_auto_import_edits
extern neboc_organize_imports

section .rodata
selective: db 'import "project.users" { User; findUser; }.users;'
selective_len equ $-selective
reexport: db 'export import "project.users" { User; }.users;'
reexport_len equ $-reexport
duplicate: db 'import "project.users" { User; User; }.users;'
duplicate_len equ $-duplicate
wildcard: db 'import "project.users" { *; }.users;'
wildcard_len equ $-wildcard
replacement: db 'import "project.users" { User; };'
replacement_len equ $-replacement

section .bss
align 16
ast: resb NEBOC_IMPORT_AST_SIZE
export_ast: resb NEBOC_IMPORT_AST_SIZE
records: resb NEBOC_SELECTIVE_SYMBOL_SIZE*4
result: resb NEBOC_SELECTIVE_RESULT_SIZE
visibility_record: resb NEBOC_VIS_RECORD_SIZE
visible: resq 1
edges: resb NEBOC_REEXPORT_EDGE_SIZE*4
candidate: resb NEBOC_REEXPORT_EDGE_SIZE
graph: resb NEBOC_REEXPORT_GRAPH_SIZE
impact: resb NEBOC_API_IMPACT_SIZE
used: resq 2
count: resq 1
diagnostic: resq 3
plan: resb NEBOC_AUTO_IMPORT_PLAN_SIZE
edit: resb NEBOC_IMPORT_EDIT_SIZE
ordered: resq NEBOC_SELECTIVE_MAX
span_snapshot: resq 2

section .text
_start:
 ; S01: the public selective parser produces the shared G151/G152 AST with
 ; bounded SymbolIds, source spans and a source-sensitive trace.
 lea rdi,[rel selective]
 mov esi,selective_len
 lea rdx,[rel ast]
 call neboc_selective_parse
 test eax,eax
 jnz fail_11
 cmp qword [rel ast+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne fail_12
 cmp qword [rel ast+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET],2
 jne fail_13
 cmp qword [rel ast+NEBOC_IMPORT_AST_CONSUMED_OFFSET],selective_len
 jne fail_14
 cmp qword [rel ast+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET],0
 je fail_15
 cmp qword [rel ast+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET+8],0
 je fail_16
 cmp qword [rel ast+NEBOC_IMPORT_AST_TRACE_HASH_OFFSET],0
 je fail_17

 ; S02: equal spellings occupy distinct namespaces. Type and value records
 ; coexist; only the explicitly requested namespace can satisfy resolution.
 mov rax,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov [rel records+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET],rax
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET],NEBOC_NAMESPACE_TYPE
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_MODULE_OFFSET],0x101
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_PACKAGE_OFFSET],0x201
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_VALUE_OFFSET],41
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_ID_OFFSET],0x301
 mov [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET],rax
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET],NEBOC_NAMESPACE_VALUE
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_MODULE_OFFSET],0x101
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_PACKAGE_OFFSET],0x201
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_VALUE_OFFSET],43
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE+NEBOC_SELECTIVE_SYMBOL_ID_OFFSET],0x302
 mov rax,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+8]
 mov [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET],rax
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET],NEBOC_NAMESPACE_CALLABLE
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_MODULE_OFFSET],0x101
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_PACKAGE_OFFSET],0x201
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_VALUE_OFFSET],47
 mov qword [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*2+NEBOC_SELECTIVE_SYMBOL_ID_OFFSET],0x303
 lea rdi,[rel ast]
 mov rsi,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov edx,NEBOC_NAMESPACE_TYPE
 lea rcx,[rel records]
 mov r8d,3
 lea r9,[rel result]
 call neboc_selective_resolve
 test eax,eax
 jnz fail_21
 cmp qword [rel result+NEBOC_SELECTIVE_RESULT_VALUE_OFFSET],41
 jne fail_22
 cmp qword [rel result+NEBOC_SELECTIVE_RESULT_ID_OFFSET],0x301
 jne fail_23
 lea rdi,[rel ast]
 mov rsi,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+8]
 mov edx,NEBOC_NAMESPACE_CALLABLE
 lea rcx,[rel records]
 mov r8d,3
 lea r9,[rel result]
 call neboc_selective_resolve
 test eax,eax
 jnz fail_24
 cmp qword [rel result+NEBOC_SELECTIVE_RESULT_VALUE_OFFSET],47
 jne fail_25
 lea rdi,[rel records]
 mov esi,3
 lea rdx,[rel count]
 call neboc_imports_ambiguous
 test eax,eax
 jnz fail_26
 cmp qword [rel count],0
 jne fail_27

 ; S03: public, package-internal and module-private visibility are explicit.
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_OWNER_MODULE_OFFSET],0x101
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_OWNER_PACKAGE_OFFSET],0x201
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_FLAGS_OFFSET],NEBOC_VIS_FLAG_EXPLICIT_REEXPORT
 lea rdi,[rel visibility_record]
 mov esi,0x999
 mov edx,0x998
 mov ecx,1
 lea r8,[rel visible]
 call neboc_visibility_check
 test eax,eax
 jnz fail_31
 cmp qword [rel visible],1
 jne fail_32
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_VISIBILITY_OFFSET],NEBOC_VIS_INTERNAL
 lea rdi,[rel visibility_record]
 mov esi,0x999
 mov edx,0x201
 xor ecx,ecx
 lea r8,[rel visible]
 call neboc_visibility_check
 test eax,eax
 jnz fail_33
 lea rdi,[rel visibility_record]
 mov esi,0x999
 mov edx,0x202
 xor ecx,ecx
 lea r8,[rel visible]
 call neboc_visibility_check
 test eax,eax
 jz fail_34
 cmp qword [rel visible],0
 jne fail_35
 mov qword [rel visibility_record+NEBOC_VIS_RECORD_VISIBILITY_OFFSET],NEBOC_VIS_PRIVATE
 lea rdi,[rel visibility_record]
 mov esi,0x101
 mov edx,0x201
 xor ecx,ecx
 lea r8,[rel visible]
 call neboc_visibility_check
 test eax,eax
 jnz fail_36
 lea rdi,[rel visibility_record]
 mov esi,0x102
 mov edx,0x201
 xor ecx,ecx
 lea r8,[rel visible]
 call neboc_visibility_check
 test eax,eax
 jz fail_37

 ; S04: only the explicit export-import grammar feeds the bounded public graph.
 lea rdi,[rel reexport]
 mov esi,reexport_len
 lea rdx,[rel export_ast]
 call neboc_selective_parse
 test eax,eax
 jnz fail_41
 test qword [rel export_ast+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jz fail_42
 lea rdi,[rel graph]
 lea rsi,[rel edges]
 mov edx,4
 call neboc_reexport_graph_init
 test eax,eax
 jnz fail_43
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_ORIGIN_OFFSET],0x501
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_SOURCE_OFFSET],0x101
 mov rax,[rel export_ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov [rel candidate+NEBOC_REEXPORT_EDGE_SYMBOL_OFFSET],rax
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_KIND_OFFSET],NEBOC_NAMESPACE_TYPE
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_VISIBILITY_OFFSET],NEBOC_VIS_PUBLIC
 lea rdi,[rel graph]
 lea rsi,[rel candidate]
 call neboc_reexport_graph_add
 test eax,eax
 jnz fail_44
 lea rdi,[rel graph]
 lea rsi,[rel candidate]
 call neboc_reexport_graph_add
 test eax,eax
 jz fail_45
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_ORIGIN_OFFSET],0x101
 mov qword [rel candidate+NEBOC_REEXPORT_EDGE_SOURCE_OFFSET],0x501
 mov rax,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+8]
 mov [rel candidate+NEBOC_REEXPORT_EDGE_SYMBOL_OFFSET],rax
 lea rdi,[rel graph]
 lea rsi,[rel candidate]
 call neboc_reexport_graph_add
 test eax,eax
 jz fail_49
 lea rdi,[rel graph]
 xor esi,esi
 lea rdx,[rel impact]
 call neboc_imports_public_api_impact
 test eax,eax
 jnz fail_46
 cmp qword [rel impact+NEBOC_API_IMPACT_ADDED_OFFSET],1
 jne fail_47
 cmp qword [rel impact+NEBOC_API_IMPACT_BREAKING_OFFSET],0
 jne fail_48

 ; S05: unused, ambiguity and diagnostic records expose independent values.
 mov rax,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov [rel used],rax
 lea rdi,[rel ast]
 lea rsi,[rel used]
 mov edx,1
 lea rcx,[rel count]
 call neboc_imports_unused
 test eax,eax
 jnz fail_51
 cmp qword [rel count],1
 jne fail_52
 movdqu xmm0,[rel records]
 movdqu [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*3],xmm0
 movdqu xmm0,[rel records+16]
 movdqu [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*3+16],xmm0
 movdqu xmm0,[rel records+32]
 movdqu [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*3+32],xmm0
 movdqu xmm0,[rel records+48]
 movdqu [rel records+NEBOC_SELECTIVE_SYMBOL_SIZE*3+48],xmm0
 lea rdi,[rel records]
 mov esi,4
 lea rdx,[rel count]
 call neboc_imports_ambiguous
 test eax,eax
 jnz fail_53
 cmp qword [rel count],1
 jne fail_54
 mov edi,NEBOC_SELECTIVE_DIAG_UNUSED-NEBOC_SELECTIVE_DIAG_BASE
 mov rsi,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET]
 mov edx,1
 lea rcx,[rel diagnostic]
 call neboc_selective_diagnostic_record
 test eax,eax
 jnz fail_55
 cmp qword [rel diagnostic],NEBOC_SELECTIVE_DIAG_UNUSED
 jne fail_56
 cmp qword [rel diagnostic+16],1
 jne fail_57

 ; S06: auto-import is explicit, public-only and snapshot-bound. Stale plans
 ; clear the output edit and fail without touching source text.
 lea rdi,[rel plan]
 mov esi,0x701
 mov edx,0x701
 mov rcx,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov r8d,0x101
 mov r9d,NEBOC_VIS_PUBLIC
 call neboc_auto_import_plan
 test eax,eax
 jnz fail_61
 lea rdi,[rel plan]
 mov esi,9
 mov edx,9
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 call neboc_auto_import_plan_set_edit
 test eax,eax
 jnz fail_62
 lea rdi,[rel plan]
 mov esi,0x701
 lea rdx,[rel edit]
 call neboc_auto_import_edits
 test eax,eax
 jnz fail_63
 cmp qword [rel edit+NEBOC_IMPORT_EDIT_START_OFFSET],9
 jne fail_64
 cmp qword [rel edit+NEBOC_IMPORT_EDIT_REPLACEMENT_LENGTH_OFFSET],replacement_len
 jne fail_65
 lea rdi,[rel plan]
 mov esi,0x702
 lea rdx,[rel edit]
 call neboc_auto_import_edits
 test eax,eax
 jz fail_66
 cmp qword [rel edit+NEBOC_IMPORT_EDIT_DIGEST_OFFSET],0
 jne fail_67
 lea rdi,[rel plan]
 mov esi,0x701
 mov edx,0x701
 mov rcx,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 mov r8d,0x101
 mov r9d,NEBOC_VIS_PRIVATE
 call neboc_auto_import_plan
 test eax,eax
 jz fail_68

 ; S07: organizing imports returns a deterministic semantic order while the
 ; parser-owned comment/trivia attachment spans remain byte-for-byte stable.
 movdqu xmm0,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET]
 movdqu [rel span_snapshot],xmm0
 lea rdi,[rel ast]
 mov esi,NEBOC_ORGANIZE_POLICY_CHECK
 lea rdx,[rel ordered]
 mov ecx,NEBOC_SELECTIVE_MAX
 lea r8,[rel count]
 call neboc_organize_imports
 test eax,eax
 jnz fail_71
 cmp qword [rel count],2
 jne fail_72
 mov rax,[rel ordered]
 cmp rax,[rel ordered+8]
 ja fail_73
 movdqu xmm0,[rel ast+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET]
 pcmpeqq xmm0,[rel span_snapshot]
 pmovmskb eax,xmm0
 cmp eax,0xffff
 jne fail_74

 ; S08: malformed, duplicate and absent selective names fail closed.
 lea rdi,[rel duplicate]
 mov esi,duplicate_len
 lea rdx,[rel export_ast]
 call neboc_selective_parse
 test eax,eax
 jz fail_81
 cmp qword [rel export_ast+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_SELECTIVE_DUPLICATE
 jne fail_82
 lea rdi,[rel wildcard]
 mov esi,wildcard_len
 lea rdx,[rel export_ast]
 call neboc_selective_parse
 test eax,eax
 jz fail_83
 cmp qword [rel export_ast+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_WILDCARD
 jne fail_84
 lea rdi,[rel ast]
 mov rsi,0xdeadbeef
 mov edx,NEBOC_NAMESPACE_TYPE
 lea rcx,[rel records]
 mov r8d,3
 lea r9,[rel result]
 call neboc_selective_resolve
 test eax,eax
 jz fail_85
 cmp qword [rel result+NEBOC_SELECTIVE_RESULT_MATCHES_OFFSET],0
 jne fail_86

 xor edi,edi
 jmp exit

%macro FAIL 1
fail_%1:
 mov edi,%1
 jmp exit
%endmacro
FAIL 11
FAIL 12
FAIL 13
FAIL 14
FAIL 15
FAIL 16
FAIL 17
FAIL 21
FAIL 22
FAIL 23
FAIL 24
FAIL 25
FAIL 26
FAIL 27
FAIL 31
FAIL 32
FAIL 33
FAIL 34
FAIL 35
FAIL 36
FAIL 37
FAIL 41
FAIL 42
FAIL 43
FAIL 44
FAIL 45
FAIL 46
FAIL 47
FAIL 48
FAIL 49
FAIL 51
FAIL 52
FAIL 53
FAIL 54
FAIL 55
FAIL 56
FAIL 57
FAIL 61
FAIL 62
FAIL 63
FAIL 64
FAIL 65
FAIL 66
FAIL 67
FAIL 68
FAIL 71
FAIL 72
FAIL 73
FAIL 74
FAIL 81
FAIL 82
FAIL 83
FAIL 84
FAIL 85
FAIL 86

exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
