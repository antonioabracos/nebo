bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .bss align=16
owner: resb NEBO_TENSOR_SIZE
owner_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
result: resb NEBO_TENSOR_SIZE
result_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
bad: resb NEBO_TENSOR_SIZE
bad_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
snapshot: resb NEBO_TENSOR_SIZE

section .rodata align=8
shape: dq 2,3
bad_shape: dq 9
sentinel: times NEBO_TENSOR_SIZE/8 dq 0x2222222222222222
payload_sentinel: times NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS dq 0x3333333333333333

section .text
global _start
_start:
 ; A borrowed parameter returns the reduction without mutating metadata.
 lea rdi,[owner]
 lea rsi,[owner_payload]
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov ecx,2
 lea r8,[shape]
 mov r9d,700
 push qword 7
 call nebo_tensor_i64_filled
 add rsp,8
 test eax,eax
 jnz .fail1
 lea rdi,[snapshot]
 lea rsi,[owner]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 lea rdi,[owner]
 call nebo_tensor_i64_borrow_sum
 cmp rax,42
 jne .fail2
 test edx,edx
 jnz .fail3
 lea rdi,[owner]
 lea rsi,[snapshot]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail4

 ; Owned result uses caller descriptor/payload and returns descriptor identity.
 lea rdi,[result]
 lea rsi,[result_payload]
 mov edx,2
 lea rcx,[shape]
 mov r8d,5
 mov r9d,701
 call nebo_tensor_i64_sret_filled
 lea rcx,[result]
 cmp rax,rcx
 jne .fail5
 test edx,edx
 jnz .fail6
 cmp qword [result_payload+40],5
 jne .fail7
 lea rdi,[result]
 call nebo_tensor_i64_sum_all
 cmp rax,30
 jne .fail8
 test edx,edx
 jnz .fail9

 ; A rejected sret plan preserves every destination byte.
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 lea rdi,[bad_payload]
 lea rsi,[payload_sentinel]
 mov ecx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 rep movsq
 lea rdi,[bad]
 lea rsi,[bad_payload]
 mov edx,1
 lea rcx,[bad_shape]
 mov r8d,9
 mov r9d,702
 call nebo_tensor_i64_sret_filled
 test rax,rax
 jnz .fail10
 cmp edx,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail12
 lea rdi,[bad_payload]
 lea rsi,[payload_sentinel]
 mov ecx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 repe cmpsq
 jne .fail13
 xor edi,edi
 jmp .exit
%assign i 1
%rep 13
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
