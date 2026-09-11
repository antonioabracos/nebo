bits 64
default rel
%include "compiler/semantic/matrix/matrix_contract.inc"
section .bss
align 8
owner resb NEBO_MATRIX_SIZE
view resb NEBO_MATRIX_SIZE
data resq 16
section .text
global _start
_start:
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,77
 call nebo_matrix_init_owned
 test eax,eax
 jnz .fail1
 lea rdi,[owner]
 call nebo_matrix_validate
 test eax,eax
 jnz .fail2
 cmp qword [owner+NEBO_MATRIX_ROWS],4
 jne .fail3
 cmp qword [owner+NEBO_MATRIX_COLS],4
 jne .fail4
 cmp qword [owner+NEBO_MATRIX_CAPACITY],16
 jne .fail5
 lea rsi,[owner]
 lea rdi,[view]
 mov ecx,NEBO_MATRIX_SIZE/8
 rep movsq
 and qword [view+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_OWNED
 or qword [view+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW|NEBO_MATRIX_FLAG_READONLY
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_matrix_validate_view_owner
 test eax,eax
 jnz .fail6
 inc qword [owner+NEBO_MATRIX_GENERATION]
 lea rdi,[view]
 lea rsi,[owner]
 call nebo_matrix_validate_view_owner
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail7
 mov qword [owner+NEBO_MATRIX_GENERATION],1
 mov qword [owner+NEBO_MATRIX_ROWS],65
 lea rdi,[owner]
 call nebo_matrix_validate
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail8
 mov qword [owner+NEBO_MATRIX_ROWS],4
 mov qword [owner+NEBO_MATRIX_MAGIC_OFF],0
 lea rdi,[owner]
 call nebo_matrix_validate
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail9
 xor edi,edi
 call nebo_matrix_validate
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail10
 lea rdi,[owner]
 lea rsi,[data]
 mov edx,65
 mov ecx,1
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 lea rdi,[owner]
 xor esi,esi
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail12
 lea rdi,[owner]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 test eax,eax
 jnz .fail13
 lea rdi,[owner]
 call nebo_matrix_validate
 test eax,eax
 jnz .fail14
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
