bits 64
default rel
%define NEBO_BACKWARD_IMPLEMENTATION 1
%include "runtime/autograd/backward.inc"
section .rodata align=8
b_one dq 1.0
b_exp dq 0x7ff0000000000000
section .text
global nebo_loss_backward
global nebo_tensor_backward
global nebo_gradient_accumulate
global nebo_gradient_zero

; Graph64: nodes*,count,root,generation,workspace*,workspace_elements,reserved,flags.
; Node64: value*,gradient*,count,op,parentA,parentB,generation,workspace_offset.
backward_validate:
 test rdi,rdi
 jz .argument
 cmp qword [rdi+48],0
 jne .graph
 cmp qword [rdi+56],0
 jne .graph
 mov r8,[rdi+8]
 test r8,r8
 jz .limit
 cmp r8,NEBO_BACKWARD_MAX_NODES
 ja .limit
 cmp qword [rdi+16],r8
 jae .graph
 mov r9,[rdi+24]
 test r9,r9
 jz .generation
 mov r10,[rdi]
 test r10,r10
 jz .argument
 cmp qword [rdi+32],0
 je .argument
 mov r11,[rdi+40]
 test r11,r11
 jz .limit
 cmp r11,NEBO_BACKWARD_MAX_ELEMENTS
 ja .limit
 xor ecx,ecx
 xor edx,edx
.nodes:
 cmp rcx,r8
 jae .done
 cmp qword [r10],0
 je .argument
 cmp qword [r10+8],0
 je .argument
 mov rax,[r10+16]
 test rax,rax
 jz .shape
 cmp rax,NEBO_BACKWARD_MAX_ELEMENTS
 ja .limit
 cmp [r10+48],r9
 jne .generation
 cmp [r10+56],rdx
 jne .graph
 add rdx,rax
 jc .limit
 cmp rdx,r11
 ja .limit
 mov rax,[r10+24]
 cmp rax,NEBO_BACKWARD_OP_SUM
 ja .graph
 test rax,rax
 jz .leaf
 mov rsi,[r10+32]
 cmp rsi,rcx
 jae .graph
 cmp rax,NEBO_BACKWARD_OP_SUM
 je .sum
 mov rsi,[r10+40]
 cmp rsi,rcx
 jae .graph
 mov rsi,[r10+32]
 imul rsi,NEBO_BACKWARD_NODE_SIZE
 add rsi,[rdi]
 mov rax,[rsi+16]
 cmp rax,1
 je .binary_b
 cmp rax,[r10+16]
 jne .shape
.binary_b:
 mov rsi,[r10+40]
 imul rsi,NEBO_BACKWARD_NODE_SIZE
 add rsi,[rdi]
 mov rax,[rsi+16]
 cmp rax,1
 je .next
 cmp rax,[r10+16]
 jne .shape
 jmp .next
.sum:
 cmp qword [r10+16],1
 jne .shape
 cmp qword [r10+40],NEBO_BACKWARD_NO_PARENT
 jne .graph
 jmp .next
.leaf:
 cmp qword [r10+32],NEBO_BACKWARD_NO_PARENT
 jne .graph
 cmp qword [r10+40],NEBO_BACKWARD_NO_PARENT
 jne .graph
.next:
 ; All forward values are finite before any gradient is changed.
 xor esi,esi
.finite_values:
 cmp rsi,[r10+16]
 jae .node_next
 mov rax,[r10]
 mov rax,[rax+rsi*8]
 mov rbx,rax
 and rbx,[rel b_exp]
 cmp rbx,[rel b_exp]
 je .nonfinite
 inc rsi
 jmp .finite_values
.node_next:
 add r10,NEBO_BACKWARD_NODE_SIZE
 inc rcx
 jmp .nodes
.done:
 cmp rdx,r11
 ja .limit
 xor eax,eax
 ret
.argument: mov eax,NEBO_BACKWARD_E_ARGUMENT
 ret
.limit: mov eax,NEBO_BACKWARD_E_LIMIT
 ret
.shape: mov eax,NEBO_BACKWARD_E_SHAPE
 ret
.graph: mov eax,NEBO_BACKWARD_E_GRAPH
 ret
.generation: mov eax,NEBO_BACKWARD_E_GENERATION
 ret
.nonfinite: mov eax,NEBO_BACKWARD_E_NONFINITE
 ret

nebo_loss_backward:
 lea rsi,[rel b_one]
 mov edx,1
 jmp backward_core

; rdi=Graph64,rsi=seed F64*,rdx=seed elements.
nebo_tensor_backward:
 jmp backward_core

backward_core:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call backward_validate
 test eax,eax
 jnz .return
 test r13,r13
 jz .argument
 mov rax,[r12+16]
 imul rax,NEBO_BACKWARD_NODE_SIZE
 add rax,[r12]
 mov r15,rax
 cmp r14,[r15+16]
 jne .shape
 xor ecx,ecx
.seed_finite:
 cmp rcx,r14
 jae .clear_workspace
 mov rax,[r13+rcx*8]
 mov rdx,rax
 and rdx,[rel b_exp]
 cmp rdx,[rel b_exp]
 je .nonfinite
 inc rcx
 jmp .seed_finite
.clear_workspace:
 mov rdi,[r12+32]
 mov rcx,[r12+40]
 xor eax,eax
 rep stosq
 mov rdi,[r12+32]
 mov rax,[r15+56]
 lea rdi,[rdi+rax*8]
 mov rsi,r13
 mov rcx,r14
 rep movsq
 mov rbp,[r12+8]
.reverse:
 test rbp,rbp
 jz .verify
 dec rbp
 mov rbx,rbp
 imul rbx,NEBO_BACKWARD_NODE_SIZE
 add rbx,[r12]
 mov rax,[rbx+24]
 test rax,rax
 jz .reverse
 mov r15,[r12+32]
 mov rdx,[rbx+56]
 lea r15,[r15+rdx*8]
 mov r8,[rbx+32]
 imul r8,NEBO_BACKWARD_NODE_SIZE
 add r8,[r12]
 mov r9,[r12+32]
 mov rdx,[r8+56]
 lea r9,[r9+rdx*8]
 cmp rax,NEBO_BACKWARD_OP_SUM
 je .reverse_sum
 mov r10,[rbx+40]
 imul r10,NEBO_BACKWARD_NODE_SIZE
 add r10,[r12]
 mov r11,[r12+32]
 mov rdx,[r10+56]
 lea r11,[r11+rdx*8]
 xor ecx,ecx
.binary_loop:
 cmp rcx,[rbx+16]
 jae .reverse
 mov rdx,rcx
 cmp qword [r8+16],1
 jne .a_index
 xor edx,edx
.a_index:
 mov rsi,rcx
 cmp qword [r10+16],1
 jne .b_index
 xor esi,esi
.b_index:
 movsd xmm0,[r15+rcx*8]
 cmp qword [rbx+24],NEBO_BACKWARD_OP_ADD
 je .add_gradients
 mov rax,[r10]
 movsd xmm1,[rax+rsi*8]
 mulsd xmm1,xmm0
 addsd xmm1,[r9+rdx*8]
 movsd [r9+rdx*8],xmm1
 mov rax,[r8]
 mulsd xmm0,[rax+rdx*8]
 addsd xmm0,[r11+rsi*8]
 movsd [r11+rsi*8],xmm0
 jmp .binary_next
.add_gradients:
 movsd xmm1,[r9+rdx*8]
 addsd xmm1,xmm0
 movsd [r9+rdx*8],xmm1
 movsd xmm1,[r11+rsi*8]
 addsd xmm1,xmm0
 movsd [r11+rsi*8],xmm1
.binary_next:
 inc rcx
 jmp .binary_loop
.reverse_sum:
 movsd xmm0,[r15]
 xor ecx,ecx
.sum_loop:
 cmp rcx,[r8+16]
 jae .reverse
 movsd xmm1,[r9+rcx*8]
 addsd xmm1,xmm0
 movsd [r9+rcx*8],xmm1
 inc rcx
 jmp .sum_loop
.verify:
 mov rdi,[r12+32]
 xor ecx,ecx
.verify_loop:
 cmp rcx,[r12+40]
 jae .publish
 mov rax,[rdi+rcx*8]
 mov rdx,rax
 and rdx,[rel b_exp]
 cmp rdx,[rel b_exp]
 je .numeric_cleanup
 inc rcx
 jmp .verify_loop
.publish:
 xor ecx,ecx
 mov rbx,[r12]
.publish_nodes:
 cmp rcx,[r12+8]
 jae .success_cleanup
 mov rsi,[r12+32]
 mov rax,[rbx+56]
 lea rsi,[rsi+rax*8]
 mov rdi,[rbx+8]
 push rcx
 mov rcx,[rbx+16]
 rep movsq
 pop rcx
 add rbx,NEBO_BACKWARD_NODE_SIZE
 inc rcx
 jmp .publish_nodes
.success_cleanup:
 xor ebx,ebx
 jmp .cleanup
.numeric_cleanup:
 mov ebx,NEBO_BACKWARD_E_NONFINITE
.cleanup:
 mov rdi,[r12+32]
 mov rcx,[r12+40]
 xor eax,eax
 rep stosq
 mov eax,ebx
 jmp .return
.argument: mov eax,NEBO_BACKWARD_E_ARGUMENT
 jmp .return
.shape: mov eax,NEBO_BACKWARD_E_SHAPE
 jmp .return
.nonfinite: mov eax,NEBO_BACKWARD_E_NONFINITE
.return:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret

; rdi=dst,rsi=src,rdx=count. Two passes preserve dst on numeric failure.
nebo_gradient_accumulate:
 test rdi,rdi
 jz .acc_argument
 test rsi,rsi
 jz .acc_argument
 test rdx,rdx
 jz .acc_limit
 cmp rdx,NEBO_BACKWARD_MAX_ELEMENTS
 ja .acc_limit
 cmp rdi,rsi
 je .acc_overlap
 xor ecx,ecx
.acc_check:
 cmp rcx,rdx
 jae .acc_write
 movsd xmm0,[rdi+rcx*8]
 addsd xmm0,[rsi+rcx*8]
 movq rax,xmm0
 and rax,[rel b_exp]
 cmp rax,[rel b_exp]
 je .acc_nonfinite
 inc rcx
 jmp .acc_check
.acc_write:
 xor ecx,ecx
.acc_loop:
 cmp rcx,rdx
 jae .acc_ok
 movsd xmm0,[rdi+rcx*8]
 addsd xmm0,[rsi+rcx*8]
 movsd [rdi+rcx*8],xmm0
 inc rcx
 jmp .acc_loop
.acc_ok: xor eax,eax
 ret
.acc_argument: mov eax,NEBO_BACKWARD_E_ARGUMENT
 ret
.acc_limit: mov eax,NEBO_BACKWARD_E_LIMIT
 ret
.acc_nonfinite: mov eax,NEBO_BACKWARD_E_NONFINITE
 ret
.acc_overlap: mov eax,NEBO_BACKWARD_E_OVERLAP
 ret

nebo_gradient_zero:
 test rdi,rdi
 jz .zero_argument
 test rsi,rsi
 jz .zero_limit
 cmp rsi,NEBO_BACKWARD_MAX_ELEMENTS
 ja .zero_limit
 mov rcx,rsi
 xor eax,eax
 rep stosq
 xor eax,eax
 ret
.zero_argument: mov eax,NEBO_BACKWARD_E_ARGUMENT
 ret
.zero_limit: mov eax,NEBO_BACKWARD_E_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
