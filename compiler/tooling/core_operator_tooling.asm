; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW-FECHAR-COMPOSITION-FORMATTER-LSP-SOURCE-MAPS-E-MIGRATIONS-COM-CONTRATO-IMPLEMENTACAO-EVIDENCE-FACTUAL-REGRESSOES-DOS-SUBSTRATOS-AFETADOS-DETERMINISMO-E-OPEN-P0-0-OPEN-P1-0-OPEN-P2-0-F07 — shared bounded tooling metadata for the public P02 forms.
; Formatter, LSP, source maps and migration diagnostics consume this table;
; none of them infer operator meaning from spelling independently.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/diagnostics/operator_diagnostics.inc"

%define CORE_TOOL_FLAG_CANONICAL       1
%define CORE_TOOL_FLAG_SHORT_CIRCUIT   2
%define CORE_TOOL_FLAG_CONTEXTUAL      4
%define CORE_TOOL_FLAG_UNICODE         8
%define CORE_TOOL_FLAG_NONASSOCIATIVE 16
%define CORE_TOOL_FLAG_STATEMENT      32
%define CORE_TOOL_FLAG_FLOW           64

%define CORE_TOOL_TOKEN_OFFSET         0
%define CORE_TOOL_REGISTRY_ID_OFFSET   8
%define CORE_TOOL_FIXITY_OFFSET       16
%define CORE_TOOL_BINDING_POWER_OFFSET 24
%define CORE_TOOL_ASSOC_OFFSET        32
%define CORE_TOOL_FLAGS_OFFSET        40
%define CORE_TOOL_LEXEME_OFFSET       48
%define CORE_TOOL_LEXEME_LENGTH_OFFSET 56
%define CORE_TOOL_API_OFFSET          64
%define CORE_TOOL_API_LENGTH_OFFSET   72
%define CORE_TOOL_DIAGNOSTIC_OFFSET   80
%define CORE_TOOL_RECORD_SIZE         88
%define CORE_TOOL_RECORD_COUNT         9

%define CORE_SOURCE_MAP_START_OFFSET        0
%define CORE_SOURCE_MAP_END_OFFSET          8
%define CORE_SOURCE_MAP_REGISTRY_ID_OFFSET 16
%define CORE_SOURCE_MAP_TOKEN_OFFSET       24
%define CORE_SOURCE_MAP_SIZE               32

%macro CORE_TOOL_ROW 11
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11
%endmacro

section .rodata
lex_question: db '?'
lex_coalesce: db '??'
lex_optional_chain: db '?.'
lex_option_assign: db '??='
lex_range_inclusive: db 0xe2,0x80,0xa6
lex_range_exclusive_end: db 0xe2,0x80,0xa6,'<'
lex_range_exclusive_start: db '<',0xe2,0x80,0xa6
lex_range_exclusive: db '<',0xe2,0x80,0xa6,'<'
lex_lateral_flow: db '..'

api_question: db 'Result.propagate'
api_coalesce: db 'Option.unwrapOr'
api_optional_chain: db 'Option.member'
api_option_assign: db 'Option.assignIfNone'
api_range_inclusive: db 'Range.inclusive'
api_range_exclusive_end: db 'Range.exclusiveEnd'
api_range_exclusive_start: db 'Range.exclusiveStart'
api_range_exclusive: db 'Range.exclusive'
api_lateral_flow: db 'lateral'

migration_xor: db 'xor'
migration_range: db 0xe2,0x80,0xa6

align 8
core_tool_records:
 CORE_TOOL_ROW NEBOC_TOKEN_QUESTION,38,NEBOC_OPERATOR_PARSE_FIXITY_POSTFIX,NEBOC_OPERATOR_BP_POSTFIX,NEBOC_OPERATOR_PARSE_ASSOC_LEFT,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_SHORT_CIRCUIT|CORE_TOOL_FLAG_CONTEXTUAL,lex_question,1,api_question,16,NEBOC_DIAG_QUESTION_PROPAGATION_CONTEXT
 CORE_TOOL_ROW NEBOC_TOKEN_COALESCE,39,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_COALESCE,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_SHORT_CIRCUIT,lex_coalesce,2,api_coalesce,15,NEBOC_DIAG_QUESTION_COALESCE_OPERANDS
 CORE_TOOL_ROW NEBOC_TOKEN_OPTIONAL_CHAIN,40,NEBOC_OPERATOR_PARSE_FIXITY_SUFFIX,NEBOC_OPERATOR_BP_SUFFIX,NEBOC_OPERATOR_PARSE_ASSOC_LEFT,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_SHORT_CIRCUIT|CORE_TOOL_FLAG_CONTEXTUAL,lex_optional_chain,2,api_optional_chain,13,NEBOC_DIAG_QUESTION_OPTIONAL_CHAIN_RECEIVER
 CORE_TOOL_ROW NEBOC_TOKEN_OPTION_ASSIGN,41,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_ASSIGNMENT,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_SHORT_CIRCUIT|CORE_TOOL_FLAG_CONTEXTUAL|CORE_TOOL_FLAG_STATEMENT,lex_option_assign,3,api_option_assign,19,NEBOC_DIAG_QUESTION_CONDITIONAL_ASSIGN_TARGET
 CORE_TOOL_ROW NEBOC_TOKEN_RANGE_INCLUSIVE,43,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RANGE,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_UNICODE|CORE_TOOL_FLAG_NONASSOCIATIVE,lex_range_inclusive,3,api_range_inclusive,15,NEBOC_DIAG_OPERATOR_AMBIGUOUS
 CORE_TOOL_ROW NEBOC_TOKEN_RANGE_EXCLUSIVE_END,44,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RANGE,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_UNICODE|CORE_TOOL_FLAG_NONASSOCIATIVE,lex_range_exclusive_end,4,api_range_exclusive_end,18,NEBOC_DIAG_OPERATOR_AMBIGUOUS
 CORE_TOOL_ROW NEBOC_TOKEN_RANGE_EXCLUSIVE_START,45,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RANGE,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_UNICODE|CORE_TOOL_FLAG_NONASSOCIATIVE,lex_range_exclusive_start,4,api_range_exclusive_start,20,NEBOC_DIAG_OPERATOR_AMBIGUOUS
 CORE_TOOL_ROW NEBOC_TOKEN_RANGE_EXCLUSIVE,46,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_RANGE,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_UNICODE|CORE_TOOL_FLAG_NONASSOCIATIVE,lex_range_exclusive,5,api_range_exclusive,15,NEBOC_DIAG_OPERATOR_AMBIGUOUS
 CORE_TOOL_ROW NEBOC_TOKEN_LATERAL_FLOW,47,NEBOC_OPERATOR_PARSE_FIXITY_INFIX,NEBOC_OPERATOR_BP_COMPOSITION,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC,CORE_TOOL_FLAG_CANONICAL|CORE_TOOL_FLAG_CONTEXTUAL|CORE_TOOL_FLAG_NONASSOCIATIVE|CORE_TOOL_FLAG_FLOW,lex_lateral_flow,2,api_lateral_flow,7,NEBOC_DIAG_OPERATOR_AMBIGUOUS

section .text
; tooling_lookup(token_kind) -> RAX=immutable record or zero.  Successful
; lookups also publish registry ID, fixity, binding power and style flags.
NEBOC_ABI_FUNCTION neboc_core_operator_tooling_lookup
 lea rax,[rel core_tool_records]
 mov ecx,CORE_TOOL_RECORD_COUNT
.loop:
 cmp [rax+CORE_TOOL_TOKEN_OFFSET],rdi
 je .found
 add rax,CORE_TOOL_RECORD_SIZE
 dec ecx
 jnz .loop
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 ret
.found:
 mov edx,[rax+CORE_TOOL_REGISTRY_ID_OFFSET]
 mov ecx,[rax+CORE_TOOL_FIXITY_OFFSET]
 mov r8d,[rax+CORE_TOOL_BINDING_POWER_OFFSET]
 mov r9d,[rax+CORE_TOOL_FLAGS_OFFSET]
 ret

; tooling_table() -> RAX=records, EDX=count, ECX=record size.
NEBOC_ABI_FUNCTION neboc_core_operator_tooling_table
 lea rax,[rel core_tool_records]
 mov edx,CORE_TOOL_RECORD_COUNT
 mov ecx,CORE_TOOL_RECORD_SIZE
 ret

; formatter_lexeme(token, out_bytes**, out_length*) -> status.  Outputs are
; failure atomic and always name the exact registered canonical source form.
NEBOC_ABI_FUNCTION neboc_core_operator_formatter_lexeme
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 lea rax,[rel core_tool_records]
 mov ecx,CORE_TOOL_RECORD_COUNT
.find:
 cmp [rax+CORE_TOOL_TOKEN_OFFSET],rdi
 je .publish
 add rax,CORE_TOOL_RECORD_SIZE
 dec ecx
 jnz .find
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.publish:
 mov rcx,[rax+CORE_TOOL_LEXEME_OFFSET]
 mov [rsi],rcx
 mov rcx,[rax+CORE_TOOL_LEXEME_LENGTH_OFFSET]
 mov [rdx],rcx
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; source_map(token,start,end,source_length,out*) validates byte-exact spans and
; publishes a stable token/Registry mapping only after every bound is GREEN.
NEBOC_ABI_FUNCTION neboc_core_operator_source_map
 test r8,r8
 jz .map_invalid
 cmp rsi,rdx
 jae .map_invalid
 cmp rdx,rcx
 ja .map_invalid
 lea rax,[rel core_tool_records]
 mov r9d,CORE_TOOL_RECORD_COUNT
.map_find:
 cmp [rax+CORE_TOOL_TOKEN_OFFSET],rdi
 je .map_width
 add rax,CORE_TOOL_RECORD_SIZE
 dec r9d
 jnz .map_find
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.map_width:
 mov r9,rdx
 sub r9,rsi
 cmp r9,[rax+CORE_TOOL_LEXEME_LENGTH_OFFSET]
 jne .map_invalid
 mov [r8+CORE_SOURCE_MAP_START_OFFSET],rsi
 mov [r8+CORE_SOURCE_MAP_END_OFFSET],rdx
 mov r9,[rax+CORE_TOOL_REGISTRY_ID_OFFSET]
 mov [r8+CORE_SOURCE_MAP_REGISTRY_ID_OFFSET],r9
 mov [r8+CORE_SOURCE_MAP_TOKEN_OFFSET],rdi
 xor eax,eax
 ret
.map_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; composition_validate(outer_token,inner_token) rejects non-associative range
; chains and nested lateral-flow forms while preserving option/range composition.
NEBOC_ABI_FUNCTION neboc_core_operator_composition_validate
 cmp rdi,NEBOC_TOKEN_QUESTION
 jb .composition_invalid_argument
 cmp rdi,NEBOC_TOKEN_LATERAL_FLOW
 ja .composition_invalid_argument
 cmp rsi,NEBOC_TOKEN_QUESTION
 jb .composition_invalid_argument
 cmp rsi,NEBOC_TOKEN_LATERAL_FLOW
 ja .composition_invalid_argument
 cmp rdi,NEBOC_TOKEN_RANGE_INCLUSIVE
 jb .check_lateral
 cmp rdi,NEBOC_TOKEN_RANGE_EXCLUSIVE
 ja .check_lateral
 cmp rsi,NEBOC_TOKEN_RANGE_INCLUSIVE
 jb .composition_ok
 cmp rsi,NEBOC_TOKEN_RANGE_EXCLUSIVE
 jbe .composition_invalid_source
.check_lateral:
 cmp rdi,NEBOC_TOKEN_LATERAL_FLOW
 jne .composition_ok
 cmp rsi,NEBOC_TOKEN_LATERAL_FLOW
 je .composition_invalid_source
.composition_ok:
 xor eax,eax
 ret
.composition_invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.composition_invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; migration_hint(source,length,out_bytes**,out_length*,out_diagnostic*) accepts
; only exact known lookalikes.  It never normalizes arbitrary Unicode.
NEBOC_ABI_FUNCTION neboc_core_operator_migration_hint
 test rdi,rdi
 jz .migration_invalid_argument
 test rdx,rdx
 jz .migration_invalid_argument
 test rcx,rcx
 jz .migration_invalid_argument
 test r8,r8
 jz .migration_invalid_argument
 cmp rsi,3
 jne .migration_missing
 cmp byte [rdi],0xe2
 jne .ascii_ellipsis
 cmp byte [rdi+1],0x8a
 jne .unicode_midline_ellipsis
 cmp byte [rdi+2],0xbb
 jne .migration_missing
 lea rax,[rel migration_xor]
 mov [rdx],rax
 mov qword [rcx],3
 mov qword [r8],NEBOC_DIAG_OPERATOR_LOOKALIKE
 xor eax,eax
 ret
.unicode_midline_ellipsis:
 cmp byte [rdi+1],0x8b
 jne .migration_missing
 cmp byte [rdi+2],0xaf
 jne .migration_missing
 jmp .publish_range
.ascii_ellipsis:
 cmp byte [rdi],'.'
 jne .migration_missing
 cmp byte [rdi+1],'.'
 jne .migration_missing
 cmp byte [rdi+2],'.'
 jne .migration_missing
.publish_range:
 lea rax,[rel migration_range]
 mov [rdx],rax
 mov qword [rcx],3
 mov qword [r8],NEBOC_DIAG_ASCII_RANGE_SPELLING
 xor eax,eax
 ret
.migration_missing:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.migration_invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
