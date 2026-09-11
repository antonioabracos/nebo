bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
owner: resb NEBO_MATRIX_SIZE
transv: resb NEBO_MATRIX_SIZE
copy: resb NEBO_MATRIX_SIZE
data: resq 64
copy_data: resq 64

section .rodata align=8
source: dq 1,2,3,4,5,6

section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 lea rdx,[source]
 mov ecx,2
 mov r8d,3
 mov r9d,400
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[transv]
 lea rsi,[owner]
 call nebo_matrix_i64_transpose_view
 test eax,eax
 jnz .fail2
 lea rdi,[copy]
 lea rsi,[copy_data]
 lea rdx,[transv]
 lea rcx,[owner]
 mov r8d,401
 call nebo_matrix_i64_contiguous
 test eax,eax
 jnz .fail3
 cmp qword [copy+NEBO_MATRIX_ROWS],3
 jne .fail4
 cmp qword [copy+NEBO_MATRIX_COLS],2
 jne .fail5
 cmp qword [copy+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED|NEBO_MATRIX_FLAG_CONTIGUOUS
 jne .fail6
 cmp qword [copy_data],1
 jne .fail7
 cmp qword [copy_data+8],4
 jne .fail8
 cmp qword [copy_data+16],2
 jne .fail9
 cmp qword [copy_data+24],5
 jne .fail10
 cmp qword [copy_data+32],3
 jne .fail11
 cmp qword [copy_data+40],6
 jne .fail12
 ; Reusing owner storage as a materialization destination is rejected.
 lea rdi,[copy]
 lea rsi,[data]
 lea rdx,[transv]
 lea rcx,[owner]
 mov r8d,402
 call nebo_matrix_i64_contiguous
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail13
 xor edi,edi
 jmp .exit
%assign i 1
%rep 13
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
