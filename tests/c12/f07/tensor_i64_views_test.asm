bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_234: dq 2,3,4
idx_narrow: dq 1,1,3
idx_select: dq 1,3

section .bss align=8
owner: resb NEBO_TENSOR_SIZE
narrowed: resb NEBO_TENSOR_SIZE
selected: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
payload: resq 64

section .text
global _start
_start:
 ; Fill payload with its flat index.
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
 mov r9d,701
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1

 ; narrow axis 1 from 1 for length 2: base offset 4, noncontiguous.
 lea rdi,[owner]
 lea rsi,[narrowed]
 mov edx,1
 mov ecx,1
 mov r8d,2
 call nebo_tensor_i64_narrow_view
 test eax,eax
 jnz .fail2
 lea rdi,[narrowed]
 lea rsi,[owner]
 call nebo_tensor_i64_view_validate_owner
 test eax,eax
 jnz .fail3
 cmp qword [narrowed+NEBO_TENSOR_STORAGE_ID],701
 jne .fail4
 cmp qword [narrowed+NEBO_TENSOR_SHAPE+8],2
 jne .fail5
 test qword [narrowed+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_CONTIGUOUS
 jnz .fail6
 lea rdi,[narrowed]
 lea rsi,[owner]
 lea rdx,[idx_narrow]
 mov ecx,3
 call nebo_tensor_i64_view_at
 test edx,edx
 jnz .fail7
 cmp rax,23
 jne .fail8

 ; select axis 1 index 2: shape [2,4], shared identity, no copy.
 lea rdi,[owner]
 lea rsi,[selected]
 mov edx,1
 mov ecx,2
 call nebo_tensor_i64_select_view
 test eax,eax
 jnz .fail9
 cmp qword [selected+NEBO_TENSOR_RANK],2
 jne .fail10
 cmp qword [selected+NEBO_TENSOR_SHAPE],2
 jne .fail11
 cmp qword [selected+NEBO_TENSOR_SHAPE+8],4
 jne .fail12
 lea rdi,[selected]
 lea rsi,[owner]
 lea rdx,[idx_select]
 mov ecx,2
 call nebo_tensor_i64_view_at
 test edx,edx
 jnz .fail13
 cmp rax,23
 jne .fail14

 ; Owner mutation API refuses a view.
 lea rdi,[selected]
 lea rsi,[idx_select]
 mov edx,2
 mov ecx,99
 call nebo_tensor_i64_set
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail15
 cmp qword [payload+23*8],23
 jne .fail16

 ; Bounds failure preserves the destination descriptor sentinel.
 mov qword [bad],0x1234
 lea rdi,[owner]
 lea rsi,[bad]
 mov edx,1
 mov ecx,3
 mov r8d,1
 call nebo_tensor_i64_narrow_view
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail17
 cmp qword [bad],0x1234
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
