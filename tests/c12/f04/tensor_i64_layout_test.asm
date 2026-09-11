bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_234: dq 2,3,4
shape_zero: dq 2,0,4

section .bss align=8
owner: resb NEBO_TENSOR_SIZE
empty_owner: resb NEBO_TENSOR_SIZE
payload: resq 64

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_234]
 mov r9d,401
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1

 ; Canonical row-major element strides [12,4,1].
 lea rdi,[owner]
 xor esi,esi
 call nebo_tensor_i64_stride
 test edx,edx
 jnz .fail2
 cmp rax,12
 jne .fail3
 lea rdi,[owner]
 mov esi,1
 call nebo_tensor_i64_stride
 test edx,edx
 jnz .fail4
 cmp rax,4
 jne .fail5
 lea rdi,[owner]
 mov esi,2
 call nebo_tensor_i64_stride
 test edx,edx
 jnz .fail6
 cmp rax,1
 jne .fail7
 lea rdi,[owner]
 mov esi,3
 call nebo_tensor_i64_stride
 cmp edx,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail8
 lea rdi,[owner]
 call nebo_tensor_i64_is_contiguous
 test edx,edx
 jnz .fail9
 cmp eax,1
 jne .fail10

 ; Zero-dimensional owners retain a canonical, bounded stride chain [0,4,1].
 lea rdi,[empty_owner]
 xor esi,esi
 xor edx,edx
 mov ecx,3
 lea r8,[shape_zero]
 mov r9d,402
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail11
 cmp qword [empty_owner+NEBO_TENSOR_STRIDES],0
 jne .fail12
 cmp qword [empty_owner+NEBO_TENSOR_STRIDES+8],4
 jne .fail13
 cmp qword [empty_owner+NEBO_TENSOR_STRIDES+16],1
 jne .fail14
 lea rdi,[empty_owner]
 call nebo_tensor_i64_is_contiguous
 test edx,edx
 jnz .fail15
 cmp eax,1
 jne .fail16

 ; A forged active stride fails closed; no copy or canonicalization occurs.
 mov qword [owner+NEBO_TENSOR_STRIDES+8],5
 lea rdi,[owner]
 call nebo_tensor_i64_is_contiguous
 cmp edx,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail17
 cmp qword [owner+NEBO_TENSOR_STRIDES+8],5
 jne .fail18

 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
