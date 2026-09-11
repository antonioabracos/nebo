bits 64
default rel
%include "compiler/semantic/tensor/tensor_contract.inc"
section .data
shape dq 2,3,4
bad_shape dq 2,3,4097
section .bss
align 8
owner resb NEBO_TENSOR_SIZE
view resb NEBO_TENSOR_SIZE
data resq 24
section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,3
 lea rcx,[shape]
 mov r8d,NEBO_TENSOR_DTYPE_F64
 mov r9d,91
 call nebo_tensor_init_owned
 test eax,eax
 jnz .fail1
 cmp qword [owner+NEBO_TENSOR_RANK],3
 jne .fail2
 cmp qword [owner+NEBO_TENSOR_CAPACITY],24
 jne .fail3
 cmp qword [owner+NEBO_TENSOR_STRIDES],12
 jne .fail4
 cmp qword [owner+NEBO_TENSOR_STRIDES+8],4
 jne .fail5
 cmp qword [owner+NEBO_TENSOR_STRIDES+16],1
 jne .fail6
 lea rdi,[owner]
 call nebo_tensor_validate
 test eax,eax
 jnz .fail7
 lea rsi,[owner]
 lea rdi,[view]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 and qword [view+NEBO_TENSOR_FLAGS],~NEBO_TENSOR_FLAG_OWNED
 or qword [view+NEBO_TENSOR_FLAGS],NEBO_TENSOR_FLAG_VIEW|NEBO_TENSOR_FLAG_READONLY
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_tensor_validate_view_owner
 test eax,eax
 jnz .fail8
 inc qword [owner+NEBO_TENSOR_GENERATION]
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_tensor_validate_view_owner
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail9
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,7
 lea rcx,[shape]
 mov r8d,NEBO_TENSOR_DTYPE_I64
 mov r9d,1
 call nebo_tensor_init_owned
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail10
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,3
 lea rcx,[bad_shape]
 mov r8d,NEBO_TENSOR_DTYPE_I64
 mov r9d,1
 call nebo_tensor_init_owned
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 xor edi,edi
 call nebo_tensor_validate
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail12
 xor edi,edi
 jmp .exit
%assign i 1
%rep 12
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
