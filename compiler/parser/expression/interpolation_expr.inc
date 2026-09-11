; Native InterpolatedTextExpr alternates Text leaves and ordinary expression
; AST children. Formatting and purity are semantic decisions after parsing.
expression_prefix_interpolated:
 mov rax,[r11+NEBOC_TOKEN_START_OFFSET]
 mov [rsp],rax
 mov rdi,r15
 mov esi,NEBOC_AST_INTERPOLATED_TEXT
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,rax
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+8]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov qword [rsp+16],0
.literal:
 EXPR_TOKEN_PTR r11,rbx
 mov rdi,r15
 mov esi,NEBOC_AST_TEXT_LITERAL
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_END_OFFSET]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 EXPR_TOKEN_PTR r11,rbx
 mov rax,[r11+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rbx
 mov qword [rsp+56],0
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTERPOLATION_TAIL
 jne .link
 mov rax,[r11+NEBOC_TOKEN_END_OFFSET]
 mov [rsp+56],rax
.link:
 cmp qword [rsp+16],0
 je .first
 mov rdi,r15
 mov rsi,[rsp+16]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 jmp .root
.first:
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+32]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
.root:
 mov rdi,r15
 mov rsi,[rsp+8]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 inc qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rax,[rsp+32]
 mov [rsp+16],rax
 cmp qword [rsp+56],0
 jne .finished
 ; A value wrapper is followed by another Text chunk; a literal by `${`.
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTERPOLATION_VALUE
 je .next_literal
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTERPOLATION_OPEN
 jne expression_prefix_expected
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 test eax,eax
 jnz expression_prefix_done
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+40],rax
 mov qword [rsp+48],0
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_COLON
 jne .close
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 mov rax,[r12+NEBOC_EXPR_FLAGS_OFFSET]
 sub rsp,16
 mov [rsp],rax
 or qword [r12+NEBOC_EXPR_FLAGS_OFFSET],NEBOC_EXPR_FLAG_FORMAT_PROFILE
 mov rdi,r12
 xor esi,esi
 call neboc_expression_parse_bp
 mov rcx,[rsp]
 mov [r12+NEBOC_EXPR_FLAGS_OFFSET],rcx
 add rsp,16
 test eax,eax
 jnz expression_prefix_done
 mov rax,[r12+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rsp+48],rax
 mov rbx,[r12+NEBOC_EXPR_INDEX_OFFSET]
 cmp rbx,r14
 jae expression_prefix_expected
.close:
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTERPOLATION_CLOSE
 jne expression_prefix_expected
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+48]
 mov [r10+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],rax
 EXPR_TOKEN_PTR r11,rbx
 mov rdi,r15
 mov esi,NEBOC_AST_INTERPOLATION_VALUE
 mov rdx,[r12+NEBOC_EXPR_SOURCE_ID_OFFSET]
 mov rcx,[r10+NEBOC_AST_NODE_START_OFFSET]
 mov r8,[r11+NEBOC_TOKEN_START_OFFSET]
 lea r9,[rsp+32]
 call neboc_ast_builder_append
 test eax,eax
 jnz expression_prefix_done
 mov rdi,r15
 mov rsi,[rsp+32]
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz expression_prefix_done
 mov r10,[rsp+24]
 mov rax,[rsp+40]
 mov [r10+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 cmp qword [rsp+48],0
 je .link
 inc qword [r10+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jmp .link
.next_literal:
 inc rbx
 cmp rbx,r14
 jae expression_prefix_expected
 EXPR_TOKEN_PTR r11,rbx
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTERPOLATION_MIDDLE
 je .literal
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTERPOLATION_TAIL
 je .literal
 jmp expression_prefix_expected
.finished:
 mov rax,[rsp+56]
 mov [r10+NEBOC_AST_NODE_END_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+NEBOC_EXPR_RESULT_NODE_OFFSET],rax
 inc rbx
 mov [r12+NEBOC_EXPR_INDEX_OFFSET],rbx
 xor eax,eax
 jmp expression_prefix_done
