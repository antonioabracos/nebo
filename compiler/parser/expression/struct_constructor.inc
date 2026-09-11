; A named product constructor keeps each field initializer in lexical order.
; It shares the normal named-argument expression grammar. Native semantic
; declarations subsequently decide field identity, type, count and layout.
expression_bp_struct_constructor:
 cmp qword [rsp],NEBOC_EXPR_BP_SUFFIX
 ja expression_bp_finish
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_bp_done_decrement
 mov r10,[rsp+48]
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne expression_bp_finish
 mov qword [rsp+88],0
 mov qword [rsp+96],0
 mov qword [rsp+104],0
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
.field:
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 je .close
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne expression_bp_expected
 lea rax,[rbx+1]
 cmp rax,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r10,rax
 cmp qword [r10+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_COLON
 jne expression_bp_expected
 EXPR_PARSE_ARGUMENT
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 cmp qword [rsp+88],0
 jne .link
 mov [rsp+88],rax
 mov [rsp+96],rax
 jmp .count
.link:
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
.count:
 inc qword [rsp+104]
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_bp_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 je .close
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne expression_bp_argument_unexpected
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 jmp .field
.close:
 mov [rsp+112],rbx
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 EXPR_TOKEN_PTR r11,qword [rsp+112]
 mov r10,[rsp+48]
 mov rdi,r15
 mov esi,NEBOC_AST_STRUCT_CONSTRUCTOR
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
 mov rax,[rsp+88]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+104]
 mov [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov rax,[rsp+48]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+8],rax
 jmp expression_bp_loop
