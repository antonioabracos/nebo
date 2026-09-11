; Nebo Assembly — MF017 Pratt expression parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/core_option_range_flow_registry.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"

extern neboc_ast_builder_append
extern neboc_ast_builder_node
extern neboc_operator_precedence_lookup

%macro EXPR_TOKEN_PTR 2
 mov %1,%2
 imul %1,NEBOC_TOKEN_SIZE
 add %1,[r12+NEBOC_EXPR_TOKENS_OFFSET]
%endmacro

; One lexical argument grammar serves ordinary calls and typed constructors.
%macro EXPR_PARSE_ARGUMENT 0
 mov qword [rsp+120],-1
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne %%value
 lea rax,[rbx+1]
 cmp rax,r14
 jae %%value
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_COLON
 jne %%value
 mov [rsp+120],rbx
 add rbx,2
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
%%value:
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_bp_done_decrement
 cmp qword [rsp+120],-1
 je %%ready
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+56]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+56]
 EXPR_TOKEN_PTR r11,qword [rsp+120]
 mov rdi,r15
 mov esi,NEBOC_AST_NAMED_ARGUMENT
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r10+NEBOC_AST_NODE_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+56]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+56]
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+120]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+40]
 mov [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],rax
%%ready:
%endmacro

section .rodata
expression_mutable_name: db "mutable"
expression_mutable_name_len equ $-expression_mutable_name

section .text

; expression_set_error(request*, diagnostic_code, token_index)
NEBOC_ABI_FUNCTION neboc_expression_set_error
 test rdi,rdi
 jz .invalid
 mov [rdi+NEBOC_EXPR_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_EXPR_ERROR_TOKEN_OFFSET],rdx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; expression_parse(ExpressionRequest*)
NEBOC_ABI_FUNCTION neboc_expression_parse
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz expression_parse_invalid
 mov r13,[r12+NEBOC_EXPR_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_EXPR_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_EXPR_BUILDER_OFFSET]
 test r13,r13
 jz expression_parse_invalid
 test r14,r14
 jz expression_parse_invalid
 test r15,r15
 jz expression_parse_invalid
 cmp qword [r12+NEBOC_EXPR_MAX_NESTING_OFFSET],0
 jne expression_parse_limit_ready
 mov qword [r12+NEBOC_EXPR_MAX_NESTING_OFFSET],NEBOC_EXPR_DEFAULT_MAX_NESTING
expression_parse_limit_ready:
 mov qword [r12+NEBOC_EXPR_NESTING_OFFSET],0
 mov qword [r12+NEBOC_EXPR_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_EXPR_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],0
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 jmp expression_parse_done
expression_parse_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
expression_parse_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Public G119 spelling for the live Pratt entry point.
NEBOC_ABI_FUNCTION neboc_parse_operator_expression
 jmp neboc_expression_parse

; expression_parse_bp(ExpressionRequest*, min_binding_power)
NEBOC_ABI_FUNCTION neboc_expression_parse_bp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov r12,rdi
 mov [rsp],rsi
 mov r13,[r12+NEBOC_EXPR_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_EXPR_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_EXPR_BUILDER_OFFSET]
 inc qword [r12+NEBOC_EXPR_NESTING_OFFSET]
 mov rax,[r12+NEBOC_EXPR_NESTING_OFFSET]
 cmp rax,[r12+NEBOC_EXPR_MAX_NESTING_OFFSET]
 ja expression_bp_nesting
 mov rdi,r12
 call neboc_expression_parse_prefix
 test eax,eax
 jnz expression_bp_done_decrement
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+8],rax

expression_bp_loop:
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_finish
 EXPR_TOKEN_PTR r11,rbx
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_RESERVED_LBRACKET
 je expression_bp_legacy_index
 cmp rcx,NEBOC_TOKEN_LBRACE
 je expression_bp_struct_constructor
 mov [rsp+16],rcx
 mov rdi,rcx
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 cmp rcx,NEBOC_TOKEN_PERCENT
 je expression_bp_percent_fixity
 cmp rcx,NEBOC_TOKEN_DEGREE
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_PER_MILLE
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_BASIS_POINTS
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_CELSIUS
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_FAHRENHEIT
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_BANG
 je expression_bp_lookup_postfix
 cmp rcx,NEBOC_TOKEN_DOT
 je expression_bp_lookup_suffix
 cmp rcx,NEBOC_TOKEN_OPTIONAL_CHAIN
 je expression_bp_lookup_suffix
 cmp rcx,NEBOC_TOKEN_LPAREN
 je expression_bp_lookup_suffix
 cmp rcx,NEBOC_TOKEN_QUESTION
 je expression_bp_lookup_postfix
 jmp expression_bp_lookup
expression_bp_lookup_suffix:
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_SUFFIX
 jmp expression_bp_lookup
expression_bp_lookup_postfix:
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_POSTFIX
 jmp expression_bp_lookup
expression_bp_percent_fixity:
 ; A following primary expression keeps the established whitespace-insensitive
 ; remainder grammar (`37%6`).  Before an ambiguous prefix-capable token,
 ; adjacency selects typed postfix (`11% + 13%`) while spacing selects an
 ; infix signed RHS (`37 % -6`).
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+96]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,rbx
 mov rax,[rsp+96]
 mov rax,[rax+NEBOC_AST_NODE_END_OFFSET]
 xor edx,edx
 cmp rax,[r11+NEBOC_TOKEN_START_OFFSET]
 sete dl
 mov [rsp+88],rdx
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 lea rax,[rbx+1]
 cmp rax,r14
 jae .percent_postfix
 EXPR_TOKEN_PTR r11,rax
 mov rdx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rdx,NEBOC_TOKEN_IDENTIFIER
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_INTEGER
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_FLOAT
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_TEXT
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_CHAR
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_KW_TRUE
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_KW_FALSE
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_LPAREN
 je .percent_fixity_ready
 cmp rdx,NEBOC_TOKEN_MINUS
 je .percent_ambiguous_prefix
 cmp rdx,NEBOC_TOKEN_PLUS
 je .percent_ambiguous_prefix
 cmp rdx,NEBOC_TOKEN_BANG
 jne .percent_postfix
.percent_ambiguous_prefix:
 cmp qword [rsp+88],0
 je .percent_fixity_ready
.percent_postfix:
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_POSTFIX
.percent_fixity_ready:
 mov rdi,[rsp+16]
expression_bp_lookup:
 mov [rsp+80],rsi
 call neboc_operator_precedence_lookup
 test rax,rax
 jz expression_bp_finish
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz expression_bp_finish
 mov r8d,edx
 mov r10d,r9d
 mov r9d,ecx
 mov rcx,[rsp+16]
 cmp r8,[rsp]
 jb expression_bp_finish
 cmp rcx,NEBOC_TOKEN_DOT
 je expression_bp_suffix
 cmp rcx,NEBOC_TOKEN_OPTIONAL_CHAIN
 je expression_bp_suffix
 cmp rcx,NEBOC_TOKEN_LATERAL_FLOW
 je expression_bp_lateral_flow
 cmp rcx,NEBOC_TOKEN_LPAREN
 je expression_bp_direct_call
 cmp rcx,NEBOC_TOKEN_QUESTION
 je expression_bp_result_propagate
 cmp rcx,NEBOC_TOKEN_PERCENT
 jne .not_contextual_percent
 cmp qword [rsp+80],NEBOC_OPERATOR_PARSE_FIXITY_POSTFIX
 je expression_bp_quantity_postfix
 jmp expression_bp_have_power
.not_contextual_percent:
 cmp rcx,NEBOC_TOKEN_DEGREE
 je expression_bp_quantity_postfix
 cmp rcx,NEBOC_TOKEN_PER_MILLE
 je expression_bp_quantity_postfix
 cmp rcx,NEBOC_TOKEN_BASIS_POINTS
 je expression_bp_quantity_postfix
 cmp rcx,NEBOC_TOKEN_CELSIUS
 je expression_bp_quantity_postfix
 cmp rcx,NEBOC_TOKEN_FAHRENHEIT
 je expression_bp_quantity_postfix
 cmp rcx,NEBOC_TOKEN_BANG
 je expression_bp_quantity_postfix
expression_bp_have_power:
 cmp r8,[rsp]
 jb expression_bp_finish
 mov [rsp+120],r9
 cmp r10d,NEBOC_OPERATOR_FAMILY_EQUALITY
 je expression_bp_check_nonassoc
 cmp r10d,NEBOC_OPERATOR_FAMILY_RELATIONAL
 je expression_bp_check_nonassoc
 cmp r10d,NEBOC_OPERATOR_FAMILY_RANGE
 jne expression_bp_nonassoc_ok
expression_bp_check_nonassoc:
 mov [rsp+112],r10
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r11,[rsp+48]
 cmp qword [r11+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 jne expression_bp_nonassoc_ok
 mov rax,[r11+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r10,[rsp+112]
 cmp r10d,NEBOC_OPERATOR_FAMILY_EQUALITY
 jne expression_bp_check_previous_relation
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je expression_bp_nonassoc_rejected
 jmp expression_bp_nonassoc_ok
expression_bp_check_previous_relation:
 cmp rax,NEBOC_TOKEN_LESS
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_GREATER
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_SPACESHIP
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_RANGE_INCLUSIVE
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 je expression_bp_nonassoc_rejected
 cmp rax,NEBOC_TOKEN_RANGE_EXCLUSIVE
 je expression_bp_nonassoc_rejected
expression_bp_nonassoc_ok:
 mov r9,[rsp+120]
 mov [rsp+24],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 mov rsi,r9
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_bp_done_decrement
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+32],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+56]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 mov r11,[rsp+56]
 mov rdi,r15
 mov esi,NEBOC_AST_BINARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_AST_NODE_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+24]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov r10,[rsp+48]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_nonassoc_rejected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NONASSOCIATIVE_CHAIN
 mov rdx,rbx
 call neboc_expression_set_error
 jmp expression_bp_done_decrement

expression_bp_result_propagate:
 mov [rsp+72],rbx
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+72]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_UNARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_QUESTION
 mov rax,[rsp+72]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 inc rax
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_quantity_postfix:
 mov [rsp+72],rbx
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+72]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_UNARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+16]
 cmp rax,NEBOC_TOKEN_PERCENT
 jne .maybe_factorial
 mov eax,NEBOC_TOKEN_POSTFIX_PERCENT
.maybe_factorial:
 cmp rax,NEBOC_TOKEN_BANG
 jne .quantity_kind_ready
 mov eax,NEBOC_TOKEN_POSTFIX_FACTORIAL
.quantity_kind_ready:
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+72]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 inc rax
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_lateral_flow:
 mov rax,[rsp+16]
 NEBOC_CORE_ORF_CLASSIFY rax,rdx,expression_bp_expected
 cmp rdx,NEBOC_OPERATOR_ID_NSR_CORE_047
 jne expression_bp_expected
 mov [rsp+72],rbx
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne expression_bp_expected
 mov [rsp+80],rax
 mov edx,1
 inc rax
.lateral_scan:
 cmp rax,r14
 jae expression_bp_expected
 cmp rdx,NEBOC_EXPR_DEFAULT_MAX_NESTING
 ja expression_bp_nesting
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne .lateral_maybe_close
 inc rdx
 jmp .lateral_next
.lateral_maybe_close:
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 jne .lateral_next
 dec rdx
 jz .lateral_found
.lateral_next:
 inc rax
 jmp .lateral_scan
.lateral_found:
 mov [rsp+104],rax
 mov rax,[rsp+80]
 inc rax
 cmp rax,[rsp+104]
 jae expression_bp_expected
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_bp_done_decrement
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 test rax,rax
 jz expression_bp_expected
 mov [rsp+96],rax
 mov rax,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rax,[rsp+104]
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne expression_bp_expected
 inc rax
 cmp rax,[rsp+104]
 jne expression_bp_expected
 mov rbx,[rsp+104]
 lea rax,[rbx+1]
 mov [rsp+88],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,rbx
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_UNARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_LATERAL_FLOW
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov r11,[rsp+48]
 mov rax,[rsp+96]
 mov [r11+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+88]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop


%include "compiler/parser/expression/struct_constructor.inc"

expression_bp_direct_call:
 ; Direct calls are reserved for explicit built-in type constructors such as
 ; Int(100), Bool(true) and Text("Nebo"). Semantic/codegen validation freezes
 ; the built-in name and requires the wrapped expression to have that type.
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne expression_bp_finish
 mov [rsp+72],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .direct_empty
 EXPR_PARSE_ARGUMENT
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+88],rax
.direct_argument_first:
 mov [rsp+96],rax
 mov qword [rsp+104],1
 jmp .direct_argument_tail
.direct_empty:
 mov rax,[rsp+48]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
 jnz .direct_empty_allowed
 ; None() is the canonical zero-payload variant. Contextual typing remains
 ; the enclosing Option constructor's responsibility.
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 EXPR_TOKEN_PTR r11,rax
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp rax,4
 jne .direct_empty_profile
 mov rax,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rax,rax
 jz .direct_empty_profile
 add rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rax],0x656e6f4e
 je .direct_empty_allowed
.direct_empty_profile:
 test qword [r12+NEBOC_EXPR_FLAGS_OFFSET],NEBOC_EXPR_FLAG_FORMAT_PROFILE
 jz expression_bp_expected
.direct_empty_allowed:
 mov qword [rsp+88],0
 mov qword [rsp+96],0
 mov qword [rsp+104],0
.direct_argument_tail:
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 je .direct_argument_comma
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne expression_bp_expected
 mov [rsp+112],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov rax,[rsp+48]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
 jz .direct_flags_ready
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
.direct_flags_ready:
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+104]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov rax,[rsp+48]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+104]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 ; A typed constructor retains its complete type-application node before
 ; the ordered value arguments. Semantic owners consume types explicitly.
 mov rax,[rsp+48]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .direct_type_ready
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 mov rcx,[rsp+88]
 mov [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rcx
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 inc qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
.direct_type_ready:
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop
.direct_argument_comma:
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 EXPR_PARSE_ARGUMENT
 mov rdi,r15
 mov rsi,[rsp+96]
 lea rdx,[rsp+56]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+56]
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov [rsp+96],rax
 inc qword [rsp+104]
 jmp .direct_argument_tail

; The typed backend admits only the published Array<Int,4> literal-index
; envelope. Represent the alias as the same ordered receiver/argument CALL
; as .at(), retaining the original bracket token as method provenance.
expression_bp_legacy_index:
 cmp qword [rsp],NEBOC_EXPR_BP_SUFFIX
 ja expression_bp_finish
 mov [rsp+80],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne expression_bp_expected
 EXPR_PARSE_ARGUMENT
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+88],rax
 mov [rsp+96],rax
 mov qword [rsp+104],1
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_RBRACKET
 jne expression_bp_expected
 jmp expression_bp_call_done

expression_bp_suffix:
 mov [rsp+72],rbx
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_KW_RETURN
 je expression_bp_return_terminal
 cmp rcx,NEBOC_TOKEN_INTEGER
 je expression_bp_tuple_positional_projection
 cmp rcx,NEBOC_TOKEN_KW_AWAIT
 jne .ordinary_method_name
 ; Await remains a keyword outside the existing method-call position.
 lea rdx,[rax+1]
 cmp rdx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rdx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_bp_expected
 jmp .method_name_ready
.ordinary_method_name:
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne expression_bp_expected
.method_name_ready:
 mov [rsp+80],rax
 lea rdx,[rax+1]
 cmp rdx,r14
 jae expression_bp_binding_terminal
 EXPR_TOKEN_PTR r10,rdx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 je expression_bp_tuple_generic_projection
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_bp_binding_terminal
 lea rdx,[rdx+1]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rdx
 mov qword [rsp+88],0
 mov qword [rsp+96],0
 mov qword [rsp+104],0
expression_bp_argument_loop:
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je expression_bp_call_done
 EXPR_PARSE_ARGUMENT
expression_bp_argument_ready:
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 cmp qword [rsp+88],0
 jne expression_bp_argument_link
 mov [rsp+88],rax
 mov [rsp+96],rax
 jmp expression_bp_argument_count
expression_bp_argument_link:
 mov rdi,r15
 mov rsi,[rsp+96]
 lea rdx,[rsp+56]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+56]
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov [rsp+96],rax
expression_bp_argument_count:
 inc qword [rsp+104]
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_COMMA
 je expression_bp_argument_comma
 cmp rcx,NEBOC_TOKEN_RPAREN
 je expression_bp_call_done
 ; A present nonseparator token after an argument is unexpected. A missing
 ; closing delimiter at end of input remains the distinct expected-token case.
 jmp expression_bp_argument_unexpected
expression_bp_argument_comma:
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 jmp expression_bp_argument_loop
expression_bp_call_done:
 mov [rsp+112],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+104]
 inc rax
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+104]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 cmp qword [rsp+88],0
 je expression_bp_call_lhs_ready
 mov r10,[rsp+48]
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
expression_bp_call_lhs_ready:
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_tuple_generic_projection:
 ; Preserve the two authenticated generic suffixes in the shared Program AST:
 ; Tuple `.at<CONST>()` and ownership Arena `.allocate<T>(count)`.
 EXPR_TOKEN_PTR r11,qword [rsp+80]
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp rax,2
 je .generic_at_name
 cmp rax,4
 je .generic_cast_name
 cmp rax,7
 je .generic_collect_name
 cmp rax,8
 jne expression_bp_expected
 mov rsi,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rsi,rsi
 jz expression_bp_expected
 add rsi,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rsi],0x6f6c6c61 ; "allo"
 jne expression_bp_expected
 cmp dword [rsi+4],0x65746163 ; "cate"
 je expression_bp_allocate_generic
 jmp expression_bp_expected
.generic_cast_name:
 mov rsi,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rsi,rsi
 jz expression_bp_expected
 add rsi,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rsi],0x74736163 ; cast
 jne expression_bp_expected
 jmp .generic_type_argument
.generic_collect_name:
 mov rsi,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rsi,rsi
 jz expression_bp_expected
 add rsi,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rsi],0x6c6c6f63 ; coll
 jne expression_bp_expected
 cmp word [rsi+4],0x6365 ; ec
 jne expression_bp_expected
 cmp byte [rsi+6],'t'
 jne expression_bp_expected
.generic_type_argument:
 lea rax,[rbx+3]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rdi,r12
 call neboc_expression_parse_prefix
 test eax,eax
 jnz expression_bp_done_decrement
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+88],rax
 mov rax,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne expression_bp_expected
 inc rax
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_bp_expected
 inc rax
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne expression_bp_expected
 mov [rsp+112],rax
 inc rax
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_METHOD
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 mov r10,[rsp+48]
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop
.generic_at_name:
 mov rsi,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rsi,rsi
 jz expression_bp_expected
 add rsi,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp word [rsi],0x7461       ; "at"
 jne expression_bp_expected
 lea rax,[rbx+3]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne expression_bp_expected
 mov [rsp+96],rax            ; generic constant token
 lea rax,[rbx+4]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne expression_bp_expected
 lea rax,[rbx+5]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_bp_expected
 lea rax,[rbx+6]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne expression_bp_expected
 mov [rsp+112],rax           ; closing parenthesis token
 ; Materialize the generic constant as the call's sole argument.
 EXPR_TOKEN_PTR r11,qword [rsp+96]
 mov rdi,r15
 mov esi,NEBOC_AST_INTEGER_LITERAL
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+88]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+88]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 EXPR_TOKEN_PTR r11,qword [rsp+96]
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+96]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 ; Build the ordinary receiver-plus-one-argument CallExpr shape.
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 lea rax,[rbx+7]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_allocate_generic:
 ; Token shape: receiver.allocate<Type>(count). The type argument is retained
 ; as a compiler-owned IdentifierExpr before the ordinary value argument.
 lea rax,[rbx+3]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne expression_bp_expected
 mov [rsp+96],rax
 lea rax,[rbx+4]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne expression_bp_expected
 lea rax,[rbx+5]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_bp_expected
 lea rax,[rbx+6]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_bp_done_decrement
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+88],rax
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne expression_bp_expected
 mov [rsp+112],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 ; Materialize the generic type name.
 EXPR_TOKEN_PTR r11,qword [rsp+96]
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+104]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+104]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+96]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 ; Build the receiver-plus-type-plus-count call shape.
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 mov rax,[rsp+104]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_tuple_positional_projection:
 ; `.N` is the established Tuple positional projection.  A dedicated flag
 ; prevents this compiler-private call-shaped node from being mistaken for a
 ; source-visible method invocation.
 mov [rsp+80],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TUPLE_POSITIONAL_PROJECTION
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 EXPR_TOKEN_PTR r11,qword [rsp+80]
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 lea rax,[rbx+2]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_binding_terminal:
 ; A nominal enum receiver has one additional public method suffix:
 ; `Type.Variant.discriminant()`.  The independently authenticated nominal
 ; owner still decides whether the type, variant and operation are valid.  The
 ; shared parser only preserves the exact two-token receiver long enough for
 ; the ordinary call-suffix path to build the final call node.
 lea rdx,[rbx+4]
 cmp rdx,r14
 jae .binding_terminal_regular
 lea rax,[rbx+2]
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .binding_terminal_regular
 lea rax,[rbx+3]
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .binding_terminal_regular
 lea rax,[rbx+4]
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .binding_terminal_regular
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+80]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NOMINAL_VARIANT_RECEIVER
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+48]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 lea rax,[rbx+2]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop
.binding_terminal_regular:
 ; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F02 extends the existing terminal with exactly one `.mutable`.
 ; Payload0 remains the binding name token and the flag preserves old ASTs.
 xor r13d,r13d
 lea rdx,[rbx+3]
 cmp rdx,r14
 jae .binding_end_ready
 lea rax,[rbx+2]
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .binding_end_ready
 lea rax,[rbx+3]
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .binding_end_ready
 mov rax,[r10+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r10+NEBOC_TOKEN_START_OFFSET]
 cmp rax,expression_mutable_name_len
 jne .binding_end_ready
 mov rsi,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rsi,rsi
 jz .binding_end_ready
 add rsi,[r10+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel expression_mutable_name]
 mov ecx,expression_mutable_name_len
 cld
 repe cmpsb
 jne .binding_end_ready
 mov r13,1
 lea rax,[rbx+3]
 mov [rsp+120],rax
 lea rbx,[rbx+4]
 jmp .binding_index_ready
.binding_end_ready:
 mov rax,[rsp+80]
 mov [rsp+120],rax
 lea rbx,[rbx+2]
.binding_index_ready:
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 EXPR_TOKEN_PTR r11,qword [rsp+120]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_BINDING_TERMINAL
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 test r13,r13
 jz .binding_flags_ready
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
.binding_flags_ready:
 mov rax,[rsp+40]
 mov [rsp+8],rax
 test r13,r13
 jz expression_bp_loop
 jmp expression_bp_finish

expression_bp_return_terminal:
 lea rbx,[rbx+2]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 lea rax,[rbx-1]
 EXPR_TOKEN_PTR r11,rax
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_RETURN_TERMINAL
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_bp_done_decrement
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 lea rax,[rbx-1]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_finish

expression_bp_argument_unexpected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_UNEXPECTED_TOKEN
 mov rdx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 call neboc_expression_set_error
 jmp expression_bp_done_decrement
expression_bp_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 call neboc_expression_set_error
 jmp expression_bp_done_decrement
expression_bp_nesting:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rdx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 call neboc_expression_set_error
 jmp expression_bp_done_decrement
expression_bp_finish:
 mov rax,[rsp+8]
 mov [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],rax
 xor eax,eax
expression_bp_done_decrement:
 dec qword [r12+NEBOC_EXPR_NESTING_OFFSET]
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; expression_parse_prefix(ExpressionRequest*)
NEBOC_ABI_FUNCTION neboc_expression_parse_prefix
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,[r12+NEBOC_EXPR_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_EXPR_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_EXPR_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_DOT
 je expression_prefix_contextual_option
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 je expression_prefix_identifier
 cmp rcx,NEBOC_TOKEN_RESERVED_LBRACKET
 je expression_prefix_array
 cmp rcx,NEBOC_TOKEN_INTEGER
 je expression_prefix_integer
 cmp rcx,NEBOC_TOKEN_FLOAT
 je expression_prefix_float
 cmp rcx,NEBOC_TOKEN_TEXT
 je expression_prefix_text
 cmp rcx,NEBOC_TOKEN_INTERPOLATION_HEAD
 je expression_prefix_interpolated
 cmp rcx,NEBOC_TOKEN_CHAR
 je expression_prefix_char
 cmp rcx,NEBOC_TOKEN_KW_TRUE
 je expression_prefix_true
 cmp rcx,NEBOC_TOKEN_KW_FALSE
 je expression_prefix_false
 cmp rcx,NEBOC_TOKEN_INFINITY
 je expression_prefix_math_constant
 cmp rcx,NEBOC_TOKEN_PI
 je expression_prefix_math_constant
 cmp rcx,NEBOC_TOKEN_TAU
 je expression_prefix_math_constant
 cmp rcx,NEBOC_TOKEN_EMPTY_SET
 je expression_prefix_empty_set
 cmp rcx,NEBOC_TOKEN_MINUS
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_PLUS
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_BANG
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_SQUARE_ROOT
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_CUBE_ROOT
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_FOURTH_ROOT
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_REDUCTION_SUM
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_REDUCTION_PRODUCT
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_FLOOR_OPEN
 je expression_prefix_math_delimited
 cmp rcx,NEBOC_TOKEN_CEIL_OPEN
 je expression_prefix_math_delimited
 cmp rcx,NEBOC_TOKEN_LPAREN
 je expression_prefix_group
 jmp expression_prefix_expected
expression_prefix_contextual_option:
 ; Preserve the exact leading-dot source span and the option name token.
 ; No implicit variable or globally callable option is fabricated.
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+40],rax
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .option_name
 ; enum retains its keyword token; only this leading-dot call context admits
 ; it as a selector. Ordinary enum declarations keep their existing grammar.
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_ENUM
 jne expression_prefix_expected
.option_name:
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne expression_prefix_expected
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[rsp+40]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_identifier:
 ; Recognize associative type applications before treating '<' as comparison.
 ; Type checking is owned by the collection semantic plan, not this parser.
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 test rdx,rdx
 jz .ordinary
 add rdx,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp rax,7
 jne .not_channel_name
 cmp dword [rdx],0x6e616843 ; Chan
 jne .not_channel_name
 cmp word [rdx+4],0x656e ; ne
 jne .not_channel_name
 cmp byte [rdx+6],'l'
 je expression_prefix_associative_type
.not_channel_name:
 cmp rax,6
 jne .not_column_name
 cmp dword [rdx],0x6f4c7752 ; RwLo
 jne .not_rwlock_name
 cmp word [rdx+4],0x6b63 ; ck
 je expression_prefix_associative_type
.not_rwlock_name:
 cmp dword [rdx],0x6974704f ; Opti
 jne .not_option_name
 cmp word [rdx+4],0x6e6f ; on
 je expression_prefix_associative_type
.not_option_name:
 cmp dword [rdx],0x75736552 ; Resu
 jne .not_result_name
 cmp word [rdx+4],0x746c ; lt
 je expression_prefix_associative_type
.not_result_name:
 cmp dword [rdx],0x65727453 ; Stre
 jne .column_name
 cmp word [rdx+4],0x6d61 ; am
 je expression_prefix_associative_type
.column_name:
 cmp dword [rdx],0x7274614d ; Matr
 jne .vector_name
 cmp word [rdx+4],0x7869 ; ix
 je expression_prefix_associative_type
.vector_name:
 cmp dword [rdx],0x74636556 ; Vect
 jne .column_only
 cmp word [rdx+4],0x726f ; or
 je expression_prefix_associative_type
.column_only:
 cmp dword [rdx],0x736e6554 ; Tens
 jne .column_type
 cmp word [rdx+4],0x726f ; or
 je expression_prefix_associative_type
.column_type:
 cmp dword [rdx],0x756c6f43 ; Colu
 jne .not_column_name
 cmp word [rdx+4],0x6e6d ; mn
 je expression_prefix_associative_type
.not_column_name:
 cmp rax,4
 jne .maybe_set
 cmp dword [rdx],0x74636944 ; Dict
 je expression_prefix_associative_type
 cmp dword [rdx],0x7473694c ; List
 je expression_prefix_associative_type
 cmp dword [rdx],0x65657254 ; Tree
 je expression_prefix_associative_type
 cmp dword [rdx],0x65646f4e ; Node
 je expression_prefix_associative_type
 cmp dword [rdx],0x776f6c46 ; Flow
 je expression_prefix_associative_type
.maybe_set:
 cmp rax,5
 jne .set_name
 cmp dword [rdx],0x6574754d ; Mute
 jne .not_mutex_name
 cmp byte [rdx+4],'x'
 je expression_prefix_associative_type
.not_mutex_name:
 cmp dword [rdx],0x6e657645 ; Even
 jne .graph_name
 cmp byte [rdx+4],'t'
 je expression_prefix_associative_type
.graph_name:
 cmp dword [rdx],0x70617247 ; Graph
 jne .stack_name
 cmp byte [rdx+4],'h'
 je expression_prefix_associative_type
.stack_name:
 cmp dword [rdx],0x63617453 ; Stack
 jne .queue_name
 cmp byte [rdx+4],'k'
 je expression_prefix_associative_type
.queue_name:
 cmp dword [rdx],0x75657551 ; Queue
 jne .deque_name
 cmp byte [rdx+4],'e'
 je expression_prefix_associative_type
.deque_name:
 cmp dword [rdx],0x75716544 ; Deque
 jne .ordinary
 cmp byte [rdx+4],'e'
 je expression_prefix_associative_type
.set_name:
 cmp rax,3
 jne .ordinary
 cmp word [rdx],0x6553
 jne .ordinary
 cmp byte [rdx+2],'t'
 je expression_prefix_associative_type
.ordinary:
 mov qword [rsp],NEBOC_AST_IDENTIFIER_EXPR
 mov [rsp+8],rbx
 mov qword [rsp+16],0
 jmp expression_prefix_leaf
expression_prefix_associative_type:
 ; The type application itself owns every comma/type token and its source span.
 ; Ordered IdentifierExpr children retain both K and V for typed lowering.
 mov [rsp+8],rbx
 mov qword [rsp+16],0
 mov qword [rsp+32],0
 mov qword [rsp+40],0
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 jne expression_prefix_expected
.type_next:
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .type_identifier
 ; Only the second Vector argument is a value-level dimension. Preserve its
 ; integer node/value/span; associative key/value arguments remain types.
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne expression_prefix_expected
 cmp qword [rsp+16],1
 jne expression_prefix_expected
 EXPR_TOKEN_PTR r10,qword [rsp+8]
 mov rax,[r10+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r10+NEBOC_TOKEN_START_OFFSET]
 cmp rax,6
 jne expression_prefix_expected
 mov rdx,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 add rdx,[r10+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rdx],0x74636556
 jne expression_prefix_expected
 cmp word [rdx+4],0x726f
 jne expression_prefix_expected
 mov esi,NEBOC_AST_INTEGER_LITERAL
 jmp .type_append
.type_identifier:
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 jne .plain_type_identifier
 ; Nested type applications use the same parser and nesting budget. Their
 ; child order, identity and full source spans remain attached to the AST.
 inc qword [r12+NEBOC_EXPR_NESTING_OFFSET]
 mov rax,[r12+NEBOC_EXPR_NESTING_OFFSET]
 cmp rax,[r12+NEBOC_EXPR_MAX_NESTING_OFFSET]
 jae .nested_type_limit
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 call neboc_expression_parse_prefix
 dec qword [r12+NEBOC_EXPR_NESTING_OFFSET]
 test eax,eax
 jnz expression_prefix_done
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 dec rbx
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+48],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 jmp .type_payload_ready
.nested_type_limit:
 dec qword [r12+NEBOC_EXPR_NESTING_OFFSET]
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rdx,rbx
 call neboc_expression_set_error
 jmp expression_prefix_done
.plain_type_identifier:
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
.type_append:
 mov rdi,r15
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+48]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[rsp+48]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rbx
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .type_payload_ready
 EXPR_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rbx
.type_payload_ready:
 cmp qword [rsp+32],0
 jne .link_type
 mov rax,[rsp+48]
 mov [rsp+32],rax
 jmp .type_linked
.link_type:
 mov r10,[rsp+40]
 mov rax,[rsp+48]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
.type_linked:
 mov rax,[rsp+24]
 mov [rsp+40],rax
 inc qword [rsp+16]
 cmp qword [rsp+16],2
 ja expression_prefix_expected
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 je .type_next
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne expression_prefix_expected
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 EXPR_TOKEN_PTR r11,qword [rsp+8]
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 lea r9,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 ; Preserve the existing public bounded `Node<Int> value.name` spelling.
 ; Both spellings share one typed constructor AST and native Node owner.
 EXPR_TOKEN_PTR r11,qword [rsp+8]
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp rax,6
 je .prefix_column_name
 cmp rax,5
 je .prefix_event_name
 cmp rax,4
 jne .type_only
 mov rdx,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 add rdx,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rdx],0x65646f4e
 je .prefix_scalar_value
 cmp dword [rdx],0x776f6c46
 jne .type_only
 jmp .prefix_scalar_value
.prefix_event_name:
 mov rdx,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 add rdx,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rdx],0x6e657645
 jne .type_only
 cmp byte [rdx+4],'t'
 jne .type_only
.prefix_scalar_value:
 cmp rbx,r14
 jae .type_only
 EXPR_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_INTEGER
 je .prefix_node_value
 cmp rax,NEBOC_TOKEN_MINUS
 je .prefix_node_value
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .type_only
 jmp .prefix_node_value
.prefix_column_name:
 mov rdx,[r12+NEBOC_EXPR_SOURCE_DATA_OFFSET]
 add rdx,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp dword [rdx],0x74636556
 jne .prefix_column_only
 cmp word [rdx+4],0x726f
 je .prefix_array_value
.prefix_column_only:
 cmp dword [rdx],0x756c6f43
 jne .type_only
 cmp word [rdx+4],0x6e6d
 jne .type_only
.prefix_array_value:
 cmp rbx,r14
 jae .type_only
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_LBRACKET
 jne .type_only
.prefix_node_value:
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+32],rax
 mov rdi,r12
 call neboc_expression_parse_prefix
 test eax,eax
 jnz expression_prefix_done
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+40],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+48]
 mov r8,[r10+NEBOC_AST_NODE_END_OFFSET]
 mov r10,[rsp+24]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov rax,[rsp+40]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rdi,r15
 mov esi,NEBOC_AST_CALL_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 lea r9,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+48]
 mov qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
.type_only:
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_array:
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+32],0
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
.element:
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_RBRACKET
 je .array_done
 cmp qword [rsp+32],64
 jae expression_prefix_expected
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_prefix_done
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 cmp qword [rsp+8],0
 jne .link
 mov [rsp+8],rax
 jmp .linked
.link:
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
.linked:
 mov [rsp+16],rax
 inc qword [rsp+32]
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_RBRACKET
 je .array_done
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne expression_prefix_expected
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 jmp .element
.array_done:
 mov rdi,r15
 mov esi,NEBOC_AST_ARRAY_LITERAL
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 xor eax,eax
 jmp expression_prefix_done
%include "compiler/parser/expression/interpolation_expr.inc"

expression_prefix_integer:
 mov qword [rsp],NEBOC_AST_INTEGER_LITERAL
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp+8],rax
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_float:
 mov qword [rsp],NEBOC_AST_FLOAT_LITERAL
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp+8],rax
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_text:
 mov qword [rsp],NEBOC_AST_TEXT_LITERAL
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp+8],rax
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_char:
 mov qword [rsp],NEBOC_AST_CHAR_LITERAL
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp+8],rax
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_true:
 mov qword [rsp],NEBOC_AST_BOOL_LITERAL
 mov qword [rsp+8],1
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_false:
 mov qword [rsp],NEBOC_AST_BOOL_LITERAL
 mov qword [rsp+8],0
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_math_constant:
 mov qword [rsp],NEBOC_AST_MATH_CONSTANT
 mov [rsp+8],rcx
 mov [rsp+16],rbx
 jmp expression_prefix_leaf
expression_prefix_empty_set:
 mov qword [rsp],NEBOC_AST_SET_EMPTY_LITERAL
 mov [rsp+8],rcx
 mov [rsp+16],rbx
expression_prefix_leaf:
 mov rdi,r15
 mov rsi,[rsp]
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_math_delimited:
 mov [rsp],rcx
 mov [rsp+8],rbx
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+16],rax
 mov qword [rsp+48],NEBOC_TOKEN_FLOOR_CLOSE
 cmp rcx,NEBOC_TOKEN_FLOOR_OPEN
 je .math_delimiter_ready
 mov qword [rsp+48],NEBOC_TOKEN_CEIL_CLOSE
.math_delimiter_ready:
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_prefix_done
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+56],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 mov rax,[rsp+48]
 cmp [r11+NEBOC_TOKEN_KIND_OFFSET],rax
 jne expression_prefix_expected
 mov rdi,r15
 mov esi,NEBOC_AST_UNARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[rsp+16]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+40]
 mov rax,[rsp+56]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rax,[rsp+32]
 mov [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_group:
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_prefix_done
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne expression_prefix_expected
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_unary:
 mov [rsp],rcx
 mov [rsp+8],rbx
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+16],rax
 mov rdi,rcx
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_PREFIX
 cmp rcx,NEBOC_TOKEN_REDUCTION_SUM
 je .binder_fixity
 cmp rcx,NEBOC_TOKEN_REDUCTION_PRODUCT
 jne .fixity_ready
.binder_fixity:
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_BINDER
.fixity_ready:
 call neboc_operator_precedence_lookup
 test rax,rax
 jz expression_prefix_expected
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz expression_prefix_expected
 mov [rsp+48],rcx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 mov rsi,[rsp+48]
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r11,[rsp+24]
 mov rdi,r15
 mov esi,NEBOC_AST_UNARY_EXPR
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[rsp+16]
 mov r8,[r11+NEBOC_AST_NODE_END_OFFSET]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+40]
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp expression_prefix_done
expression_prefix_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 call neboc_expression_set_error
expression_prefix_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
