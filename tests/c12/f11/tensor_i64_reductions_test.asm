bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"
section .rodata align=8
shape_23: dq 2,3
values: dq 1,2,3,4,5,6
axis0: dq 0
axis1: dq 1
shape_empty: dq 0,3
section .bss align=8
owner: resb NEBO_TENSOR_SIZE
result: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
empty: resb NEBO_TENSOR_SIZE
payload: resq 64
result_payload: resq 64
bad_payload: resq 64
section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,1101
 push qword 6
 lea rax,[values]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail1
 ; Reduce axis 1 without keepDimensions -> [2] = [6,15].
 lea rdi,[result]
 lea rsi,[result_payload]
 lea rdx,[owner]
 lea rcx,[axis1]
 mov r8d,1
 xor r9d,r9d
 push qword 1102
 call nebo_tensor_i64_sum_axes
 add rsp,8
 test eax,eax
 jnz .fail2
 cmp qword [result+NEBO_TENSOR_RANK],1
 jne .fail3
 cmp qword [result+NEBO_TENSOR_SHAPE],2
 jne .fail4
 cmp qword [result_payload],6
 jne .fail5
 cmp qword [result_payload+8],15
 jne .fail6
 ; Reduce axis 0 with keepDimensions -> [1,3] = [5,7,9].
 lea rdi,[result]
 lea rsi,[result_payload]
 lea rdx,[owner]
 lea rcx,[axis0]
 mov r8d,1
 mov r9d,1
 push qword 1103
 call nebo_tensor_i64_sum_axes
 add rsp,8
 test eax,eax
 jnz .fail7
 cmp qword [result+NEBO_TENSOR_RANK],2
 jne .fail8
 cmp qword [result+NEBO_TENSOR_SHAPE],1
 jne .fail9
 cmp qword [result_payload],5
 jne .fail10
 cmp qword [result_payload+8],7
 jne .fail11
 cmp qword [result_payload+16],9
 jne .fail12
 lea rdi,[owner]
 call nebo_tensor_i64_sum_all
 test edx,edx
 jnz .fail13
 cmp rax,21
 jne .fail14
 lea rdi,[owner]
 call nebo_tensor_i64_min
 test edx,edx
 jnz .fail15
 cmp rax,1
 jne .fail16
 lea rdi,[owner]
 call nebo_tensor_i64_max
 test edx,edx
 jnz .fail17
 cmp rax,6
 jne .fail18
 ; Empty sum is zero; min/max have no result.
 lea rdi,[empty]
 xor esi,esi
 xor edx,edx
 mov ecx,2
 lea r8,[shape_empty]
 mov r9d,1104
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail19
 lea rdi,[empty]
 call nebo_tensor_i64_sum_all
 test edx,edx
 jnz .fail20
 test rax,rax
 jnz .fail21
 lea rdi,[empty]
 call nebo_tensor_i64_min
 cmp edx,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail22
 ; Overflow preflight preserves output.
 mov rax,0x7fffffffffffffff
 mov [payload],rax
 mov qword [payload+8],1
 mov qword [bad],0x1111
 mov qword [bad_payload],0x2222
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[owner]
 lea rcx,[axis1]
 mov r8d,1
 xor r9d,r9d
 push qword 1105
 call nebo_tensor_i64_sum_axes
 add rsp,8
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail23
 cmp qword [bad],0x1111
 jne .fail24
 cmp qword [bad_payload],0x2222
 jne .fail25
 xor edi,edi
 jmp .exit
%assign i 1
%rep 25
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
