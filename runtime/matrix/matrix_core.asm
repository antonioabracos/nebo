; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F02 Matrix construction, indexing and safe read-only views
bits 64
default rel
%define NEBO_MATRIX_CORE_IMPLEMENTATION 1
%include "runtime/matrix/matrix_core.inc"
section .rodata
align 8
matrix_one dq 1.0
section .text
global nebo_matrix_identity_f64
global nebo_matrix_at_f64
global nebo_matrix_set_f64
global nebo_matrix_row_view
global nebo_matrix_column_view
global nebo_matrix_slice_view
global nebo_matrix_transpose_view
global nebo_matrix_contiguous_f64

nebo_matrix_identity_f64:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .identity_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .identity_contract
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .identity_alias
 mov rax,[r12+NEBO_MATRIX_ROWS]
 cmp rax,[r12+NEBO_MATRIX_COLS]
 jne .identity_shape
 mov rcx,[r12+NEBO_MATRIX_CAPACITY]
 mov rdi,[r12+NEBO_MATRIX_DATA]
 xor edx,edx
.identity_zero:
 cmp rdx,rcx
 jae .identity_diag
 mov qword [rdi+rdx*8],0
 inc rdx
 jmp .identity_zero
.identity_diag:
 xor edx,edx
 mov r8,rax
 inc r8
.identity_diag_loop:
 cmp rdx,rax
 jae .identity_ok
 movsd xmm0,[rel matrix_one]
 mov rcx,rdx
 imul rcx,r8
 movsd [rdi+rcx*8],xmm0
 inc rdx
 jmp .identity_diag_loop
.identity_ok: xor eax,eax
.identity_ret: pop r12
 ret
.identity_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .identity_ret
.identity_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .identity_ret
.identity_shape: mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .identity_ret

; desc rdi row rsi col rdx -> xmm0
nebo_matrix_at_f64:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_matrix_validate
 test eax,eax
 jnz .at_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .at_contract
 cmp r13,[r12+NEBO_MATRIX_ROWS]
 jae .at_bounds
 cmp r14,[r12+NEBO_MATRIX_COLS]
 jae .at_bounds
 imul r13,[r12+NEBO_MATRIX_ROW_STRIDE]
 imul r14,[r12+NEBO_MATRIX_COL_STRIDE]
 add r13,r14
 mov rax,[r12+NEBO_MATRIX_DATA]
 movsd xmm0,[rax+r13*8]
 xor eax,eax
.at_ret: pop r14
 pop r13
 pop r12
 ret
.at_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .at_ret
.at_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .at_ret

; desc rdi row rsi col rdx value xmm0
nebo_matrix_set_f64:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_matrix_validate
 test eax,eax
 jnz .set_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .set_contract
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .set_alias
 cmp r13,[r12+NEBO_MATRIX_ROWS]
 jae .set_bounds
 cmp r14,[r12+NEBO_MATRIX_COLS]
 jae .set_bounds
 imul r13,[r12+NEBO_MATRIX_ROW_STRIDE]
 imul r14,[r12+NEBO_MATRIX_COL_STRIDE]
 add r13,r14
 mov rax,[r12+NEBO_MATRIX_DATA]
 movsd [rax+r13*8],xmm0
 xor eax,eax
.set_ret: pop r14
 pop r13
 pop r12
 ret
.set_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .set_ret
.set_alias: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .set_ret
.set_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .set_ret

; Internal view init: rdi out rsi owner, rdx rows rcx cols r8 data,
; r9 rowstride; colstride passed in r10.
matrix_init_view:
 mov rax,NEBO_MATRIX_MAGIC
 mov [rdi+NEBO_MATRIX_MAGIC_OFF],rax
 mov rax,[rsi+NEBO_MATRIX_DTYPE]
 mov [rdi+NEBO_MATRIX_DTYPE],rax
 mov [rdi+NEBO_MATRIX_ROWS],rdx
 mov [rdi+NEBO_MATRIX_COLS],rcx
 mov [rdi+NEBO_MATRIX_ROW_STRIDE],r9
 mov [rdi+NEBO_MATRIX_COL_STRIDE],r10
 mov [rdi+NEBO_MATRIX_DATA],r8
 mov rax,[rsi+NEBO_MATRIX_CAPACITY]
 mov [rdi+NEBO_MATRIX_CAPACITY],rax
 mov rax,[rsi+NEBO_MATRIX_STORAGE_ID]
 mov [rdi+NEBO_MATRIX_STORAGE_ID],rax
 mov rax,[rsi+NEBO_MATRIX_GENERATION]
 mov [rdi+NEBO_MATRIX_GENERATION],rax
 mov qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW|NEBO_MATRIX_FLAG_READONLY
 cmp r10,1
 jne .view_ok
 cmp r9,rcx
 jne .view_ok
 or qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_CONTIGUOUS
.view_ok: xor eax,eax
 ret

; out rdi owner rsi row rdx
nebo_matrix_row_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .row_ret
 cmp r14,[r13+NEBO_MATRIX_ROWS]
 jae .row_bounds
 mov r8,[r13+NEBO_MATRIX_ROW_STRIDE]
 imul r8,r14
 shl r8,3
 add r8,[r13+NEBO_MATRIX_DATA]
 mov rdi,r12
 mov rsi,r13
 mov edx,1
 mov rcx,[r13+NEBO_MATRIX_COLS]
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 call matrix_init_view
.row_ret: pop r14
 pop r13
 pop r12
 ret
.row_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .row_ret

; out rdi owner rsi col rdx
nebo_matrix_column_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .col_ret
 cmp r14,[r13+NEBO_MATRIX_COLS]
 jae .col_bounds
 mov r8,[r13+NEBO_MATRIX_COL_STRIDE]
 imul r8,r14
 shl r8,3
 add r8,[r13+NEBO_MATRIX_DATA]
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r13+NEBO_MATRIX_ROWS]
 mov ecx,1
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 call matrix_init_view
.col_ret: pop r14
 pop r13
 pop r12
 ret
.col_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .col_ret

; out, owner, rowStart, rowCount, colStart, colCount
nebo_matrix_slice_view:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .slice_ret
 mov rax,r14
 add rax,r15
 jc .slice_bounds
 cmp rax,[r13+NEBO_MATRIX_ROWS]
 ja .slice_bounds
 mov rax,r8
 add rax,r9
 jc .slice_bounds
 cmp rax,[r13+NEBO_MATRIX_COLS]
 ja .slice_bounds
 mov rax,r14
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,r8
 imul rdx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 shl rax,3
 add rax,[r13+NEBO_MATRIX_DATA]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 mov r8,rax
 mov rdx,r15
 mov rcx,r9
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rdi,r12
 mov rsi,r13
 call matrix_init_view
.slice_ret: pop r15
 pop r14
 pop r13
 pop r12
 ret
.slice_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .slice_ret

nebo_matrix_transpose_view:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .trans_ret
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r13+NEBO_MATRIX_COLS]
 mov rcx,[r13+NEBO_MATRIX_ROWS]
 mov r8,[r13+NEBO_MATRIX_DATA]
 mov r9,[r13+NEBO_MATRIX_COL_STRIDE]
 mov r10,[r13+NEBO_MATRIX_ROW_STRIDE]
 call matrix_init_view
.trans_ret: pop r13
 pop r12
 ret

; outdesc rdi outdata rsi source rdx storageId rcx
nebo_matrix_contiguous_f64:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r13,r13
 jz .cont_arg
 mov rdi,r14
 call nebo_matrix_validate
 test eax,eax
 jnz .cont_ret
 cmp qword [r14+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .cont_contract
 xor r8d,r8d
.cont_rows:
 cmp r8,[r14+NEBO_MATRIX_ROWS]
 jae .cont_init
 xor r9d,r9d
.cont_cols:
 cmp r9,[r14+NEBO_MATRIX_COLS]
 jae .cont_next_row
 mov rax,r8
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r9
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 movsd xmm0,[rdx+rax*8]
 mov rax,r8
 imul rax,[r14+NEBO_MATRIX_COLS]
 add rax,r9
 movsd [r13+rax*8],xmm0
 inc r9
 jmp .cont_cols
.cont_next_row:
 inc r8
 jmp .cont_rows
.cont_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r14+NEBO_MATRIX_COLS]
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9,r15
 call nebo_matrix_init_owned
.cont_ret: pop r15
 pop r14
 pop r13
 pop r12
 ret
.cont_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .cont_ret
.cont_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .cont_ret
section .note.GNU-stack noalloc noexec nowrite progbits
