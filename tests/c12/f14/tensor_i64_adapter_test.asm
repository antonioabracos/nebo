bits 64
default rel
%include "runtime/tensor/tensor_i64_public.inc"

section .bss align=16
owner: resb NEBO_TENSOR_SIZE
decoded: resb NEBO_TENSOR_SIZE
bad: resb NEBO_TENSOR_SIZE
view: resb NEBO_TENSOR_SIZE
owner_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
decoded_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
bad_payload: resq NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
encoded: resb NEBO_TENSOR_I64_NBT1_MAX_BYTES

section .rodata align=8
shape: dq 2,3
source: dq -1,2,3,4,5,6
sentinel_desc: times NEBO_TENSOR_SIZE/8 dq 0x4444444444444444
sentinel_payload: times NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS dq 0x5555555555555555

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[owner_payload]
 mov edx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 mov ecx,2
 lea r8,[shape]
 mov r9d,800
 push qword 6
 lea rax,[source]
 push rax
 call nebo_tensor_i64_from_buffer
 add rsp,16
 test eax,eax
 jnz .fail1

 lea rdi,[owner]
 call nebo_tensor_i64_serialized_size
 test eax,eax
 jnz .fail2
 cmp rdx,192
 jne .fail3
 lea rdi,[owner]
 lea rsi,[encoded]
 mov edx,NEBO_TENSOR_I64_NBT1_MAX_BYTES
 call nebo_tensor_i64_serialize
 test eax,eax
 jnz .fail4
 cmp rdx,192
 jne .fail5
 cmp dword [encoded],0x3154424e
 jne .fail6
 cmp word [encoded+4],1
 jne .fail7
 cmp word [encoded+6],0
 jne .fail8
 cmp qword [encoded+8],NEBO_TENSOR_DTYPE_I64
 jne .fail9
 cmp qword [encoded+16],NEBO_TENSOR_DEVICE_CPU
 jne .fail10
 cmp qword [encoded+24],2
 jne .fail11
 cmp qword [encoded+32],2
 jne .fail12
 cmp qword [encoded+40],3
 jne .fail13
 cmp qword [encoded+48],0
 jne .fail14
 cmp qword [encoded+80],3
 jne .fail15
 cmp qword [encoded+88],1
 jne .fail16
 cmp qword [encoded+96],0
 jne .fail17
 cmp qword [encoded+128],6
 jne .fail18
 cmp qword [encoded+136],48
 jne .fail19

 lea rdi,[decoded]
 lea rsi,[decoded_payload]
 lea rdx,[encoded]
 mov ecx,192
 mov r8d,801
 call nebo_tensor_i64_deserialize
 test eax,eax
 jnz .fail20
 lea rsi,[source]
 lea rdi,[decoded_payload]
 mov ecx,6
 repe cmpsq
 jne .fail21
 lea rdi,[decoded]
 call nebo_tensor_i64_headless_shape
 test eax,eax
 jnz .fail22
 cmp rdx,2
 jne .fail23
 cmp rcx,2
 jne .fail24
 cmp r8,3
 jne .fail25
 test r9,r9
 jnz .fail26
 cmp r10,6
 jne .fail27
 cmp r11,1
 jne .fail28

 ; Wrong magic is rejected before either caller destination is touched.
 mov byte [encoded],0
 lea rdi,[bad]
 lea rsi,[sentinel_desc]
 mov ecx,NEBO_TENSOR_SIZE/8
 rep movsq
 lea rdi,[bad_payload]
 lea rsi,[sentinel_payload]
 mov ecx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 rep movsq
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[encoded]
 mov ecx,192
 mov r8d,802
 call nebo_tensor_i64_deserialize
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail29
 lea rdi,[bad]
 lea rsi,[sentinel_desc]
 mov ecx,NEBO_TENSOR_SIZE/8
 repe cmpsq
 jne .fail30
 lea rdi,[bad_payload]
 lea rsi,[sentinel_payload]
 mov ecx,NEBO_TENSOR_I64_PUBLIC_MAX_ELEMENTS
 repe cmpsq
 jne .fail31
 mov byte [encoded],0x4e

 ; Trailing bytes and noncanonical unused slots fail closed.
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[encoded]
 mov ecx,193
 mov r8d,803
 call nebo_tensor_i64_deserialize
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail32
 mov qword [encoded+48],1
 lea rdi,[bad]
 lea rsi,[bad_payload]
 lea rdx,[encoded]
 mov ecx,192
 mov r8d,803
 call nebo_tensor_i64_deserialize
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail33
 mov qword [encoded+48],0

 ; A view is never serialized implicitly.
 lea rdi,[owner]
 lea rsi,[view]
 xor edx,edx
 xor ecx,ecx
 mov r8d,1
 call nebo_tensor_i64_narrow_view
 test eax,eax
 jnz .fail34
 lea rdi,[view]
 lea rsi,[encoded]
 mov edx,NEBO_TENSOR_I64_NBT1_MAX_BYTES
 call nebo_tensor_i64_serialize
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail35

 xor edi,edi
 jmp .exit
%assign i 1
%rep 35
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
