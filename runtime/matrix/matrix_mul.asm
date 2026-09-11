; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F04 scalar reference Matrix multiplication
bits 64
default rel
%define NEBO_MATRIX_MUL_IMPLEMENTATION 1
%include "runtime/matrix/matrix_mul.inc"
section .text
global nebo_matrix_matmul_f64
global nebo_matrix_matvec_f64
global nebo_matrix_outer_f64
global nebo_matrix_dot_flattened_f64
global nebo_matrix_batched_matmul_f64

; rdi output desc, rsi A, rdx B
nebo_matrix_matmul_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .mm_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .mm_ret
 mov rdi,r14
 call nebo_matrix_validate
 test eax,eax
 jnz .mm_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .mm_contract
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .mm_contract
 cmp qword [r14+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .mm_contract
 mov rax,[r13+NEBO_MATRIX_COLS]
 cmp rax,[r14+NEBO_MATRIX_ROWS]
 jne .mm_shape
 mov rax,[r13+NEBO_MATRIX_ROWS]
 cmp rax,[r12+NEBO_MATRIX_ROWS]
 jne .mm_shape
 mov rax,[r14+NEBO_MATRIX_COLS]
 cmp rax,[r12+NEBO_MATRIX_COLS]
 jne .mm_shape
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .mm_alias
 ; Reject any byte-range overlap with either input before first write.
 mov r8,[r12+NEBO_MATRIX_DATA]
 mov r9,[r12+NEBO_MATRIX_CAPACITY]
 shl r9,3
 add r9,r8
 mov r10,[r13+NEBO_MATRIX_DATA]
 mov r11,[r13+NEBO_MATRIX_CAPACITY]
 shl r11,3
 add r11,r10
 cmp r8,r11
 jae .mm_check_b
 cmp r10,r9
 jb .mm_alias
.mm_check_b:
 mov r10,[r14+NEBO_MATRIX_DATA]
 mov r11,[r14+NEBO_MATRIX_CAPACITY]
 shl r11,3
 add r11,r10
 cmp r8,r11
 jae .mm_run
 cmp r10,r9
 jb .mm_alias
.mm_run:
 xor ebx,ebx
.mm_i:
 cmp rbx,[r13+NEBO_MATRIX_ROWS]
 jae .mm_ok
 xor ebp,ebp
.mm_j:
 cmp rbp,[r14+NEBO_MATRIX_COLS]
 jae .mm_next_i
 xorpd xmm0,xmm0
 xor r15d,r15d
.mm_k:
 cmp r15,[r13+NEBO_MATRIX_COLS]
 jae .mm_store
 mov rax,rbx
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mov rax,r15
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbp
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mulsd xmm1,[rdx+rax*8]
 addsd xmm0,xmm1
 inc r15
 jmp .mm_k
.mm_store:
 mov rax,rbx
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbp
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 inc rbp
 jmp .mm_j
.mm_next_i: inc rbx
 jmp .mm_i
.mm_ok: xor eax,eax
.mm_ret:
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.mm_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .mm_ret
.mm_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .mm_ret
.mm_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .mm_ret

; out span rdi, Matrix rsi, vector rdx, length rcx
nebo_matrix_matvec_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r12,r12
 jz .mv_arg
 test r14,r14
 jz .mv_arg
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .mv_ret
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .mv_contract
 cmp r15,[r13+NEBO_MATRIX_COLS]
 jne .mv_shape
 ; A raw result span must be disjoint from both input storage spans.
 mov r8,r12
 mov r9,[r13+NEBO_MATRIX_ROWS]
 lea r9,[r8+r9*8]
 mov r10,[r13+NEBO_MATRIX_DATA]
 mov r11,[r13+NEBO_MATRIX_CAPACITY]
 lea r11,[r10+r11*8]
 cmp r8,r11
 jae .mv_vector_alias
 cmp r10,r9
 jb .mv_alias
.mv_vector_alias:
 lea r11,[r14+r15*8]
 cmp r8,r11
 jae .mv_disjoint
 cmp r14,r9
 jb .mv_alias
.mv_disjoint:
 xor ebx,ebx
.mv_i:
 cmp rbx,[r13+NEBO_MATRIX_ROWS]
 jae .mv_ok
 xorpd xmm0,xmm0
 xor ecx,ecx
.mv_k:
 cmp rcx,r15
 jae .mv_store
 mov rax,rbx
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,rcx
 imul rdx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[r13+NEBO_MATRIX_DATA]
 movsd xmm1,[rdx+rax*8]
 mulsd xmm1,[r14+rcx*8]
 addsd xmm0,xmm1
 inc rcx
 jmp .mv_k
.mv_store: movsd [r12+rbx*8],xmm0
 inc rbx
 jmp .mv_i
.mv_ok: xor eax,eax
.mv_ret:
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.mv_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .mv_ret
.mv_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .mv_ret

.mv_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .mv_ret
.mv_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .mv_ret

; output desc rdi, x rsi nx rdx, y rcx ny r8
nebo_matrix_outer_f64:
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
 jz .outer_arg
 test r15,r15
 jz .outer_arg
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .outer_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .outer_contract
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .outer_alias
 cmp r14,[r12+NEBO_MATRIX_ROWS]
 jne .outer_shape
 cmp rbp,[r12+NEBO_MATRIX_COLS]
 jne .outer_shape
 mov r8,[r12+NEBO_MATRIX_DATA]
 mov r9,[r12+NEBO_MATRIX_CAPACITY]
 lea r9,[r8+r9*8]
 lea r11,[r13+r14*8]
 cmp r8,r11
 jae .outer_second_alias
 cmp r13,r9
 jb .outer_alias
.outer_second_alias:
 lea r11,[r15+rbp*8]
 cmp r8,r11
 jae .outer_disjoint
 cmp r15,r9
 jb .outer_alias
.outer_disjoint:
 xor ebx,ebx
.outer_i:
 cmp rbx,r14
 jae .outer_ok
 xor ecx,ecx
.outer_j:
 cmp rcx,rbp
 jae .outer_next
 movsd xmm0,[r13+rbx*8]
 mulsd xmm0,[r15+rcx*8]
 mov rax,rbx
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,rcx
 imul rdx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 movsd [rdx+rax*8],xmm0
 inc rcx
 jmp .outer_j
.outer_next: inc rbx
 jmp .outer_i
.outer_ok: xor eax,eax
.outer_ret:
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.outer_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .outer_ret
.outer_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .outer_ret

.outer_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .outer_ret
.outer_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .outer_ret

; A rdi, B rsi -> flattened dot in xmm0. Logical shape equality is required.
nebo_matrix_dot_flattened_f64:
 push r12
 push r13
 push rbx
 push rbp
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .dot_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .dot_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .dot_contract
 cmp qword [r13+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .dot_contract
 mov rax,[r12+NEBO_MATRIX_ROWS]
 cmp rax,[r13+NEBO_MATRIX_ROWS]
 jne .dot_shape
 mov rcx,[r12+NEBO_MATRIX_COLS]
 cmp rcx,[r13+NEBO_MATRIX_COLS]
 jne .dot_shape
 xorpd xmm0,xmm0
 xor ebx,ebx
.dot_rows:
 cmp rbx,rax
 jae .dot_ok
 xor ebp,ebp
.dot_columns:
 cmp rbp,rcx
 jae .dot_next_row
 mov rdx,rbx
 imul rdx,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov r8,rbp
 imul r8,[r12+NEBO_MATRIX_COL_STRIDE]
 add rdx,r8
 mov r8,[r12+NEBO_MATRIX_DATA]
 movsd xmm1,[r8+rdx*8]
 mov rdx,rbx
 imul rdx,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r8,rbp
 imul r8,[r13+NEBO_MATRIX_COL_STRIDE]
 add rdx,r8
 mov r8,[r13+NEBO_MATRIX_DATA]
 mulsd xmm1,[r8+rdx*8]
 addsd xmm0,xmm1
 inc rbp
 jmp .dot_columns
.dot_next_row:
 inc rbx
 jmp .dot_rows
.dot_ok:
 xor eax,eax
.dot_ret:
 add rsp,8
 pop rbp
 pop rbx
 pop r13
 pop r12
 ret
.dot_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .dot_ret
.dot_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .dot_ret

; Reserved until the Tensor group. Valid Matrix descriptors fail closed with
; the public unsupported status and the output is never touched.
nebo_matrix_batched_matmul_f64:
 push r12
 push r13
 sub rsp,8
 mov r12,rsi
 mov r13,rdx
 call nebo_matrix_validate
 test eax,eax
 jnz .batch_ret
 mov rdi,r12
 call nebo_matrix_validate
 test eax,eax
 jnz .batch_ret
 mov rdi,r13
 call nebo_matrix_validate
 test eax,eax
 jnz .batch_ret
 mov eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
.batch_ret:
 add rsp,8
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
