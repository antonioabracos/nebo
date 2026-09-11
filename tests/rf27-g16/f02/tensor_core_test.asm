bits 64
default rel
%include "runtime/tensor/tensor_core.inc"
section .data
shape dq 2,3
values dq 1.0,2.0,3.0,4.0,5.0,6.0
section .bss
align 8
desc resb NEBO_TENSOR_SIZE
data resq 6
section .text
global _start
_start:
 lea rdi,[desc]
 lea rsi,[data]
 mov edx,2
 lea rcx,[shape]
 mov r8d,7
 call nebo_tensor_zeros_f64
 test eax,eax
 jnz .fail1
 cmp qword [data],0
 jne .fail2
 lea rdi,[desc]
 call nebo_tensor_rank
 cmp rax,2
 jne .fail3
 lea rdi,[desc]
 xor esi,esi
 call nebo_tensor_size
 test edx,edx
 jnz .fail4
 cmp rax,2
 jne .fail5
 lea rdi,[desc]
 mov esi,2
 call nebo_tensor_size
 cmp edx,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail6
 lea rdi,[desc]
 call nebo_tensor_is_contiguous
 test edx,edx
 jnz .fail7
 cmp eax,1
 jne .fail8
 push qword 8
 lea rdi,[desc]
 lea rsi,[data]
 mov edx,2
 lea rcx,[shape]
 lea r8,[values]
 call nebo_tensor_from_values_f64
 add rsp,8
 test eax,eax
 jnz .fail9
 mov rax,[values+40]
 cmp [data+40],rax
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
