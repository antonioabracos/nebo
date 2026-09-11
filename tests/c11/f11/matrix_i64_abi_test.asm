bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
result: resb NEBO_MATRIX_SIZE
bad: resb NEBO_MATRIX_SIZE
data: resq 64
result_data: resq 64
bad_data: resq 64

section .rodata align=8
source: dq 1,2,3,4,5,6
sentinel: times 64 dq 0x2222222222222222

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 lea rdx,[source]
 mov ecx,2
 mov r8d,3
 mov r9d,800
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 call nebo_matrix_i64_borrow_sum
 test eax,eax
 jnz .fail2
 cmp rdx,21
 jne .fail3
 lea rdi,[result]
 lea rsi,[result_data]
 lea rdx,[owner]
 mov rcx,3
 mov r8d,801
 call nebo_matrix_i64_sret_scale
 lea rcx,[result]
 cmp rax,rcx
 jne .fail4
 test rdx,rdx
 jnz .fail5
 cmp qword [result_data+40],18
 jne .fail6
 ; Failure does not publish sret or payload.
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
 lea rdx,[owner]
 mov rcx,0x7fffffffffffffff
 mov r8d,802
 call nebo_matrix_i64_sret_scale
 test rax,rax
 jnz .fail7
 cmp edx,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail8
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 repe cmpsq
 jne .fail9
 lea rdi,[bad_data]
 lea rsi,[sentinel]
 mov ecx,64
 repe cmpsq
 jne .fail10
 xor edi,edi
 jmp .exit
%assign i 1
%rep 10
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
