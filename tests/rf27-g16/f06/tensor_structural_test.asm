bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_structural.inc"
section .data
shape22 dq 2,2
values_a dq 1.0,2.0,3.0,4.0
values_b dq 5.0,6.0,7.0,8.0
pads dq 1,1,1,1
zero dq 0.0
section .bss
align 8
a resb NEBO_TENSOR_SIZE
b resb NEBO_TENSOR_SIZE
result resb NEBO_TENSOR_SIZE
left_view resb NEBO_TENSOR_SIZE
right_view resb NEBO_TENSOR_SIZE
a_data resq 4
b_data resq 4
result_data resq 32
section .text
global _start
_start:
 push qword 1
 lea rdi,[a]
 lea rsi,[a_data]
 mov edx,2
 lea rcx,[shape22]
 lea r8,[values_a]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail1
 push qword 2
 lea rdi,[b]
 lea rsi,[b_data]
 mov edx,2
 lea rcx,[shape22]
 lea r8,[values_b]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail2
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,3
 call nebo_tensor_concat0_f64
 test eax,eax
 jnz .fail3
 cmp qword [result+NEBO_TENSOR_SHAPE],4
 jne .fail4
 mov rax,[values_b+24]
 cmp [result_data+56],rax
 jne .fail5
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,4
 call nebo_tensor_stack0_f64
 test eax,eax
 jnz .fail6
 cmp qword [result+NEBO_TENSOR_RANK],3
 jne .fail7
 cmp qword [result+NEBO_TENSOR_SHAPE],2
 jne .fail8
 lea rdi,[left_view]
 lea rsi,[right_view]
 lea rdx,[a]
 mov ecx,1
 call nebo_tensor_split0_view
 test eax,eax
 jnz .fail9
 cmp qword [left_view+NEBO_TENSOR_SHAPE],1
 jne .fail10
 cmp qword [right_view+NEBO_TENSOR_SHAPE],1
 jne .fail11
 movsd xmm0,[zero]
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[a]
 lea rcx,[pads]
 mov r8d,5
 call nebo_tensor_pad2d_f64
 test eax,eax
 jnz .fail12
 cmp qword [result+NEBO_TENSOR_SHAPE],4
 jne .fail13
 mov rax,[values_a]
 cmp [result_data+40],rax
 jne .fail14
 mov rax,[values_a+24]
 cmp [result_data+80],rax
 jne .fail15
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,6
 call nebo_tensor_matmul2d_f64
 test eax,eax
 jnz .fail16
 mov rax,__float64__(19.0)
 cmp [result_data],rax
 jne .fail17
 mov rax,__float64__(50.0)
 cmp [result_data+24],rax
 jne .fail18
 call nebo_tensor_einsum_reject
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail19
 xor edi,edi
 jmp .exit
%assign i 1
%rep 19
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
