bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .rodata align=8
shape_zero: dq 2,0,4
shape_max: dq 4,4,4
sentinel: times (NEBO_TENSOR_SIZE/8) dq 0x5a5a5a5a5a5a5a5a

section .bss align=8
rank0_desc: resb NEBO_TENSOR_SIZE
empty_desc: resb NEBO_TENSOR_SIZE
max_desc: resb NEBO_TENSOR_SIZE
other_desc: resb NEBO_TENSOR_SIZE
bad_desc: resb NEBO_TENSOR_SIZE
rank0_payload: resq 1
max_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
other_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS

section .text
global _start
_start:
 ; Rank 0 is one I64 element and permits a null shape pointer.
 lea rdi,[rank0_desc]
 lea rsi,[rank0_payload]
 mov edx,1
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,101
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail1
 cmp qword [rank0_desc+NEBO_TENSOR_DTYPE],NEBO_TENSOR_DTYPE_I64
 jne .fail2
 cmp qword [rank0_desc+NEBO_TENSOR_CAPACITY],1
 jne .fail3
 cmp qword [rank0_desc+NEBO_TENSOR_STORAGE_ID],101
 jne .fail4
 cmp qword [rank0_desc+NEBO_TENSOR_GENERATION],1
 jne .fail5
 cmp qword [rank0_desc+NEBO_TENSOR_FLAGS],NEBO_TENSOR_I64_PUBLIC_OWNER_FLAGS
 jne .fail6
 lea rdi,[rank0_desc]
 call nebo_tensor_i64_owner_validate
 test eax,eax
 jnz .fail7

 ; A rank>0 zero dimension is an empty owner with canonical strides.
 lea rdi,[empty_desc]
 xor esi,esi
 xor edx,edx
 mov ecx,3
 lea r8,[shape_zero]
 mov r9d,102
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail8
 cmp qword [empty_desc+NEBO_TENSOR_CAPACITY],0
 jne .fail9
 cmp qword [empty_desc+NEBO_TENSOR_STRIDES],0
 jne .fail10
 cmp qword [empty_desc+NEBO_TENSOR_STRIDES+8],4
 jne .fail11
 cmp qword [empty_desc+NEBO_TENSOR_STRIDES+16],1
 jne .fail12

 ; Maximum selected rank/product and all unused descriptor slots are exact.
 lea rdi,[max_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_max]
 mov r9d,103
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail13
 cmp qword [max_desc+NEBO_TENSOR_CAPACITY],64
 jne .fail14
 cmp qword [max_desc+NEBO_TENSOR_STRIDES],16
 jne .fail15
 cmp qword [max_desc+NEBO_TENSOR_STRIDES+8],4
 jne .fail16
 cmp qword [max_desc+NEBO_TENSOR_STRIDES+16],1
 jne .fail17
 mov ecx,3
.unused:
 cmp ecx,NEBO_TENSOR_MAX_RANK
 jae .second_owner
 cmp qword [max_desc+NEBO_TENSOR_SHAPE+rcx*8],0
 jne .fail18
 cmp qword [max_desc+NEBO_TENSOR_STRIDES+rcx*8],0
 jne .fail19
 inc ecx
 jmp .unused

.second_owner:
 lea rdi,[other_desc]
 lea rsi,[other_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_max]
 mov r9d,104
 call nebo_tensor_i64_owner_init
 test eax,eax
 jnz .fail20
 mov rax,[max_desc+NEBO_TENSOR_STORAGE_ID]
 cmp rax,[other_desc+NEBO_TENSOR_STORAGE_ID]
 je .fail21

 ; Capacity failure preserves every destination descriptor byte.
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 lea rdi,[bad_desc]
 lea rsi,[max_payload]
 mov edx,63
 mov ecx,3
 lea r8,[shape_max]
 mov r9d,105
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jne .fail22
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail23

 ; Descriptor/payload overlap and zero identity reject before publication.
 lea rdi,[bad_desc]
 lea rsi,[bad_desc]
 mov edx,64
 mov ecx,3
 lea r8,[shape_max]
 mov r9d,106
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail24
 lea rdi,[bad_desc]
 lea rsi,[max_payload]
 mov edx,64
 mov ecx,3
 lea r8,[shape_max]
 xor r9d,r9d
 call nebo_tensor_i64_owner_init
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail25

 ; Cleanup advances generation once, clears descriptor identity and frees nothing.
 mov rax,0x1122334455667788
 mov [max_payload],rax
 lea rdi,[max_desc]
 call nebo_tensor_i64_owner_invalidate
 test eax,eax
 jnz .fail26
 cmp qword [max_desc+NEBO_TENSOR_MAGIC_OFF],0
 jne .fail27
 cmp qword [max_desc+NEBO_TENSOR_GENERATION],2
 jne .fail28
 cmp qword [max_desc+NEBO_TENSOR_DATA],0
 jne .fail29
 mov rax,0x1122334455667788
 cmp [max_payload],rax
 jne .fail30
 lea rdi,[max_desc]
 call nebo_tensor_i64_owner_invalidate
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail31

 xor edi,edi
 jmp .exit
%assign i 1
%rep 31
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
