; Typed bounded Regex compile/match/escape. Each call validates actual Text
; operands and reaches the canonical bounded native pattern owner.
section .text
fcg_regex_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 CP_MATCH rx_name_0,7,.method_0
 CP_MATCH rx_name_1,7,.method_1
 CP_MATCH rx_name_2,6,.method_2
 jmp .no
.method_0:
 lea r14,[rel rx_plan_0]
 jmp .receiver
.method_1:
 lea r14,[rel rx_plan_1]
 jmp .receiver
.method_2:
 lea r14,[rel rx_plan_2]
 jmp .receiver
.receiver:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r14+24],0
 je .instance
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .no
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r14+24]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov r15,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .shape
.instance:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_REGEX
 jne .no
 mov r15,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.shape:
 mov rax,[r14+8]
 cmp qword [r14+24],0
 je .count
 inc rax
.count:
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 mov qword [rsp],0
.arguments:
 mov rax,[rsp]
 cmp rax,[r14+8]
 jae .yes
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[r14+32+rax*8]
 mov [rsp+8],rdx
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+8]
 jne .bad
 jmp .next
.next:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp]
 jmp .arguments
.yes:
 mov rax,[r14]
 mov rcx,[r14+16]
 mov rdx,r14
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_regex_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_regex_public_info
 test eax,eax
 jz .bad
 mov r14,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 cmp qword [r14+24],0
 je .allocate
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.allocate:
 CP_APPEND rx_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,1024
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 mov qword [rsp],0
.arguments:
 mov rax,[rsp]
 cmp rax,[r14+8]
 jae .invoke
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[r14+32+rax*8]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .store
.store:
 CP_APPEND rx_store_head
 mov rsi,[rsp]
 cmp rsi,3
 jb .slot
 inc rsi
.slot:
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND rx_store_tail
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp]
 jmp .arguments
.invoke:
 CP_APPEND rx_operation
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND rx_invoke
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
rx_Regex: db 'Regex'
rx_name_0: db 'compile'
align 8
rx_plan_0: dq 1,1,FCG_TYPE_REGEX,rx_Regex,NEBOC_TYPE_ID_TEXT,0,0,0
rx_name_1: db 'isMatch'
align 8
rx_plan_1: dq 2,2,NEBOC_TYPE_ID_BOOL,0,FCG_TYPE_REGEX,NEBOC_TYPE_ID_TEXT,0,0
rx_name_2: db 'escape'
align 8
rx_plan_2: dq 3,1,NEBOC_TYPE_ID_TEXT,rx_Regex,NEBOC_TYPE_ID_TEXT,0,0,0
rx_extern: db 37,105,102,110,100,101,102,32,78,69,66,79,95,82,69,71,69,88,95,80,85,66,76,73,67,95,69,88,84,69,82,78,10,37,100,101,102,105,110,101,32,78,69,66,79,95,82,69,71,69,88,95,80,85,66,76,73,67,95,69,88,84,69,82,78,32,49,10,101,120,116,101,114,110,32,110,101,98,111,95,114,117,110,116,105,109,101,95,114,101,103,101,120,95,112,117,98,108,105,99,10,37,101,110,100,105,102,10
rx_extern_len equ $-rx_extern
rx_load_constant: db 32,32,32,32,109,111,118,32,114,97,120,44,32
rx_load_constant_len equ $-rx_load_constant
rx_newline: db 10
rx_newline_len equ $-rx_newline
rx_store_head: db 32,32,32,32,109,111,118,32,91,114,49,50,43
rx_store_head_len equ $-rx_store_head
rx_store_tail: db 93,44,32,114,97,120,10
rx_store_tail_len equ $-rx_store_tail
rx_operation: db 32,32,32,32,109,111,118,32,101,100,105,44,32
rx_operation_len equ $-rx_operation
rx_invoke: db 10,32,32,32,32,109,111,118,32,114,115,105,44,32,114,49,50,10,32,32,32,32,99,97,108,108,32,110,101,98,111,95,114,117,110,116,105,109,101,95,114,101,103,101,120,95,112,117,98,108,105,99,10,32,32,32,32,109,111,118,32,114,115,112,44,32,114,49,50,10,32,32,32,32,109,111,118,32,114,49,50,44,32,91,114,49,50,43,50,52,93,10
rx_invoke_len equ $-rx_invoke
section .text
