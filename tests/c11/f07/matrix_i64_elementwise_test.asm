bits 64
default rel
%include "runtime/matrix/matrix_i64.inc"

section .bss align=8
a: resb NEBO_MATRIX_SIZE
b: resb NEBO_MATRIX_SIZE
out: resb NEBO_MATRIX_SIZE
bad: resb NEBO_MATRIX_SIZE
adata: resq 64
bdata: resq 64
outdata: resq 64
baddata: resq 64

section .rodata align=8
asrc: dq 1,2,3,4,5,6
bsrc: dq 6,5,4,3,2,1
sentinel: times 64 dq 0x5555555555555555

section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[adata]
 lea rdx,[asrc]
 mov ecx,2
 mov r8d,3
 mov r9d,500
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail1
 lea rdi,[b]
 lea rsi,[bdata]
 lea rdx,[bsrc]
 mov ecx,2
 mov r8d,3
 mov r9d,501
 call nebo_matrix_i64_from_buffer
 test eax,eax
 jnz .fail2
 lea rdi,[out]
 lea rsi,[outdata]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,502
 call nebo_matrix_i64_add
 test eax,eax
 jnz .fail3
 cmp qword [outdata],7
 jne .fail4
 cmp qword [outdata+40],7
 jne .fail5
 lea rdi,[out]
 lea rsi,[outdata]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,503
 call nebo_matrix_i64_subtract
 test eax,eax
 jnz .fail6
 cmp qword [outdata],-5
 jne .fail7
 cmp qword [outdata+40],5
 jne .fail8
 lea rdi,[out]
 lea rsi,[outdata]
 lea rdx,[a]
 lea rcx,[b]
 mov r8d,504
 call nebo_matrix_i64_multiply_elements
 test eax,eax
 jnz .fail9
 cmp qword [outdata+16],12
 jne .fail10
 lea rdi,[out]
 lea rsi,[outdata]
 lea rdx,[a]
 mov rcx,-2
 mov r8d,505
 call nebo_matrix_i64_scale
 test eax,eax
 jnz .fail11
 cmp qword [outdata],-2
 jne .fail12
 cmp qword [outdata+40],-12
 jne .fail13
 ; Overflow is detected before descriptor or payload publication.
 mov rax,0x7fffffffffffffff
 mov [adata],rax
 mov qword [bdata],1
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
 mov r8d,506
 call nebo_matrix_i64_add
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail14
 lea rdi,[bad]
 lea rsi,[sentinel]
 mov ecx,NEBO_MATRIX_SIZE/8
 repe cmpsq
 jne .fail15
 lea rdi,[baddata]
 lea rsi,[sentinel]
 mov ecx,64
 repe cmpsq
 jne .fail16
 xor edi,edi
 jmp .exit
%assign i 1
%rep 16
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
