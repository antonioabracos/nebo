bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_23: dq 2,3
source: dq 11,12,13,14,15,16
sentinel_desc: times (NEBO_TENSOR_SIZE/8) dq 0x5a5a5a5a5a5a5a5a

section .bss align=8
zeros_desc: resb NEBO_TENSOR_SIZE
filled_desc: resb NEBO_TENSOR_SIZE
copy_desc: resb NEBO_TENSOR_SIZE
bad_desc: resb NEBO_TENSOR_SIZE
zeros_payload: resq 64
filled_payload: resq 64
copy_payload: resq 64
bad_payload: resq 64

section .text
global _start
_start:
 mov rcx,64
 lea rdi,[zeros_payload]
 mov rax,99
 rep stosq
 lea rdi,[zeros_desc]
 lea rsi,[zeros_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,501
 call nebo_tensor_i64_zeros
 test eax,eax
 jnz .fail1
 xor ecx,ecx
.zero_check:
 cmp ecx,6
 je .zero_tail
 cmp qword [zeros_payload+rcx*8],0
 jne .fail2
 inc ecx
 jmp .zero_check
.zero_tail:
 cmp qword [zeros_payload+6*8],99
 jne .fail3

 lea rdi,[filled_desc]
 lea rsi,[filled_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,502
 push qword -7
 call nebo_tensor_i64_filled
 add rsp,8
 test eax,eax
 jnz .fail4
 xor ecx,ecx
.fill_check:
 cmp ecx,6
 je .copy
 cmp qword [filled_payload+rcx*8],-7
 jne .fail5
 inc ecx
 jmp .fill_check

.copy:
 lea rdi,[copy_desc]
 lea rsi,[copy_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,503
 push qword 6
 lea rax,[source]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail6
 lea rsi,[source]
 lea rdi,[copy_payload]
 mov ecx,6
 repe cmpsq
 jne .fail7
 lea rdi,[copy_desc]
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .fail8

 ; Length mismatch preserves both descriptor and payload.
 lea rdi,[bad_desc]
 lea rsi,[sentinel_desc]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 mov rcx,64
 lea rdi,[bad_payload]
 mov rax,77
 rep stosq
 lea rdi,[bad_desc]
 lea rsi,[bad_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,504
 push qword 5
 lea rax,[source]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail9
 lea rdi,[bad_desc]
 lea rsi,[sentinel_desc]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail10
 cmp qword [bad_payload],77
 jne .fail11

 ; Explicit-copy source/destination aliasing is rejected before publication.
 lea rdi,[bad_desc]
 lea rsi,[bad_payload]
 mov edx,64
 mov ecx,2
 lea r8,[shape_23]
 mov r9d,505
 push qword 6
 lea rax,[bad_payload]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail12
 cmp qword [bad_payload],77
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

section .note.GNU-stack noalloc noexec nowrite progbits
