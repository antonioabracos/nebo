bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_234: dq 2,3,4
index_123: dq 1,2,3
index_020: dq 0,2,0
index_bad: dq 2,0,0

section .bss align=8
owner: resb NEBO_TENSOR_SIZE
scalar: resb NEBO_TENSOR_SIZE
payload: resq 64
scalar_payload: resq 1

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_234]
 mov r9d,601
 push qword 7
 call nebo_tensor_i64_filled
 add rsp,8
 test eax,eax
 jnz .fail1

 ; [1,2,3] -> 1*12 + 2*4 + 3 = 23.
 lea rdi,[owner]
 lea rsi,[index_123]
 mov edx,3
 mov ecx,91
 call nebo_tensor_i64_set
 test eax,eax
 jnz .fail2
 cmp qword [payload+23*8],91
 jne .fail3
 lea rdi,[owner]
 lea rsi,[index_123]
 mov edx,3
 call nebo_tensor_i64_at
 test edx,edx
 jnz .fail4
 cmp rax,91
 jne .fail5

 ; A different checked coordinate remains independent.
 lea rdi,[owner]
 lea rsi,[index_020]
 mov edx,3
 call nebo_tensor_i64_at
 test edx,edx
 jnz .fail6
 cmp rax,7
 jne .fail7

 ; Bounds and rank mismatch fail before mutation.
 lea rdi,[owner]
 lea rsi,[index_bad]
 mov edx,3
 mov ecx,55
 call nebo_tensor_i64_set
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail8
 cmp qword [payload+23*8],91
 jne .fail9
 lea rdi,[owner]
 lea rsi,[index_123]
 mov edx,2
 call nebo_tensor_i64_at
 cmp edx,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail10

 ; Rank-zero uses the single scalar coordinate with no index pointer.
 lea rdi,[scalar]
 lea rsi,[scalar_payload]
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,602
 call nebo_tensor_i64_zeros
 test eax,eax
 jnz .fail11
 lea rdi,[scalar]
 xor esi,esi
 xor edx,edx
 mov rcx,-22
 call nebo_tensor_i64_set
 test eax,eax
 jnz .fail12
 lea rdi,[scalar]
 xor esi,esi
 xor edx,edx
 call nebo_tensor_i64_at
 test edx,edx
 jnz .fail13
 cmp rax,-22
 jne .fail14

 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
