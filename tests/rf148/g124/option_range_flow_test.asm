; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW native Option/Result, range, lateral-flow and tooling conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"
%include "compiler/semantic/operators/core_option_range_flow_registry.inc"
%include "compiler/diagnostics/operator_diagnostics.inc"

extern neboc_lexer_scan
extern neboc_operator_precedence_lookup
extern neboc_core_orf_registry_table
extern neboc_core_orf_registry_lookup
extern neboc_core_orf_registry_resolve
extern neboc_result_propagation
extern neboc_option_coalesce
extern neboc_optional_chain
extern neboc_option_coalesce_assignment_plan
extern neboc_option_coalesce_assignment_commit
extern neboc_mathematical_range_plan
extern neboc_lateral_flow_plan
extern neboc_core_operator_tooling_lookup
extern neboc_core_operator_tooling_table
extern neboc_core_operator_formatter_lexeme
extern neboc_core_operator_source_map
extern neboc_core_operator_composition_validate
extern neboc_core_operator_migration_hint

%define SENTINEL 0x5a5a5a5a5a5a5a5a

%define RANGE_START_OFFSET 0
%define RANGE_END_OFFSET 8
%define RANGE_STEP_OFFSET 16
%define RANGE_CARDINALITY_OFFSET 24
%define RANGE_INCLUDE_START_OFFSET 32
%define RANGE_INCLUDE_END_OFFSET 40
%define RANGE_START_EVALUATIONS_OFFSET 48
%define RANGE_END_EVALUATIONS_OFFSET 56
%define RANGE_PLAN_SIZE 64

%define SOURCE_MAP_START_OFFSET 0
%define SOURCE_MAP_END_OFFSET 8
%define SOURCE_MAP_REGISTRY_ID_OFFSET 16
%define SOURCE_MAP_TOKEN_OFFSET 24
%define SOURCE_MAP_SIZE 32

%define LATERAL_READ 1
%define LATERAL_DERIVE 2
%define LATERAL_MUTATE 4
%define LATERAL_MOVE 8
%define LATERAL_ESCAPE 16
%define LATERAL_PARALLEL 32

%macro CHECK_TOKEN 2
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*%1+NEBOC_TOKEN_KIND_OFFSET],%2
 jne fail
%endmacro

section .rodata
source:
 db 'a? b??c d?.e f??=g 1'
 db 0xe2,0x80,0xa6
 db '3 1'
 db 0xe2,0x80,0xa6,'<'
 db '3 1<',0xe2,0x80,0xa6
 db '3 1<',0xe2,0x80,0xa6,'<'
 db '3 h..{i}'
source_len equ $-source
ascii_dot_source: db '1...3'
ascii_dot_source_len equ $-ascii_dot_source
ascii_ellipsis: db '...'
unicode_xor: db 0xe2,0x8a,0xbb
canonical_ellipsis: db 0xe2,0x80,0xa6

section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*40
eval_plan: resb NEBOC_EVAL_PLAN_SIZE
range_plan: resb RANGE_PLAN_SIZE
source_map: resb SOURCE_MAP_SIZE
target: resq 1
out_pointer: resq 1
out_length: resq 1
out_diagnostic: resq 1

section .text
global _start
_start:
 ; Maximal munch distinguishes every question and range form.  U+2026 is the
 ; only range atom; ASCII `..` remains the lateral-flow token.
 mov ebx,1
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],source_len
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],124
 mov qword [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],tokens
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],40
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],29
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 CHECK_TOKEN 0,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 1,NEBOC_TOKEN_QUESTION
 CHECK_TOKEN 2,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 3,NEBOC_TOKEN_COALESCE
 CHECK_TOKEN 4,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 5,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 6,NEBOC_TOKEN_OPTIONAL_CHAIN
 CHECK_TOKEN 7,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 8,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 9,NEBOC_TOKEN_OPTION_ASSIGN
 CHECK_TOKEN 10,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 11,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 12,NEBOC_TOKEN_RANGE_INCLUSIVE
 CHECK_TOKEN 13,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 14,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 15,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 CHECK_TOKEN 16,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 17,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 18,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 CHECK_TOKEN 19,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 20,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 21,NEBOC_TOKEN_RANGE_EXCLUSIVE
 CHECK_TOKEN 22,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 23,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 24,NEBOC_TOKEN_LATERAL_FLOW
 CHECK_TOKEN 25,NEBOC_TOKEN_LBRACE
 CHECK_TOKEN 26,NEBOC_TOKEN_IDENTIFIER
 CHECK_TOKEN 27,NEBOC_TOKEN_RBRACE
 CHECK_TOKEN 28,NEBOC_TOKEN_EOF

 ; G144 reserves three ASCII dots as one exact, non-executable Registry row.
 ; U+2026 remains the only active mathematical range atom.
 mov ebx,2
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],ascii_dot_source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],ascii_dot_source_len
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],4
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne fail
 CHECK_TOKEN 0,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 1,NEBOC_TOKEN_RESERVED_SYMBOL
 CHECK_TOKEN 2,NEBOC_TOKEN_INTEGER
 CHECK_TOKEN 3,NEBOC_TOKEN_EOF
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_LEX_DIAG_RESERVED_SYMBOL
 jne fail
 mov rax,[rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_FLAGS_OFFSET]
 shr rax,NEBOC_TOKEN_FLAG_RESERVED_ID_SHIFT
 and eax,0xff
 cmp eax,3
 jne fail

 ; Public precedence remains a single factual table.
 mov ebx,3
 mov edi,NEBOC_TOKEN_COALESCE
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_COALESCE
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 jne fail
 mov edi,NEBOC_TOKEN_OPTIONAL_CHAIN
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_SUFFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_SUFFIX
 jne fail
 mov edi,NEBOC_TOKEN_RANGE_INCLUSIVE
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_RANGE
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC
 jne fail
 mov edi,NEBOC_TOKEN_LATERAL_FLOW
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_COMPOSITION
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC
 jne fail

 ; The current Registry contains exactly IDs 038-041 and 043-047. ID 042 is
 ; intentionally absent, and context resolution does not widen `??=` into an
 ; expression operator.
 mov ebx,31
 call neboc_core_orf_registry_table
 test rax,rax
 jz fail
 cmp edx,NEBOC_CORE_ORF_REGISTRY_ENTRY_COUNT
 jne fail
 cmp ecx,NEBOC_CORE_ORF_REGISTRY_SCHEMA_VERSION
 jne fail
 mov edi,42
 call neboc_core_orf_registry_lookup
 test rax,rax
 jnz fail
 mov edi,NEBOC_OPERATOR_ID_NSR_CORE_038
 call neboc_core_orf_registry_lookup
 test rax,rax
 jz fail
 cmp qword [rax+NEBOC_CORE_ORF_ENTRY_TOKEN_OFFSET],NEBOC_TOKEN_QUESTION
 jne fail
 cmp qword [rax+NEBOC_CORE_ORF_ENTRY_PROTOCOL_OFFSET],NEBOC_CORE_ORF_PROTOCOL_RESULT_PROPAGATE
 jne fail
 cmp qword [rax+NEBOC_CORE_ORF_ENTRY_STATE_OFFSET],NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
 jne fail
 mov edi,NEBOC_TOKEN_OPTION_ASSIGN
 mov esi,NEBOC_OPERATOR_CONTEXT_STATEMENT
 call neboc_core_orf_registry_resolve
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_ID_NSR_CORE_041
 jne fail
 mov edi,NEBOC_TOKEN_OPTION_ASSIGN
 mov esi,NEBOC_OPERATOR_CONTEXT_EXPRESSION
 call neboc_core_orf_registry_resolve
 test rax,rax
 jnz fail
 test edx,edx
 jnz fail

 ; Result `?`: Ok unwraps, Err takes the exact typed early-return edge.
 mov ebx,4
 xor edi,edi
 mov esi,41
 lea rdx,[rel eval_plan]
 call neboc_result_propagation
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_RESULT_PROPAGATE
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],41
 jne fail
 test qword [rel eval_plan+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
 jnz fail
 mov edi,1
 mov esi,77
 lea rdx,[rel eval_plan]
 call neboc_result_propagation
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],77
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],1
 jne fail
 test qword [rel eval_plan+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
 jz fail
 mov rax,SENTINEL
 mov [rel eval_plan],rax
 mov edi,2
 xor esi,esi
 lea rdx,[rel eval_plan]
 call neboc_result_propagation
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel eval_plan],rax
 jne fail

 ; `??` and `?.` evaluate their right/member arm only on the lazy path.
 mov ebx,5
 mov edi,1
 mov esi,7
 mov edx,9
 lea rcx,[rel eval_plan]
 call neboc_option_coalesce
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],7
 jne fail
 xor edi,edi
 mov esi,7
 mov edx,9
 lea rcx,[rel eval_plan]
 call neboc_option_coalesce
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],9
 jne fail
 xor edi,edi
 mov esi,7
 mov edx,11
 lea rcx,[rel eval_plan]
 call neboc_optional_chain
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 jne fail
 mov edi,1
 mov esi,7
 mov edx,11
 lea rcx,[rel eval_plan]
 call neboc_optional_chain
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail

 ; `??=` evaluates the lvalue once, stores zero times for Some and once for
 ; None; plan failure never mutates either target or output plan.
 mov ebx,6
 mov qword [rel target],7
 lea rdi,[rel target]
 mov esi,1
 mov edx,9
 lea rcx,[rel eval_plan]
 call neboc_option_coalesce_assignment_plan
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 jne fail
 lea rdi,[rel eval_plan]
 call neboc_option_coalesce_assignment_commit
 test eax,eax
 jnz fail
 cmp qword [rel target],7
 jne fail
 lea rdi,[rel target]
 xor esi,esi
 mov edx,9
 lea rcx,[rel eval_plan]
 call neboc_option_coalesce_assignment_plan
 test eax,eax
 jnz fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 jne fail
 lea rdi,[rel eval_plan]
 call neboc_option_coalesce_assignment_commit
 test eax,eax
 jnz fail
 cmp qword [rel target],9
 jne fail
 mov rax,SENTINEL
 mov [rel eval_plan],rax
 lea rdi,[rel target]
 mov esi,2
 mov edx,99
 lea rcx,[rel eval_plan]
 call neboc_option_coalesce_assignment_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel eval_plan],rax
 jne fail
 cmp qword [rel target],9
 jne fail

 ; Four exact U+2026 ranges have explicit inclusion, direction and cardinality.
 mov ebx,7
 mov edi,1
 mov esi,1
 mov edx,3
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 test eax,eax
 jnz fail
 cmp qword [rel range_plan+RANGE_STEP_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_CARDINALITY_OFFSET],3
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_START_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_END_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_START_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_END_EVALUATIONS_OFFSET],1
 jne fail
 mov edi,2
 mov esi,1
 mov edx,3
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 test eax,eax
 jnz fail
 cmp qword [rel range_plan+RANGE_CARDINALITY_OFFSET],2
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_START_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_END_OFFSET],0
 jne fail
 mov edi,3
 mov esi,1
 mov edx,3
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 test eax,eax
 jnz fail
 cmp qword [rel range_plan+RANGE_CARDINALITY_OFFSET],2
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_START_OFFSET],0
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_END_OFFSET],1
 jne fail
 mov edi,4
 mov esi,1
 mov edx,3
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 test eax,eax
 jnz fail
 cmp qword [rel range_plan+RANGE_CARDINALITY_OFFSET],1
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_START_OFFSET],0
 jne fail
 cmp qword [rel range_plan+RANGE_INCLUDE_END_OFFSET],0
 jne fail
 mov edi,1
 mov esi,3
 mov edx,1
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 test eax,eax
 jnz fail
 cmp qword [rel range_plan+RANGE_STEP_OFFSET],-1
 jne fail
 cmp qword [rel range_plan+RANGE_CARDINALITY_OFFSET],3
 jne fail
 mov rax,SENTINEL
 mov [rel range_plan],rax
 mov edi,1
 xor esi,esi
 mov edx,1048576
 lea rcx,[rel range_plan]
 call neboc_mathematical_range_plan
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel range_plan],rax
 jne fail

 ; Lateral flow returns the original receiver and rejects mutation, move,
 ; escape and hidden parallelism without partially materializing a plan.
 mov ebx,8
 mov edi,0x1234
 mov esi,LATERAL_READ|LATERAL_DERIVE
 lea rdx,[rel eval_plan]
 call neboc_lateral_flow_plan
 mov ebx,81
 test eax,eax
 jnz fail
 mov ebx,82
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],0x1234
 jne fail
 mov ebx,83
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 mov ebx,84
 cmp qword [rel eval_plan+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 jne fail
 mov rax,SENTINEL
 mov [rel eval_plan],rax
 mov edi,0x1234
 mov esi,LATERAL_MUTATE|LATERAL_MOVE|LATERAL_ESCAPE|LATERAL_PARALLEL
 lea rdx,[rel eval_plan]
 call neboc_lateral_flow_plan
 mov ebx,85
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov ebx,86
 mov rax,SENTINEL
 cmp [rel eval_plan],rax
 jne fail

 ; One shared tooling table drives formatter, source maps, composition and
 ; exact migration hints without accepting arbitrary Unicode normalization.
 mov ebx,9
 mov edi,NEBOC_TOKEN_QUESTION
 call neboc_core_operator_tooling_lookup
 test rax,rax
 jz fail
 cmp edx,38
 jne fail
 mov edi,NEBOC_TOKEN_RANGE_EXCLUSIVE
 call neboc_core_operator_tooling_lookup
 test rax,rax
 jz fail
 cmp edx,46
 jne fail
 mov edi,NEBOC_TOKEN_LATERAL_FLOW
 call neboc_core_operator_tooling_lookup
 test rax,rax
 jz fail
 cmp edx,47
 jne fail
 call neboc_core_operator_tooling_table
 cmp edx,9
 jne fail
 cmp ecx,88
 jne fail
 ; Every tooling projection must resolve back to the live semantic Registry;
 ; token, stable ID and binding power are compared for all nine rows.
 call neboc_core_orf_registry_table
 mov r12,rax
 mov r13,rdx
.tooling_registry_loop:
 mov rdi,[r12+NEBOC_CORE_ORF_ENTRY_TOKEN_OFFSET]
 call neboc_core_operator_tooling_lookup
 test rax,rax
 jz fail
 cmp edx,[r12+NEBOC_CORE_ORF_ENTRY_ID_OFFSET]
 jne fail
 cmp r8d,[r12+NEBOC_CORE_ORF_ENTRY_PRECEDENCE_OFFSET]
 jne fail
 add r12,NEBOC_CORE_ORF_ENTRY_SIZE
 dec r13
 jnz .tooling_registry_loop
 mov edi,NEBOC_TOKEN_RANGE_INCLUSIVE
 lea rsi,[rel out_pointer]
 lea rdx,[rel out_length]
 call neboc_core_operator_formatter_lexeme
 test eax,eax
 jnz fail
 cmp qword [rel out_length],3
 jne fail
 mov r10,[rel out_pointer]
 cmp byte [r10],0xe2
 jne fail
 cmp byte [r10+1],0x80
 jne fail
 cmp byte [r10+2],0xa6
 jne fail
 mov rax,SENTINEL
 mov [rel out_pointer],rax
 mov [rel out_length],rax
 xor edi,edi
 lea rsi,[rel out_pointer]
 lea rdx,[rel out_length]
 call neboc_core_operator_formatter_lexeme
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_pointer],rax
 jne fail
 cmp [rel out_length],rax
 jne fail

 mov edi,NEBOC_TOKEN_RANGE_INCLUSIVE
 mov esi,5
 mov edx,8
 mov ecx,10
 lea r8,[rel source_map]
 call neboc_core_operator_source_map
 test eax,eax
 jnz fail
 cmp qword [rel source_map+SOURCE_MAP_START_OFFSET],5
 jne fail
 cmp qword [rel source_map+SOURCE_MAP_END_OFFSET],8
 jne fail
 cmp qword [rel source_map+SOURCE_MAP_REGISTRY_ID_OFFSET],43
 jne fail
 cmp qword [rel source_map+SOURCE_MAP_TOKEN_OFFSET],NEBOC_TOKEN_RANGE_INCLUSIVE
 jne fail
 mov rax,SENTINEL
 mov [rel source_map],rax
 mov edi,NEBOC_TOKEN_RANGE_INCLUSIVE
 mov esi,5
 mov edx,9
 mov ecx,10
 lea r8,[rel source_map]
 call neboc_core_operator_source_map
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 mov rax,SENTINEL
 cmp [rel source_map],rax
 jne fail

 mov edi,NEBOC_TOKEN_QUESTION
 mov esi,NEBOC_TOKEN_RANGE_INCLUSIVE
 call neboc_core_operator_composition_validate
 test eax,eax
 jnz fail
 mov edi,NEBOC_TOKEN_RANGE_INCLUSIVE
 mov esi,NEBOC_TOKEN_RANGE_EXCLUSIVE
 call neboc_core_operator_composition_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov edi,NEBOC_TOKEN_LATERAL_FLOW
 mov esi,NEBOC_TOKEN_LATERAL_FLOW
 call neboc_core_operator_composition_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov rax,SENTINEL
 mov [rel out_pointer],rax
 mov [rel out_length],rax
 mov [rel out_diagnostic],rax
 lea rdi,[rel ascii_ellipsis]
 mov esi,3
 lea rdx,[rel out_pointer]
 lea rcx,[rel out_length]
 lea r8,[rel out_diagnostic]
 call neboc_core_operator_migration_hint
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_pointer],rax
 jne fail
 cmp [rel out_length],rax
 jne fail
 cmp [rel out_diagnostic],rax
 jne fail
 lea rdi,[rel unicode_xor]
 mov esi,3
 lea rdx,[rel out_pointer]
 lea rcx,[rel out_length]
 lea r8,[rel out_diagnostic]
 call neboc_core_operator_migration_hint
 test eax,eax
 jnz fail
 cmp qword [rel out_length],3
 jne fail
 cmp qword [rel out_diagnostic],NEBOC_DIAG_OPERATOR_LOOKALIKE
 jne fail
 mov r10,[rel out_pointer]
 cmp byte [r10],'x'
 jne fail
 cmp byte [r10+1],'o'
 jne fail
 cmp byte [r10+2],'r'
 jne fail
 mov rax,SENTINEL
 mov [rel out_pointer],rax
 mov [rel out_length],rax
 mov [rel out_diagnostic],rax
 lea rdi,[rel canonical_ellipsis]
 mov esi,3
 lea rdx,[rel out_pointer]
 lea rcx,[rel out_length]
 lea r8,[rel out_diagnostic]
 call neboc_core_operator_migration_hint
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_pointer],rax
 jne fail
 cmp [rel out_length],rax
 jne fail
 cmp [rel out_diagnostic],rax
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
