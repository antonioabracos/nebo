; Typed Path and capability-bounded File convenience operations. A plan owns
; one call, validates every argument, and invokes the canonical native owners.
section .text
fcg_filesystem_public_info:
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
 CP_MATCH fs_name_0,5,.method_0
 CP_MATCH fs_name_1,10,.method_1
 CP_MATCH fs_name_2,8,.method_2
 CP_MATCH fs_name_3,9,.method_3
 CP_MATCH fs_name_4,4,.method_4
 CP_MATCH fs_name_5,8,.method_5
 CP_MATCH fs_name_6,9,.method_6
 jmp .no
.method_0:
 lea r14,[rel fs_plan_0]
 jmp .receiver
.method_1:
 lea r14,[rel fs_plan_1]
 jmp .receiver
.method_2:
 lea r14,[rel fs_plan_2]
 jmp .receiver
.method_3:
 lea r14,[rel fs_plan_3]
 jmp .receiver
.method_4:
 lea r14,[rel fs_plan_4]
 jmp .receiver
.method_5:
 lea r14,[rel fs_plan_5]
 jmp .receiver
.method_6:
 lea r14,[rel fs_plan_6]
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
 mov ecx,4
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
 cmp rax,FCG_TYPE_PATH
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
 cmp rdx,65533
 jae .context
 mov [rsp+8],rdx
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+8]
 jne .bad
 jmp .next
.context:
 call fcg_filesystem_context_value
 test eax,eax
 jz .bad
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

; Contextual spelling from the existing File contract, not a runtime variable.
; Return native policy + 1; a prior lexical binding shadows this context.
fcg_filesystem_context_value:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rdx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .no
 cmp r12,65533
 jne .modes
 mov rdi,rbx
 mov rsi,r13
 lea rdx,[rel fs_utf8]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov eax,2
 jmp .done
.modes:
 lea r14,[rel fs_mode_table]
.loop:
 cmp qword [r14],0
 je .no
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[r14]
 mov rcx,[r14+8]
 call fcg_token_matches_literal
 test eax,eax
 jnz .found
 add r14,24
 jmp .loop
.found:
 mov rax,[r14+16]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_filesystem_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_filesystem_public_info
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
 CP_APPEND fs_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,4384
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
 cmp rdx,65533
 jae .context
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .store
.context:
 call fcg_filesystem_context_value
 test eax,eax
 jz .bad
 dec rax
 mov [rsp+8],rax
 CP_APPEND fs_load_constant
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND fs_newline
.store:
 CP_APPEND fs_store_head
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
 CP_APPEND fs_store_tail
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp]
 jmp .arguments
.invoke:
 CP_APPEND fs_operation
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND fs_invoke
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
fs_Path: db 'Path'
fs_File: db 'File'
fs_utf8: db 'utf8'
fs_truncate: db 'truncate'
fs_append: db 'append'
fs_atomic: db 'atomic'
fs_mode_table: dq fs_truncate,8,1,fs_append,6,2,fs_atomic,6,3,0,0,0
fs_name_0: db 'parse'
align 8
fs_plan_0: dq 1,1,FCG_TYPE_PATH,fs_Path,NEBOC_TYPE_ID_TEXT,0,0,0
fs_name_1: db 'isAbsolute'
align 8
fs_plan_1: dq 2,1,NEBOC_TYPE_ID_BOOL,0,FCG_TYPE_PATH,0,0,0
fs_name_2: db 'fileName'
align 8
fs_plan_2: dq 3,1,NEBOC_TYPE_ID_TEXT,0,FCG_TYPE_PATH,0,0,0
fs_name_3: db 'normalize'
align 8
fs_plan_3: dq 4,1,FCG_TYPE_PATH,0,FCG_TYPE_PATH,0,0,0
fs_name_4: db 'join'
align 8
fs_plan_4: dq 5,2,FCG_TYPE_PATH,0,FCG_TYPE_PATH,FCG_TYPE_PATH,0,0
fs_name_5: db 'readText'
align 8
fs_plan_5: dq 10,3,NEBOC_TYPE_ID_TEXT,fs_File,FCG_TYPE_PATH,65533,NEBOC_TYPE_ID_INT,0
fs_name_6: db 'writeText'
align 8
fs_plan_6: dq 11,4,NEBOC_TYPE_ID_INT,fs_File,FCG_TYPE_PATH,NEBOC_TYPE_ID_TEXT,65533,65534
fs_extern: db 37,105,102,110,100,101,102,32,78,69,66,79,95,70,83,95,80,85,66,76,73,67,95,69,88,84,69,82,78,10,37,100,101,102,105,110,101,32,78,69,66,79,95,70,83,95,80,85,66,76,73,67,95,69,88,84,69,82,78,32,49,10,101,120,116,101,114,110,32,110,101,98,111,95,114,117,110,116,105,109,101,95,102,105,108,101,115,121,115,116,101,109,95,112,117,98,108,105,99,10,37,101,110,100,105,102,10
fs_extern_len equ $-fs_extern
fs_load_constant: db 32,32,32,32,109,111,118,32,114,97,120,44,32
fs_load_constant_len equ $-fs_load_constant
fs_newline: db 10
fs_newline_len equ $-fs_newline
fs_store_head: db 32,32,32,32,109,111,118,32,91,114,49,50,43
fs_store_head_len equ $-fs_store_head
fs_store_tail: db 93,44,32,114,97,120,10
fs_store_tail_len equ $-fs_store_tail
fs_operation: db 32,32,32,32,109,111,118,32,101,100,105,44,32
fs_operation_len equ $-fs_operation
fs_invoke: db 10,32,32,32,32,109,111,118,32,114,115,105,44,32,114,49,50,10,32,32,32,32,99,97,108,108,32,110,101,98,111,95,114,117,110,116,105,109,101,95,102,105,108,101,115,121,115,116,101,109,95,112,117,98,108,105,99,10,32,32,32,32,109,111,118,32,114,115,112,44,32,114,49,50,10,32,32,32,32,109,111,118,32,114,49,50,44,32,91,114,49,50,43,50,52,93,10
fs_invoke_len equ $-fs_invoke
section .text
