bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
%include "runtime/tensor/tensor_views.inc"
section .data
shape dq 2,3
reshape dq 3,2
axes dq 1,0
coord dq 1,2
values dq 1.0,2.0,3.0,4.0,5.0,6.0
seven dq 7.0
section .bss
align 8
owner resb NEBO_TENSOR_SIZE
view resb NEBO_TENSOR_SIZE
owned2 resb NEBO_TENSOR_SIZE
data resq 6
copy resq 6
section .text
global _start
_start:
 push qword 11
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,2
 lea rcx,[shape]
 lea r8,[values]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 lea rsi,[coord]
 call nebo_tensor_at_f64
 test eax,eax
 jnz .fail2
 movq rax,xmm0
 cmp rax,[values+40]
 jne .fail3
 movsd xmm0,[seven]
 lea rdi,[owner]
 lea rsi,[coord]
 call nebo_tensor_set_f64
 test eax,eax
 jnz .fail4
 mov rax,[seven]
 cmp [data+40],rax
 jne .fail5
 lea rdi,[view]
 lea rsi,[owner]
 xor edx,edx
 mov ecx,1
 mov r8d,1
 call nebo_tensor_narrow_view
 test eax,eax
 jnz .fail6
 cmp qword [view+NEBO_TENSOR_SHAPE],1
 jne .fail7
 lea rdi,[view]
 lea rsi,[owner]
 lea rdx,[axes]
 call nebo_tensor_permute_view
 test eax,eax
 jnz .fail8
 cmp qword [view+NEBO_TENSOR_SHAPE],3
 jne .fail9
 cmp qword [view+NEBO_TENSOR_STRIDES],1
 jne .fail10
 lea rdi,[owned2]
 lea rsi,[copy]
 lea rdx,[view]
 mov ecx,12
 call nebo_tensor_contiguous_f64
 test eax,eax
 jnz .fail11
 mov rax,[data+24]
 cmp [copy+8],rax
 jne .fail12
 lea rdi,[view]
 lea rsi,[owner]
 mov edx,2
 lea rcx,[reshape]
 call nebo_tensor_reshape_view
 test eax,eax
 jnz .fail13
 cmp qword [view+NEBO_TENSOR_SHAPE],3
 jne .fail14
 movsd xmm0,[seven]
 lea rdi,[view]
 lea rsi,[coord]
 call nebo_tensor_set_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
