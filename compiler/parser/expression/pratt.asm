; Nebo Assembly — MF017 Pratt expression parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"

extern neboc_ast_builder_append
extern neboc_ast_builder_node

%macro EXPR_TOKEN_PTR 2
 mov %1,%2
 imul %1,NEBOC_TOKEN_SIZE
 add %1,[r12+NEBOC_EXPR_TOKENS_OFFSET]
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
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 cmp rcx,NEBOC_TOKEN_OR_OR
 je expression_bp_or
 cmp rcx,NEBOC_TOKEN_COALESCE
 je expression_bp_coalesce
 cmp rcx,NEBOC_TOKEN_AND_AND
 je expression_bp_and
 cmp rcx,NEBOC_TOKEN_XOR
 je expression_bp_xor
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je expression_bp_equality
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je expression_bp_equality
 cmp rcx,NEBOC_TOKEN_LESS
 je expression_bp_comparison
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je expression_bp_comparison
 cmp rcx,NEBOC_TOKEN_GREATER
 je expression_bp_comparison
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 je expression_bp_comparison
 cmp rcx,NEBOC_TOKEN_SPACESHIP
 je expression_bp_comparison
 cmp rcx,NEBOC_TOKEN_RANGE_INCLUSIVE
 je expression_bp_range
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_END
 je expression_bp_range
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 je expression_bp_range
 cmp rcx,NEBOC_TOKEN_RANGE_EXCLUSIVE
 je expression_bp_range
 cmp rcx,NEBOC_TOKEN_PLUS
 je expression_bp_term
 cmp rcx,NEBOC_TOKEN_MINUS
 je expression_bp_term
 cmp rcx,NEBOC_TOKEN_STAR
 je expression_bp_factor
 cmp rcx,NEBOC_TOKEN_SLASH
 je expression_bp_factor
 cmp rcx,NEBOC_TOKEN_PERCENT
 je expression_bp_factor
 cmp rcx,NEBOC_TOKEN_CARET
 je expression_bp_power
 jmp expression_bp_finish
expression_bp_or:
 mov r10d,NEBOC_OPERATOR_FAMILY_OR
 mov r8d,NEBOC_EXPR_BP_OR
 mov r9d,NEBOC_EXPR_BP_OR+1
 jmp expression_bp_have_power
expression_bp_coalesce:
 mov r10d,NEBOC_OPERATOR_FAMILY_COALESCE
 mov r8d,NEBOC_OPERATOR_BP_COALESCE
 mov r9d,NEBOC_OPERATOR_BP_COALESCE
 jmp expression_bp_have_power
expression_bp_and:
 mov r10d,NEBOC_OPERATOR_FAMILY_AND
 mov r8d,NEBOC_EXPR_BP_AND
 mov r9d,NEBOC_EXPR_BP_AND+1
 jmp expression_bp_have_power
expression_bp_xor:
 mov r10d,NEBOC_OPERATOR_FAMILY_XOR
 mov r8d,NEBOC_EXPR_BP_XOR
 mov r9d,NEBOC_EXPR_BP_XOR+1
 jmp expression_bp_have_power
expression_bp_equality:
 mov r10d,NEBOC_OPERATOR_FAMILY_EQUALITY
 mov r8d,NEBOC_EXPR_BP_EQUALITY
 mov r9d,NEBOC_EXPR_BP_EQUALITY+1
 jmp expression_bp_have_power
expression_bp_comparison:
 mov r10d,NEBOC_OPERATOR_FAMILY_RELATIONAL
 mov r8d,NEBOC_EXPR_BP_COMPARISON
 mov r9d,NEBOC_EXPR_BP_COMPARISON+1
 jmp expression_bp_have_power
expression_bp_range:
 mov r10d,NEBOC_OPERATOR_FAMILY_RANGE
 mov r8d,NEBOC_OPERATOR_BP_RANGE
 mov r9d,NEBOC_OPERATOR_BP_RANGE+1
 jmp expression_bp_have_power
expression_bp_term:
 mov r10d,NEBOC_OPERATOR_FAMILY_ADDITIVE
 mov r8d,NEBOC_EXPR_BP_TERM
 mov r9d,NEBOC_EXPR_BP_TERM+1
 jmp expression_bp_have_power
expression_bp_factor:
 mov r10d,NEBOC_OPERATOR_FAMILY_MULTIPLICATIVE
 mov r8d,NEBOC_EXPR_BP_FACTOR
 mov r9d,NEBOC_EXPR_BP_FACTOR+1
 jmp expression_bp_have_power
expression_bp_power:
 mov r10d,NEBOC_OPERATOR_FAMILY_POWER
 mov r8d,NEBOC_EXPR_BP_POWER
 mov r9d,NEBOC_EXPR_BP_POWER
expression_bp_have_power:
 cmp r8,[rsp]
 jb expression_bp_finish
 mov [rsp+16],rcx
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
 cmp qword [rsp],NEBOC_OPERATOR_BP_POSTFIX
 ja expression_bp_finish
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

expression_bp_lateral_flow:
 cmp qword [rsp],NEBOC_OPERATOR_BP_COMPOSITION
 ja expression_bp_finish
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
 mov rbx,rax
 inc rax
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
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_LATERAL_FLOW
 mov rax,[rsp+80]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov rax,[rsp+88]
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop


expression_bp_direct_call:
 cmp qword [rsp],NEBOC_EXPR_BP_SUFFIX
 ja expression_bp_finish
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
 je expression_bp_expected
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
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+48]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop

expression_bp_suffix:
 cmp qword [rsp],NEBOC_EXPR_BP_SUFFIX
 ja expression_bp_finish
 mov [rsp+72],rbx
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rax
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_KW_RETURN
 je expression_bp_return_terminal
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne expression_bp_expected
 mov [rsp+80],rax
 lea rdx,[rax+1]
 cmp rdx,r14
 jae expression_bp_binding_terminal
 EXPR_TOKEN_PTR r10,rdx
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
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_bp_done_decrement
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
 jmp expression_bp_expected
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

expression_bp_binding_terminal:
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
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 je expression_prefix_identifier
 cmp rcx,NEBOC_TOKEN_INTEGER
 je expression_prefix_integer
 cmp rcx,NEBOC_TOKEN_FLOAT
 je expression_prefix_float
 cmp rcx,NEBOC_TOKEN_TEXT
 je expression_prefix_text
 cmp rcx,NEBOC_TOKEN_CHAR
 je expression_prefix_char
 cmp rcx,NEBOC_TOKEN_KW_TRUE
 je expression_prefix_true
 cmp rcx,NEBOC_TOKEN_KW_FALSE
 je expression_prefix_false
 cmp rcx,NEBOC_TOKEN_MINUS
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_PLUS
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_BANG
 je expression_prefix_unary
 cmp rcx,NEBOC_TOKEN_LPAREN
 je expression_prefix_group
 jmp expression_prefix_expected
expression_prefix_identifier:
 mov qword [rsp],NEBOC_AST_IDENTIFIER_EXPR
 mov [rsp+8],rbx
 mov qword [rsp+16],0
 jmp expression_prefix_leaf
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
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 mov esi,NEBOC_EXPR_BP_UNARY
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
