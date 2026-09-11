; ABI bridge only: canonical Matrix constructors/accessors own all storage
; initialization, bounds, stride and numeric behavior.
bits 64
default rel
%include "runtime/matrix/matrix_core.inc"
%include "runtime/matrix/matrix_i64.inc"
%include "runtime/matrix/matrix_ops.inc"
%include "runtime/matrix/matrix_mul.inc"
%include "runtime/matrix/matrix_lu.inc"
%include "runtime/matrix/matrix_factor.inc"
section .text
global nebo_matrix_public_borrow
global nebo_matrix_public_sret
; Public descriptors include private root provenance after the native 88 bytes.
; Snapshot only that descriptor. The source payload remains a readonly borrow.
nebo_matrix_public_borrow:
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsi
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov ecx,12
 rep movsq
 and qword [r12+NEBO_MATRIX_FLAGS],~NEBO_MATRIX_FLAG_OWNED
 or qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW|NEBO_MATRIX_FLAG_READONLY
 mov rdx,r12
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; Caller-owned destination, source, exact native dtype. Reuse the canonical
; contiguous/copy owner including Int view provenance and checked bounds.
nebo_matrix_public_sret:
 push rbx
 sub rsp,64
 mov rbx,rdi
 mov [rsp],rsi
 mov rsi,rdx
 mov rdx,rbx
 mov rcx,rsp
 lea r8,[rbx+96]
 mov edi,10
 call nebo_matrix_public_dispatch
 add rsp,64
 pop rbx
 ret

global nebo_matrix_public_dispatch
; op RDI, dtype RSI, result descriptor RDX, ordered argument frame RCX,
; owned result payload R8. Success: EAX=0 and material value/bits in RDX.
nebo_matrix_public_dispatch:
 cmp rdi,1
 jb .argument
 cmp rdi,43
 ja .argument
 cmp rsi,1
 jb .argument
 cmp rsi,2
 ja .argument
 test rdx,rdx
 jz .argument
 test rcx,rcx
 jz .argument
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,r8
 mov r15,rcx
 cmp ebx,41
 jae .decomposition_member
 cmp ebx,39
 jae .decomposition
 cmp ebx,38
 je .matmul_into
 cmp ebx,35
 je .matvec
 cmp ebx,36
 je .outer
 cmp ebx,37
 je .matvec
 cmp ebx,31
 jae .axis
 cmp ebx,30
 je .map
 cmp ebx,29
 je .slice
 cmp ebx,24
 je .dot_flattened
 cmp ebx,25
 jae .algebra
 cmp ebx,22
 je .from_buffer
 cmp ebx,23
 je .sum
 cmp ebx,21
 je .safe_get
 cmp ebx,14
 jae .operation
 cmp ebx,13
 je .from_rows
 cmp ebx,2
 ja .method
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15+8]
 mov rcx,[r15+16]
 mov r8,r13                    ; private owned descriptor identity
 cmp ebx,2
 je .filled
 cmp r12d,1
 jne .zeros_float
 call nebo_matrix_i64_zeros
 jmp .owned_result
.zeros_float:
 call nebo_matrix_zeros_f64
 jmp .owned_result
.filled:
 cmp r12d,1
 jne .filled_float
 mov r9,r13
 mov r8,[r15+32]
 call nebo_matrix_i64_filled
 jmp .owned_result
.filled_float:
 movq xmm0,[r15+32]
 call nebo_matrix_filled_f64
.owned_result:
 mov [r13+NEBO_MATRIX_SIZE],r13 ; private root-owner provenance, outside ABI
 mov rdx,r13
 jmp .done
.from_rows:
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15+32]
 mov rcx,[r15+8]
 mov r8,[r15+16]
 mov r9,r13
 cmp r12d,1
 jne .from_rows_float
 call nebo_matrix_i64_from_rows
 jmp .owned_result
.from_rows_float:
 call nebo_matrix_from_rows_f64
 jmp .owned_result
.from_buffer:
 ; The Slice ABI carries data and count. Reject a mismatching count before
 ; calling a native copy constructor, whose raw-pointer ABI cannot check it.
 mov rax,[r15+16]
 test rax,rax
 js .shape
 mov rcx,[r15+32]
 test rcx,rcx
 js .shape
 imul rax,rcx
 jo .shape
 mov rdx,[r15+8]
 test rdx,rdx
 jz .shape
 cmp rax,[rdx+8]
 jne .shape
 mov rdx,[rdx]
 mov rdi,r13
 mov rsi,r14
 mov rcx,[r15+16]
 mov r8,[r15+32]
 mov r9,r13
 cmp r12d,1
 jne .buffer_float
 call nebo_matrix_i64_from_buffer
 jmp .owned_result
.buffer_float:
 call nebo_matrix_from_buffer_f64
 jmp .owned_result
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .done
.decomposition_member:
 cmp ebx,43
 je .decomposition_length
 mov rax,[r15]
 sub ebx,41
 mov rdx,[rax+rbx*8]
 xor eax,eax
 jmp .done
.decomposition_length:
 mov edx,2                  ; The authenticated product has two typed members.
 xor eax,eax
 jmp .done
.decomposition:
 ; Typed Tuple: LU = (compact factors, permutation Vector<Int>),
 ; QR = (thin Q, R). Members use canonical public Matrix/Vector descriptors.
 cmp r12d,2
 jne .unsupported
 mov rdi,[r15]
 call nebo_matrix_validate_finite_f64
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rcx,[rax+NEBO_MATRIX_COLS]
 test rdx,rdx
 jz .shape
 test rcx,rcx
 jz .shape
 cmp rdx,32
 ja .shape
 cmp rcx,32
 ja .shape
 cmp ebx,39
 jne .qr_shape
 cmp rdx,rcx
 jne .shape
 jmp .decomposition_shape_ready
.qr_shape:
 cmp rdx,rcx
 jb .shape
.decomposition_shape_ready:
 lea rdi,[r15+96]
 lea rsi,[r15+288]
 mov r8,rdi
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .done
 lea rax,[r15+96]
 mov [rax+NEBO_MATRIX_SIZE],rax
 mov [r13],rax
 cmp ebx,40
 je .qr_decomposition
 mov rdi,[r15]
 lea rsi,[r15+288]
 lea rdx,[r15+8480]
 xorpd xmm0,xmm0
 call nebo_matrix_lu_f64
 test eax,eax
 jnz .done
 lea rax,[r15+192]
 lea rdx,[r15+8480]
 mov [rax],rdx
 mov rdx,[r15]
 mov rdx,[rdx+NEBO_MATRIX_ROWS]
 mov [rax+8],rdx
 jmp .decomposition_ready
.qr_decomposition:
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_COLS]
 mov rcx,rdx
 lea rdi,[r15+192]
 lea rsi,[r15+8480]
 mov r8,rdi
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .done
 lea rax,[r15+192]
 mov [rax+NEBO_MATRIX_SIZE],rax
 mov rdi,[r15]
 lea rsi,[r15+96]
 lea rdx,[r15+192]
 xorpd xmm0,xmm0
 call nebo_matrix_qr_f64
 test eax,eax
 jnz .done
 lea rax,[r15+192]
.decomposition_ready:
 mov [r13+8],rax
 mov rdx,r13
 xor eax,eax
 jmp .done
.matmul_into:
 mov rdi,[r15+16]
 mov rsi,[r15]
 mov rdx,[r15+8]
 cmp r12d,1
 jne .matmul_into_float
 call nebo_matrix_i64_matmul_into
 jmp .matmul_into_done
.matmul_into_float:
 call nebo_matrix_matmul_f64
.matmul_into_done:
 xor edx,edx                ; Void, never a fabricated new Matrix value.
 jmp .done
.sum:
 mov rdi,[r15]
 cmp r12d,1
 jne .sum_float
 call nebo_matrix_i64_sum
 jmp .done
.sum_float:
 mov esi,NEBO_MATRIX_REDUCE_SUM
 call nebo_matrix_reduce_f64
 movq rdx,xmm0
 jmp .done
.dot_flattened:
 mov rdi,[r15]
 mov rsi,[r15+8]
 call nebo_matrix_dot_flattened_f64
 movq rdx,xmm0
 jmp .done
.algebra:
 cmp r12d,2
 jne .unsupported
 cmp ebx,25
 je .determinant
 mov rdi,[r15]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rcx,[rax+NEBO_MATRIX_COLS]
 mov rdi,r13
 mov rsi,r14
 mov r8,r13
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .done
 mov rdi,[r15]
 mov rsi,r13
 lea rdx,[r15+32928]
 ; The no-argument public methods use exact zero-pivot rejection; no
 ; undocumented epsilon changes source values or the native singularity gate.
 xorpd xmm0,xmm0
 cmp ebx,27
 je .cholesky
 cmp ebx,28
 je .condition
 call nebo_matrix_inverse_f64
 jmp .owned_result
.cholesky:
 call nebo_matrix_cholesky_f64
 jmp .owned_result
.condition:
 call nebo_matrix_condition_estimate_f64
 movq rdx,xmm0
 jmp .done
.determinant:
 mov rdi,[r15]
 lea rsi,[r15+32928]
 lea rdx,[r15+41120]
 xorpd xmm0,xmm0
 call nebo_matrix_determinant_f64
 movq rdx,xmm0
 jmp .done
.matvec:
 mov rdi,[r15]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[r15+8]
 mov rcx,[rdx+8]
 cmp rcx,[rax+NEBO_MATRIX_COLS]
 jne .shape
 cmp ebx,37
 je .solve_vector
 cmp r12d,2
 je .matvec_float
 ; Reuse checked Int Matrix multiplication with an N-by-one Vector view.
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rdi,r13
 mov rsi,r14
 mov ecx,1
 mov r8,r13
 call nebo_matrix_i64_zeros
 test eax,eax
 jnz .done
 mov rax,[r15+8]
 lea rdi,[r15+672]
 mov rsi,[rax]
 mov rdx,[rax+8]
 mov ecx,1
 mov r8d,NEBO_MATRIX_DTYPE_I64
 mov r9,rsi
 call nebo_matrix_init_owned
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,[r15]
 lea rdx,[r15+672]
 call nebo_matrix_i64_matmul_into
 jmp .vector_result
.matvec_float:
 mov rsi,rax
 mov rdi,r14
 mov rdx,[rdx]
 call nebo_matrix_matvec_f64
 jmp .vector_result
.solve_vector:
 cmp r12d,2
 jne .unsupported
 mov rdi,rax
 mov rsi,[rdx]
 mov rdx,r14
 lea rcx,[r15+32928]
 lea r8,[r15+41120]
 xorpd xmm0,xmm0
 call nebo_matrix_solve_f64
.vector_result:
 mov rcx,[r15]
 mov rcx,[rcx+NEBO_MATRIX_ROWS]
 mov [r13],r14
 mov [r13+8],rcx
 mov rdx,r13
 jmp .done
.outer:
 mov rax,[r15]
 mov rdx,[rax+8]
 mov rax,[r15+8]
 mov rcx,[rax+8]
 mov rdi,r13
 mov rsi,r14
 mov r8,r13
 cmp r12d,2
 je .outer_zero_float
 call nebo_matrix_i64_zeros
 jmp .outer_initialized
.outer_zero_float:
 call nebo_matrix_zeros_f64
.outer_initialized:
 test eax,eax
 jnz .done
 cmp r12d,2
 je .outer_float
 ; x[N,1] * y[1,M] uses the existing checked Int matmul owner.
 mov rax,[r15]
 lea rdi,[r15+672]
 mov rsi,[rax]
 mov rdx,[rax+8]
 mov ecx,1
 mov r8d,NEBO_MATRIX_DTYPE_I64
 mov r9,rsi
 call nebo_matrix_init_owned
 test eax,eax
 jnz .done
 mov rax,[r15+8]
 lea rdi,[r15+768]
 mov rsi,[rax]
 mov edx,1
 mov rcx,[rax+8]
 mov r8d,NEBO_MATRIX_DTYPE_I64
 mov r9,rsi
 call nebo_matrix_init_owned
 test eax,eax
 jnz .done
 mov rdi,r13
 lea rsi,[r15+672]
 lea rdx,[r15+768]
 call nebo_matrix_i64_matmul_into
 jmp .owned_result
.outer_float:
 mov rax,[r15]
 mov rsi,[rax]
 mov rdx,[rax+8]
 mov rax,[r15+8]
 mov rcx,[rax]
 mov r8,[rax+8]
 mov rdi,r13
 call nebo_matrix_outer_f64
 jmp .owned_result
.axis:
 mov rdi,[r15]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rdx,[r15+8]
 cmp rdx,1
 ja .shape
 mov rax,[r15]
 mov r8,[rax+NEBO_MATRIX_COLS]
 test rdx,rdx
 jz .axis_extent
 mov r8,[rax+NEBO_MATRIX_ROWS]
.axis_extent:
 mov [r13],r14
 mov [r13+8],r8
 mov rdi,rax
 lea rsi,[rbx-30]
 mov rcx,r14
 cmp r12d,2
 je .axis_float
 call nebo_matrix_reduce_axis_i64
 jmp .axis_result
.axis_float:
 call nebo_matrix_reduce_axis_f64
.axis_result:
 mov rdx,r13
 jmp .done
.map:
 mov rdi,[r15]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rcx,[rax+NEBO_MATRIX_COLS]
 mov rdi,r13
 mov rsi,r14
 mov r8,r13
 cmp r12d,2
 je .map_zero_float
 call nebo_matrix_i64_zeros
 jmp .map_initialized
.map_zero_float:
 call nebo_matrix_zeros_f64
.map_initialized:
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,[r15]
 mov rdx,[r15+8]
 xor ecx,ecx
 cmp r12d,2
 je .map_float
 call nebo_matrix_map_i64
 jmp .owned_result
.map_float:
 call nebo_matrix_map_f64
 jmp .owned_result
.slice:
 mov rdi,r13
 mov rsi,[r15]
 mov rdx,[r15+8]
 mov rcx,[r15+16]
 mov r8,[r15+32]
 mov r9,[r15+40]
 cmp r12d,1
 jne .slice_float
 call nebo_matrix_i64_slice_view
 jmp .view_result
.slice_float:
 call nebo_matrix_slice_view
 jmp .view_result
.method:
 cmp ebx,9
 jae .view
 mov rdi,[r15]
 cmp ebx,3
 je .rows
 cmp ebx,4
 je .columns
 cmp ebx,5
 je .layout
 cmp ebx,6
 je .at
 cmp ebx,7
 je .square
 cmp r12d,1
 jne .trace_float
 call nebo_matrix_i64_trace
 jmp .done
.trace_float:
 call nebo_matrix_trace_f64
 movq rdx,xmm0
 jmp .done
.rows:
 call nebo_matrix_rows
 jmp .done
.columns:
 call nebo_matrix_columns
 jmp .done
.layout:
 call nebo_matrix_layout
 jmp .done
.square:
 call nebo_matrix_is_square
 jmp .done
.at:
 mov rsi,[r15+8]
 mov rdx,[r15+16]
 cmp r12d,1
 jne .at_float
 call nebo_matrix_i64_at
 jmp .done
.at_float:
 call nebo_matrix_at_f64
 movq rdx,xmm0
 jmp .done
.view:
 mov rdi,r13
 mov rsi,[r15]
 cmp ebx,10
 je .contiguous
 cmp ebx,11
 je .row
 cmp ebx,12
 je .column
 cmp r12d,1
 jne .transpose_float
 call nebo_matrix_i64_transpose_view
 jmp .view_result
.transpose_float:
 call nebo_matrix_transpose_view
 jmp .view_result
.row:
 mov rdx,[r15+8]
 cmp r12d,1
 jne .row_float
 call nebo_matrix_i64_row_view
 jmp .view_result
.row_float:
 call nebo_matrix_row_view
 jmp .view_result
.column:
 mov rdx,[r15+8]
 cmp r12d,1
 jne .column_float
 call nebo_matrix_i64_column_view
 jmp .view_result
.column_float:
 call nebo_matrix_column_view
.view_result:
 mov rcx,[r15]
 mov rcx,[rcx+NEBO_MATRIX_SIZE]
 mov [r13+NEBO_MATRIX_SIZE],rcx
 mov rdx,r13
 jmp .done
.contiguous:
 mov rsi,r14
 mov rdx,[r15]
 cmp r12d,1
 jne .contiguous_float
 mov rcx,[rdx+NEBO_MATRIX_SIZE]
 mov r8,r13
 call nebo_matrix_i64_contiguous
 jmp .owned_result
.contiguous_float:
 mov rcx,r13
 call nebo_matrix_contiguous_f64
 jmp .owned_result
.operation:
 cmp r12d,2
 je .float_operation
 mov rdi,r13
 mov rsi,r14
 mov rdx,[r15]
 mov rcx,[r15+8]
 mov r8,r13
 cmp ebx,14
 je .int_add
 cmp ebx,15
 je .int_subtract
 cmp ebx,16
 je .int_multiply
 cmp ebx,18
 je .int_scale
 cmp ebx,20
 jne .unsupported
 call nebo_matrix_i64_matmul
 jmp .owned_result
.int_add:
 call nebo_matrix_i64_add
 jmp .owned_result
.int_subtract:
 call nebo_matrix_i64_subtract
 jmp .owned_result
.int_multiply:
 call nebo_matrix_i64_multiply_elements
 jmp .owned_result
.int_scale:
 call nebo_matrix_i64_scale
 jmp .owned_result
.float_operation:
 ; The canonical Float operations write an initialized, distinct output.
 mov rdi,[r15]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rcx,[rax+NEBO_MATRIX_COLS]
 cmp ebx,20
 jne .float_shape
 mov rdi,[r15+8]
 call nebo_matrix_validate
 test eax,eax
 jnz .done
 mov rax,[r15]
 mov rdx,[rax+NEBO_MATRIX_ROWS]
 mov rax,[r15+8]
 mov rcx,[rax+NEBO_MATRIX_COLS]
.float_shape:
 mov rdi,r13
 mov rsi,r14
 mov r8,r13
 call nebo_matrix_zeros_f64
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,[r15]
 cmp ebx,18
 je .float_scale
 cmp ebx,19
 je .float_clamp
 mov rdx,[r15+8]
 cmp ebx,20
 je .float_matmul
 mov rcx,rbx
 sub rcx,13
 call nebo_matrix_elementwise_f64
 jmp .owned_result
.float_scale:
 movq xmm0,[r15+8]
 call nebo_matrix_scale_f64
 jmp .owned_result
.float_clamp:
 movq xmm0,[r15+8]
 movq xmm1,[r15+16]
 call nebo_matrix_clamp_f64
 jmp .owned_result
.float_matmul:
 call nebo_matrix_matmul_f64
 jmp .owned_result
.unsupported:
 mov eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
 jmp .done
.safe_get:
 mov rdi,[r15]
 mov rsi,[r15+8]
 mov rdx,[r15+16]
 cmp r12d,1
 jne .get_float
 call nebo_matrix_i64_at
 jmp .get_status
.get_float:
 call nebo_matrix_get_f64
 movq rdx,xmm0
.get_status:
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 je .get_none
 test eax,eax
 jnz .done
 mov qword [r13],1
 mov [r13+8],rdx
 jmp .get_result
.get_none:
 mov qword [r13],0
 mov qword [r13+8],0
.get_result:
 xor eax,eax
 mov rdx,r13
 jmp .done
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
