; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F05 bounded LU with partial pivoting, solve and explicit inverse
bits 64
default rel
%define NEBO_MATRIX_LU_IMPLEMENTATION 1
%include "runtime/matrix/matrix_lu.inc"
section .rodata
align 8
lu_zero dq 0.0
lu_one dq 1.0
lu_abs_mask dq 0x7fffffffffffffff
section .text
global nebo_matrix_lu_f64
global nebo_matrix_determinant_f64
global nebo_matrix_solve_f64
global nebo_matrix_inverse_f64

; Matrix rdi, Float workspace rsi (n*n), pivots rdx (n qwords), threshold xmm0.
; Returns status eax and permutation parity rdx (+1/-1).
nebo_matrix_lu_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 movapd xmm7,xmm0
 test r13,r13
 jz .lu_arg
 test r14,r14
 jz .lu_arg
 ucomisd xmm7,[rel lu_zero]
 jp .lu_domain
 jb .lu_domain
 call nebo_matrix_validate
 test eax,eax
 jnz .lu_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .lu_contract
 mov r15,[r12+NEBO_MATRIX_ROWS]
 test r15,r15
 jz .lu_shape
 cmp r15,32
 ja .lu_shape
 cmp r15,[r12+NEBO_MATRIX_COLS]
 jne .lu_shape
 xor r8d,r8d
.lu_copy_i:
 cmp r8,r15
 jae .lu_copy_done
 mov [r14+r8*8],r8
 xor r9d,r9d
.lu_copy_j:
 cmp r9,r15
 jae .lu_copy_next
 mov rax,r8
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rax,r8
 imul rax,r15
 add rax,r9
 movsd [r13+rax*8],xmm0
 inc r9
 jmp .lu_copy_j
.lu_copy_next: inc r8
 jmp .lu_copy_i
.lu_copy_done:
 xor ebx,ebx
 mov ebp,1
.lu_k:
 cmp rbx,r15
 jae .lu_ok
 xorpd xmm4,xmm4
 mov r10,rbx
 mov r8,rbx
.lu_pivot_scan:
 cmp r8,r15
 jae .lu_pivot_found
 mov rax,r8
 imul rax,r15
 add rax,rbx
 movsd xmm0,[r13+rax*8]
 ucomisd xmm0,xmm0
 jp .lu_domain
 movq rax,xmm0
 and rax,[rel lu_abs_mask]
 movq xmm0,rax
 ucomisd xmm0,xmm4
 jbe .lu_pivot_next
 movapd xmm4,xmm0
 mov r10,r8
.lu_pivot_next: inc r8
 jmp .lu_pivot_scan
.lu_pivot_found:
 ucomisd xmm4,xmm7
 jbe .lu_singular
 cmp r10,rbx
 je .lu_eliminate
 xor r9d,r9d
.lu_swap_cols:
 cmp r9,r15
 jae .lu_swap_pivot
 mov rax,rbx
 imul rax,r15
 add rax,r9
 mov rcx,r10
 imul rcx,r15
 add rcx,r9
 mov rdx,[r13+rax*8]
 mov r8,[r13+rcx*8]
 mov [r13+rax*8],r8
 mov [r13+rcx*8],rdx
 inc r9
 jmp .lu_swap_cols
.lu_swap_pivot:
 mov rax,[r14+rbx*8]
 mov rcx,[r14+r10*8]
 mov [r14+rbx*8],rcx
 mov [r14+r10*8],rax
 neg rbp
.lu_eliminate:
 lea r8,[rbx+1]
.lu_i:
 cmp r8,r15
 jae .lu_next_k
 mov rax,r8
 imul rax,r15
 add rax,rbx
 movsd xmm0,[r13+rax*8]
 mov rcx,rbx
 imul rcx,r15
 add rcx,rbx
 divsd xmm0,[r13+rcx*8]
 movsd [r13+rax*8],xmm0
 lea r9,[rbx+1]
.lu_j:
 cmp r9,r15
 jae .lu_next_i
 mov rax,r8
 imul rax,r15
 add rax,r9
 mov rcx,rbx
 imul rcx,r15
 add rcx,r9
 movsd xmm1,[r13+rcx*8]
 mulsd xmm1,xmm0
 movsd xmm2,[r13+rax*8]
 subsd xmm2,xmm1
 movsd [r13+rax*8],xmm2
 inc r9
 jmp .lu_j
.lu_next_i: inc r8
 jmp .lu_i
.lu_next_k: inc rbx
 jmp .lu_k
.lu_ok:
 movsxd rdx,ebp
 xor eax,eax
.lu_ret:
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.lu_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .lu_ret
.lu_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .lu_ret
.lu_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .lu_ret
.lu_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .lu_ret
.lu_singular: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .lu_ret

; Matrix rdi, work rsi, pivots rdx, threshold xmm0 -> determinant xmm0.
nebo_matrix_determinant_f64:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_lu_f64
 test eax,eax
 jnz .det_ret
 cvtsi2sd xmm0,rdx
 mov rcx,[r12+NEBO_MATRIX_ROWS]
 xor r8d,r8d
.det_loop:
 cmp r8,rcx
 jae .det_ok
 mov rax,r8
 imul rax,rcx
 add rax,r8
 mulsd xmm0,[r13+rax*8]
 inc r8
 jmp .det_loop
.det_ok: xor eax,eax
.det_ret: pop r13
 pop r12
 ret

; A rdi, b rsi, out rdx, LU work rcx, pivots r8, threshold xmm0.
nebo_matrix_solve_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 test r13,r13
 jz .solve_arg
 test r14,r14
 jz .solve_arg
 cmp r13,r14
 je .solve_alias
 mov rsi,r15
 mov rdx,rbp
 call nebo_matrix_lu_f64
 test eax,eax
 jnz .solve_ret
 mov r11,[r12+NEBO_MATRIX_ROWS]
 xor ebx,ebx
.forward_i:
 cmp rbx,r11
 jae .back_start
 mov rax,[rbp+rbx*8]
 movsd xmm0,[r13+rax*8]
 xor ecx,ecx
.forward_j:
 cmp rcx,rbx
 jae .forward_store
 mov rax,rbx
 imul rax,r11
 add rax,rcx
 movsd xmm1,[r15+rax*8]
 mulsd xmm1,[r14+rcx*8]
 subsd xmm0,xmm1
 inc rcx
 jmp .forward_j
.forward_store: movsd [r14+rbx*8],xmm0
 inc rbx
 jmp .forward_i
.back_start:
 mov rbx,r11
.back_i:
 test rbx,rbx
 jz .solve_ok
 dec rbx
 movsd xmm0,[r14+rbx*8]
 lea rcx,[rbx+1]
.back_j:
 cmp rcx,r11
 jae .back_divide
 mov rax,rbx
 imul rax,r11
 add rax,rcx
 movsd xmm1,[r15+rax*8]
 mulsd xmm1,[r14+rcx*8]
 subsd xmm0,xmm1
 inc rcx
 jmp .back_j
.back_divide:
 mov rax,rbx
 imul rax,r11
 add rax,rbx
 divsd xmm0,[r15+rax*8]
 movsd [r14+rbx*8],xmm0
 jmp .back_i
.solve_ok: xor eax,eax
.solve_ret:
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.solve_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .solve_ret
.solve_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .solve_ret

; A rdi, output Matrix rsi, workspace rdx. Layout: LU n*n, piv n,
; b n, x n. threshold xmm0.
nebo_matrix_inverse_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 movsd [rsp],xmm0
 test r14,r14
 jz .inv_arg
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .inv_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .inv_ret
 mov r15,[r12+NEBO_MATRIX_ROWS]
 cmp r15,[r13+NEBO_MATRIX_ROWS]
 jne .inv_shape
 cmp r15,[r13+NEBO_MATRIX_COLS]
 jne .inv_shape
 mov rax,r15
 imul rax,r15
 lea rbp,[r14+rax*8]
 lea r10,[rbp+r15*8]
 lea r11,[r10+r15*8]
 xor ebx,ebx
.inv_col:
 cmp rbx,r15
 jae .inv_ok
 xor ecx,ecx
.inv_basis:
 cmp rcx,r15
 jae .inv_solve
 mov qword [r10+rcx*8],0
 inc rcx
 jmp .inv_basis
.inv_solve:
 mov rax,0x3ff0000000000000
 mov [r10+rbx*8],rax
 mov rdi,r12
 mov rsi,r10
 mov rdx,r11
 mov rcx,r14
 mov r8,rbp
 movsd xmm0,[rsp]
 call nebo_matrix_solve_f64
 test eax,eax
 jnz .inv_ret
 mov rax,r15
 imul rax,r15
 lea rbp,[r14+rax*8]
 lea r10,[rbp+r15*8]
 lea r11,[r10+r15*8]
 xor ecx,ecx
.inv_store:
 cmp rcx,r15
 jae .inv_next
 movsd xmm0,[r11+rcx*8]
 mov rax,rcx
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,rbx
 imul rdx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 inc rcx
 jmp .inv_store
.inv_next: inc rbx
 jmp .inv_col
.inv_ok: xor eax,eax
.inv_ret:
 add rsp,16
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.inv_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .inv_ret
.inv_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .inv_ret
section .note.GNU-stack noalloc noexec nowrite progbits
