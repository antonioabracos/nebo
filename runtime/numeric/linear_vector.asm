; Typed Vector bridge to the canonical checked linear kernels. Caller owns
; every output; no global result, implicit publication, or process exit value.
bits 64
default rel
extern dot_i64_checked
extern cross3_i64_checked
extern hadamard_i64_checked
extern tensor_i64_checked
extern vectors_orthogonal_i64
extern vectors_parallel3_i64
section .text
global nebo_vector_linear_call
; op RDI, left RSI, right RDX, extents RCX/R8 (0: {lanes,count}), frame R9.
; Result frame: descriptor at 32, scalar at 48, private 64-lane span at 64.
; EAX status. Native arithmetic performs its own failure-atomic validation.
nebo_vector_linear_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov ebx,edi
 mov r12,r9
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 test r12,r12
 jz .shape
 test r13,r13
 jz .shape
 test r14,r14
 jz .shape
 test r15,r15
 jnz .left_ready
 mov r15,[r13+8]
 mov r13,[r13]
.left_ready:
 cmp qword [rsp],0
 jne .right_ready
 mov rax,[r14+8]
 mov [rsp],rax
 mov r14,[r14]
.right_ready:
 test r13,r13
 jz .shape
 test r14,r14
 jz .shape
 test r15,r15
 jz .shape
 cmp r15,64
 ja .shape
 mov rax,[rsp]
 test rax,rax
 jz .shape
 cmp rax,64
 ja .shape
 cmp ebx,4
 je .tensor
 cmp rax,r15
 jne .shape
 mov rdi,r13
 mov rsi,r14
 mov rdx,r15
 lea rcx,[r12+48]
 mov qword [r12+48],0
 cmp ebx,1
 je .dot
 cmp ebx,2
 je .cross
 cmp ebx,3
 je .hadamard
 cmp ebx,5
 je .orthogonal
 cmp ebx,6
 jne .shape
 cmp r15,3
 jne .shape
 lea rdx,[r12+48]
 call vectors_parallel3_i64
 jmp .done
.orthogonal:
 call vectors_orthogonal_i64
 jmp .done
.dot:
 call dot_i64_checked
 jmp .done
.cross:
 cmp r15,3
 jne .shape
 lea rdx,[r12+64]
 call cross3_i64_checked
 jmp .vector
.hadamard:
 lea rcx,[r12+64]
 call hadamard_i64_checked
 jmp .vector
.tensor:
 mov rdi,r13
 mov rsi,r15
 mov rdx,r14
 mov rcx,[rsp]
 lea r8,[r12+64]
 mov r9d,64
 call tensor_i64_checked
 test rax,rax
 js .done
 mov r15,rax
 xor eax,eax
.vector:
 test eax,eax
 jnz .done
 lea rdx,[r12+64]
 mov [r12+32],rdx
 mov [r12+40],r15
 jmp .done
.shape:
 mov eax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
