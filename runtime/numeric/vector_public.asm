; Runtime-shaped Vector ABI bridge. All numeric algorithms remain in the
; canonical Vector/statistics owners, shared with statically shaped values.
bits 64
default rel
%include "runtime/numeric/vector.inc"
extern nebo_vector_statistics_call
section .text
global nebo_vector_public_dispatch
; op RDI (3..15), dtype RSI (1 Int / 2 Float), ordered frame RDX:
; source lanes 0, argument bits/lanes 8, policy 16, parent 24,
; result descriptor 32, source count 48, other count 56,
; result lanes 64..575, statistics workspace 576..2111.
; Status EAX, material scalar bits or result lanes RDX.
nebo_vector_public_dispatch:
 cmp rdi,3
 jb .argument
 cmp rdi,15
 ja .argument
 cmp rsi,1
 jb .argument
 cmp rsi,2
 ja .argument
 test rdx,rdx
 jz .argument
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp ebx,4
 je .binary_shape
 cmp ebx,6
 je .binary_shape
 cmp ebx,15
 jne .dispatch
.binary_shape:
 mov rax,[r13+48]
 cmp rax,[r13+56]
 jne .shape
.dispatch:
 cmp ebx,9
 jae .statistics
 cmp ebx,3
 je .at
 cmp ebx,6
 je .dot
 cmp ebx,7
 je .norm
 lea rdi,[r13+64]
 mov rsi,[r13]
 mov rdx,[r13+8]
 mov rcx,[r13+48]
 cmp ebx,4
 je .add
 cmp ebx,5
 je .scale
 cmp r12d,2
 jne .contract
 mov rdx,rcx
 call nebo_vector_f64_normalize
 jmp .vector_result
.add:
 cmp r12d,2
 je .add_float
 call nebo_vector_i64_add
 jmp .vector_result
.add_float:
 call nebo_vector_f64_add
 jmp .vector_result
.scale:
 cmp r12d,2
 je .scale_float
 call nebo_vector_i64_scale
 jmp .vector_result
.scale_float:
 movq xmm0,rdx
 mov rdx,rcx
 call nebo_vector_f64_scale
.vector_result:
 lea rdx,[r13+64]
 jmp .done
.at:
 mov rdi,[r13]
 mov rsi,[r13+48]
 mov rdx,[r13+8]
 cmp r12d,2
 je .at_float
 call nebo_vector_i64_at
 jmp .done
.at_float:
 call nebo_vector_f64_at
 jmp .float_result
.dot:
 mov rdi,[r13]
 mov rsi,[r13+8]
 mov rdx,[r13+48]
 cmp r12d,2
 je .dot_float
 call nebo_vector_i64_dot
 jmp .done
.dot_float:
 call nebo_vector_f64_dot
 jmp .float_result
.norm:
 cmp r12d,2
 jne .contract
 mov rdi,[r13]
 mov rsi,[r13+48]
 call nebo_vector_f64_norm
 jmp .float_result
.statistics:
 mov rdi,rbx
 mov rsi,[r13]
 mov rdx,[r13+16]
 cmp ebx,15
 jne .statistics_policy
 mov rdx,[r13+8]
.statistics_policy:
 mov rcx,[r13+48]
 lea r8,[r12-1]
 lea r9,[r13+576]
 movq xmm0,[r13+8]
 call nebo_vector_statistics_call
 cmp ebx,9
 jne .float_result
 cmp r12d,1
 je .done
.float_result:
 movq rdx,xmm0
 jmp .done
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .done
.contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
