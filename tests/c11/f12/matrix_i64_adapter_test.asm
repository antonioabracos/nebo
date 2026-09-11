bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
decoded: resb NEBO_MATRIX_SIZE
bad: resb NEBO_MATRIX_SIZE
data: resq 64
decoded_data: resq 64
bad_data: resq 64
encoded: resb NEBO_MATRIX_I64_NBM1_MAX_BYTES

section .rodata align=8
source: dq -1,2,3,4,5,6
sentinel: times 64 dq 0x1111111111111111

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 lea rdx,[source]
 mov ecx,2
 mov r8d,3
 mov r9d,900
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 lea rsi,[encoded]
 mov edx,NEBO_MATRIX_I64_NBM1_MAX_BYTES
 call nebo_matrix_i64_serialize
 test eax,eax
 jnz .fail2
 cmp rdx,96
 jne .fail3
 cmp dword [encoded],0x314d424e
 jne .fail4
 lea rdi,[decoded]
 lea rsi,[decoded_data]
 lea rdx,[encoded]
 mov ecx,96
 mov r8d,901
 call nebo_matrix_i64_deserialize
 test eax,eax
 jnz .fail5
 cmp qword [decoded_data],-1
 jne .fail6
 cmp qword [decoded_data+40],6
 jne .fail7
 lea rdi,[decoded]
 call nebo_matrix_i64_headless_shape
 test eax,eax
 jnz .fail8
 cmp rdx,2
 jne .fail9
 cmp rcx,3
 jne .fail10
 cmp r8,6
 jne .fail11
 cmp r9,1
 jne .fail12
 ; Corrupt magic is rejected without destination publication.
 mov byte [encoded],0
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 rep movsq
 lea rdi,[bad_data]
 lea rsi,[sentinel]
 mov ecx,64
 rep movsq
 lea rdi,[bad]
 lea rsi,[bad_data]
 lea rdx,[encoded]
 mov ecx,96
 mov r8d,902
 call nebo_matrix_i64_deserialize
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail13
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 repe cmpsq
 jne .fail14
 lea rdi,[bad_data]
 lea rsi,[sentinel]
 mov ecx,64
 repe cmpsq
 jne .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
