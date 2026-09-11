; FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-F02 Matrix construction, indexing and safe read-only views
bits 64
default rel
%define NEBO_MATRIX_CORE_IMPLEMENTATION 1
%include "runtime/matrix/matrix_core.inc"
section .rodata
align 8
matrix_one dq 1.0
section .text
global nebo_matrix_zeros_f64
global nebo_matrix_filled_f64
global nebo_matrix_from_rows_f64
global nebo_matrix_from_buffer_f64
global nebo_matrix_rows
global nebo_matrix_columns
global nebo_matrix_layout
global nebo_matrix_identity_f64
global nebo_matrix_at_f64
global nebo_matrix_get_f64
global nebo_matrix_set_f64
global nebo_matrix_row_view
global nebo_matrix_column_view
global nebo_matrix_slice_view
global nebo_matrix_transpose_view
global nebo_matrix_contiguous_f64
global nebo_matrix_trace_f64
global nebo_matrix_is_square

; desc rdi, storage rsi, rows rdx, columns rcx, storage-id r8.
nebo_matrix_zeros_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9,rbx
 call nebo_matrix_init_owned
 test eax,eax
 jnz .zeros_ret
 mov rcx,r14
 imul rcx,r15
 xor edx,edx
.zeros_loop:
 cmp rdx,rcx
 jae .zeros_ok
 mov qword [r13+rdx*8],0
 inc rdx
 jmp .zeros_loop
.zeros_ok:
 xor eax,eax
.zeros_ret:
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; desc rdi, storage rsi, rows rdx, columns rcx, storage-id r8, fill xmm0.
nebo_matrix_filled_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 movq rbx,xmm0
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9,rbp
 call nebo_matrix_init_owned
 test eax,eax
 jnz .filled_ret
 mov rcx,r14
 imul rcx,r15
 xor edx,edx
.filled_loop:
 cmp rdx,rcx
 jae .filled_ok
 mov [r13+rdx*8],rbx
 inc rdx
 jmp .filled_loop
.filled_ok:
 xor eax,eax
.filled_ret:
 add rsp,8
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; desc rdi, destination storage rsi, source rdx, rows rcx, columns r8,
; storage-id r9.  The bounded public profile copies and owns row-major data.
nebo_matrix_from_rows_f64:
nebo_matrix_from_buffer_f64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 push rbp
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rbp,r9
 test r14,r14
 jnz .copy_source_ready
 mov rax,r15
 imul rax,rbx
 test rax,rax
 jnz .copy_argument
.copy_source_ready:
 mov rdx,r15
 mov rcx,rbx
 mov r8d,NEBO_MATRIX_DTYPE_F64
 mov r9,rbp
 call nebo_matrix_init_owned
 test eax,eax
 jnz .copy_ret
 mov rcx,r15
 imul rcx,rbx
 xor edx,edx
.copy_loop:
 cmp rdx,rcx
 jae .copy_ok
 mov rax,[r14+rdx*8]
 mov [r13+rdx*8],rax
 inc rdx
 jmp .copy_loop
.copy_ok:
 xor eax,eax
.copy_ret:
 add rsp,8
 pop rbp
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.copy_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .copy_ret

nebo_matrix_rows:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .rows_ret
 mov rdx,[r12+NEBO_MATRIX_ROWS]
.rows_ret:
 pop r12
 ret

nebo_matrix_columns:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .columns_ret
 mov rdx,[r12+NEBO_MATRIX_COLS]
.columns_ret:
 pop r12
 ret

; Returns row-major=1, column-major=2 or strided=3 in rdx.
nebo_matrix_layout:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .layout_ret
 mov rax,[r12+NEBO_MATRIX_COLS]
 cmp [r12+NEBO_MATRIX_ROW_STRIDE],rax
 jne .layout_column
 cmp qword [r12+NEBO_MATRIX_COL_STRIDE],1
 jne .layout_strided
 mov edx,1
 jmp .layout_ok
.layout_column:
 cmp qword [r12+NEBO_MATRIX_ROW_STRIDE],1
 jne .layout_strided
 mov rax,[r12+NEBO_MATRIX_ROWS]
 cmp [r12+NEBO_MATRIX_COL_STRIDE],rax
 jne .layout_strided
 mov edx,2
 jmp .layout_ok
.layout_strided:
 mov edx,3
.layout_ok:
 xor eax,eax
.layout_ret:
 pop r12
 ret

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

; Safe get shares the checked access contract and status channel.
nebo_matrix_get_f64:
 jmp nebo_matrix_at_f64

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

nebo_matrix_trace_f64:
 push r12
 push rbx
 sub rsp,8
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .trace_ret
 cmp qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_F64
 jne .trace_contract
 mov rcx,[r12+NEBO_MATRIX_ROWS]
 cmp rcx,[r12+NEBO_MATRIX_COLS]
 jne .trace_shape
 xorpd xmm0,xmm0
 xor ebx,ebx
.trace_loop:
 cmp rbx,rcx
 jae .trace_ok
 mov rax,rbx
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rdx,rbx
 imul rdx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rdx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 addsd xmm0,[rdx+rax*8]
 inc rbx
 jmp .trace_loop
.trace_ok:
 xor eax,eax
.trace_ret:
 add rsp,8
 pop rbx
 pop r12
 ret
.trace_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .trace_ret
.trace_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .trace_ret

nebo_matrix_is_square:
 push r12
 mov r12,rdi
 call nebo_matrix_validate
 test eax,eax
 jnz .square_ret
 xor edx,edx
 mov rcx,[r12+NEBO_MATRIX_ROWS]
 cmp rcx,[r12+NEBO_MATRIX_COLS]
 sete dl
.square_ret:
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
