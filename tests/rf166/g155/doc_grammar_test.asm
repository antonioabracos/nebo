; RF166-G155 independent native conformance for DocParser.parse.
bits 64
default rel

%include "compiler/parser/doc.inc"
%include "compiler/tokens/token_kind.inc"

global _start
extern neboc_doc_parse
extern neboc_doc_keyword
extern neboc_doc_attach
extern neboc_doc_fields
extern neboc_doc_contract_blocks
extern neboc_doc_semantic_blocks
extern neboc_doc_lifecycle
extern neboc_doc_examples
extern neboc_token_keyword_kind

%define SENTINEL 0xa5a5a5a5a5a5a5a5
%define ALL_FIELDS 0x3fff

%macro PARSE_OK 3
    lea rdi,[rel %1]
    mov esi,%2
    lea rdx,[rel result_a]
    call neboc_doc_parse
    test eax,eax
    jnz fail
    cmp qword [rel result_a+NEBOC_DOC_ATTACHMENT_KIND_OFFSET],%3
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_ATTACHMENT_SYMBOL_ID_OFFSET],0
    je fail
%endmacro

%macro PARSE_FAIL 3
    lea rdi,[rel result_b]
    mov ecx,NEBOC_DOC_RESULT_QWORDS
    mov rax,SENTINEL
    rep stosq
    lea rdi,[rel %1]
    mov esi,%2
    lea rdx,[rel result_b]
    call neboc_doc_parse
    test eax,eax
    jz fail
    cmp edx,%3
    jne fail
    mov rax,SENTINEL
    cmp qword [rel result_b],rax
    jne fail
    cmp qword [rel result_b+NEBOC_DOC_RESULT_BYTES-8],rax
    jne fail
%endmacro

section .text
_start:
    ; Registry schema v2 reserves only the exact lowercase spelling.  This is
    ; the RF148 migration decision for the new G155 source syntax.
%if NEBOC_KEYWORD_REGISTRY_SCHEMA_VERSION != 2
 %error "G155 keyword Registry schema drift"
%endif
    lea rdi,[rel doc_keyword]
    mov esi,doc_keyword_len
    call neboc_token_keyword_kind
    cmp eax,NEBOC_TOKEN_KW_DOC
    jne fail
    lea rdi,[rel docs_identifier]
    mov esi,docs_identifier_len
    call neboc_token_keyword_kind
    test eax,eax
    jnz fail
    lea rdi,[rel doc_case_identifier]
    mov esi,doc_case_identifier_len
    call neboc_token_keyword_kind
    test eax,eax
    jnz fail

    lea rdi,[rel complete_doc]
    mov esi,complete_doc_len
    lea rdx,[rel result_a]
    call neboc_doc_parse
    test eax,eax
    jnz fail
.complete_parsed:
    cmp qword [rel result_a+NEBOC_DOC_ATTACHMENT_KIND_OFFSET],NEBOC_DOC_ATTACHMENT_MODULE
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_ATTACHMENT_SYMBOL_ID_OFFSET],0
    je fail
    cmp qword [rel result_a+NEBOC_DOC_FIELD_MASK_OFFSET],ALL_FIELDS
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_FIELD_COUNT_OFFSET],14
    jne fail
    ; Native DocFieldAst records publish exact source order plus field/payload
    ; spans, instead of asking the renderer to infer nodes from the bit mask.
    lea rbx,[rel result_a+NEBOC_DOC_FIELD_RECORDS_OFFSET]
    mov r8d,NEBOC_DOC_FIELD_TITLE
    xor r10d,r10d
.field_record_loop:
    cmp [rbx+NEBOC_DOC_FIELD_RECORD_KIND_OFFSET],r8
    jne fail
    mov rax,[rbx+NEBOC_DOC_FIELD_RECORD_SPAN_OFFSET]
    mov r11d,eax
    cmp r11d,r10d
    jb fail
    mov r10d,r11d
    shr rax,32
    test eax,eax
    jz fail
    mov rax,[rbx+NEBOC_DOC_FIELD_RECORD_PAYLOAD_SPAN_OFFSET]
    shr rax,32
    test eax,eax
    jz fail
    add rbx,NEBOC_DOC_FIELD_RECORD_BYTES
    inc r8d
    cmp r8d,NEBOC_DOC_FIELD_LAW+1
    jb .field_record_loop
    cmp qword [rel result_a+NEBOC_DOC_FIELD_RECORDS_OFFSET+12*NEBOC_DOC_FIELD_RECORD_BYTES+NEBOC_DOC_FIELD_RECORD_LABEL_SPAN_OFFSET],0
    je fail
    cmp qword [rel result_a+NEBOC_DOC_FIELD_RECORDS_OFFSET+13*NEBOC_DOC_FIELD_RECORD_BYTES+NEBOC_DOC_FIELD_RECORD_LABEL_SPAN_OFFSET],0
    je fail
    cmp qword [rel result_a+NEBOC_DOC_EXAMPLE_COUNT_OFFSET],1
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_LAW_COUNT_OFFSET],1
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_COMMENT_COUNT_OFFSET],2
    jne fail
    cmp qword [rel result_a+NEBOC_DOC_EXAMPLE_SPAN_OFFSET],0
    je fail
    cmp qword [rel result_a+NEBOC_DOC_LAW_SPAN_OFFSET],0
    je fail
    mov rax,[rel result_a+NEBOC_DOC_CST_DIGEST_OFFSET]
    cmp rax,[rel result_a+NEBOC_DOC_AST_DIGEST_OFFSET]
    je fail
    test qword [rel result_a+NEBOC_DOC_FLAGS_OFFSET],NEBOC_DOC_FLAG_HAS_TRIVIA
    jz fail

    ; All allowed declaration targets use the same parser and SymbolId rule.
    PARSE_OK target_type_doc,target_type_doc_len,NEBOC_DOC_ATTACHMENT_TYPE
    PARSE_OK target_struct_doc,target_struct_doc_len,NEBOC_DOC_ATTACHMENT_STRUCT
    PARSE_OK target_enum_doc,target_enum_doc_len,NEBOC_DOC_ATTACHMENT_ENUM
    PARSE_OK target_fn_doc,target_fn_doc_len,NEBOC_DOC_ATTACHMENT_FUNCTION
    PARSE_OK target_function_doc,target_function_doc_len,NEBOC_DOC_ATTACHMENT_FUNCTION
    PARSE_OK target_const_doc,target_const_doc_len,NEBOC_DOC_ATTACHMENT_CONSTANT

    ; CST retains comment trivia while the reduced AST digest ignores it.
    PARSE_OK trivia_a,trivia_a_len,NEBOC_DOC_ATTACHMENT_MODULE
    mov rax,[rel result_a+NEBOC_DOC_CST_DIGEST_OFFSET]
    mov [rel cst_a],rax
    mov rax,[rel result_a+NEBOC_DOC_AST_DIGEST_OFFSET]
    mov [rel ast_a],rax
    PARSE_OK trivia_b,trivia_b_len,NEBOC_DOC_ATTACHMENT_MODULE
    mov rax,[rel result_a+NEBOC_DOC_CST_DIGEST_OFFSET]
    cmp rax,[rel cst_a]
    je fail
    mov rax,[rel result_a+NEBOC_DOC_AST_DIGEST_OFFSET]
    cmp rax,[rel ast_a]
    jne fail

    ; Compatibility symbols are aliases, never secondary parsers.
%macro COMPAT_OK 1
    lea rdi,[rel complete_doc]
    mov esi,complete_doc_len
    lea rdx,[rel result_a]
    call %1
    test eax,eax
    jnz fail
    cmp qword [rel result_a+NEBOC_DOC_FIELD_MASK_OFFSET],ALL_FIELDS
    jne fail
%endmacro
    COMPAT_OK neboc_doc_keyword
    COMPAT_OK neboc_doc_attach
    COMPAT_OK neboc_doc_fields
    COMPAT_OK neboc_doc_contract_blocks
    COMPAT_OK neboc_doc_semantic_blocks
    COMPAT_OK neboc_doc_lifecycle
    COMPAT_OK neboc_doc_examples
%unmacro COMPAT_OK 1

    PARSE_FAIL docs_doc,docs_doc_len,NEBOC_DOC_DIAG_DOCS_KEYWORD
    PARSE_FAIL comments_only,comments_only_len,NEBOC_DOC_DIAG_DOCS_KEYWORD
    PARSE_FAIL unknown_doc,unknown_doc_len,NEBOC_DOC_DIAG_UNKNOWN_FIELD
    PARSE_FAIL duplicate_field_doc,duplicate_field_doc_len,NEBOC_DOC_DIAG_DUPLICATE_FIELD
    PARSE_FAIL orphan_doc,orphan_doc_len,NEBOC_DOC_DIAG_ORPHAN_ATTACHMENT
    PARSE_FAIL duplicate_doc,duplicate_doc_len,NEBOC_DOC_DIAG_DUPLICATE_DOC
    PARSE_FAIL malformed_example_doc,malformed_example_doc_len,NEBOC_DOC_DIAG_MALFORMED_EXAMPLE
    PARSE_FAIL invalid_utf8_doc,invalid_utf8_doc_len,NEBOC_DOC_DIAG_UTF8

    lea rdi,[rel result_b]
    mov ecx,NEBOC_DOC_RESULT_QWORDS
    mov rax,SENTINEL
    rep stosq
    lea rdi,[rel complete_doc]
    xor esi,esi
    lea rdx,[rel result_b]
    call neboc_doc_parse
    test eax,eax
    jz fail
    cmp edx,NEBOC_DOC_DIAG_LENGTH
    jne fail
    mov rax,SENTINEL
    cmp qword [rel result_b],rax
    jne fail
    cmp qword [rel result_b+NEBOC_DOC_RESULT_BYTES-8],rax
    jne fail
    lea rdi,[rel complete_doc]
    mov esi,NEBOC_DOC_MAX_SOURCE_BYTES+1
    lea rdx,[rel result_b]
    call neboc_doc_parse
    test eax,eax
    jz fail
    cmp edx,NEBOC_DOC_DIAG_LIMIT
    jne fail

    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall

section .rodata
doc_keyword: db 'doc'
doc_keyword_len equ $-doc_keyword
docs_identifier: db 'docs'
docs_identifier_len equ $-docs_identifier
doc_case_identifier: db 'Doc'
doc_case_identifier_len equ $-doc_case_identifier

complete_doc:
    db 'doc {',10
    db '  // retained leading field trivia',10
    db '  title: "Caf',0xc3,0xa9,' API";',10
    db '  summary: "Bounded semantic documentation";',10
    db '  parameters { value: "Input identity"; }',10
    db '  returns { value: "Output identity"; }',10
    db '  errors { InvalidValue: "Rejected input"; }',10
    db '  effects { pure; }',10
    db '  capabilities { none; }',10
    db '  ownership { result: owned; }',10
    db '  complexity { time: "O(1)"; }',10
    db '  risks { overflow: "checked"; }',10
    db '  since: "1.0";',10
    db '  deprecated: "never";',10
    db '  example "seven" { start() { 7.return; } }',10
    db '  law "identity" { /* code trivia */ start() { 1.return; } }',10
    db '}',10
    db 'module sample;',10
complete_doc_len equ $-complete_doc

target_type_doc: db 'doc { title: "Alias"; } type alias Count = Int;'
target_type_doc_len equ $-target_type_doc
target_struct_doc: db 'doc { title: "Record"; } struct Point { Int.x; }'
target_struct_doc_len equ $-target_struct_doc
target_enum_doc: db 'doc { title: "State"; } enum State { Idle, Ready }'
target_enum_doc_len equ $-target_enum_doc
target_fn_doc: db 'doc { title: "Call"; } fn run() { }'
target_fn_doc_len equ $-target_fn_doc
target_function_doc: db 'doc { title: "Call"; } function render() { }'
target_function_doc_len equ $-target_function_doc
target_const_doc: db 'doc { title: "Value"; } const answer: Int = 42;'
target_const_doc_len equ $-target_const_doc

trivia_a: db 'doc{title:"Same";}module sample;'
trivia_a_len equ $-trivia_a
trivia_b: db 'doc { /* retained */ title : "Same" ; }',10,'module sample;'
trivia_b_len equ $-trivia_b
docs_doc: db 'docs { title: "No"; } module sample;'
docs_doc_len equ $-docs_doc
comments_only: db '// doc { title: "Not semantic"; }',10,'module sample;'
comments_only_len equ $-comments_only
unknown_doc: db 'doc { markdown: "No"; } module sample;'
unknown_doc_len equ $-unknown_doc
duplicate_field_doc: db 'doc { title: "One"; title: "Two"; } module sample;'
duplicate_field_doc_len equ $-duplicate_field_doc
orphan_doc: db 'doc { title: "Lost"; } start() { }'
orphan_doc_len equ $-orphan_doc
duplicate_doc: db 'doc { title: "One"; } doc { title: "Two"; } module sample;'
duplicate_doc_len equ $-duplicate_doc
malformed_example_doc: db 'doc { example bad { start() { 1.return; } } } module sample;'
malformed_example_doc_len equ $-malformed_example_doc
invalid_utf8_doc: db 'doc { title: "',0xc0,0xaf,'"; } module sample;'
invalid_utf8_doc_len equ $-invalid_utf8_doc

section .bss align=16
result_a: resq NEBOC_DOC_RESULT_QWORDS
result_b: resq NEBOC_DOC_RESULT_QWORDS
cst_a: resq 1
ast_a: resq 1

section .note.GNU-stack noalloc noexec nowrite progbits
