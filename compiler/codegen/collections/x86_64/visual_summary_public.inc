; The existing pure bounded summary owner consumes an actual typed Int value.
section .text
fcg_visual_summary_info:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
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
 CP_MATCH vs_summarize,9,.receiver
 jmp .no
.receiver:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel vs_visual]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,1
 mov ecx,NEBOC_TYPE_ID_INT
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
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_visual_summary_emit:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND vs_call
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
vs_visual: db 'visual'
vs_summarize: db 'summarize'
vs_call: db '%ifndef NEBO_VISUAL_SUMMARY_EXTERN',10,'%define NEBO_VISUAL_SUMMARY_EXTERN 1',10,'extern nebo_runtime_visual_summary',10,'%endif',10,'    mov rdi, rax',10,'    call nebo_runtime_visual_summary',10
vs_call_len equ $-vs_call
section .text
