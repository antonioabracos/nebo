bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
data: resq 64

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,8
 mov ecx,8
 mov r8d,200
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 mov esi,7
 mov edx,7
 mov rcx,-42
 call nebo_matrix_i64_set
 test eax,eax
 jnz .fail2
 cmp qword [data+63*8],-42
 jne .fail3
 lea rdi,[owner]
 mov esi,7
 mov edx,7
 call nebo_matrix_i64_at
 test eax,eax
 jnz .fail4
 cmp rdx,-42
 jne .fail5
 ; Out-of-bounds set cannot change any payload byte.
 lea rdi,[owner]
 mov esi,8
 xor edx,edx
 mov rcx,99
 call nebo_matrix_i64_set
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail6
 cmp qword [data+63*8],-42
 jne .fail7
 cmp qword [data],0
 jne .fail8
 lea rdi,[owner]
 xor esi,esi
 mov edx,8
 call nebo_matrix_i64_at
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail9
 xor edi,edi
 jmp .exit
%assign i 1
%rep 9
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
