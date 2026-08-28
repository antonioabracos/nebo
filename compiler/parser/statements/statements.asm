; Nebo Assembly — MF018 flow-first statements and if/else parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/statements/statements.inc"

extern neboc_ast_builder_append
extern neboc_ast_builder_node
extern neboc_expression_parse

%macro STMT_TOKEN_PTR 2
 mov %1,%2
 imul %1,NEBOC_TOKEN_SIZE
 add %1,[r12+NEBOC_STMT_TOKENS_OFFSET]
%endmacro

section .text

NEBOC_ABI_FUNCTION neboc_statement_set_error
 test rdi,rdi
 jz .invalid
 mov [rdi+NEBOC_STMT_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_STMT_ERROR_TOKEN_OFFSET],rdx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; request*, first-header-token-index -> InvalidSource. Publish the stable
; missing-pair diagnostic plus exact insertion edits at the condition/binding
; start and the opening brace. If no brace exists, retain the first safe edit.
statement_control_header_missing_pair:
 mov qword [rdi+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 mov [rdi+NEBOC_STMT_ERROR_TOKEN_OFFSET],rsi
 mov qword [rdi+NEBOC_STMT_FIXIT_COUNT_OFFSET],1
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_STMT_TOKENS_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+NEBOC_STMT_FIXIT0_START_OFFSET],rdx
 mov [rdi+NEBOC_STMT_FIXIT0_END_OFFSET],rdx
 mov qword [rdi+NEBOC_STMT_FIXIT0_KIND_OFFSET],NEBOC_STMT_FIXIT_INSERT_LPAREN
 mov rcx,rsi
.scan:
 cmp rcx,[rdi+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 jae .done
 mov rax,rcx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_STMT_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 je .brace
 inc rcx
 jmp .scan
.brace:
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+NEBOC_STMT_FIXIT1_START_OFFSET],rdx
 mov [rdi+NEBOC_STMT_FIXIT1_END_OFFSET],rdx
 mov qword [rdi+NEBOC_STMT_FIXIT1_KIND_OFFSET],NEBOC_STMT_FIXIT_INSERT_RPAREN
 mov qword [rdi+NEBOC_STMT_FIXIT_COUNT_OFFSET],2
.done:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; request*, current-token-index -> InvalidSource with one exact ')' insertion.
statement_control_header_missing_rparen:
 mov qword [rdi+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_RPAREN_REQUIRED
 mov [rdi+NEBOC_STMT_ERROR_TOKEN_OFFSET],rsi
 mov qword [rdi+NEBOC_STMT_FIXIT_COUNT_OFFSET],1
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_STMT_TOKENS_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+NEBOC_STMT_FIXIT0_START_OFFSET],rdx
 mov [rdi+NEBOC_STMT_FIXIT0_END_OFFSET],rdx
 mov qword [rdi+NEBOC_STMT_FIXIT0_KIND_OFFSET],NEBOC_STMT_FIXIT_INSERT_RPAREN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; Internal expression adapter. R12 is StatementRequest*.
statement_parse_expression:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,[r12+NEBOC_STMT_EXPR_REQUEST_OFFSET]
 test rbx,rbx
 jz .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 rep stosq
 mov rax,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov [rbx+NEBOC_EXPR_TOKENS_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov [rbx+NEBOC_EXPR_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov [rbx+NEBOC_EXPR_SOURCE_ID_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_SOURCE_DATA_OFFSET]
 mov [rbx+NEBOC_EXPR_SOURCE_DATA_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov [rbx+NEBOC_EXPR_BUILDER_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_INDEX_OFFSET]
 mov [rbx+NEBOC_EXPR_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_STMT_MAX_NESTING_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_STMT_DEFAULT_MAX_NESTING
.have_limit:
 mov [rbx+NEBOC_EXPR_MAX_NESTING_OFFSET],rax
 mov rdi,rbx
 call neboc_expression_parse
 test eax,eax
 jnz .copy_error
 mov rax,[rbx+NEBOC_EXPR_INDEX_OFFSET]
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rax
 mov rax,[rbx+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.copy_error:
 mov rax,[rbx+NEBOC_EXPR_ERROR_CODE_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_CODE_OFFSET],rax
 mov rax,[rbx+NEBOC_EXPR_ERROR_TOKEN_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse one statement at request.index.
NEBOC_ABI_FUNCTION neboc_statement_parse
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 test r12,r12
 jz statement_invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 test r13,r13
 jz statement_invalid
 test r14,r14
 jz statement_invalid
 test r15,r15
 jz statement_invalid
 mov qword [r12+NEBOC_STMT_RESULT_NODE_OFFSET],0
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae statement_expected
 STMT_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_KIND_OFFSET]
 ; NPT-LANG-37 closed-context guard.  Direct depth-zero outer declarations
 ; are intercepted by the CLI materializer before this dispatcher.  Seeing
 ; the exact existing receiver-first prefix here therefore proves start,
 ; branch/loop, or a second lexical depth and must not fall into Pratt.
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+6]
 cmp rcx,r14
 jae .npt37_not_nested_prefix
 lea rcx,[rbx+1]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+2]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+3]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+4]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+5]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .npt37_not_nested_prefix
 lea rcx,[rbx+6]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .npt37_not_nested_prefix
 test qword [r12+NEBOC_STMT_FLAGS_OFFSET],NEBOC_STMT_FLAG_NPT37_NESTED_FUNCTION_BODY
 jnz statement_nested_depth
 jmp statement_nested_context
.npt37_not_nested_prefix:
 cmp rax,NEBOC_TOKEN_KW_IF
 je statement_if
 cmp rax,NEBOC_TOKEN_KW_FOR
 je statement_for
 cmp rax,NEBOC_TOKEN_KW_WHEN
 je statement_unsupported
 cmp rax,NEBOC_TOKEN_KW_WHILE
 je statement_while
 cmp rax,NEBOC_TOKEN_KW_SWITCH
 je statement_unsupported
 cmp rax,NEBOC_TOKEN_KW_LOOP
 je statement_loop
 cmp rax,NEBOC_TOKEN_KW_BREAK
 je statement_break
 cmp rax,NEBOC_TOKEN_KW_CONTINUE
 je statement_continue
 ; Reject condicao.if before entering the Pratt suffix parser.
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne statement_expression
 lea rcx,[rbx+1]
 cmp rcx,r14
 jae statement_expression
 STMT_TOKEN_PTR r10,rcx
 mov rax,[r10+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_RESERVED_EQUAL
 je statement_assignment
 cmp rax,NEBOC_TOKEN_OPTION_ASSIGN
 je statement_assignment
 cmp rax,NEBOC_TOKEN_PLUS
 je .compound_assignment_probe
 cmp rax,NEBOC_TOKEN_MINUS
 je .compound_assignment_probe
 cmp rax,NEBOC_TOKEN_STAR
 je .compound_assignment_probe
 cmp rax,NEBOC_TOKEN_SLASH
 je .compound_assignment_probe
 cmp rax,NEBOC_TOKEN_PERCENT
 je .compound_assignment_probe
 cmp rax,NEBOC_TOKEN_CARET
 jne .not_assignment
.compound_assignment_probe:
 lea rcx,[rbx+2]
 cmp rcx,r14
 jae statement_expression
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_EQUAL
 je statement_assignment
.not_assignment:
 ; NPT-LANG-27 keeps `=` statement-only but permits the existing `.at(...)`
 ; call expression to be its target. Probe only for an exact top-level `=`;
 ; the dedicated parser and semantic owner still reject every other target.
 lea rcx,[rbx+1]
 xor edx,edx
.element_assignment_probe:
 cmp rcx,r14
 jae statement_expression
 STMT_TOKEN_PTR r10,rcx
 mov rax,[r10+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .not_element_assignment
 cmp rax,NEBOC_TOKEN_LPAREN
 je .element_probe_open
 cmp rax,NEBOC_TOKEN_RPAREN
 je .element_probe_close
 cmp rax,NEBOC_TOKEN_RESERVED_EQUAL
 jne .element_probe_next
 test rdx,rdx
 jz statement_element_assignment
 jmp .element_probe_next
.element_probe_open:
 inc rdx
 jmp .element_probe_next
.element_probe_close:
 test rdx,rdx
 jz statement_expression
 dec rdx
.element_probe_next:
 inc rcx
 jmp .element_assignment_probe

.not_element_assignment:
 lea rcx,[rbx+2]
 cmp rcx,r14
 jae statement_expression
 lea rcx,[rbx+1]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne statement_expression
 lea rcx,[rbx+2]
 STMT_TOKEN_PTR r10,rcx
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_IF
 je statement_invalid_control_chain

statement_expression:
 call statement_parse_expression
 test eax,eax
 jnz statement_done
 mov qword [rsp],0
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz statement_done
 mov r10,[rsp+16]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae statement_expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne statement_expected
 mov rax,[r10+NEBOC_AST_NODE_KIND_OFFSET]
 mov esi,NEBOC_AST_EXPRESSION_STMT
 cmp rax,NEBOC_AST_BINDING_TERMINAL
 jne .check_return
 mov esi,NEBOC_AST_BINDING_STMT
 jmp .kind_ready
.check_return:
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 jne .kind_ready
 mov esi,NEBOC_AST_RETURN_STMT
.kind_ready:
 mov [rsp+24],rsi
 mov rdi,r15
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz statement_done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz statement_done
 mov r10,[rsp+40]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz statement_done
 mov rax,[rsp+16]
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rcx
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rax,[rsp+32]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp statement_done

statement_if:
 mov rdi,r12
 call neboc_statement_parse_if
 jmp statement_done

statement_for:
 mov rdi,r12
 call neboc_statement_parse_for
 jmp statement_done

statement_assignment:
 mov rdi,r12
 call neboc_statement_parse_assignment
 jmp statement_done

statement_element_assignment:
 mov rdi,r12
 call neboc_statement_parse_element_assignment
 jmp statement_done

statement_loop:
 mov rdi,r12
 call neboc_statement_parse_loop
 jmp statement_done

statement_while:
 mov rdi,r12
 call neboc_statement_parse_while
 jmp statement_done

statement_break:
 mov rdi,r12
 mov esi,NEBOC_AST_BREAK_STMT
 call neboc_statement_parse_control_terminal
 jmp statement_done

statement_continue:
 mov rdi,r12
 mov esi,NEBOC_AST_CONTINUE_STMT
 call neboc_statement_parse_control_terminal
 jmp statement_done

statement_unsupported:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_UNSUPPORTED_CONTROL
 mov rdx,rbx
 call neboc_statement_set_error
 jmp statement_done
statement_invalid_control_chain:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_INVALID_CONTROL_CHAIN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp statement_done
statement_nested_context:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTED_CONTEXT
 mov rdx,rbx
 call neboc_statement_set_error
 jmp statement_done
statement_nested_depth:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_NESTED_DEPTH
 mov rdx,rbx
 call neboc_statement_set_error
 jmp statement_done
statement_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp statement_done
statement_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
statement_done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse the bounded cleanup-control form `loop { ... }`.
NEBOC_ABI_FUNCTION neboc_statement_parse_loop
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 test r12,r12
 jz .invalid
 inc qword [r12+NEBOC_STMT_NESTING_OFFSET]
 mov rax,[r12+NEBOC_STMT_MAX_NESTING_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_STMT_DEFAULT_MAX_NESTING
.have_limit:
 cmp [r12+NEBOC_STMT_NESTING_OFFSET],rax
 ja .limit
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_LOOP
 jne .expected
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rdi,r12
 call neboc_statement_parse_block
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+16]
 mov r8,[r10+NEBOC_AST_NODE_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_LOOP_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 lea r9,[rsp+24]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+24]
 lea rdx,[rsp+32]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+32]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov rax,[rsp+24]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .return
.done:
 dec qword [r12+NEBOC_STMT_NESTING_OFFSET]
.return:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
.limit:
 mov qword [r12+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rax,[r12+NEBOC_STMT_INDEX_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done

; Parse the sole canonical public form `while (BoolExpression) { ... }`.
NEBOC_ABI_FUNCTION neboc_statement_parse_while
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 test r12,r12
 jz .invalid
 inc qword [r12+NEBOC_STMT_NESTING_OFFSET]
 mov rax,[r12+NEBOC_STMT_MAX_NESTING_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_STMT_DEFAULT_MAX_NESTING
.have_limit:
 cmp [r12+NEBOC_STMT_NESTING_OFFSET],rax
 ja .limit
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_WHILE
 jne .expected
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .preview_open_required
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 call statement_parse_expression
 test eax,eax
 jnz .done
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .preview_close_required
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+8],rax
 mov rdi,r12
 call neboc_statement_parse_block
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+16],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+24]
 mov r8,[r10+NEBOC_AST_NODE_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_WHILE_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+40]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.preview_open_required:
 mov rdi,r12
 mov rsi,rbx
 call statement_control_header_missing_pair
 jmp .done
.preview_close_required:
 mov rdi,r12
 mov rsi,rbx
 call statement_control_header_missing_rparen
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_STMT_INDEX_OFFSET]
 call neboc_statement_set_error
 jmp .done
.limit:
 mov qword [r12+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rax,[r12+NEBOC_STMT_INDEX_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .return
.done:
 dec qword [r12+NEBOC_STMT_NESTING_OFFSET]
.return:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse canonical `for (item in rangeBinding) { ... }`.  The option_result_null_externo_e_erros_tipados collection
; vertical authenticates the binding kind and iterator bounds; this structural
; parser freezes the shared AST shape for general statement-tree consumers.
; This helper is also the sole source-header owner used by collection semantic
; adapters. On success it publishes the binding/iterable token indices in
; scratch1/scratch2 and leaves request.index immediately after `)`.
NEBOC_ABI_FUNCTION neboc_statement_parse_for_header
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_FOR
 jne .expected
 inc rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .missing_pair
 inc rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .expected
 mov [r12+NEBOC_STMT_SCRATCH1_OFFSET],rbx
 inc rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .expected
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp rax,2
 jne .expected
 mov rax,[r12+NEBOC_STMT_SOURCE_DATA_OFFSET]
 test rax,rax
 jz .expected
 add rax,[r11+NEBOC_TOKEN_START_OFFSET]
 cmp word [rax],0x6e69
 jne .expected
 inc rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .expected
 mov [r12+NEBOC_STMT_SCRATCH2_OFFSET],rbx
 inc rbx
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .missing_rparen
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 xor eax,eax
 jmp .done
.missing_pair:
 mov rdi,r12
 mov rsi,rbx
 call statement_control_header_missing_pair
 jmp .done
.missing_rparen:
 mov rdi,r12
 mov rsi,rbx
 call statement_control_header_missing_rparen
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

NEBOC_ABI_FUNCTION neboc_statement_parse_for
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 test r12,r12
 jz .invalid
 inc qword [r12+NEBOC_STMT_NESTING_OFFSET]
 mov rax,[r12+NEBOC_STMT_MAX_NESTING_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_STMT_DEFAULT_MAX_NESTING
.have_limit:
 cmp [r12+NEBOC_STMT_NESTING_OFFSET],rax
 ja .limit
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 mov rdi,r12
 call neboc_statement_parse_for_header
 test eax,eax
 jnz .done
 mov rbx,[r12+NEBOC_STMT_SCRATCH1_OFFSET]
 STMT_TOKEN_PTR r11,rbx
 mov [rsp+8],rbx
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+16]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+24]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rbx,[r12+NEBOC_STMT_SCRATCH2_OFFSET]
 STMT_TOKEN_PTR r11,rbx
 mov [rsp+32],rbx
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rdi,r12
 call neboc_statement_parse_block
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+56],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+64]
 mov r8,[r10+NEBOC_AST_NODE_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_RANGE_FOR_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 lea r9,[rsp+72]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+72]
 lea rdx,[rsp+80]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+80]
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+24]
 mov rax,[rsp+40]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 mov rax,[rsp+56]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rax,[rsp+72]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.limit:
 mov qword [r12+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rax,[r12+NEBOC_STMT_INDEX_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .return
.done:
 dec qword [r12+NEBOC_STMT_NESTING_OFFSET]
.return:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, AST kind -> Status for `break;` and `continue;`.
NEBOC_ABI_FUNCTION neboc_statement_parse_control_terminal
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .invalid
 mov r14,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r15,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r15
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 inc rbx
 cmp rbx,r15
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .expected
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 mov rdi,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rsi,r13
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 lea r9,[rsp+8]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rax,[rsp+8]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse `identifier = expression;`, `identifier += expression;` or
; `identifier -= expression;` as a statement-only structural AST node.
NEBOC_ABI_FUNCTION neboc_statement_parse_assignment
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .expected
 mov [rsp],rbx
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+8],rax
 mov rdx,[r11+NEBOC_TOKEN_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_IDENTIFIER_EXPR
 mov rcx,[rsp+8]
 mov r8,rdx
 lea r9,[rsp+16]
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+24]
 mov rax,[rsp]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 lea rax,[rbx+1]
 STMT_TOKEN_PTR r11,rax
 mov rax,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_RESERVED_EQUAL
 je .simple_operator
 cmp rax,NEBOC_TOKEN_OPTION_ASSIGN
 je .direct_compound_operator
 cmp rax,NEBOC_TOKEN_PLUS
 je .compound_operator
 cmp rax,NEBOC_TOKEN_MINUS
 je .compound_operator
 cmp rax,NEBOC_TOKEN_STAR
 je .compound_operator
 cmp rax,NEBOC_TOKEN_SLASH
 je .compound_operator
 cmp rax,NEBOC_TOKEN_PERCENT
 je .compound_operator
 cmp rax,NEBOC_TOKEN_CARET
 jne .expected
.compound_operator:
 mov [rsp+56],rax
 lea rax,[rbx+2]
 cmp rax,r14
 jae .expected
 STMT_TOKEN_PTR r11,rax
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_EQUAL
 jne .expected
 add rbx,3
 jmp .operator_ready
.direct_compound_operator:
 mov [rsp+56],rax
 add rbx,2
 jmp .operator_ready
.simple_operator:
 mov qword [rsp+56],0
 add rbx,2
.operator_ready:
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 call statement_parse_expression
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+32],rax
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+24]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .expected
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_ASSIGNMENT_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp+8]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rax,[rsp]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+56]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rax,[rsp+40]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse the bounded existing-token form `receiver.at(index) = expression;`.
; Target authentication is deliberately deferred to the collection semantic
; owner/codegen validator; structurally this retains the complete call AST.
NEBOC_ABI_FUNCTION neboc_statement_parse_element_assignment
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 mov [rsp],rbx
 call statement_parse_expression
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+16]
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .expected
 mov rax,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp+24],rax
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_EQUAL
 jne .expected
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 call statement_parse_expression
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+32],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+16]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .expected
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 mov rdi,r15
 mov esi,NEBOC_AST_ASSIGNMENT_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp+24]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov rax,[rsp]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_COLLECTION_ELEMENT_ASSIGNMENT
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rax,[rsp+40]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse a lexical block and attach statements in source order.
NEBOC_ABI_FUNCTION neboc_statement_parse_block
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov r12,rdi
 test r12,r12
 jz block_invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae block_expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne block_expected
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],0
block_loop:
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae block_expected
 STMT_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_RBRACE
 je block_finish
 cmp rax,NEBOC_TOKEN_EOF
 je block_expected
 mov rdi,r12
 call neboc_statement_parse
 test eax,eax
 jnz block_done
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+32],rax
 cmp qword [rsp+8],0
 jne block_link
 mov [rsp+8],rax
 mov [rsp+16],rax
 jmp block_count
block_link:
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz block_done
 mov r10,[rsp+40]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 mov [rsp+16],rax
block_count:
 inc qword [rsp+24]
 jmp block_loop
block_finish:
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 mov [rsp+48],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov rdi,r15
 mov esi,NEBOC_AST_BLOCK
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 mov r8,[rsp+48]
 lea r9,[rsp+56]
 call neboc_ast_builder_append
 test eax,eax
 jnz block_done
 mov rdi,r15
 mov rsi,[rsp+56]
 lea rdx,[rsp+64]
 call neboc_ast_builder_node
 test eax,eax
 jnz block_done
 mov r10,[rsp+64]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+24]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov rax,[rsp+56]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp block_done
block_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,rbx
 call neboc_statement_set_error
 jmp block_done
block_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
block_done:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Parse if [(]expr[)] block [else block|else if...].  Both spellings are
; public in the v1.0 source corpus; a present opening parenthesis still
; requires its exact closing mate.
NEBOC_ABI_FUNCTION neboc_statement_parse_if
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,160
 mov r12,rdi
 test r12,r12
 jz if_invalid
 mov r13,[r12+NEBOC_STMT_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov r15,[r12+NEBOC_STMT_BUILDER_OFFSET]
 inc qword [r12+NEBOC_STMT_NESTING_OFFSET]
 mov rax,[r12+NEBOC_STMT_MAX_NESTING_OFFSET]
 test rax,rax
 jnz .have_limit
 mov eax,NEBOC_STMT_DEFAULT_MAX_NESTING
.have_limit:
 cmp [r12+NEBOC_STMT_NESTING_OFFSET],rax
 ja if_limit
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_IF
 jne if_expected
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 mov qword [rsp+96],0
 cmp rbx,r14
 jae if_expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .condition
 call if_require_lparen
 test eax,eax
 jnz if_done_decrement
 mov qword [rsp+96],1
.condition:
 call statement_parse_expression
 test eax,eax
 jnz if_done_decrement
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+8],rax
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae if_expected
 cmp qword [rsp+96],0
 je .condition_ready
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne if_expected
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
.condition_ready:
 mov rdi,r12
 call neboc_statement_parse_block
 test eax,eax
 jnz if_done_decrement
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+16],rax
 mov qword [rsp+24],0
 mov qword [rsp+32],2
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae if_build
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_ELSE
 jne if_build
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 cmp rbx,r14
 jae if_expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_IF
 jne if_else_block
 mov rdi,r12
 call neboc_statement_parse_if
 test eax,eax
 jnz if_done_decrement
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+24],rax
 mov rdi,r15
 mov rsi,rax
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov r10,[rsp+40]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_ELSE_IF
 jmp if_else_ready
if_else_block:
 mov rdi,r12
 call neboc_statement_parse_block
 test eax,eax
 jnz if_done_decrement
 mov rax,[r12+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+24],rax
if_else_ready:
 mov qword [rsp+32],3
if_build:
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+40]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov r10,[rsp+40]
 mov rax,[r10+NEBOC_AST_NODE_END_OFFSET]
 cmp qword [rsp+24],0
 je .end_ready
 mov rdi,r15
 mov rsi,[rsp+24]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov rax,[rsp+48]
 mov rax,[rax+NEBOC_AST_NODE_END_OFFSET]
.end_ready:
 mov [rsp+56],rax
 mov rdi,r15
 mov esi,NEBOC_AST_IF_STMT
 mov rdx,[r12+NEBOC_STMT_SOURCE_ID_OFFSET]
 mov rcx,[rsp]
 mov r8,[rsp+56]
 lea r9,[rsp+64]
 call neboc_ast_builder_append
 test eax,eax
 jnz if_done_decrement
 mov rdi,r15
 mov rsi,[rsp+64]
 lea rdx,[rsp+72]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov r10,[rsp+72]
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+80]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov r10,[rsp+80]
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 cmp qword [rsp+24],0
 je .linked
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+88]
 call neboc_ast_builder_node
 test eax,eax
 jnz if_done_decrement
 mov r10,[rsp+88]
 mov rax,[rsp+24]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
.linked:
 mov rax,[rsp+64]
 mov [r12+NEBOC_STMT_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp if_done_decrement
if_require_lparen:
 mov rbx,[r12+NEBOC_STMT_INDEX_OFFSET]
 cmp rbx,r14
 jae .expected
 STMT_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .expected
 inc rbx
 mov [r12+NEBOC_STMT_INDEX_OFFSET],rbx
 xor eax,eax
 ret
.expected:
 sub rsp,8
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_STMT_INDEX_OFFSET]
 call neboc_statement_set_error
 add rsp,8
 ret
if_limit:
 mov qword [r12+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 mov rax,[r12+NEBOC_STMT_INDEX_OFFSET]
 mov [r12+NEBOC_STMT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp if_done_decrement
if_expected:
 mov rdi,r12
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,[r12+NEBOC_STMT_INDEX_OFFSET]
 call neboc_statement_set_error
 jmp if_done_decrement
if_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp if_done
if_done_decrement:
 dec qword [r12+NEBOC_STMT_NESTING_OFFSET]
if_done:
 add rsp,160
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
