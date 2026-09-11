; Existential Vector extent from a typed Matrix operation. The private value
; is {lanes, count}; static Vector<T,N> keeps its existing raw-lane ABI. Both
; representations normalize to the same canonical numeric owners.
section .text
fcg_shaped_vector_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+40],rdx
 call fcg_vector_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+16],r8
 mov [rsp+48],rcx
 mov [rsp+56],r9
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+24],rsi
 mov rdi,rbx
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+32],rax
 NV_APPEND sv_extern
 NV_APPEND ftm_frame_head
 NV_NUMBER 2128
 NV_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,[rsp+24]
 mov rdx,[rsp+40]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp+16],0
 je .receiver_dynamic
 NV_APPEND sv_receiver_static
 NV_NUMBER [rsp+16]
 NV_APPEND fcg_newline
 jmp .receiver_done
.receiver_dynamic:
 NV_APPEND sv_receiver_dynamic
.receiver_done:
 NV_APPEND sv_zero_argument
 cmp qword [rsp],6
 jbe .argument
 cmp qword [rsp],13
 je .argument
 cmp qword [rsp],15
 jne .invoke
.argument:
 mov qword [rsp+64],-1
 cmp qword [rsp],4
 je .vector_argument
 cmp qword [rsp],6
 je .vector_argument
 cmp qword [rsp],15
 jne .emit_argument
.vector_argument:
 mov rdi,rbx
 mov rsi,[rsp+32]
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 test rax,rax
 jz .bad
 mov [rsp+64],rdx
.emit_argument:
 mov rdi,rbx
 mov rsi,[rsp+32]
 mov rdx,[rsp+40]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp+64],0
 je .argument_dynamic
 NV_APPEND sv_argument_static
 cmp qword [rsp+64],-1
 je .invoke
 NV_APPEND sv_argument_count
 NV_NUMBER [rsp+64]
 NV_APPEND fcg_newline
 jmp .invoke
.argument_dynamic:
 NV_APPEND sv_argument_dynamic
.invoke:
 NV_APPEND sv_policy
 NV_NUMBER [rsp+56]
 NV_APPEND sv_operation
 NV_NUMBER [rsp]
 NV_APPEND sv_dtype
 mov esi,1
 cmp qword [rsp+8],FCG_TYPE_VECTOR_FLOAT_BASE
 jb .dtype
 mov esi,2
.dtype:
 NV_NUMBER rsi
 NV_APPEND sv_call
 cmp qword [rsp+48],FCG_TYPE_VECTOR_INT_BASE
 je .dynamic_result
 cmp qword [rsp+48],FCG_TYPE_VECTOR_FLOAT_BASE
 jne .result
.dynamic_result:
 NV_APPEND sv_result_descriptor
.result:
 NV_APPEND sv_finish
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
sv_extern: db '%ifndef NEBO_SHAPED_VECTOR_DECLARED',10,'%define NEBO_SHAPED_VECTOR_DECLARED 1',10,'extern nebo_vector_public_dispatch',10,'%endif',10
sv_extern_len equ $-sv_extern
sv_receiver_static: db '    mov [r12], rax',10,'    mov qword [r12 + 48], '
sv_receiver_static_len equ $-sv_receiver_static
sv_receiver_dynamic: db '    mov rdx, [rax + 8]',10,'    mov [r12 + 48], rdx',10,'    mov rax, [rax]',10,'    mov [r12], rax',10
sv_receiver_dynamic_len equ $-sv_receiver_dynamic
sv_zero_argument: db '    mov qword [r12 + 8], 0',10,'    mov qword [r12 + 56], 0',10
sv_zero_argument_len equ $-sv_zero_argument
sv_argument_static: db '    mov [r12 + 8], rax',10
sv_argument_static_len equ $-sv_argument_static
sv_argument_count: db '    mov qword [r12 + 56], '
sv_argument_count_len equ $-sv_argument_count
sv_argument_dynamic: db '    mov rdx, [rax + 8]',10,'    mov [r12 + 56], rdx',10,'    mov rax, [rax]',10,'    mov [r12 + 8], rax',10
sv_argument_dynamic_len equ $-sv_argument_dynamic
sv_policy: db '    mov qword [r12 + 16], '
sv_policy_len equ $-sv_policy
sv_operation: db 10,'    mov edi, '
sv_operation_len equ $-sv_operation
sv_dtype: db 10,'    mov esi, '
sv_dtype_len equ $-sv_dtype
sv_call: db 10,'    mov rdx, r12',10,'    call nebo_vector_public_dispatch',10,'    cmp eax, 4',10,'    je nebo_runtime_trap_overflow',10,'    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
sv_call_len equ $-sv_call
sv_result_descriptor: db '    mov [r12 + 32], rdx',10,'    mov rax, [r12 + 48]',10,'    mov [r12 + 40], rax',10,'    lea rdx, [r12 + 32]',10
sv_result_descriptor_len equ $-sv_result_descriptor
sv_finish: db '    mov rax, rdx',10,'    movq xmm0, rax',10,'    mov r12, [r12 + 24]',10
sv_finish_len equ $-sv_finish
section .text
