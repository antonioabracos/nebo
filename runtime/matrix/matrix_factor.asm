; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F06 bounded QR, Cholesky and condition estimate
bits 64
default rel
%define NEBO_MATRIX_FACTOR_IMPLEMENTATION 1
%include "runtime/matrix/matrix_factor.inc"
%include "runtime/matrix/matrix_lu.inc"
section .rodata
align 8
factor_zero dq 0.0
factor_abs_mask dq 0x7fffffffffffffff
section .text
global nebo_matrix_qr_f64
global nebo_matrix_cholesky_f64
global nebo_matrix_condition_estimate_f64

; A rdi, Q rsi (m*n), R rdx (n*n), threshold xmm0.
nebo_matrix_qr_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,40                 ; System V alignment before native owner calls.
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 movsd [rsp],xmm0
 ucomisd xmm0,[rel factor_zero]
 jp .qr_domain
 jb .qr_domain
 movq rax,xmm0
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .qr_domain
 mov rdi,r12
 call nebo_matrix_validate_finite_f64
 test eax,eax
 jnz .qr_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .qr_ret
 mov rdi,r14
 call nebo_matrix_validate
 test eax,eax
 jnz .qr_ret
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .qr_contract
 cmp qword [r14+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .qr_contract
 test qword [r13+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .qr_alias
 test qword [r14+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .qr_alias
 mov rdi,r12
 mov rsi,r13
 call factor_require_disjoint
 test eax,eax
 jnz .qr_ret
 mov rdi,r12
 mov rsi,r14
 call factor_require_disjoint
 test eax,eax
 jnz .qr_ret
 mov rdi,r13
 mov rsi,r14
 call factor_require_disjoint
 test eax,eax
 jnz .qr_ret
 mov r15,[r12+NEBO_MATRIX_ROWS]
 mov rbp,[r12+NEBO_MATRIX_COLS]
 test r15,r15
 jz .qr_shape
 test rbp,rbp
 jz .qr_shape
 cmp r15,32
 ja .qr_shape
 cmp rbp,32
 ja .qr_shape
 cmp r15,rbp
 jb .qr_shape
 cmp r15,[r13+NEBO_MATRIX_ROWS]
 jne .qr_shape
 cmp rbp,[r13+NEBO_MATRIX_COLS]
 jne .qr_shape
 cmp rbp,[r14+NEBO_MATRIX_ROWS]
 jne .qr_shape
 cmp rbp,[r14+NEBO_MATRIX_COLS]
 jne .qr_shape
 mov rcx,[r14+NEBO_MATRIX_CAPACITY]
 mov rdi,[r14+NEBO_MATRIX_DATA]
 xor eax,eax
.qr_zero_r:
 cmp rax,rcx
 jae .qr_columns
 mov qword [rdi+rax*8],0
 inc rax
 jmp .qr_zero_r
.qr_columns:
 xor ebx,ebx
.qr_j:
 cmp rbx,rbp
 jae .qr_ok
 xor r8d,r8d
.qr_copy:
 cmp r8,r15
 jae .qr_project_start
 mov rax,r8
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 inc r8
 jmp .qr_copy
.qr_project_start:
 xor r9d,r9d
.qr_k:
 cmp r9,rbx
 jae .qr_norm
 xorpd xmm0,xmm0
 xor r8d,r8d
.qr_dot:
 cmp r8,r15
 jae .qr_dot_done
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mulsd xmm1,[rdx+rax*8]
 addsd xmm0,xmm1
 inc r8
 jmp .qr_dot
.qr_dot_done:
 movq rax,xmm0
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .qr_domain
 movsd [rsp+8],xmm0
 mov rax,r9
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 xor r8d,r8d
.qr_subtract:
 cmp r8,r15
 jae .qr_next_k
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mulsd xmm1,[rsp+8]
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 movsd xmm0,[rdx+rax*8]
 subsd xmm0,xmm1
 movsd [rdx+rax*8],xmm0
 inc r8
 jmp .qr_subtract
.qr_next_k: inc r9
 jmp .qr_k
.qr_norm:
 xorpd xmm0,xmm0
 xor r8d,r8d
.qr_norm_loop:
 cmp r8,r15
 jae .qr_norm_done
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mulsd xmm1,xmm1
 addsd xmm0,xmm1
 inc r8
 jmp .qr_norm_loop
.qr_norm_done:
 sqrtsd xmm0,xmm0
 movq rax,xmm0
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .qr_domain
 ucomisd xmm0,[rsp]
 jbe .qr_domain
 movsd [rsp+8],xmm0
 mov rax,rbx
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 xor r8d,r8d
.qr_normalize:
 cmp r8,r15
 jae .qr_next_j
 mov rax,r8
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 divsd xmm0,[rsp+8]
 movsd [rdx+rax*8],xmm0
 inc r8
 jmp .qr_normalize
.qr_next_j: inc rbx
 jmp .qr_j
.qr_ok: xor eax,eax
.qr_ret:
 add rsp,40
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.qr_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .qr_ret
.qr_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .qr_ret
.qr_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .qr_ret
.qr_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .qr_ret

; Validated Matrix descriptors: reject storage overlap before output writes.
; Strided descriptors retain their complete backing capacity, so this also
; rejects overlapping views rather than merely comparing first-element ptrs.
factor_require_disjoint:
 mov r8,[rdi+NEBO_MATRIX_DATA]
 mov r9,[rdi+NEBO_MATRIX_CAPACITY]
 mov r10,[rsi+NEBO_MATRIX_DATA]
 mov r11,[rsi+NEBO_MATRIX_CAPACITY]
 test r9,r9
 jz .ok
 test r11,r11
 jz .ok
 mov rax,r9
 or rax,r11
 shr rax,61
 jnz .alias
 shl r9,3
 add r9,r8
 jc .alias
 shl r11,3
 add r11,r10
 jc .alias
 cmp r8,r11
 jae .ok
 cmp r10,r9
 jb .alias
.ok:
 xor eax,eax
 ret
.alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret

; A rdi, lower output rsi, threshold xmm0.
nebo_matrix_cholesky_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 movsd [rsp],xmm0
 ucomisd xmm0,[rel factor_zero]
 jp .chol_domain
 jb .chol_domain
 movq rax,xmm0
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .chol_domain
 mov rdi,r12
 call nebo_matrix_validate_finite_f64
 test eax,eax
 jnz .chol_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .chol_ret
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .chol_contract
 test qword [r13+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .chol_alias
 mov rdi,r12
 mov rsi,r13
 call factor_require_disjoint
 test eax,eax
 jnz .chol_ret
 mov r14,[r12+NEBO_MATRIX_ROWS]
 test r14,r14
 jz .chol_shape
 cmp r14,32
 ja .chol_shape
 cmp r14,[r12+NEBO_MATRIX_COLS]
 jne .chol_shape
 cmp r14,[r13+NEBO_MATRIX_ROWS]
 jne .chol_shape
 cmp r14,[r13+NEBO_MATRIX_COLS]
 jne .chol_shape
 ; SPD requires symmetry, not merely a positive lower triangle. Compare
 ; mirrored logical elements using the caller's explicit absolute threshold.
 xor r8d,r8d
.chol_symmetry_row:
 cmp r8,r14
 jae .chol_symmetry_done
 lea r9,[r8+1]
.chol_symmetry_column:
 cmp r9,r14
 jae .chol_symmetry_next
 mov rax,r8
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rax,r9
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r8
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 subsd xmm0,[rdx+rax*8]
 movq rax,xmm0
 btr rax,63
 movq xmm0,rax
 ucomisd xmm0,[rsp]
 ja .chol_domain
 inc r9
 jmp .chol_symmetry_column
.chol_symmetry_next:
 inc r8
 jmp .chol_symmetry_row
.chol_symmetry_done:
 mov rcx,[r13+NEBO_MATRIX_CAPACITY]
 mov rdi,[r13+NEBO_MATRIX_DATA]
 xor eax,eax
.chol_zero:
 cmp rax,rcx
 jae .chol_i_start
 mov qword [rdi+rax*8],0
 inc rax
 jmp .chol_zero
.chol_i_start:
 xor ebx,ebx
.chol_i:
 cmp rbx,r14
 jae .chol_ok
 xor r15d,r15d
.chol_j:
 cmp r15,rbx
 ja .chol_next_i
 ; sum = A[i,j]
 mov rax,rbx
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 xor r8d,r8d
.chol_k:
 cmp r8,r15
 jae .chol_finish
 mov rax,rbx
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r8
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mov rax,r15
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r8
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mulsd xmm1,[rdx+rax*8]
 subsd xmm0,xmm1
 inc r8
 jmp .chol_k
.chol_finish:
 cmp rbx,r15
 jne .chol_offdiag
 ucomisd xmm0,[rsp]
 jbe .chol_domain
 sqrtsd xmm0,xmm0
 jmp .chol_store
.chol_offdiag:
 mov rax,r15
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 divsd xmm0,[rdx+rax*8]
.chol_store:
 movq rax,xmm0
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .chol_domain
 mov rax,rbx
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 inc r15
 jmp .chol_j
.chol_next_i: inc rbx
 jmp .chol_i
.chol_ok: xor eax,eax
.chol_ret:
 add rsp,16
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.chol_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .chol_ret
.chol_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .chol_ret
.chol_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .chol_ret
.chol_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .chol_ret

matrix_one_norm:
 mov r10,[rdi+NEBO_MATRIX_ROWS]
 mov r11,[rdi+NEBO_MATRIX_COLS]
 xorpd xmm0,xmm0
 xor r9d,r9d
.norm_col:
 cmp r9,r11
 jae .norm_ret
 xorpd xmm1,xmm1
 xor r8d,r8d
.norm_row:
 cmp r8,r10
 jae .norm_compare
 mov rax,r8
 imul rax,[rdi+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[rdi+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[rdi+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 and rax,[rel factor_abs_mask]
 movq xmm2,rax
 addsd xmm1,xmm2
 inc r8
 jmp .norm_row
.norm_compare: maxsd xmm0,xmm1
 inc r9
 jmp .norm_col
.norm_ret: ret

; A rdi, explicit inverse output rsi, workspace rdx, threshold xmm0.
nebo_matrix_condition_estimate_f64:
 push r12
 push r13
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 movsd [rsp],xmm0
 call nebo_matrix_inverse_f64
 test eax,eax
 jnz .cond_ret
 mov rdi,r12
 call matrix_one_norm
 movsd [rsp+8],xmm0
 mov rdi,r13
 call matrix_one_norm
 mulsd xmm0,[rsp+8]
 xor eax,eax
.cond_ret:
 add rsp,16
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
