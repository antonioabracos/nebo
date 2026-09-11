; Source-visible RenderPlan and contextual render targets share the typed
; Program owner; the existing native Slash parser/renderer owns directives.
section .text
fcg_slash_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
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
 CP_MATCH slp_RenderPlan,10,.constructor
 CP_MATCH slp_render,6,.render
 jmp .no
.constructor:
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .bad
 mov eax,1
 mov ecx,FCG_TYPE_RENDER_PLAN
 xor edx,edx
 jmp .done
.render:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_RENDER_PLAN
 jne .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_CONTEXTUAL_OPTION
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],0
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea r15,[rel slp_targets]
.target:
 cmp qword [r15],0
 je .bad
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 call fcg_token_matches_literal
 test eax,eax
 jnz .target_found
 add r15,24
 jmp .target
.target_found:
 mov rdx,[r15+16]
 mov eax,2
 mov ecx,NEBOC_TYPE_ID_TEXT
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
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_slash_public_emit:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_slash_public_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 CP_APPEND slp_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,16640
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND slp_op
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND slp_target
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND slp_call
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
slp_RenderPlan: db 'RenderPlan'
slp_render: db 'render'
slp_plain: db 'plain'
slp_ansi: db 'ansi'
slp_markdown: db 'markdown'
slp_html: db 'html'
slp_console: db 'console'
align 8
slp_targets: dq slp_plain,5,1,slp_ansi,4,2,slp_markdown,8,3,slp_html,4,4,slp_console,7,5,0,0,0
slp_extern: db '%ifndef NEBO_SLASH_PUBLIC_EXTERN',10,'%define NEBO_SLASH_PUBLIC_EXTERN 1',10,'extern nebo_runtime_slash_public',10,'%endif',10
slp_extern_len equ $-slp_extern
slp_op: db '    mov edi, '
slp_op_len equ $-slp_op
slp_target: db 10,'    mov ecx, '
slp_target_len equ $-slp_target
slp_call: db 10,'    mov rsi, rax',10,'    mov rdx, r12',10,'    call nebo_runtime_slash_public',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
slp_call_len equ $-slp_call
section .text
