bits 64
default rel
%include "runtime/matrix/matrix_lu.inc"
section .data
align 8
ad dq 4.0,7.0,2.0,6.0
singular_data dq 1.0,2.0,2.0,4.0
out_data times 4 dq 0.0
bv dq 1.0,0.0
xv dq 0.0,0.0
threshold dq 1.0e-12
det10 dq 10.0
expected_x dq 0.6,-0.2
expected_inv dq 0.6,-0.7,-0.2,0.4
tol dq 1.0e-12
section .bss
align 8
a resb NEBO_MATRIX_SIZE
s resb NEBO_MATRIX_SIZE
outm resb NEBO_MATRIX_SIZE
work resq 1200
piv resq 32
section .text
global _start
close:
 subsd xmm0,xmm1
 movq rax,xmm0
 btr rax,63
 movq xmm0,rax
 ucomisd xmm0,[rel tol]
 seta al
 movzx eax,al
 ret
_start:
 lea rdi,[a]
 lea rsi,[ad]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,1
 call nebo_matrix_init_owned
 lea rdi,[outm]
 lea rsi,[out_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,2
 call nebo_matrix_init_owned
 lea rdi,[a]
 lea rsi,[work]
 lea rdx,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_lu_f64
 test eax,eax
 jnz .fail1
 cmp rdx,1
 jne .fail2
 lea rdi,[a]
 lea rsi,[work]
 lea rdx,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_determinant_f64
 test eax,eax
 jnz .fail3
 movsd xmm1,[rel det10]
 call close
 test eax,eax
 jnz .fail4
 lea rdi,[a]
 lea rsi,[bv]
 lea rdx,[xv]
 lea rcx,[work]
 lea r8,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_solve_f64
 test eax,eax
 jnz .fail5
 movsd xmm0,[xv]
 movsd xmm1,[expected_x]
 call close
 test eax,eax
 jnz .fail6
 movsd xmm0,[xv+8]
 movsd xmm1,[expected_x+8]
 call close
 test eax,eax
 jnz .fail7
 lea rdi,[a]
 lea rsi,[outm]
 lea rdx,[work]
 movsd xmm0,[rel threshold]
 call nebo_matrix_inverse_f64
 test eax,eax
 jnz .fail8
 xor ecx,ecx
.inv_check:
 movsd xmm0,[out_data+rcx*8]
 movsd xmm1,[expected_inv+rcx*8]
 call close
 test eax,eax
 jnz .fail9
 inc rcx
 cmp rcx,4
 jb .inv_check
 lea rdi,[s]
 lea rsi,[singular_data]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9d,3
 call nebo_matrix_init_owned
 lea rdi,[s]
 lea rsi,[work]
 lea rdx,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_lu_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail10
 lea rdi,[a]
 lea rsi,[bv]
 lea rdx,[bv]
 lea rcx,[work]
 lea r8,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_solve_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail11
 lea rdi,[a]
 lea rsi,[work]
 lea rdx,[piv]
 mov rax,0xbff0000000000000
 movq xmm0,rax
 call nebo_matrix_lu_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail12
 mov rax,0x7ff0000000000000
 mov [bv+8],rax
 mov qword [xv],17
 mov qword [xv+8],29
 lea rdi,[a]
 lea rsi,[bv]
 lea rdx,[xv]
 lea rcx,[work]
 lea r8,[piv]
 movsd xmm0,[rel threshold]
 call nebo_matrix_solve_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail13
 cmp qword [xv],17
 jne .fail14
 cmp qword [xv+8],29
 jne .fail14
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
