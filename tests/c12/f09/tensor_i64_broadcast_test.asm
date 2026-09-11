bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"
section .rodata align=8
source_shape: dq 2,1,4
target_shape: dq 2,3,4
bad_shape: dq 2,3,5
over_shape: dq 2,8,8
index: dq 1,2,3
section .bss align=8
owner: resb NEBO_TENSOR_SIZE
view: resb NEBO_TENSOR_SIZE
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
 lea r8,[source_shape]
 mov r9d,901
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 lea rsi,[view]
 mov edx,3
 lea rcx,[target_shape]
 call nebo_tensor_i64_broadcast_view
 test eax,eax
 jnz .fail2
 cmp qword [view+NEBO_TENSOR_STRIDES],4
 jne .fail3
 cmp qword [view+NEBO_TENSOR_STRIDES+8],0
 jne .fail4
 cmp qword [view+NEBO_TENSOR_STRIDES+16],1
 jne .fail5
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_tensor_i64_view_validate_owner
 test eax,eax
 jnz .fail6
 lea rdi,[view]
 lea rsi,[owner]
 lea rdx,[index]
 mov ecx,3
 call nebo_tensor_i64_view_at
 test edx,edx
 jnz .fail7
 cmp rax,7
 jne .fail8
 ; Incompatibility and 65+ result plans preserve destination.
 mov qword [bad],0x9090
 lea rdi,[owner]
 lea rsi,[bad]
 mov edx,3
 lea rcx,[bad_shape]
 call nebo_tensor_i64_broadcast_view
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail9
 cmp qword [bad],0x9090
 jne .fail10
 lea rdi,[owner]
 lea rsi,[bad]
 mov edx,3
 lea rcx,[over_shape]
 call nebo_tensor_i64_broadcast_view
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 cmp qword [bad],0x9090
 jne .fail12
 xor edi,edi
 jmp .exit
%assign i 1
%rep 12
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
