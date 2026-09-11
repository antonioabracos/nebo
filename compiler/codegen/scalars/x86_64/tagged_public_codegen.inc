; Composed tagged values retain typed constructor nodes and lexical operands.
; No statement, branch or explicit process return is evaluated by this owner.
section .text
; RDI TypeId -> EAX recognized, RCX payload TypeId, RDX payload kind.
fcg_tagged_decode:
 mov rdx,rdi
 sub rdx,FCG_TAGGED_OPTION_BASE
 cmp rdx,16
 jb .index
 sub rdx,16
.index:
 cmp rdx,1
 jb .no
 cmp rdx,8
 ja .no
 lea rcx,[rel tg_payload_types]
 mov rcx,[rcx+rdx*8]
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; State, type node -> exact supported payload TypeId and kind in RDX.
fcg_tagged_payload_type:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,rax
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .collection
 mov edx,1
 cmp rax,NEBOC_TYPE_ID_INT
 je .done
 inc edx
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .done
 inc edx
 cmp rax,NEBOC_TYPE_ID_CHAR
 je .done
 inc edx
 cmp rax,NEBOC_TYPE_ID_FLOAT
 je .done
 inc edx
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .done
 jmp .no
.collection:
 test qword [r12+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .no
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_dict]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jnz .dict
 cmp qword [r12+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_list]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .set
 mov eax,FCG_TYPE_NATIVE_LIST_INT
 mov edx,6
 jmp .done
.set:
 mov rdi,rbx
 mov rsi,[r12+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_set]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov eax,FCG_TYPE_HASH_SET_INT
 mov edx,8
 jmp .done
.dict:
 cmp qword [r12+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 mov eax,FCG_TYPE_DICT_INT_INT
 mov edx,7
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; EAX operation, RCX result type, RDX tagged type, R8 evaluated node.
fcg_tagged_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
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
 CP_MATCH tg_Option,6,.option
 CP_MATCH tg_Result,6,.result
 jmp .method
.option:
 mov qword [rsp],FCG_TAGGED_OPTION_BASE
 jmp .constructor
.result:
 mov qword [rsp],FCG_TAGGED_RESULT_BASE
.constructor:
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 mov ecx,1
 cmp qword [rsp],FCG_TAGGED_RESULT_BASE
 jne .type_count
 inc ecx
.type_count:
 cmp [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rcx
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_tagged_payload_type
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 add [rsp],rdx
 cmp qword [rsp],FCG_TAGGED_RESULT_BASE
 jb .variant
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call fcg_tagged_payload_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
.variant:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .bad
 mov r15,rax
 mov qword [rsp+24],1
 lea rdx,[rel tg_Some]
 cmp qword [rsp],FCG_TAGGED_RESULT_BASE
 jb .match_variant
 mov qword [rsp+24],3
 lea rdx,[rel tg_Ok]
.match_variant:
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov ecx,4
 cmp qword [rsp+24],1
 je .match_length
 mov ecx,2
.match_length:
 call fcg_token_matches_literal
 test eax,eax
 jnz .payload
 inc qword [rsp+24]
 lea rdx,[rel tg_None]
 mov ecx,4
 cmp qword [rsp+24],2
 je .alternate
 lea rdx,[rel tg_Err]
 mov ecx,3
.alternate:
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_token_matches_literal
 test eax,eax
 jz .bad
 cmp qword [rsp+24],2
 jne .error_payload
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],0
 jne .bad
 xor r8d,r8d
 jmp .constructor_yes
.error_payload:
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
.payload:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+16]
 jne .bad
 mov r8,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.constructor_yes:
 mov rax,[rsp+24]
 mov rcx,[rsp]
 mov rdx,rcx
 jmp .done
.method:
 mov qword [rsp+24],5
 CP_MATCH tg_isSome,6,.receiver
 CP_MATCH tg_isOk,4,.receiver
 mov qword [rsp+24],6
 CP_MATCH tg_isNone,6,.receiver
 CP_MATCH tg_isErr,5,.receiver
 mov qword [rsp+24],7
 CP_MATCH ac_get,3,.receiver
 CP_MATCH ac_expect,6,.receiver
 mov qword [rsp+24],8
 CP_MATCH tg_getErr,6,.receiver
 CP_MATCH tg_expectErr,9,.receiver
 mov qword [rsp+24],9
 CP_MATCH ac_unwrap_or,8,.receiver
 jmp .no
.receiver:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_probe_receiver_type
 mov [rsp],rax
 mov rdi,rax
 call fcg_tagged_decode
 test eax,eax
 jz .no
 mov [rsp+16],rcx
 ; Family-specific tag predicates are not interchangeable aliases.
 mov r14,[rsp]
 cmp r14,FCG_TAGGED_RESULT_BASE
 jb .option_method
 CP_MATCH tg_isSome,6,.bad
 CP_MATCH tg_isNone,6,.bad
 jmp .arity
.option_method:
 CP_MATCH tg_isOk,4,.bad
 CP_MATCH tg_isErr,5,.bad
 cmp qword [rsp+24],8
 je .bad
.arity:
 mov r14,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp qword [rsp+24],9
 je .fallback
 cmp qword [rsp+24],7
 jb .no_extra
 CP_MATCH ac_expect,6,.message
 CP_MATCH tg_expectErr,9,.message
.no_extra:
 cmp r14,1
 jne .bad
 jmp .method_yes
.message:
 mov qword [rsp+32],NEBOC_TYPE_ID_TEXT
 jmp .one_argument
.fallback:
 mov rax,[rsp+16]
 mov [rsp+32],rax
.one_argument:
 cmp r14,2
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
.method_yes:
 mov rax,[rsp+24]
 mov rcx,[rsp+16]
 cmp eax,6
 ja .not_predicate
 mov ecx,NEBOC_TYPE_ID_BOOL
.not_predicate:
 cmp eax,8
 jne .typed_method
 mov ecx,NEBOC_TYPE_ID_INT
.typed_method:
 mov rdx,[rsp]
 mov r8,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
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
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_tagged_public_emit:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,40
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_tagged_public_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov r14,r8
 CP_APPEND tg_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,4352
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 test r14,r14
 jz .empty
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .value
.empty:
 CP_APPEND ac_zero
.value:
 CP_APPEND tg_save
 cmp qword [rsp],5
 jb .arguments_ready
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .arguments_ready
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND tg_fallback
.arguments_ready:
 CP_APPEND tg_operation
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND tg_type
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND tg_call
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,40
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
tg_Option: db 'Option'
tg_Result: db 'Result'
tg_Some: db 'Some'
tg_None: db 'None'
tg_Ok: db 'Ok'
tg_Err: db 'Err'
tg_isSome: db 'isSome'
tg_isNone: db 'isNone'
tg_isOk: db 'isOk'
tg_isErr: db 'isErr'
tg_getErr: db 'getErr'
tg_expectErr: db 'expectErr'
align 8
tg_payload_types:
 dq 0,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_CHAR,NEBOC_TYPE_ID_FLOAT,NEBOC_TYPE_ID_TEXT
 dq FCG_TYPE_NATIVE_LIST_INT,FCG_TYPE_DICT_INT_INT,FCG_TYPE_HASH_SET_INT
tg_extern: db '%ifndef NEBO_TAGGED_PUBLIC_EXTERN',10,'%define NEBO_TAGGED_PUBLIC_EXTERN 1',10,'extern nebo_tagged_public',10,'%endif',10
tg_extern_len equ $-tg_extern
tg_save: db '    mov [r12], rax',10,'    mov qword [r12+8], 0',10
tg_save_len equ $-tg_save
tg_fallback: db '    mov [r12+8], rax',10
tg_fallback_len equ $-tg_fallback
tg_operation: db '    mov edi, '
tg_operation_len equ $-tg_operation
tg_type: db 10,'    mov edx, '
tg_type_len equ $-tg_type
tg_call: db 10,'    mov rsi, [r12]',10,'    mov rcx, [r12+8]',10,'    lea r8, [r12+64]',10,'    call nebo_tagged_public',10,'    movq xmm0, rax',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
tg_call_len equ $-tg_call
section .text
