; Typed linear operators share the ordinary expression tree and native G134
; kernels. They consume their two children, never a complete source program.
section .text
; state, expression -> op RAX, result type RCX, extents R8/R9 (zero: dynamic).
fcg_linear_vector_info:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,40
 mov rbx,rdi
 mov r12,rsi
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 jne .no
 mov r13,rax
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r14d,1
 cmp rdx,NEBOC_TOKEN_LINEAR_DOT
 je .operands
 inc r14d
 cmp rdx,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .operands
 inc r14d
 cmp rdx,NEBOC_TOKEN_LINEAR_HADAMARD
 je .operands
 inc r14d
 cmp rdx,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 je .operands
 inc r14d
 cmp rdx,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 je .operands
 inc r14d
 cmp rdx,NEBOC_TOKEN_LINEAR_PARALLEL
 jne .no
.operands:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_probe_receiver_type
 mov rdi,rax
 call fcg_vector_type_decode
 test rax,rax
 jnz .left_type
 cmp r14d,2
 je .no                         ; Array Cartesian product belongs to Set.
 jmp .bad
.left_type:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov [rsp],rdx
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov [rsp+8],rdx
 cmp r14d,4
 je .tensor
 test rdx,rdx
 jz .shape_ready
 cmp qword [rsp],0
 je .shape_ready
 cmp rdx,[rsp]
 jne .bad
.shape_ready:
 cmp r14d,2
 je .three
 cmp r14d,6
 jne .result
.three:
 cmp qword [rsp],0
 je .right_three
 cmp qword [rsp],3
 jne .bad
.right_three:
 test rdx,rdx
 jz .result
 cmp rdx,3
 jne .bad
.result:
 mov ecx,NEBOC_TYPE_ID_INT
 cmp r14d,1
 je .yes
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp r14d,5
 jae .yes
 mov rcx,[rsp]
 add rcx,FCG_TYPE_VECTOR_INT_BASE
 jmp .yes
.tensor:
 mov rcx,[rsp]
 imul rcx,rdx
 cmp rcx,64
 ja .bounds
 add rcx,FCG_TYPE_VECTOR_INT_BASE
.yes:
 mov rax,r14
 mov r8,[rsp]
 mov r9,[rsp+8]
 jmp .done
.bounds:
 mov edx,2
 jmp .error
.bad:
 mov edx,1
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,40
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_linear_vector_emit:
 push rbx
 push r12
 push r13
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_linear_vector_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rcx
 mov [rsp+16],r8
 mov [rsp+24],r9
 NV_APPEND lv_extern
 NV_APPEND ftm_frame_head
 NV_NUMBER 592
 NV_APPEND ftm_frame_tail
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+32],rsi
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_save_receiver
 mov rdi,rbx
 mov rsi,[rsp+32]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_save_argument
 NV_APPEND lv_op
 NV_NUMBER [rsp]
 NV_APPEND lv_left_count
 NV_NUMBER [rsp+16]
 NV_APPEND lv_right_count
 NV_NUMBER [rsp+24]
 NV_APPEND lv_call
 cmp qword [rsp+8],FCG_TYPE_VECTOR_INT_BASE
 je .descriptor
 cmp qword [rsp+8],FCG_TYPE_VECTOR_INT_BASE
 ja .lanes
 NV_APPEND lv_scalar
 jmp .done
.descriptor:
 NV_APPEND lv_descriptor
 jmp .done
.lanes:
 NV_APPEND lv_lanes
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
lv_extern: db '%ifndef NEBO_LINEAR_VECTOR_EXTERN',10,'%define NEBO_LINEAR_VECTOR_EXTERN 1',10,'extern nebo_vector_linear_call',10,'%endif',10
lv_extern_len equ $-lv_extern
lv_op: db '    mov edi, '
lv_op_len equ $-lv_op
lv_left_count: db 10,'    mov ecx, '
lv_left_count_len equ $-lv_left_count
lv_right_count: db 10,'    mov r8d, '
lv_right_count_len equ $-lv_right_count
lv_call:
 db 10,'    mov rsi, [r12]',10,'    mov rdx, [r12+8]',10,'    mov r9, r12',10
 db '    call nebo_vector_linear_call',10,'    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10
lv_call_len equ $-lv_call
lv_scalar: db '    mov rax, [r12+48]',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
lv_scalar_len equ $-lv_scalar
lv_descriptor: db '    lea rax, [r12+32]',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
lv_descriptor_len equ $-lv_descriptor
lv_lanes: db '    lea rax, [r12+64]',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
lv_lanes_len equ $-lv_lanes
section .text
