bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
rowv: resb NEBO_MATRIX_SIZE
colv: resb NEBO_MATRIX_SIZE
slicev: resb NEBO_MATRIX_SIZE
transv: resb NEBO_MATRIX_SIZE
data: resq 64

section .rodata align=8
source: dq 1,2,3,4,5,6,7,8,9,10,11,12

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 lea rdx,[source]
 mov ecx,3
 mov r8d,4
 mov r9d,300
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[rowv]
 lea rsi,[owner]
 mov edx,1
 call nebo_matrix_i64_row_view
 test eax,eax
 jnz .fail2
 lea rdi,[rowv]
 lea rsi,[owner]
 call nebo_matrix_i64_validate_view_owner
 test eax,eax
 jnz .fail3
 lea rdi,[rowv]
 xor esi,esi
 mov edx,2
 call nebo_matrix_i64_at
 cmp rdx,7
 jne .fail4
 lea rdi,[rowv]
 xor esi,esi
 xor edx,edx
 mov ecx,99
 call nebo_matrix_i64_set
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail5
 lea rdi,[colv]
 lea rsi,[owner]
 mov edx,2
 call nebo_matrix_i64_column_view
 test eax,eax
 jnz .fail6
 lea rdi,[colv]
 mov esi,2
 xor edx,edx
 call nebo_matrix_i64_at
 cmp rdx,11
 jne .fail7
 lea rdi,[slicev]
 lea rsi,[owner]
 mov edx,1
 mov ecx,2
 mov r8d,1
 mov r9d,2
 call nebo_matrix_i64_slice_view
 test eax,eax
 jnz .fail8
 lea rdi,[slicev]
 mov esi,1
 mov edx,1
 call nebo_matrix_i64_at
 cmp rdx,11
 jne .fail9
 lea rdi,[transv]
 lea rsi,[owner]
 call nebo_matrix_i64_transpose_view
 test eax,eax
 jnz .fail10
 lea rdi,[transv]
 mov esi,3
 mov edx,2
 call nebo_matrix_i64_at
 cmp rdx,12
 jne .fail11
 cmp qword [transv+NEBO_MATRIX_ROW_STRIDE],1
 jne .fail12
 cmp qword [transv+NEBO_MATRIX_COL_STRIDE],4
 jne .fail13
 ; Generation mismatch makes the view stale without reading payload.
 inc qword [owner+NEBO_MATRIX_GENERATION]
 lea rdi,[rowv]
 lea rsi,[owner]
 call nebo_matrix_i64_validate_view_owner
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail14
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
