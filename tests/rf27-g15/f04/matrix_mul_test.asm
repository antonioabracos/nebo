bits 64
default rel
%include "runtime/matrix/matrix_mul.inc"
section .data
align 8
ad dq 1.0,2.0,3.0,4.0,5.0,6.0
bd dq 7.0,8.0,9.0,10.0,11.0,12.0
od times 4 dq 0.0
vd dq 1.0,2.0,3.0
vo times 2 dq 0.0
x dq 1.0,2.0
y dq 3.0,4.0
expected dq 58.0,64.0,139.0,154.0
mvexpected dq 14.0,32.0
outerexpected dq 3.0,4.0,6.0,8.0
section .bss
align 8
a resb NEBO_MATRIX_SIZE
b resb NEBO_MATRIX_SIZE
o resb NEBO_MATRIX_SIZE
outer resb NEBO_MATRIX_SIZE
section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[ad]
 mov edx,2
 mov ecx,3
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 lea rdi,[b]
 lea rsi,[bd]
 mov edx,3
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,2
 call nebo_matrix_init_owned
 lea rdi,[o]
 lea rsi,[od]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,3
 call nebo_matrix_init_owned
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[b]
 call nebo_matrix_matmul_f64
 test eax,eax
 jnz .fail1
 xor ecx,ecx
.check_mm:
 movsd xmm0,[od+rcx*8]
 ucomisd xmm0,[expected+rcx*8]
 jne .fail2
 inc rcx
 cmp rcx,4
 jb .check_mm
 lea rdi,[vo]
 lea rsi,[a]
 lea rdx,[vd]
 mov ecx,3
 call nebo_matrix_matvec_f64
 test eax,eax
 jnz .fail3
 movsd xmm0,[vo]
 ucomisd xmm0,[mvexpected]
 jne .fail4
 movsd xmm0,[vo+8]
 ucomisd xmm0,[mvexpected+8]
 jne .fail5
 lea rdi,[outer]
 lea rsi,[od]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,4
 call nebo_matrix_init_owned
 lea rdi,[outer]
 lea rsi,[x]
 mov edx,2
 lea rcx,[y]
 mov r8d,2
 call nebo_matrix_outer_f64
 test eax,eax
 jnz .fail6
 xor ecx,ecx
.check_outer:
 movsd xmm0,[od+rcx*8]
 ucomisd xmm0,[outerexpected+rcx*8]
 jne .fail7
 inc rcx
 cmp rcx,4
 jb .check_outer
 lea rdi,[a]
 lea rsi,[a]
 lea rdx,[b]
 call nebo_matrix_matmul_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail8
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[a]
 call nebo_matrix_matmul_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail9
 ; Reinitialize A as 2x2 over output storage to prove overlap rejection.
 lea rdi,[a]
 lea rsi,[od]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,5
 call nebo_matrix_init_owned
 lea rdi,[o]
 lea rsi,[a]
 lea rdx,[a]
 call nebo_matrix_matmul_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail10
 lea rdi,[vo]
 lea rsi,[a]
 lea rdx,[vd]
 mov ecx,3
 call nebo_matrix_matvec_f64
 cmp eax,NEBO_NUMERIC_ERROR_SHAPE
 jne .fail11
 mov qword [a+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 lea rdi,[vo]
 lea rsi,[a]
 lea rdx,[vd]
 mov ecx,2
 call nebo_matrix_matvec_f64
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail12
 mov qword [a+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 lea rdi,[od]
 lea rsi,[a]
 lea rdx,[vd]
 mov ecx,2
 call nebo_matrix_matvec_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail13
 lea rdi,[vd]
 lea rsi,[a]
 lea rdx,[vd]
 mov ecx,2
 call nebo_matrix_matvec_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail14
 or qword [outer+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 lea rdi,[outer]
 lea rsi,[x]
 mov edx,2
 lea rcx,[y]
 mov r8d,2
 call nebo_matrix_outer_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail15
 and qword [outer+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_READONLY
 mov qword [outer+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 lea rdi,[outer]
 lea rsi,[x]
 mov edx,2
 lea rcx,[y]
 mov r8d,2
 call nebo_matrix_outer_f64
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail16
 mov qword [outer+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 lea rax,[x]
 mov [outer+NEBO_MATRIX_DATA],rax
 lea rdi,[outer]
 lea rsi,[x]
 mov edx,2
 lea rcx,[y]
 mov r8d,2
 call nebo_matrix_outer_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail17
 movsd xmm0,[od]
 ucomisd xmm0,[outerexpected]
 jne .fail18
 movsd xmm0,[vo]
 ucomisd xmm0,[mvexpected]
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
