bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_ops.inc"
section .data
shape_a dq 2,3
shape_b dq 1,3
a_values dq 1.0,2.0,3.0,4.0,5.0,6.0
b_values dq 10.0,20.0,30.0
low dq 15.0
high dq 32.0
section .bss
align 8
a resb NEBO_TENSOR_SIZE
b resb NEBO_TENSOR_SIZE
bv resb NEBO_TENSOR_SIZE
result_desc resb NEBO_TENSOR_SIZE
ad resq 6
bd resq 3
od resq 6
section .text
global _start
_start:
 push qword 1
 lea rdi,[a]
 lea rsi,[ad]
 mov edx,2
 lea rcx,[shape_a]
 lea r8,[a_values]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail1
 push qword 2
 lea rdi,[b]
 lea rsi,[bd]
 mov edx,2
 lea rcx,[shape_b]
 lea r8,[b_values]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail2
 lea rdi,[bv]
 lea rsi,[b]
 lea rdx,[shape_a]
 call nebo_tensor_broadcast_view
 test eax,eax
 jnz .fail3
 cmp qword [bv+NEBO_TENSOR_STRIDES],0
 jne .fail4
 lea rdi,[result_desc]
 lea rsi,[od]
 lea rdx,[a]
 lea rcx,[bv]
 mov r8d,NEBO_TENSOR_OP_ADD
 mov r9d,3
 call nebo_tensor_binary_f64
 test eax,eax
 jnz .fail5
 mov rax,__float64__(11.0)
 cmp [od],rax
 jne .fail6
 mov rax,__float64__(36.0)
 cmp [od+40],rax
 jne .fail7
 movsd xmm0,[low]
 movsd xmm1,[high]
 lea rdi,[result_desc]
 call nebo_tensor_clamp_f64
 test eax,eax
 jnz .fail8
 mov rax,[low]
 cmp [od],rax
 jne .fail9
 mov rax,[high]
 cmp [od+40],rax
 jne .fail10
 xor edi,edi
 jmp .exit
%assign i 1
%rep 10
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
