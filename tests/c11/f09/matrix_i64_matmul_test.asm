bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
a: resb NEBO_MATRIX_SIZE
b: resb NEBO_MATRIX_SIZE
out: resb NEBO_MATRIX_SIZE
into: resb NEBO_MATRIX_SIZE
bad: resb NEBO_MATRIX_SIZE
adata: resq 64
bdata: resq 64
outdata: resq 64
intodata: resq 64
baddata: resq 64

section .rodata align=8
asrc: dq 1,2,3,4,5,6
bsrc: dq 7,8,9,10,11,12
sentinel: times 64 dq 0x3333333333333333

section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[adata]
 lea rdx,[asrc]
 mov ecx,2
 mov r8d,3
 mov r9d,700
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[b]
 lea rsi,[bdata]
 lea rdx,[bsrc]
 mov ecx,3
 mov r8d,2
 mov r9d,701
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail2
 lea rdi,[out]
 lea rsi,[outdata]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,702
 call nebo_matrix_i64_matmul
 test eax,eax
 jnz .fail3
 cmp qword [outdata],58
 jne .fail4
 cmp qword [outdata+8],64
 jne .fail5
 cmp qword [outdata+16],139
 jne .fail6
 cmp qword [outdata+24],154
 jne .fail7
 lea rdi,[into]
 lea rsi,[intodata]
 mov edx,2
 mov ecx,2
 mov r8d,703
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .fail8
 lea rdi,[into]
 lea rsi,[a]
 lea rdx,[b]
 call nebo_matrix_i64_matmul_into
 test eax,eax
 jnz .fail9
 cmp qword [intodata+16],139
 jne .fail10
 ; Checked product overflow leaves a fresh result entirely untouched.
 mov rax,0x7fffffffffffffff
 mov [adata],rax
 mov qword [bdata],2
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 rep movsq
 lea rdi,[baddata]
 lea rsi,[sentinel]
 mov ecx,64
 rep movsq
 lea rdi,[bad]
 lea rsi,[baddata]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,704
 call nebo_matrix_i64_matmul
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail11
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 repe cmpsq
 jne .fail12
 lea rdi,[baddata]
 lea rsi,[sentinel]
 mov ecx,64
 repe cmpsq
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
