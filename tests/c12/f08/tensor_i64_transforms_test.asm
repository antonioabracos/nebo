bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_234: dq 2,3,4
shape_46: dq 4,6
shape_bad: dq 5,5
axes_201: dq 2,0,1
axes_dup: dq 0,0,1
idx_permuted: dq 3,1,2
shape_34: dq 3,4
idx_transpose: dq 3,2

section .bss align=8
owner: resb NEBO_TENSOR_SIZE
reshaped: resb NEBO_TENSOR_SIZE
permuted: resb NEBO_TENSOR_SIZE
matrix_owner: resb NEBO_TENSOR_SIZE
transposed: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
payload: resq 64

section .text
global _start
_start:
 xor ecx,ecx
.seed:
 cmp ecx,64
 je .owner
 mov [payload+rcx*8],rcx
 inc ecx
 jmp .seed
.owner:
 lea rdi,[owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_234]
 mov r9d,801
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 lea rsi,[reshaped]
 mov edx,2
 lea rcx,[shape_46]
 call nebo_tensor_i64_reshape_view
 test eax,eax
 jnz .fail2
 cmp qword [reshaped+NEBO_TENSOR_STRIDES],6
 jne .fail3
 cmp qword [reshaped+NEBO_TENSOR_STRIDES+8],1
 jne .fail4
 lea rdi,[reshaped]
 lea rsi,[owner]
 call nebo_tensor_i64_view_validate_owner
 test eax,eax
 jnz .fail5

 lea rdi,[owner]
 lea rsi,[permuted]
 lea rdx,[axes_201]
 mov ecx,3
 call nebo_tensor_i64_permute_view
 test eax,eax
 jnz .fail6
 cmp qword [permuted+NEBO_TENSOR_SHAPE],4
 jne .fail7
 cmp qword [permuted+NEBO_TENSOR_STRIDES],1
 jne .fail8
 lea rdi,[permuted]
 lea rsi,[owner]
 lea rdx,[idx_permuted]
 mov ecx,3
 call nebo_tensor_i64_view_at
 test edx,edx
 jnz .fail9
 cmp rax,23
 jne .fail10

 ; Invalid equal-count and duplicate-axis requests preserve destination.
 mov qword [bad],0x8181
 lea rdi,[owner]
 lea rsi,[bad]
 mov edx,2
 lea rcx,[shape_bad]
 call nebo_tensor_i64_reshape_view
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail11
 cmp qword [bad],0x8181
 jne .fail12
 lea rdi,[owner]
 lea rsi,[bad]
 lea rdx,[axes_dup]
 mov ecx,3
 call nebo_tensor_i64_permute_view
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail13

 ; Rank-2 transpose is permutation [1,0] and maps [3,2] to source [2,3].
 lea rdi,[matrix_owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_34]
 mov r9d,802
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail14
 lea rdi,[matrix_owner]
 lea rsi,[transposed]
 call nebo_tensor_i64_transpose_view
 test eax,eax
 jnz .fail15
 lea rdi,[transposed]
 lea rsi,[matrix_owner]
 lea rdx,[idx_transpose]
 mov ecx,2
 call nebo_tensor_i64_view_at
 test edx,edx
 jnz .fail16
 cmp rax,11
 jne .fail17

 xor edi,edi
 jmp .exit
%assign i 1
%rep 17
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
