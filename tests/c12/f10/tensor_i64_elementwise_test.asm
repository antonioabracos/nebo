bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"
section .rodata align=8
shape_21: dq 2,1
shape_13: dq 1,3
left_values: dq 10,20
right_values: dq 1,2,3
overflow_values: dq 0x7fffffffffffffff,1
section .bss align=8
left: resb NEBO_TENSOR_SIZE
right: resb NEBO_TENSOR_SIZE
out: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
left_payload: resq 64
right_payload: resq 64
out_payload: resq 64
bad_payload: resq 64
section .text
global _start
_start:
 lea rdi,[left]
 lea rsi,[left_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_21]
 mov r9d,1001
 push qword 2
 lea rax,[left_values]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail1
 lea rdi,[right]
 lea rsi,[right_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_13]
 mov r9d,1002
 push qword 3
 lea rax,[right_values]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail2
 lea rdi,[out]
 lea rsi,[out_payload]
 lea rdx,[left]
 lea rcx,[right]
 mov r8d,1003
 call nebo_tensor_i64_add
 test eax,eax
 jnz .fail3
 cmp qword [out+NEBO_TENSOR_RANK],2
 jne .fail4
 cmp qword [out+NEBO_TENSOR_SHAPE],2
 jne .fail5
 cmp qword [out+NEBO_TENSOR_SHAPE+8],3
 jne .fail6
 cmp qword [out_payload],11
 jne .fail7
 cmp qword [out_payload+2*8],13
 jne .fail8
 cmp qword [out_payload+3*8],21
 jne .fail9
 cmp qword [out_payload+5*8],23
 jne .fail10
 lea rdi,[out]
 lea rsi,[out_payload]
 lea rdx,[left]
 lea rcx,[right]
 mov r8d,1004
 call nebo_tensor_i64_multiply
 test eax,eax
 jnz .fail11
 cmp qword [out_payload],10
 jne .fail12
 cmp qword [out_payload+5*8],60
 jne .fail13
 ; Full overflow preflight preserves descriptor and all destination payload.
 mov rax,0x7fffffffffffffff
 mov [left_payload],rax
 mov qword [right_payload],1
 mov qword [bad],0xaaaa
 mov qword [bad_payload],0x5555
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[left]
 lea rcx,[right]
 mov r8d,1005
 call nebo_tensor_i64_add
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail14
 cmp qword [bad],0xaaaa
 jne .fail15
 cmp qword [bad_payload],0x5555
 jne .fail16
 xor edi,edi
 jmp .exit
%assign i 1
%rep 16
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
