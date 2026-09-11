bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_zero: dq 2,0,4
shape_max: dq 4,4,4
shape_product_over: dq 8,8,2
shape_dimension_over: dq 9
shape_rank_over: dq 1,1,1,1
sentinel: times (NEBO_TENSOR_SIZE/8) dq 0x3c3c3c3c3c3c3c3c

section .bss align=8
rank0_desc: resb NEBO_TENSOR_SIZE
zero_desc: resb NEBO_TENSOR_SIZE
max_desc: resb NEBO_TENSOR_SIZE
bad_desc: resb NEBO_TENSOR_SIZE
rank0_payload: resq 1
max_payload: resq 64

section .text
global _start
_start:
 lea rdi,[rank0_desc]
 lea rsi,[rank0_payload]
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,201
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1
 lea rdi,[rank0_desc]
 call nebo_tensor_i64_rank
 test edx,edx
 jnz .fail2
 test rax,rax
 jnz .fail3
 lea rdi,[rank0_desc]
 call nebo_tensor_i64_element_count
 test edx,edx
 jnz .fail4
 cmp rax,1
 jne .fail5
 lea rdi,[rank0_desc]
 xor esi,esi
 call nebo_tensor_i64_dimension
 cmp edx,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail6

 lea rdi,[zero_desc]
 xor esi,esi
 xor edx,edx
 mov ecx,3
 lea r8,[shape_zero]
 mov r9d,202
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail7
 lea rdi,[zero_desc]
 call nebo_tensor_i64_element_count
 test edx,edx
 jnz .fail8
 test rax,rax
 jnz .fail9
 lea rdi,[zero_desc]
 mov esi,1
 call nebo_tensor_i64_dimension
 test edx,edx
 jnz .fail10
 test rax,rax
 jnz .fail11

 lea rdi,[max_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_max]
 mov r9d,203
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail12
 lea rdi,[max_desc]
 call nebo_tensor_i64_element_count
 test edx,edx
 jnz .fail13
 cmp rax,64
 jne .fail14

 ; Every rejected boundary preserves the descriptor byte-for-byte.
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 lea rdi,[bad_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_product_over]
 mov r9d,204
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail15
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail16

 lea rdi,[bad_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,1
 lea r8,[shape_dimension_over]
 mov r9d,205
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail17
 lea rdi,[bad_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,4
 lea r8,[shape_rank_over]
 mov r9d,206
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail18

 ; Corrupted unused metadata is fail-closed and never observable as a value.
 mov qword [max_desc+NEBO_TENSOR_SHAPE+24],1
 lea rdi,[max_desc]
 call nebo_tensor_i64_rank
 cmp edx,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail19

 xor edi,edi
 jmp .exit
%assign i 1
%rep 19
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
