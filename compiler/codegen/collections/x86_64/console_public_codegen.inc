; Material Console handles share the ordinary Program statement owner.
; Native lifecycle/document operations consume every operand exactly once.
section .text
%macro CP_MATCH 3
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro
fcg_console_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_CONSOLE_HANDLE
 jne .no
 CP_MATCH cp_title,5,.title
 CP_MATCH cp_clear,5,.clear
 CP_MATCH cp_append,6,.append
 CP_MATCH cp_style,5,.style
 CP_MATCH cp_scroll,11,.scroll
 CP_MATCH cp_size,4,.size
 CP_MATCH cp_close,5,.close
 jmp .no
.style:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_console_range_info
 test eax,eax
 jz .bad
 mov r14,rax
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_CONSOLE_OPTION
 jne .bad
 jmp .yes
.title:
 mov r14d,1
 mov r15d,NEBOC_TYPE_ID_TEXT
 jmp .one
.clear:
 mov r14d,2
 jmp .zero
.append:
 mov r14d,3
 xor r15d,r15d
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .one
 mov qword [rsp],16
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_CONSOLE_OPTION
 jne .bad
 jmp .first
.scroll:
 mov r14d,6
 jmp .zero
.size:
 mov r14d,7
 jmp .zero
.close:
 mov r14d,8
.zero:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 jmp .yes
.one:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
.first:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 test r15,r15
 jz .append_type
 cmp rax,r15
 jne .bad
 jmp .yes
.append_type:
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .yes
 inc r14
 cmp rax,NEBOC_TYPE_ID_INT
 je .yes
 inc r14
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .bad
.yes:
 mov rax,r14
 add rax,[rsp]
 mov ecx,NEBOC_TYPE_ID_VOID
 cmp eax,7
 jne .done
 mov ecx,FCG_TYPE_VECTOR_INT_BASE+2
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

%macro CP_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
fcg_console_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_console_public_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 CP_APPEND cp_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,64
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
 CP_APPEND cp_save_receiver
 cmp qword [rsp],9
 je .emit_style_range
 cmp qword [rsp],10
 je .emit_style_range
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .invoke
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_save_argument
 cmp qword [rsp],16
 jb .invoke
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_save_style
 jmp .invoke
.emit_style_range:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rsi
 mov rdi,rbx
 call fcg_console_range_info
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov rdi,rbx
 mov rsi,rdx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_save_argument
 mov rdi,rbx
 mov rsi,[rsp+24]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_save_style
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_save_range_role
.invoke:
 CP_APPEND cp_op
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND cp_call
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
cp_title: db 'title'
cp_clear: db 'clear'
cp_append: db 'append'
cp_scroll: db 'scrollToEnd'
cp_size: db 'size'
cp_close: db 'close'
cp_extern: db '%ifndef NEBO_PUBLIC_CONSOLE_DECLARED',10,'%define NEBO_PUBLIC_CONSOLE_DECLARED 1',10,'extern nebo_runtime_console_public_call',10,'%endif',10
cp_extern_len equ $-cp_extern
cp_save_receiver: db '    mov [r12], rax',10
cp_save_receiver_len equ $-cp_save_receiver
cp_save_argument: db '    mov [r12+8], rax',10
cp_save_argument_len equ $-cp_save_argument
cp_op: db '    mov edi, '
cp_op_len equ $-cp_op
cp_call: db 10,'    mov rsi, [r12]',10,'    mov rdx, [r12+8]',10,'    lea rcx, [r12+32]',10,'    mov r8, [r12+16]',10,'    mov r9, [r12+32]',10,'    call nebo_runtime_console_public_call',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
cp_call_len equ $-cp_call

cp_console_save_receiver:
 db '%ifndef NEBO_CONSOLE_OPTIONS_PUBLIC_DECLARED',10,'%define NEBO_CONSOLE_OPTIONS_PUBLIC_DECLARED 1',10
 db 'extern nebo_runtime_console_position_accumulate',10,'extern nebo_runtime_console_option_accumulate',10,'extern nebo_runtime_console_options_prepare',10,'%endif',10
 db '    lea r11, [rsp-64]',10,'    cmp r11, [rel nebo_runtime_owned_stack_floor]',10,'    jb nebo_runtime_trap_stack_budget',10
 db '    sub rsp, 64',10,'    mov [rsp+24], r12',10,'    mov r12, rsp',10,'    mov [r12], rax',10
 db '    mov qword [r12+8], 0',10,'    mov qword [r12+16], 0',10,'    mov qword [r12+32], 0',10
cp_console_save_receiver_len equ $-cp_console_save_receiver
cp_console_save_option: db '    mov rdi, r12',10,'    mov rsi, rax',10,'    call nebo_runtime_console_option_accumulate',10
cp_console_save_option_len equ $-cp_console_save_option
cp_console_prepare_receiver: db '    mov rdi, r12',10,'    call nebo_runtime_console_options_prepare',10,'    mov rax, [r12]',10
cp_console_prepare_receiver_len equ $-cp_console_prepare_receiver
cp_console_release: db '    mov rsp, r12',10,'    mov r12, [r12+24]',10,'    add rsp, 64',10
cp_console_release_len equ $-cp_console_release

cp_save_style: db '    mov [r12+16], rax',10
cp_save_style_len equ $-cp_save_style

cp_console_save_position: db '    mov rdi, r12',10,'    mov rsi, rax',10,'    call nebo_runtime_console_position_accumulate',10
cp_console_save_position_len equ $-cp_console_save_position

cp_style: db 'style'
cp_Range: db 'Range'
cp_range_inclusive: db 'inclusive'
cp_range_exclusive: db 'exclusive'
cp_save_range_role: db '    mov [r12+32], rax',10
cp_save_range_role_len equ $-cp_save_range_role
section .text
; Inline canonical Range.exclusive/inclusive(Int,Int) -> operation and node IDs.
; The bounded Console profile selects payload node ordinals, excluding root.
fcg_console_range_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,rax
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel cp_Range]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .no
 CP_MATCH cp_range_exclusive,9,.exclusive
 CP_MATCH cp_range_inclusive,9,.inclusive
 jmp .no
.exclusive:
 mov qword [rsp],9
 jmp .args
.inclusive:
 mov qword [rsp],10
.args:
 mov r14,[r14+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],r15
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 ; This parsed constructor is consumed inline by the typed style plan.
 ; It is not a receiver-first user function call in the ABI call inventory.
 or qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov rax,[rsp]
 mov rdx,[rsp+8]
 mov rcx,[rsp+16]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
cp_publish_table: db '%ifndef NEBO_PUBLIC_STRUCTURED_DECLARED',10,'%define NEBO_PUBLIC_STRUCTURED_DECLARED 1',10,'extern nebo_runtime_console_publish_structured',10,'%endif',10,'    mov rdi, rax',10,'    mov esi, 15',10,'    call nebo_runtime_console_publish_structured',10
cp_publish_table_len equ $-cp_publish_table
cp_publish_tree: db '%ifndef NEBO_PUBLIC_STRUCTURED_DECLARED',10,'%define NEBO_PUBLIC_STRUCTURED_DECLARED 1',10,'extern nebo_runtime_console_publish_structured',10,'%endif',10,'    mov rdi, rax',10,'    mov esi, 21',10,'    call nebo_runtime_console_publish_structured',10
cp_publish_tree_len equ $-cp_publish_tree
