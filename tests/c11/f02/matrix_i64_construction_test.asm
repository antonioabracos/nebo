bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
zeros_desc: resb NEBO_MATRIX_SIZE
filled_desc: resb NEBO_MATRIX_SIZE
rows_desc: resb NEBO_MATRIX_SIZE
buffer_desc: resb NEBO_MATRIX_SIZE
bad_desc: resb NEBO_MATRIX_SIZE
zeros_data: resq 64
filled_data: resq 64
rows_data: resq 64
buffer_data: resq 64
bad_data: resq 64

section .rodata align=8
source: dq 1,2,3,4,5,6
sentinel: times 64 dq 0x5a5a5a5a5a5a5a5a

section .text
global _start
_start:
 lea rdi,[zeros_desc]
 lea rsi,[zeros_data]
 mov edx,8
 mov ecx,8
 mov r8d,101
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .fail1
 cmp qword [zeros_desc+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 jne .fail2
 cmp qword [zeros_desc+NEBO_MATRIX_CAPACITY],64
 jne .fail3
 mov ecx,64
 lea rsi,[zeros_data]
.check_zero:
 dec ecx
 js .filled
 cmp qword [rsi+rcx*8],0
 jne .fail4
 jmp .check_zero
.filled:
 lea rdi,[filled_desc]
 lea rsi,[filled_data]
 mov edx,2
 mov ecx,3
 mov r8,-7
 mov r9d,102
 call nebo_matrix_i64_filled
 test eax,eax
 jnz .fail5
 mov ecx,6
 lea rsi,[filled_data]
.check_fill:
 dec ecx
 js .rows
 cmp qword [rsi+rcx*8],-7
 jne .fail6
 jmp .check_fill
.rows:
 lea rdi,[rows_desc]
 lea rsi,[rows_data]
 lea rdx,[source]
 mov ecx,2
 mov r8d,3
 mov r9d,103
 call nebo_matrix_i64_from_rows
 test eax,eax
 jnz .fail7
 cmp qword [rows_data+40],6
 jne .fail8
.buffer:
 lea rdi,[buffer_desc]
 lea rsi,[buffer_data]
 lea rdx,[source]
 mov ecx,3
 mov r8d,2
 mov r9d,104
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail9
 cmp qword [buffer_data+24],4
 jne .fail10
 ; Failed construction is atomic for descriptor and payload.
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov rcx,NEBO_MATRIX_SIZE/8
 rep movsq
 lea rdi,[bad_data]
 lea rsi,[sentinel]
 mov ecx,64
 rep movsq
 lea rdi,[bad_desc]
 lea rsi,[bad_data]
 mov edx,9
 mov ecx,1
 mov r8d,105
 call nebo_matrix_i64_zeros
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 lea rdi,[bad_desc]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 repe cmpsq
 jne .fail12
 lea rdi,[bad_data]
 lea rsi,[sentinel]
 mov ecx,64
 repe cmpsq
 jne .fail13
 lea rdi,[filled_desc]
 call nebo_matrix_i64_release
 test eax,eax
 jnz .fail14
 cmp qword [filled_desc+NEBO_MATRIX_MAGIC_OFF],0
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
