bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
empty: resb NEBO_MATRIX_SIZE
data: resq 64

section .rodata align=8
source: dq 3,-2,7,4,9,1

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 lea rdx,[source]
 mov ecx,2
 mov r8d,3
 mov r9d,600
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 call nebo_matrix_i64_sum
 test eax,eax
 jnz .fail2
 cmp rdx,22
 jne .fail3
 lea rdi,[owner]
 call nebo_matrix_i64_min
 test eax,eax
 jnz .fail4
 cmp rdx,-2
 jne .fail5
 lea rdi,[owner]
 call nebo_matrix_i64_max
 cmp rdx,9
 jne .fail6
 lea rdi,[owner]
 call nebo_matrix_i64_trace
 test eax,eax
 jnz .fail7
 cmp rdx,12
 jne .fail8
 lea rdi,[owner]
 call nebo_matrix_i64_is_square
 cmp rdx,0
 jne .fail9
 lea rdi,[empty]
 xor esi,esi
 xor edx,edx
 mov ecx,8
 mov r8d,601
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .fail10
 lea rdi,[empty]
 call nebo_matrix_i64_sum
 test eax,eax
 jnz .fail11
 test rdx,rdx
 jnz .fail12
 lea rdi,[empty]
 call nebo_matrix_i64_min
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail13
 lea rdi,[empty]
 call nebo_matrix_i64_trace
 test eax,eax
 jnz .fail14
 test rdx,rdx
 jnz .fail15
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
