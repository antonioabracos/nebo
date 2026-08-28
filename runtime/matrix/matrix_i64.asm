; C11 CPU_I64_SMALL_V1 Matrix implementation: constructors and fixed storage.
bits 64
default rel
%define NEBO_MATRIX_I64_IMPLEMENTATION 1
%include "runtime/matrix/matrix_i64.inc"

section .text
global nebo_matrix_i64_zeros
global nebo_matrix_i64_filled
global nebo_matrix_i64_from_rows
global nebo_matrix_i64_from_buffer
global nebo_matrix_i64_release
global nebo_matrix_i64_validate
global nebo_matrix_i64_rows
global nebo_matrix_i64_columns
global nebo_matrix_i64_element_count
global nebo_matrix_i64_layout
global nebo_matrix_i64_storage_id
global nebo_matrix_i64_is_contiguous
global nebo_matrix_i64_at
global nebo_matrix_i64_set
global nebo_matrix_i64_row_view
global nebo_matrix_i64_column_view
global nebo_matrix_i64_slice_view
global nebo_matrix_i64_transpose_view
global nebo_matrix_i64_validate_view_owner
global nebo_matrix_i64_contiguous
global nebo_matrix_i64_add
global nebo_matrix_i64_subtract
global nebo_matrix_i64_multiply_elements
global nebo_matrix_i64_scale
global nebo_matrix_i64_sum
global nebo_matrix_i64_min
global nebo_matrix_i64_max
global nebo_matrix_i64_trace
global nebo_matrix_i64_is_square
global nebo_matrix_i64_matmul
global nebo_matrix_i64_matmul_into
global nebo_matrix_i64_borrow_sum
global nebo_matrix_i64_sret_scale
global nebo_matrix_i64_serialized_size
global nebo_matrix_i64_serialize
global nebo_matrix_i64_deserialize
global nebo_matrix_i64_headless_shape

; Validate constructor inputs without changing descriptor or payload.
; rdi descriptor, rsi payload, rdx rows, rcx columns, r8 storage identity.
; success: eax=0, r10=element count.
matrix_i64_constructor_validate:
 test rdi,rdi
 jz .argument
 test rdi,7
 jnz .argument
 test r8,r8
 jz .argument
 cmp rdx,NEBO_MATRIX_I64_MAX_DIMENSION
 ja .shape
 cmp rcx,NEBO_MATRIX_I64_MAX_DIMENSION
 ja .shape
 mov r10,rdx
 imul r10,rcx
 jo .shape
 cmp r10,NEBO_MATRIX_I64_MAX_ELEMENTS
 ja .shape
 test r10,r10
 jz .ok
 test rsi,rsi
 jz .argument
 test rsi,7
 jnz .argument
.ok:
 xor eax,eax
 ret
.argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret

; Common descriptor materialization after complete validation.
; rdi descriptor, rsi payload, rdx rows, rcx columns, r8 storage identity.
matrix_i64_init:
 mov r9,r8
 mov r8d,NEBO_MATRIX_DTYPE_I64
 jmp nebo_matrix_init_owned

; descriptor, payload, rows, columns, storage identity
nebo_matrix_i64_zeros:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 call matrix_i64_init
 test eax,eax
 jnz .done
 mov rcx,r14
 imul rcx,r15
 xor eax,eax
.zero:
 test rcx,rcx
 jz .done
 dec rcx
 mov qword [r13+rcx*8],0
 jmp .zero
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; descriptor, payload, rows, columns, fill value, storage identity
nebo_matrix_i64_filled:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov r8,r9
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .filled_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 call matrix_i64_init
 test eax,eax
 jnz .filled_done
 mov rcx,r14
 imul rcx,r15
.fill:
 test rcx,rcx
 jz .filled_ok
 dec rcx
 mov [r13+rcx*8],rbx
 jmp .fill
.filled_ok:
 xor eax,eax
.filled_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; descriptor, destination, source, rows, columns, storage identity.
; The public caller proves source has the exact checked logical element count.
nebo_matrix_i64_from_rows:
 jmp matrix_i64_from_copy

nebo_matrix_i64_from_buffer:
matrix_i64_from_copy:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov r8,r9
 mov rdx,r15
 mov rcx,rbx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .copy_done
 test r10,r10
 jz .copy_init
 test r14,r14
 jz .copy_argument
 test r14,7
 jnz .copy_argument
 ; Explicit construction never aliases its input storage.
 mov rax,r10
 shl rax,3
 jo .copy_shape
 mov rdx,r13
 add rdx,rax
 jc .copy_shape
 mov rcx,r14
 add rcx,rax
 jc .copy_shape
 cmp r13,rcx
 jae .copy_init
 cmp r14,rdx
 jae .copy_init
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .copy_done
.copy_init:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 mov rcx,rbx
 mov r8,r9
 call matrix_i64_init
 test eax,eax
 jnz .copy_done
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
 jmp .copy_done
.copy_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .copy_done
.copy_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
.copy_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Explicit cleanup for caller-fixed storage: invalidate descriptor only.
nebo_matrix_i64_release:
 push rdi
 call nebo_matrix_validate
 pop rdi
 test eax,eax
 jnz .release_done
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .release_alias
 mov rcx,NEBO_MATRIX_SIZE/8
 xor eax,eax
 rep stosq
 ret
.release_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
.release_done:
 ret

; Public-profile descriptor validation. The legacy descriptor may also carry
; F64 and larger native shapes; neither is admitted by CPU_I64_SMALL_V1.
nebo_matrix_i64_validate:
 push rdi
 call nebo_matrix_validate
 pop rdi
 test eax,eax
 jnz .validate_done
 cmp qword [rdi+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 jne .validate_contract
 cmp qword [rdi+NEBO_MATRIX_ROWS],NEBO_MATRIX_I64_MAX_DIMENSION
 ja .validate_shape
 cmp qword [rdi+NEBO_MATRIX_COLS],NEBO_MATRIX_I64_MAX_DIMENSION
 ja .validate_shape
 mov rax,[rdi+NEBO_MATRIX_ROWS]
 imul rax,[rdi+NEBO_MATRIX_COLS]
 jo .validate_shape
 cmp rax,NEBO_MATRIX_I64_MAX_ELEMENTS
 ja .validate_shape
 xor eax,eax
.validate_done:
 ret
.validate_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
.validate_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 ret

; Metadata accessors return status in EAX and the value in RDX.
nebo_matrix_i64_rows:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .rows_done
 mov rdx,[rdi+NEBO_MATRIX_ROWS]
.rows_done:
 ret

nebo_matrix_i64_columns:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .columns_done
 mov rdx,[rdi+NEBO_MATRIX_COLS]
.columns_done:
 ret

nebo_matrix_i64_element_count:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .count_done
 mov rdx,[rdi+NEBO_MATRIX_ROWS]
 imul rdx,[rdi+NEBO_MATRIX_COLS]
.count_done:
 ret

; layout 1 is canonical contiguous row-major; 2 is a strided read-only view.
nebo_matrix_i64_layout:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .layout_done
 mov edx,2
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_CONTIGUOUS
 jz .layout_done
 mov edx,1
.layout_done:
 ret

nebo_matrix_i64_storage_id:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .storage_done
 mov rdx,[rdi+NEBO_MATRIX_STORAGE_ID]
.storage_done:
 ret

nebo_matrix_i64_is_contiguous:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .contiguous_done
 xor edx,edx
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_CONTIGUOUS
 setnz dl
.contiguous_done:
 ret

; Shared checked address plan. rdi descriptor, rsi row, rdx column.
; success returns address in R8 and status zero in EAX.
matrix_i64_checked_address:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .address_done
 cmp r13,[r12+NEBO_MATRIX_ROWS]
 jae .address_bounds
 cmp r14,[r12+NEBO_MATRIX_COLS]
 jae .address_bounds
 mov rax,r13
 mul qword [r12+NEBO_MATRIX_ROW_STRIDE]
 test rdx,rdx
 jnz .address_overflow
 mov r8,rax
 mov rax,r14
 mul qword [r12+NEBO_MATRIX_COL_STRIDE]
 test rdx,rdx
 jnz .address_overflow
 add r8,rax
 jc .address_overflow
 cmp r8,[r12+NEBO_MATRIX_CAPACITY]
 jae .address_bounds
 shl r8,3
 jc .address_overflow
 add r8,[r12+NEBO_MATRIX_DATA]
 jc .address_overflow
 xor eax,eax
.address_done:
 pop r14
 pop r13
 pop r12
 ret
.address_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .address_done
.address_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .address_done

; descriptor, row, column -> status EAX, value RDX.
nebo_matrix_i64_at:
 call matrix_i64_checked_address
 test eax,eax
 jnz .at_done
 mov rdx,[r8]
.at_done:
 ret

; descriptor, row, column, value. All checks precede the one payload store.
nebo_matrix_i64_set:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call matrix_i64_checked_address
 test eax,eax
 jnz .set_done
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .set_alias
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .set_alias
 mov [r8],r15
 xor eax,eax
.set_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.set_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .set_done

; rdi output, rsi source, rdx rows, rcx columns, r8 data, r9 row stride,
; r10 column stride. The complete view descriptor is published only after all
; output alias and depth checks pass.
matrix_i64_init_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov [rsp+8],r10
 test r12,r12
 jz .view_argument
 test r12,7
 jnz .view_argument
 cmp r12,r13
 je .view_alias
 mov rax,[r13+NEBO_MATRIX_DATA]
 mov rcx,[r13+NEBO_MATRIX_CAPACITY]
 shl rcx,3
 jo .view_contract
 mov rdx,rax
 add rdx,rcx
 jc .view_contract
 cmp r12,rax
 jb .view_output_ok
 cmp r12,rdx
 jb .view_alias
.view_output_ok:
 xor ecx,ecx
 test qword [r13+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW
 jz .view_depth_ready
 mov rcx,[r13+NEBO_MATRIX_FLAGS]
 and rcx,NEBO_MATRIX_I64_VIEW_DEPTH_MASK
 shr rcx,NEBO_MATRIX_I64_VIEW_DEPTH_SHIFT
 test rcx,rcx
 jnz .view_depth_ready
 mov ecx,1
.view_depth_ready:
 inc rcx
 cmp rcx,NEBO_MATRIX_I64_MAX_VIEW_DEPTH
 ja .view_depth
 mov rax,NEBO_MATRIX_MAGIC
 mov [r12+NEBO_MATRIX_MAGIC_OFF],rax
 mov qword [r12+NEBO_MATRIX_DTYPE],NEBO_MATRIX_DTYPE_I64
 mov [r12+NEBO_MATRIX_ROWS],r14
 mov [r12+NEBO_MATRIX_COLS],r15
 mov rax,[rsp]
 mov [r12+NEBO_MATRIX_ROW_STRIDE],rax
 mov rax,[rsp+8]
 mov [r12+NEBO_MATRIX_COL_STRIDE],rax
 mov [r12+NEBO_MATRIX_DATA],rbx
 mov rax,[r13+NEBO_MATRIX_CAPACITY]
 mov [r12+NEBO_MATRIX_CAPACITY],rax
 mov rax,[r13+NEBO_MATRIX_STORAGE_ID]
 mov [r12+NEBO_MATRIX_STORAGE_ID],rax
 mov rax,[r13+NEBO_MATRIX_GENERATION]
 mov [r12+NEBO_MATRIX_GENERATION],rax
 shl rcx,NEBO_MATRIX_I64_VIEW_DEPTH_SHIFT
 or rcx,NEBO_MATRIX_FLAG_VIEW|NEBO_MATRIX_FLAG_READONLY
 mov rax,[rsp+8]
 cmp rax,1
 jne .view_flags
 mov rax,[rsp]
 cmp rax,r15
 jne .view_flags
 or rcx,NEBO_MATRIX_FLAG_CONTIGUOUS
.view_flags:
 mov [r12+NEBO_MATRIX_FLAGS],rcx
 xor eax,eax
 jmp .view_done
.view_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .view_done
.view_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .view_done
.view_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .view_done
.view_depth:
 mov eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
.view_done:
 add rsp,16
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; output, source, row
nebo_matrix_i64_row_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r13
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .row_done
 cmp r14,[r13+NEBO_MATRIX_ROWS]
 jae .row_bounds
 mov r8,r14
 imul r8,[r13+NEBO_MATRIX_ROW_STRIDE]
 jo .row_overflow
 shl r8,3
 jc .row_overflow
 add r8,[r13+NEBO_MATRIX_DATA]
 jc .row_overflow
 mov rdi,r12
 mov rsi,r13
 mov edx,1
 mov rcx,[r13+NEBO_MATRIX_COLS]
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 call matrix_i64_init_view
.row_done:
 pop r14
 pop r13
 pop r12
 ret
.row_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .row_done
.row_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .row_done

; output, source, column
nebo_matrix_i64_column_view:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r13
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .column_done
 cmp r14,[r13+NEBO_MATRIX_COLS]
 jae .column_bounds
 mov r8,r14
 imul r8,[r13+NEBO_MATRIX_COL_STRIDE]
 jo .column_overflow
 shl r8,3
 jc .column_overflow
 add r8,[r13+NEBO_MATRIX_DATA]
 jc .column_overflow
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r13+NEBO_MATRIX_ROWS]
 mov ecx,1
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 call matrix_i64_init_view
.column_done:
 pop r14
 pop r13
 pop r12
 ret
.column_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .column_done
.column_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .column_done

; output, source, rowStart, rowCount, columnStart, columnCount
nebo_matrix_i64_slice_view:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rdi,r13
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .slice_done
 mov rax,r14
 add rax,r15
 jc .slice_bounds
 cmp rax,[r13+NEBO_MATRIX_ROWS]
 ja .slice_bounds
 mov rax,rbx
 add rax,[rsp]
 jc .slice_bounds
 cmp rax,[r13+NEBO_MATRIX_COLS]
 ja .slice_bounds
 mov rax,r14
 imul rax,[r13+NEBO_MATRIX_ROW_STRIDE]
 jo .slice_overflow
 mov r8,rbx
 imul r8,[r13+NEBO_MATRIX_COL_STRIDE]
 jo .slice_overflow
 add r8,rax
 jc .slice_overflow
 shl r8,3
 jc .slice_overflow
 add r8,[r13+NEBO_MATRIX_DATA]
 jc .slice_overflow
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 mov rcx,[rsp]
 mov r9,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov r10,[r13+NEBO_MATRIX_COL_STRIDE]
 call matrix_i64_init_view
.slice_done:
 add rsp,16
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.slice_bounds:
 mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .slice_done
.slice_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .slice_done

; output, source
nebo_matrix_i64_transpose_view:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .transpose_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r13+NEBO_MATRIX_COLS]
 mov rcx,[r13+NEBO_MATRIX_ROWS]
 mov r8,[r13+NEBO_MATRIX_DATA]
 mov r9,[r13+NEBO_MATRIX_COL_STRIDE]
 mov r10,[r13+NEBO_MATRIX_ROW_STRIDE]
 call matrix_i64_init_view
.transpose_done:
 pop r13
 pop r12
 ret

nebo_matrix_i64_validate_view_owner:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_validate_view_owner
 test eax,eax
 jnz .owner_done
 mov rdi,r12
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .owner_done
 mov rdi,r13
 call nebo_matrix_i64_validate
.owner_done:
 pop r13
 pop r12
 ret

; out descriptor, destination payload, source descriptor, owner descriptor,
; new storage identity. A source view must be authenticated against its owner.
nebo_matrix_i64_contiguous:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r14
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .materialize_done
 test qword [r14+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_VIEW
 jz .materialize_owner
 mov rdi,r14
 mov rsi,r15
 call nebo_matrix_i64_validate_view_owner
 test eax,eax
 jnz .materialize_done
 jmp .materialize_identity_ready
.materialize_owner:
 cmp r14,r15
 jne .materialize_alias
 test qword [r14+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .materialize_alias
.materialize_identity_ready:
 cmp r12,r14
 je .materialize_alias
 cmp r12,r15
 je .materialize_alias
 ; New descriptor cannot be placed inside either payload span.
 mov rax,[r15+NEBO_MATRIX_CAPACITY]
 shl rax,3
 jo .materialize_overflow
 mov rcx,[r15+NEBO_MATRIX_DATA]
 mov rdx,rcx
 add rdx,rax
 jc .materialize_overflow
 cmp r12,rcx
 jb .materialize_descriptor_ok
 cmp r12,rdx
 jb .materialize_alias
.materialize_descriptor_ok:
 ; Destination storage is an explicit distinct owner allocation.
 mov rax,[r14+NEBO_MATRIX_ROWS]
 imul rax,[r14+NEBO_MATRIX_COLS]
 jo .materialize_overflow
 shl rax,3
 jo .materialize_overflow
 mov rcx,r13
 add rcx,rax
 jc .materialize_overflow
 mov rdx,[r15+NEBO_MATRIX_DATA]
 mov r8,[r15+NEBO_MATRIX_CAPACITY]
 shl r8,3
 jo .materialize_overflow
 add r8,rdx
 jc .materialize_overflow
 cmp r13,r8
 jae .materialize_destination_ok
 cmp rdx,rcx
 jae .materialize_destination_ok
 jmp .materialize_alias
.materialize_destination_ok:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r14+NEBO_MATRIX_COLS]
 mov r8,rbx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .materialize_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r14+NEBO_MATRIX_COLS]
 mov r8,rbx
 call matrix_i64_init
 test eax,eax
 jnz .materialize_done
 xor r10d,r10d
.materialize_rows:
 cmp r10,[r14+NEBO_MATRIX_ROWS]
 jae .materialize_ok
 xor r11d,r11d
.materialize_columns:
 cmp r11,[r14+NEBO_MATRIX_COLS]
 jae .materialize_next_row
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mov rdx,[rdx+rax*8]
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_COLS]
 add rax,r11
 mov [r13+rax*8],rdx
 inc r11
 jmp .materialize_columns
.materialize_next_row:
 inc r10
 jmp .materialize_rows
.materialize_ok:
 xor eax,eax
 jmp .materialize_done
.materialize_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .materialize_done
.materialize_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.materialize_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi destination, rsi logical element count, rdx source descriptor.
matrix_i64_require_disjoint_payload:
 mov rax,rsi
 shl rax,3
 jo .disjoint_overflow
 mov rcx,rdi
 add rcx,rax
 jc .disjoint_overflow
 mov r8,[rdx+NEBO_MATRIX_DATA]
 mov r9,[rdx+NEBO_MATRIX_CAPACITY]
 shl r9,3
 jo .disjoint_overflow
 add r9,r8
 jc .disjoint_overflow
 cmp rdi,r9
 jae .disjoint_ok
 cmp r8,rcx
 jae .disjoint_ok
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
.disjoint_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 ret
.disjoint_ok:
 xor eax,eax
 ret

; out descriptor, destination, lhs, rhs, storage identity.
nebo_matrix_i64_add:
 mov r9d,1
 jmp matrix_i64_binary
nebo_matrix_i64_subtract:
 mov r9d,2
 jmp matrix_i64_binary
nebo_matrix_i64_multiply_elements:
 mov r9d,3

matrix_i64_binary:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 mov rdi,r14
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .binary_done
 mov rdi,r15
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .binary_done
 mov rax,[r14+NEBO_MATRIX_ROWS]
 cmp rax,[r15+NEBO_MATRIX_ROWS]
 jne .binary_shape
 mov rax,[r14+NEBO_MATRIX_COLS]
 cmp rax,[r15+NEBO_MATRIX_COLS]
 jne .binary_shape
 cmp r12,r14
 je .binary_alias
 cmp r12,r15
 je .binary_alias
 mov rsi,[r14+NEBO_MATRIX_ROWS]
 imul rsi,[r14+NEBO_MATRIX_COLS]
 mov rdi,r13
 mov rdx,r14
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .binary_done
 mov rdi,r13
 mov rdx,r15
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .binary_done
 ; First pass proves every checked scalar result before output publication.
 xor r10d,r10d
.binary_check_rows:
 cmp r10,[r14+NEBO_MATRIX_ROWS]
 jae .binary_publish
 xor r11d,r11d
.binary_check_columns:
 cmp r11,[r14+NEBO_MATRIX_COLS]
 jae .binary_check_next_row
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 mov rdx,r10
 imul rdx,[r15+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r15+NEBO_MATRIX_COL_STRIDE]
 add rdx,rcx
 mov rcx,[r15+NEBO_MATRIX_DATA]
 mov rdx,[rcx+rdx*8]
 cmp qword [rsp],1
 je .binary_check_add
 cmp qword [rsp],2
 je .binary_check_sub
 imul rax,rdx
 jo .binary_overflow
 jmp .binary_check_next
.binary_check_add:
 add rax,rdx
 jo .binary_overflow
 jmp .binary_check_next
.binary_check_sub:
 sub rax,rdx
 jo .binary_overflow
.binary_check_next:
 inc r11
 jmp .binary_check_columns
.binary_check_next_row:
 inc r10
 jmp .binary_check_rows
.binary_publish:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r14+NEBO_MATRIX_COLS]
 mov r8,rbx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .binary_done
 call matrix_i64_init
 test eax,eax
 jnz .binary_done
 xor r10d,r10d
.binary_write_rows:
 cmp r10,[r14+NEBO_MATRIX_ROWS]
 jae .binary_ok
 xor r11d,r11d
.binary_write_columns:
 cmp r11,[r14+NEBO_MATRIX_COLS]
 jae .binary_write_next_row
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 mov rdx,r10
 imul rdx,[r15+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r15+NEBO_MATRIX_COL_STRIDE]
 add rdx,rcx
 mov rcx,[r15+NEBO_MATRIX_DATA]
 mov rdx,[rcx+rdx*8]
 cmp qword [rsp],1
 je .binary_write_add
 cmp qword [rsp],2
 je .binary_write_sub
 imul rax,rdx
 jmp .binary_store
.binary_write_add:
 add rax,rdx
 jmp .binary_store
.binary_write_sub:
 sub rax,rdx
.binary_store:
 mov rdx,r10
 imul rdx,[r14+NEBO_MATRIX_COLS]
 add rdx,r11
 mov [r13+rdx*8],rax
 inc r11
 jmp .binary_write_columns
.binary_write_next_row:
 inc r10
 jmp .binary_write_rows
.binary_ok:
 xor eax,eax
 jmp .binary_done
.binary_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .binary_done
.binary_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .binary_done
.binary_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.binary_done:
 add rsp,16
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; out descriptor, destination, source, scalar, storage identity.
nebo_matrix_i64_scale:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r14
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .scale_done
 cmp r12,r14
 je .scale_alias
 mov rsi,[r14+NEBO_MATRIX_ROWS]
 imul rsi,[r14+NEBO_MATRIX_COLS]
 mov rdi,r13
 mov rdx,r14
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .scale_done
 xor r10d,r10d
.scale_check_rows:
 cmp r10,[r14+NEBO_MATRIX_ROWS]
 jae .scale_publish
 xor r11d,r11d
.scale_check_columns:
 cmp r11,[r14+NEBO_MATRIX_COLS]
 jae .scale_check_next_row
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 imul rax,r15
 jo .scale_overflow
 inc r11
 jmp .scale_check_columns
.scale_check_next_row:
 inc r10
 jmp .scale_check_rows
.scale_publish:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r14+NEBO_MATRIX_COLS]
 mov r8,rbx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .scale_done
 call matrix_i64_init
 test eax,eax
 jnz .scale_done
 xor r10d,r10d
.scale_write_rows:
 cmp r10,[r14+NEBO_MATRIX_ROWS]
 jae .scale_ok
 xor r11d,r11d
.scale_write_columns:
 cmp r11,[r14+NEBO_MATRIX_COLS]
 jae .scale_write_next_row
 mov rax,r10
 imul rax,[r14+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r11
 imul rcx,[r14+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r14+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 imul rax,r15
 mov rdx,r10
 imul rdx,[r14+NEBO_MATRIX_COLS]
 add rdx,r11
 mov [r13+rdx*8],rax
 inc r11
 jmp .scale_write_columns
.scale_write_next_row:
 inc r10
 jmp .scale_write_rows
.scale_ok:
 xor eax,eax
 jmp .scale_done
.scale_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .scale_done
.scale_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.scale_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; descriptor -> status EAX, scalar RDX.
nebo_matrix_i64_sum:
 mov esi,1
 jmp matrix_i64_reduce
nebo_matrix_i64_min:
 mov esi,2
 jmp matrix_i64_reduce
nebo_matrix_i64_max:
 mov esi,3

matrix_i64_reduce:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .reduce_done
 mov rax,[r12+NEBO_MATRIX_ROWS]
 imul rax,[r12+NEBO_MATRIX_COLS]
 test rax,rax
 jnz .reduce_nonempty
 cmp r13,1
 jne .reduce_empty
 xor edx,edx
 xor eax,eax
 jmp .reduce_done
.reduce_nonempty:
 xor r14d,r14d
 xor r15d,r15d
 xor r8d,r8d
 xor edx,edx
.reduce_rows:
 cmp r14,[r12+NEBO_MATRIX_ROWS]
 jae .reduce_ok
 xor r15d,r15d
.reduce_columns:
 cmp r15,[r12+NEBO_MATRIX_COLS]
 jae .reduce_next_row
 mov rax,r14
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rcx,[r12+NEBO_MATRIX_DATA]
 mov rax,[rcx+rax*8]
 cmp r13,1
 je .reduce_sum
 test r8,r8
 jz .reduce_first
 cmp r13,2
 je .reduce_min
 cmp rax,rdx
 jle .reduce_next
 mov rdx,rax
 jmp .reduce_next
.reduce_min:
 cmp rax,rdx
 jge .reduce_next
 mov rdx,rax
 jmp .reduce_next
.reduce_first:
 mov rdx,rax
 mov r8d,1
 jmp .reduce_next
.reduce_sum:
 add rdx,rax
 jo .reduce_overflow
.reduce_next:
 inc r15
 jmp .reduce_columns
.reduce_next_row:
 inc r14
 jmp .reduce_rows
.reduce_ok:
 xor eax,eax
 jmp .reduce_done
.reduce_empty:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .reduce_done
.reduce_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.reduce_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

nebo_matrix_i64_trace:
 push r12
 push r13
 mov r12,rdi
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .trace_done
 mov r13,[r12+NEBO_MATRIX_ROWS]
 cmp r13,[r12+NEBO_MATRIX_COLS]
 cmova r13,[r12+NEBO_MATRIX_COLS]
 xor ecx,ecx
 xor edx,edx
.trace_loop:
 cmp rcx,r13
 jae .trace_ok
 mov rax,rcx
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov r8,rcx
 imul r8,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,r8
 mov r8,[r12+NEBO_MATRIX_DATA]
 add rdx,[r8+rax*8]
 jo .trace_overflow
 inc rcx
 jmp .trace_loop
.trace_ok:
 xor eax,eax
 jmp .trace_done
.trace_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.trace_done:
 pop r13
 pop r12
 ret

nebo_matrix_i64_is_square:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .square_done
 xor edx,edx
 mov rcx,[rdi+NEBO_MATRIX_ROWS]
 cmp rcx,[rdi+NEBO_MATRIX_COLS]
 sete dl
.square_done:
 ret

; rdi lhs, rsi rhs. Validate shape/budget and every checked result without
; publishing output. This is the scalar reference oracle used by both APIs.
matrix_i64_matmul_preflight:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .matcheck_done
 mov rdi,r13
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .matcheck_done
 mov rax,[r12+NEBO_MATRIX_COLS]
 cmp rax,[r13+NEBO_MATRIX_ROWS]
 jne .matcheck_shape
 mov rax,[r12+NEBO_MATRIX_ROWS]
 imul rax,[r13+NEBO_MATRIX_COLS]
 jo .matcheck_overflow
 cmp rax,NEBO_MATRIX_I64_MAX_ELEMENTS
 ja .matcheck_shape
 imul rax,[r12+NEBO_MATRIX_COLS]
 jo .matcheck_overflow
 cmp rax,512
 ja .matcheck_workspace
 xor r14d,r14d
.matcheck_rows:
 cmp r14,[r12+NEBO_MATRIX_ROWS]
 jae .matcheck_ok
 xor r15d,r15d
.matcheck_columns:
 cmp r15,[r13+NEBO_MATRIX_COLS]
 jae .matcheck_next_row
 xor r8d,r8d
 xor ebx,ebx
.matcheck_inner:
 cmp rbx,[r12+NEBO_MATRIX_COLS]
 jae .matcheck_next_column
 mov rax,r14
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 mov rdx,rbx
 imul rdx,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rdx,rcx
 mov rcx,[r13+NEBO_MATRIX_DATA]
 mov rdx,[rcx+rdx*8]
 imul rax,rdx
 jo .matcheck_overflow
 add r8,rax
 jo .matcheck_overflow
 inc rbx
 jmp .matcheck_inner
.matcheck_next_column:
 inc r15
 jmp .matcheck_columns
.matcheck_next_row:
 inc r14
 jmp .matcheck_rows
.matcheck_ok:
 xor eax,eax
 jmp .matcheck_done
.matcheck_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
 jmp .matcheck_done
.matcheck_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jmp .matcheck_done
.matcheck_workspace:
 mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
.matcheck_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; rdi contiguous destination payload, rsi lhs, rdx rhs. Preflight required.
matrix_i64_matmul_write:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov [rsp],rdi
 mov r12,rsi
 mov r13,rdx
 xor r14d,r14d
.matwrite_rows:
 cmp r14,[r12+NEBO_MATRIX_ROWS]
 jae .matwrite_ok
 xor r15d,r15d
.matwrite_columns:
 cmp r15,[r13+NEBO_MATRIX_COLS]
 jae .matwrite_next_row
 xor r8d,r8d
 xor ebx,ebx
.matwrite_inner:
 cmp rbx,[r12+NEBO_MATRIX_COLS]
 jae .matwrite_store
 mov rax,r14
 imul rax,[r12+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,rbx
 imul rcx,[r12+NEBO_MATRIX_COL_STRIDE]
 add rax,rcx
 mov rdx,[r12+NEBO_MATRIX_DATA]
 mov rax,[rdx+rax*8]
 mov rdx,rbx
 imul rdx,[r13+NEBO_MATRIX_ROW_STRIDE]
 mov rcx,r15
 imul rcx,[r13+NEBO_MATRIX_COL_STRIDE]
 add rdx,rcx
 mov rcx,[r13+NEBO_MATRIX_DATA]
 mov rdx,[rcx+rdx*8]
 imul rax,rdx
 add r8,rax
 inc rbx
 jmp .matwrite_inner
.matwrite_store:
 mov rax,r14
 imul rax,[r13+NEBO_MATRIX_COLS]
 add rax,r15
 mov rdx,[rsp]
 mov [rdx+rax*8],r8
 inc r15
 jmp .matwrite_columns
.matwrite_next_row:
 inc r14
 jmp .matwrite_rows
.matwrite_ok:
 xor eax,eax
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; out descriptor, destination payload, lhs, rhs, storage identity.
nebo_matrix_i64_matmul:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r14
 mov rsi,r15
 call matrix_i64_matmul_preflight
 test eax,eax
 jnz .matmul_done
 cmp r12,r14
 je .matmul_alias
 cmp r12,r15
 je .matmul_alias
 mov rsi,[r14+NEBO_MATRIX_ROWS]
 imul rsi,[r15+NEBO_MATRIX_COLS]
 mov rdi,r13
 mov rdx,r14
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .matmul_done
 mov rdi,r13
 mov rdx,r15
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .matmul_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r14+NEBO_MATRIX_ROWS]
 mov rcx,[r15+NEBO_MATRIX_COLS]
 mov r8,rbx
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .matmul_done
 call matrix_i64_init
 test eax,eax
 jnz .matmul_done
 mov rdi,r13
 mov rsi,r14
 mov rdx,r15
 call matrix_i64_matmul_write
 jmp .matmul_done
.matmul_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
.matmul_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; existing destination owner, lhs, rhs.
nebo_matrix_i64_matmul_into:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_matrix_i64_validate
 test eax,eax
 jnz .into_done
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .into_alias
 test qword [r12+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_READONLY
 jnz .into_alias
 mov rdi,r13
 mov rsi,r14
 call matrix_i64_matmul_preflight
 test eax,eax
 jnz .into_done
 mov rax,[r13+NEBO_MATRIX_ROWS]
 cmp rax,[r12+NEBO_MATRIX_ROWS]
 jne .into_shape
 mov rax,[r14+NEBO_MATRIX_COLS]
 cmp rax,[r12+NEBO_MATRIX_COLS]
 jne .into_shape
 mov rsi,[r12+NEBO_MATRIX_ROWS]
 imul rsi,[r12+NEBO_MATRIX_COLS]
 mov rdi,[r12+NEBO_MATRIX_DATA]
 mov rdx,r13
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .into_done
 mov rdi,[r12+NEBO_MATRIX_DATA]
 mov rdx,r14
 call matrix_i64_require_disjoint_payload
 test eax,eax
 jnz .into_done
 mov rdi,[r12+NEBO_MATRIX_DATA]
 mov rsi,r13
 mov rdx,r14
 call matrix_i64_matmul_write
 jmp .into_done
.into_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .into_done
.into_shape:
 mov eax,NEBO_NUMERIC_ERROR_SHAPE
.into_done:
 pop r14
 pop r13
 pop r12
 ret

; One borrowed read-only Matrix parameter. The descriptor is snapshotted once;
; the payload is never copied and the pointer cannot escape this call.
nebo_matrix_i64_borrow_sum:
 push rbp
 mov rbp,rsp
 sub rsp,96
 mov rsi,rdi
 lea rdi,[rsp]
 mov ecx,NEBO_MATRIX_SIZE/8
 rep movsq
 lea rdi,[rsp]
 call nebo_matrix_i64_sum
 leave
 ret

; Hidden sret descriptor RDI, explicit caller payload RSI, borrowed descriptor
; RDX, scalar RCX, new storage identity R8. Success returns the identical sret
; pointer in RAX. Failure returns RAX=0 and the numeric status in EDX.
nebo_matrix_i64_sret_scale:
 push rbp
 mov rbp,rsp
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,104
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rsi,r14
 lea rdi,[rsp]
 mov ecx,NEBO_MATRIX_SIZE/8
 rep movsq
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 mov rcx,r15
 mov r8,rbx
 call nebo_matrix_i64_scale
 test eax,eax
 jnz .sret_failure
 mov rax,r12
 xor edx,edx
 jmp .sret_done
.sret_failure:
 mov edx,eax
 xor eax,eax
.sret_done:
 add rsp,104
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 leave
 ret

; descriptor -> status EAX, exact NBM1 bytes RDX.
nebo_matrix_i64_serialized_size:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .size_done
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_OWNED
 jz .size_alias
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_CONTIGUOUS
 jz .size_contract
 mov rdx,[rdi+NEBO_MATRIX_ROWS]
 imul rdx,[rdi+NEBO_MATRIX_COLS]
 shl rdx,3
 add rdx,NEBO_MATRIX_I64_NBM1_HEADER_BYTES
 xor eax,eax
.size_done:
 ret
.size_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
.size_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret

; descriptor, output bytes, output capacity -> status EAX, written bytes RDX.
nebo_matrix_i64_serialize:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_matrix_i64_serialized_size
 test eax,eax
 jnz .serialize_done
 test r13,r13
 jz .serialize_argument
 cmp r14,rdx
 jb .serialize_workspace
 ; Output must not overlap descriptor or payload.
 mov rax,r13
 add rax,rdx
 jc .serialize_overflow
 cmp r13,r12
 ja .serialize_descriptor_end
 lea rcx,[r12+NEBO_MATRIX_SIZE]
 cmp rax,rcx
 ja .serialize_alias
.serialize_descriptor_end:
 mov rcx,[r12+NEBO_MATRIX_DATA]
 mov r8,[r12+NEBO_MATRIX_CAPACITY]
 shl r8,3
 add r8,rcx
 cmp r13,r8
 jae .serialize_write
 cmp rcx,rax
 jb .serialize_alias
.serialize_write:
 mov dword [r13],0x314d424e
 mov word [r13+4],1
 mov word [r13+6],0
 mov qword [r13+8],NEBO_MATRIX_DTYPE_I64
 mov rax,[r12+NEBO_MATRIX_ROWS]
 mov [r13+16],rax
 mov rax,[r12+NEBO_MATRIX_COLS]
 mov [r13+24],rax
 mov rax,[r12+NEBO_MATRIX_ROWS]
 imul rax,[r12+NEBO_MATRIX_COLS]
 mov [r13+32],rax
 mov rcx,rax
 shl rax,3
 mov [r13+40],rax
 mov rsi,[r12+NEBO_MATRIX_DATA]
 lea rdi,[r13+NEBO_MATRIX_I64_NBM1_HEADER_BYTES]
 rep movsq
 mov rdx,[r13+40]
 add rdx,NEBO_MATRIX_I64_NBM1_HEADER_BYTES
 xor eax,eax
 jmp .serialize_done
.serialize_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .serialize_done
.serialize_workspace:
 mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jmp .serialize_done
.serialize_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .serialize_done
.serialize_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.serialize_done:
 pop r14
 pop r13
 pop r12
 ret

; destination descriptor, destination payload, exact NBM1 bytes, byte length,
; new storage identity. Validation is complete before any destination write.
nebo_matrix_i64_deserialize:
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r14,r14
 jz .deserialize_argument
 cmp r15,NEBO_MATRIX_I64_NBM1_HEADER_BYTES
 jb .deserialize_contract
 cmp dword [r14],0x314d424e
 jne .deserialize_contract
 cmp word [r14+4],1
 jne .deserialize_contract
 cmp word [r14+6],0
 jne .deserialize_contract
 cmp qword [r14+8],NEBO_MATRIX_DTYPE_I64
 jne .deserialize_contract
 mov rdx,[r14+16]
 mov rcx,[r14+24]
 mov r8,rbx
 mov rdi,r12
 mov rsi,r13
 call matrix_i64_constructor_validate
 test eax,eax
 jnz .deserialize_done
 mov rax,[r14+16]
 imul rax,[r14+24]
 jo .deserialize_overflow
 cmp rax,[r14+32]
 jne .deserialize_contract
 mov rcx,rax
 shl rax,3
 jo .deserialize_overflow
 cmp rax,[r14+40]
 jne .deserialize_contract
 add rax,NEBO_MATRIX_I64_NBM1_HEADER_BYTES
 jc .deserialize_overflow
 cmp rax,r15
 jne .deserialize_contract
 mov rdx,r14
 add rdx,r15
 jc .deserialize_overflow
 ; Descriptor and payload destination must not overlap serialized input.
 cmp r12,rdx
 jae .deserialize_desc_ok
 lea rax,[r12+NEBO_MATRIX_SIZE]
 cmp r14,rax
 jb .deserialize_alias
.deserialize_desc_ok:
 mov rax,rcx
 shl rax,3
 mov r8,r13
 add r8,rax
 jc .deserialize_overflow
 cmp r13,rdx
 jae .deserialize_publish
 cmp r14,r8
 jb .deserialize_alias
.deserialize_publish:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r14+NEBO_MATRIX_I64_NBM1_HEADER_BYTES]
 mov rcx,[r14+16]
 mov r8,[r14+24]
 mov r9,rbx
 call nebo_matrix_i64_from_buffer
 jmp .deserialize_done
.deserialize_argument:
 mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .deserialize_done
.deserialize_contract:
 mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 jmp .deserialize_done
.deserialize_alias:
 mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp .deserialize_done
.deserialize_overflow:
 mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
.deserialize_done:
 add rsp,8
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; Stable headless adapter: descriptor -> rows RDX, columns RCX,
; elementCount R8, layout R9. It performs no I/O and touches no display.
nebo_matrix_i64_headless_shape:
 push rdi
 call nebo_matrix_i64_validate
 pop rdi
 test eax,eax
 jnz .headless_done
 mov rdx,[rdi+NEBO_MATRIX_ROWS]
 mov rcx,[rdi+NEBO_MATRIX_COLS]
 mov r8,rdx
 imul r8,rcx
 mov r9d,2
 test qword [rdi+NEBO_MATRIX_FLAGS],NEBO_MATRIX_FLAG_CONTIGUOUS
 jz .headless_done
 mov r9d,1
.headless_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
