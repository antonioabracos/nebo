bits 64
default rel
%include "runtime/matrix/matrix_core.inc"
section .bss
align 8
owner resb NEBO_MATRIX_SIZE
view resb NEBO_MATRIX_SIZE
trans resb NEBO_MATRIX_SIZE
copy resb NEBO_MATRIX_SIZE
data resq 9
copydata resq 9
section .rodata
align 8
five dq 5.0
seven dq 7.0
one dq 1.0
zero dq 0.0
section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,51
 call nebo_matrix_init_owned
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 call nebo_matrix_identity_f64
 test eax,eax
 jnz .fail2
 lea rdi,[owner]
 mov esi,1
 mov edx,1
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel one]
 jne .fail3
 lea rdi,[owner]
 mov esi,1
 mov edx,2
 movsd xmm0,[rel five]
 call nebo_matrix_set_f64
 test eax,eax
 jnz .fail4
 lea rdi,[owner]
 mov esi,1
 mov edx,2
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel five]
 jne .fail5
 lea rdi,[view]
 lea rsi,[owner]
 mov edx,1
 call nebo_matrix_row_view
 test eax,eax
 jnz .fail6
 lea rdi,[view]
 xor esi,esi
 mov edx,2
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel five]
 jne .fail7
 lea rdi,[view]
 xor esi,esi
 mov edx,1
 movsd xmm0,[rel seven]
 call nebo_matrix_set_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail8
 lea rdi,[view]
 lea rsi,[owner]
 mov edx,2
 call nebo_matrix_column_view
 test eax,eax
 jnz .fail9
 lea rdi,[view]
 mov esi,1
 xor edx,edx
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel five]
 jne .fail10
 lea rdi,[trans]
 lea rsi,[owner]
 call nebo_matrix_transpose_view
 test eax,eax
 jnz .fail11
 lea rdi,[trans]
 mov esi,2
 mov edx,1
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel five]
 jne .fail12
 lea rdi,[view]
 lea rsi,[owner]
 mov edx,1
 mov ecx,2
 mov r8d,1
 mov r9d,2
 call nebo_matrix_slice_view
 test eax,eax
 jnz .fail13
 cmp qword [view+NEBO_MATRIX_ROWS],2
 jne .fail14
 cmp qword [view+NEBO_MATRIX_COLS],2
 jne .fail15
 lea rdi,[copy]
 lea rsi,[copydata]
 lea rdx,[trans]
 mov ecx,99
 call nebo_matrix_contiguous_f64
 test eax,eax
 jnz .fail16
 lea rdi,[copy]
 mov esi,2
 mov edx,1
 call nebo_matrix_at_f64
 ucomisd xmm0,[rel five]
 jne .fail17
 lea rdi,[owner]
 mov esi,3
 xor edx,edx
 call nebo_matrix_at_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
