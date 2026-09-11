bits 64
default rel
%include "runtime/matrix/matrix_factor.inc"
section .data
align 8
qr_a_data dq 1.0,1.0,1.0,-1.0,1.0,1.0
q_data times 6 dq 0.0
r_data times 4 dq 0.0
spd_data dq 4.0,2.0,2.0,3.0
bad_data dq 1.0,2.0,2.0,1.0
l_data times 4 dq 0.0
diag_data dq 2.0,0.0,0.0,1.0
inv_data times 4 dq 0.0
threshold dq 1.0e-12
one dq 1.0
zero dq 0.0
two dq 2.0
sqrt2 dq 1.4142135623730951
tol dq 1.0e-12
section .bss
align 8
qa resb NEBO_MATRIX_SIZE
qm resb NEBO_MATRIX_SIZE
rm resb NEBO_MATRIX_SIZE
spd resb NEBO_MATRIX_SIZE
bad resb NEBO_MATRIX_SIZE
lm resb NEBO_MATRIX_SIZE
diag resb NEBO_MATRIX_SIZE
invm resb NEBO_MATRIX_SIZE
work resq 1200
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
init_desc:
 ; caller supplies descriptor rdi data rsi rows rdx cols rcx id r9
 mov r8d,NEBO_MATRIX_DTYPE_F64
 call nebo_matrix_init_owned
 ret
_start:
 lea rdi,[qa]
 lea rsi,[qr_a_data]
 mov edx,3
 mov ecx,2
 mov r9d,1
 call init_desc
 lea rdi,[qm]
 lea rsi,[q_data]
 mov edx,3
 mov ecx,2
 mov r9d,2
 call init_desc
 lea rdi,[rm]
 lea rsi,[r_data]
 mov edx,2
 mov ecx,2
 mov r9d,3
 call init_desc
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[rm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 test eax,eax
 jnz .fail1
 ; Q columns unit and orthogonal.
 movsd xmm0,[q_data]
 mulsd xmm0,xmm0
 movsd xmm1,[q_data+16]
 mulsd xmm1,xmm1
 addsd xmm0,xmm1
 movsd xmm1,[q_data+32]
 mulsd xmm1,xmm1
 addsd xmm0,xmm1
 movsd xmm1,[rel one]
 call close
 test eax,eax
 jnz .fail2
 movsd xmm0,[q_data]
 mulsd xmm0,[q_data+8]
 movsd xmm1,[q_data+16]
 mulsd xmm1,[q_data+24]
 addsd xmm0,xmm1
 movsd xmm1,[q_data+32]
 mulsd xmm1,[q_data+40]
 addsd xmm0,xmm1
 movsd xmm1,[rel zero]
 call close
 test eax,eax
 jnz .fail3
 lea rdi,[spd]
 lea rsi,[spd_data]
 mov edx,2
 mov ecx,2
 mov r9d,4
 call init_desc
 lea rdi,[lm]
 lea rsi,[l_data]
 mov edx,2
 mov ecx,2
 mov r9d,5
 call init_desc
 lea rdi,[spd]
 lea rsi,[lm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 test eax,eax
 jnz .fail4
 movsd xmm0,[l_data]
 ucomisd xmm0,[rel two]
 jne .fail5
 movsd xmm0,[l_data+16]
 ucomisd xmm0,[rel one]
 jne .fail6
 movsd xmm0,[l_data+24]
 movsd xmm1,[rel sqrt2]
 call close
 test eax,eax
 jnz .fail7
 lea rdi,[bad]
 lea rsi,[bad_data]
 mov edx,2
 mov ecx,2
 mov r9d,6
 call init_desc
 lea rdi,[bad]
 lea rsi,[lm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail8
 lea rdi,[diag]
 lea rsi,[diag_data]
 mov edx,2
 mov ecx,2
 mov r9d,7
 call init_desc
 lea rdi,[invm]
 lea rsi,[inv_data]
 mov edx,2
 mov ecx,2
 mov r9d,8
 call init_desc
 lea rdi,[diag]
 lea rsi,[invm]
 lea rdx,[work]
 movsd xmm0,[rel threshold]
 call nebo_matrix_condition_estimate_f64
 test eax,eax
 jnz .fail9
 movsd xmm1,[rel two]
 call close
 test eax,eax
 jnz .fail10
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[rm]
 mov rax,0xbff0000000000000
 movq xmm0,rax
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail11
 ; Asymmetric input must fail before the caller's output is modified.
 mov rax,0x4022000000000000 ; 9.0, unequal to mirrored 2.0
 mov [spd_data+8],rax
 mov qword [l_data],177
 lea rdi,[spd]
 lea rsi,[lm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail12
 cmp qword [l_data],177
 jne .fail13
 ; A nonfinite input is rejected by the shared algebra-domain owner.
 mov rax,0x7ff0000000000000
 mov [diag_data],rax
 lea rdi,[diag]
 lea rsi,[invm]
 lea rdx,[work]
 movsd xmm0,[rel threshold]
 call nebo_matrix_condition_estimate_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail14
 ; QR rejects invalid descriptor/type/alias/threshold before any output write.
 mov qword [q_data],177
 mov qword [r_data],179
 lea rdi,[qa]
 lea rsi,[qm]
 xor edx,edx
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail15
 mov qword [rm+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[rm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail16
 mov qword [rm+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 or qword [qm+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[rm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail17
 and qword [qm+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_READONLY
 lea rdi,[qa]
 lea rsi,[qa]
 lea rdx,[rm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail18
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[qm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail19
 lea rdi,[qa]
 lea rsi,[qm]
 lea rdx,[rm]
 mov rax,0x7ff0000000000000
 movq xmm0,rax
 call nebo_matrix_qr_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail20
 cmp qword [q_data],177
 jne .fail21
 cmp qword [r_data],179
 jne .fail22
 ; Cholesky has the same writable/disjoint Float output policy.
 mov rax,0x4000000000000000
 mov [diag_data],rax
 lea rdi,[diag]
 lea rsi,[diag]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail23
 mov qword [invm+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 lea rdi,[diag]
 lea rsi,[invm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail24
 mov qword [invm+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 or qword [invm+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 lea rdi,[diag]
 lea rsi,[invm]
 movsd xmm0,[rel threshold]
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail25
 and qword [invm+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_READONLY
 lea rdi,[diag]
 lea rsi,[invm]
 mov rax,0x7ff0000000000000
 movq xmm0,rax
 call nebo_matrix_cholesky_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail26
 xor edi,edi
 jmp .exit
%assign i 1
%rep 26
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
