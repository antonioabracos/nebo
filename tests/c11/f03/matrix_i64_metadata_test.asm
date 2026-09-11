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
 mov edx,3
 mov ecx,5
 mov r8d,0x1234
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .fail2
 lea rdi,[owner]
 call nebo_matrix_i64_rows
 test eax,eax
 jnz .fail3
 cmp rdx,3
 jne .fail4
 lea rdi,[owner]
 call nebo_matrix_i64_columns
 cmp rdx,5
 jne .fail5
 lea rdi,[owner]
 call nebo_matrix_i64_element_count
 cmp rdx,15
 jne .fail6
 lea rdi,[owner]
 call nebo_matrix_i64_layout
 cmp rdx,1
 jne .fail7
 lea rdi,[owner]
 call nebo_matrix_i64_storage_id
 cmp rdx,0x1234
 jne .fail8
 lea rdi,[owner]
 call nebo_matrix_i64_is_contiguous
 cmp rdx,1
 jne .fail9
 cmp qword [owner+NEBO_MATRIX_ROW_STRIDE],5
 jne .fail10
 cmp qword [owner+NEBO_MATRIX_COL_STRIDE],1
 jne .fail11
 cmp qword [owner+NEBO_MATRIX_DATA],data
 jne .fail12
 xor edi,edi
 jmp .exit
%assign i 1
%rep 12
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
