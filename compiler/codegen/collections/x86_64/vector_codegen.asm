; Bounded Vector/Matrix scientific source emitter.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/vector_vertical.inc"
%include "compiler/codegen/collections/x86_64/vector_codegen.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal

section .rodata
legacy_prefix: db 10,'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    mov rax, '
legacy_prefix_len equ $-legacy_prefix
legacy_suffix: db 10,'    ret',10
legacy_suffix_len equ $-legacy_suffix
composition_legacy_prefix: db 10,'section .text',10,'nebo_scientific_owner_'
composition_legacy_prefix_len equ $-composition_legacy_prefix
composition_legacy_mid: db ':',10,'    mov rax, '
composition_legacy_mid_len equ $-composition_legacy_mid
composition_legacy_suffix: db 10,'    xor edx, edx',10,'    ret',10
composition_legacy_suffix_len equ $-composition_legacy_suffix
matrix_common: db 10,'extern nebo_matrix_i64_zeros',10,'extern nebo_matrix_i64_filled',10,'extern nebo_matrix_i64_from_rows',10,'extern nebo_matrix_i64_from_buffer',10,'extern nebo_matrix_i64_add',10,'extern nebo_matrix_i64_sum',10,'section .bss align=16',10,'matrix_desc0: resb 88',10,'matrix_payload0: resb 512',10,'matrix_desc1: resb 88',10,'matrix_payload1: resb 512',10,'matrix_desc2: resb 88',10,'matrix_payload2: resb 512',10
matrix_common_len equ $-matrix_common
matrix_r2_common: db 10
 db 'extern nebo_matrix_i64_zeros',10,'extern nebo_matrix_i64_filled',10
 db 'extern nebo_matrix_i64_from_rows',10,'extern nebo_matrix_i64_from_buffer',10
 db 'extern nebo_matrix_i64_rows',10,'extern nebo_matrix_i64_columns',10,'extern nebo_matrix_i64_layout',10
 db 'extern nebo_matrix_i64_at',10,'extern nebo_matrix_i64_set',10
 db 'extern nebo_matrix_i64_row_view',10,'extern nebo_matrix_i64_column_view',10,'extern nebo_matrix_i64_slice_view',10
 db 'extern nebo_matrix_i64_transpose_view',10,'extern nebo_matrix_i64_contiguous',10
 db 'extern nebo_matrix_i64_add',10,'extern nebo_matrix_i64_subtract',10,'extern nebo_matrix_i64_multiply_elements',10
 db 'extern nebo_matrix_i64_scale',10,'extern nebo_matrix_i64_sum',10,'extern nebo_matrix_i64_min',10,'extern nebo_matrix_i64_max',10
 db 'extern nebo_matrix_i64_trace',10,'extern nebo_matrix_i64_is_square',10
 db 'extern nebo_matrix_i64_matmul',10,'extern nebo_matrix_i64_matmul_into',10
 db 'extern nebo_matrix_i64_borrow_sum',10,'extern nebo_matrix_i64_serialized_size',10
 db 'extern nebo_matrix_i64_serialize',10,'extern nebo_matrix_i64_deserialize',10
 db 'extern nebo_tensor_i64_borrow_sum',10
 db 'extern nebo_tensor_i64_sret_filled',10
 db 'extern nebo_tensor_i64_sum_all',10
 db 'section .bss align=16',10
 db 'matrix_desc0: resb 88',10,'matrix_payload0: resb 512',10
 db 'matrix_desc1: resb 88',10,'matrix_payload1: resb 512',10
 db 'matrix_desc2: resb 88',10,'matrix_payload2: resb 512',10
 db 'matrix_encoded: resb 560',10
matrix_r2_common_len equ $-matrix_r2_common
matrix_data: db 'section .data align=8',10,'matrix_source:',10
matrix_data_len equ $-matrix_data
dq_prefix: db '    dq '
dq_prefix_len equ $-dq_prefix
matrix_text: db 'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10
matrix_text_len equ $-matrix_text
matrix_composition_text: db 'section .text',10,'nebo_scientific_owner_'
matrix_composition_text_len equ $-matrix_composition_text
matrix_composition_label_tail: db ':',10
matrix_composition_label_tail_len equ $-matrix_composition_label_tail
matrix_composition_data: db 'section .data align=8',10,'matrix_source_'
matrix_composition_data_len equ $-matrix_composition_data
matrix_composition_data_tail: db ':',10
matrix_composition_data_tail_len equ $-matrix_composition_data_tail
desc0: db '    lea rdi, [rel matrix_desc0]',10,'    lea rsi, [rel matrix_payload0]',10
desc0_len equ $-desc0
desc1: db '    lea rdi, [rel matrix_desc1]',10,'    lea rsi, [rel matrix_payload1]',10
desc1_len equ $-desc1
desc2: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10
desc2_len equ $-desc2
zeros0_call: db '    mov r8, 1',10,'    call nebo_matrix_i64_zeros',10,'    test eax, eax',10,'    jnz .matrix_fail',10
zeros0_call_len equ $-zeros0_call
zeros1_call: db '    mov r8, 2',10,'    call nebo_matrix_i64_zeros',10,'    test eax, eax',10,'    jnz .matrix_fail',10
zeros1_call_len equ $-zeros1_call
filled_call: db '    mov r9, 1',10,'    call nebo_matrix_i64_filled',10,'    test eax, eax',10,'    jnz .matrix_fail',10
filled_call_len equ $-filled_call
filled1_call: db '    mov r9, 2',10,'    call nebo_matrix_i64_filled',10,'    test eax, eax',10,'    jnz .matrix_fail',10
filled1_call_len equ $-filled1_call
zeros2_call: db '    mov r8, 3',10,'    call nebo_matrix_i64_zeros',10,'    test eax, eax',10,'    jnz .matrix_fail',10
zeros2_call_len equ $-zeros2_call
copy_source: db '    lea rdx, [rel matrix_source]',10
copy_source_len equ $-copy_source
copy_composition_source: db '    lea rdx, [rel matrix_source_'
copy_composition_source_len equ $-copy_composition_source
copy_composition_source_tail: db ']',10
copy_composition_source_tail_len equ $-copy_composition_source_tail
from_buffer_call: db '    mov r9, 1',10,'    call nebo_matrix_i64_from_buffer',10,'    test eax, eax',10,'    jnz .matrix_fail',10
from_buffer_call_len equ $-from_buffer_call
from_rows_call: db '    mov r9, 1',10,'    call nebo_matrix_i64_from_rows',10,'    test eax, eax',10,'    jnz .matrix_fail',10
from_rows_call_len equ $-from_rows_call
add_call: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10,'    lea rdx, [rel matrix_desc0]',10,'    lea rcx, [rel matrix_desc1]',10,'    mov r8, 3',10,'    call nebo_matrix_i64_add',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    lea rdi, [rel matrix_desc2]',10
add_call_len equ $-add_call
sum0: db '    lea rdi, [rel matrix_desc0]',10
sum0_len equ $-sum0
sum_finish: db '    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10,'.matrix_fail:',10,'    mov rax, 1',10,'    ret',10
sum_finish_len equ $-sum_finish
composition_sum_finish: db '    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10,'.matrix_fail:',10,'    xor eax, eax',10,'    mov edx, 1',10,'    ret',10
composition_sum_finish_len equ $-composition_sum_finish
matrix_fail_tail: db '.matrix_fail:',10,'    mov rax, 1',10,'    ret',10
matrix_fail_tail_len equ $-matrix_fail_tail
composition_matrix_fail_tail: db '.matrix_fail:',10,'    xor eax, eax',10,'    mov edx, 1',10,'    ret',10
composition_matrix_fail_tail_len equ $-composition_matrix_fail_tail
status_to_scalar_tail: db '    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
status_to_scalar_tail_len equ $-status_to_scalar_tail
composition_status_to_scalar_tail: db '    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_status_to_scalar_tail_len equ $-composition_status_to_scalar_tail
sum_desc0_tail: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
sum_desc0_tail_len equ $-sum_desc0_tail
composition_sum_desc0_tail: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_sum_desc0_tail_len equ $-composition_sum_desc0_tail
sum_desc1_tail: db '    lea rdi, [rel matrix_desc1]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
sum_desc1_tail_len equ $-sum_desc1_tail
composition_sum_desc1_tail: db '    lea rdi, [rel matrix_desc1]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_sum_desc1_tail_len equ $-composition_sum_desc1_tail
sum_desc2_tail: db '    lea rdi, [rel matrix_desc2]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
sum_desc2_tail_len equ $-sum_desc2_tail
composition_sum_desc2_tail: db '    lea rdi, [rel matrix_desc2]',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_sum_desc2_tail_len equ $-composition_sum_desc2_tail
arg_rsi: db '    mov rsi, '
arg_rsi_len equ $-arg_rsi
arg_r9: db '    mov r9, '
arg_r9_len equ $-arg_r9
scalar_rows: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_rows',10
scalar_rows_len equ $-scalar_rows
scalar_columns: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_columns',10
scalar_columns_len equ $-scalar_columns
scalar_layout: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_layout',10
scalar_layout_len equ $-scalar_layout
scalar_at: db '    lea rdi, [rel matrix_desc0]',10
scalar_at_len equ $-scalar_at
scalar_at_call: db '    call nebo_matrix_i64_at',10
scalar_at_call_len equ $-scalar_at_call
scalar_min: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_min',10
scalar_min_len equ $-scalar_min
scalar_max: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_max',10
scalar_max_len equ $-scalar_max
scalar_trace: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_trace',10
scalar_trace_len equ $-scalar_trace
scalar_square: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_is_square',10
scalar_square_len equ $-scalar_square
scalar_size: db '    lea rdi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_serialized_size',10
scalar_size_len equ $-scalar_size
set_call: db '    lea rdi, [rel matrix_desc0]',10
set_call_len equ $-set_call
set_finish: db '    call nebo_matrix_i64_set',10,'    test eax, eax',10,'    jnz .matrix_fail',10
set_finish_len equ $-set_finish
row_view_start: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_desc0]',10
row_view_start_len equ $-row_view_start
row_view_call: db '    call nebo_matrix_i64_row_view',10,'    test eax, eax',10,'    jnz .matrix_fail',10
row_view_call_len equ $-row_view_call
column_view_call: db '    call nebo_matrix_i64_column_view',10,'    test eax, eax',10,'    jnz .matrix_fail',10
column_view_call_len equ $-column_view_call
slice_view_call: db '    call nebo_matrix_i64_slice_view',10,'    test eax, eax',10,'    jnz .matrix_fail',10
slice_view_call_len equ $-slice_view_call
transpose_call: db '    lea rdi, [rel matrix_desc1]',10,'    lea rsi, [rel matrix_desc0]',10,'    call nebo_matrix_i64_transpose_view',10,'    test eax, eax',10,'    jnz .matrix_fail',10
transpose_call_len equ $-transpose_call
contiguous_call: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10,'    lea rdx, [rel matrix_desc1]',10,'    lea rcx, [rel matrix_desc0]',10,'    mov r8, 3',10,'    call nebo_matrix_i64_contiguous',10,'    test eax, eax',10,'    jnz .matrix_fail',10
contiguous_call_len equ $-contiguous_call
binary_start: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10,'    lea rdx, [rel matrix_desc0]',10,'    lea rcx, [rel matrix_desc1]',10,'    mov r8, 3',10
binary_start_len equ $-binary_start
binary_add_call: db '    call nebo_matrix_i64_add',10,'    test eax, eax',10,'    jnz .matrix_fail',10
binary_add_call_len equ $-binary_add_call
binary_subtract_call: db '    call nebo_matrix_i64_subtract',10,'    test eax, eax',10,'    jnz .matrix_fail',10
binary_subtract_call_len equ $-binary_subtract_call
binary_multiply_call: db '    call nebo_matrix_i64_multiply_elements',10,'    test eax, eax',10,'    jnz .matrix_fail',10
binary_multiply_call_len equ $-binary_multiply_call
binary_matmul_call: db '    call nebo_matrix_i64_matmul',10,'    test eax, eax',10,'    jnz .matrix_fail',10
binary_matmul_call_len equ $-binary_matmul_call
scale_start: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10,'    lea rdx, [rel matrix_desc0]',10
scale_start_len equ $-scale_start
scale_finish: db '    mov r8, 3',10,'    call nebo_matrix_i64_scale',10,'    test eax, eax',10,'    jnz .matrix_fail',10
scale_finish_len equ $-scale_finish
matmul_into_call: db '    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_desc0]',10,'    lea rdx, [rel matrix_desc1]',10,'    call nebo_matrix_i64_matmul_into',10,'    test eax, eax',10,'    jnz .matrix_fail',10
matmul_into_call_len equ $-matmul_into_call
serialize_start: db '    lea rdi, [rel matrix_desc0]',10,'    lea rsi, [rel matrix_encoded]',10,'    mov rdx, 560',10,'    call nebo_matrix_i64_serialize',10,'    test eax, eax',10,'    jnz .matrix_fail',10
serialize_start_len equ $-serialize_start
serialize_length_return: db '    mov rax, 70',10,'    ret',10
serialize_length_return_len equ $-serialize_length_return
composition_serialize_length_return: db '    mov rax, 70',10,'    xor edx, edx',10,'    ret',10
composition_serialize_length_return_len equ $-composition_serialize_length_return
deserialize_finish: db '    mov rcx, rdx',10,'    lea rdi, [rel matrix_desc2]',10,'    lea rsi, [rel matrix_payload2]',10,'    lea rdx, [rel matrix_encoded]',10,'    mov r8, 3',10,'    call nebo_matrix_i64_deserialize',10,'    test eax, eax',10,'    jnz .matrix_fail',10
deserialize_finish_len equ $-deserialize_finish
function_parameter_text: db 'section .text',10,'matrix_user_f:',10,'    call nebo_matrix_i64_borrow_sum',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10
function_parameter_text_len equ $-function_parameter_text
function_parameter_call: db '    lea rdi, [rel matrix_desc0]',10,'    call matrix_user_f',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
function_parameter_call_len equ $-function_parameter_call
function_return_prefix: db 'section .text',10,'matrix_user_f:',10,'    push r12',10,'    mov r12, rdi',10
function_return_prefix_len equ $-function_return_prefix
function_return_publish: db '    mov r9, 4',10,'    call nebo_matrix_i64_filled',10,'    test eax, eax',10,'    jnz .sret_fail',10,'    mov rax, r12',10,'    pop r12',10,'    ret',10,'.sret_fail:',10,'    xor eax, eax',10,'    pop r12',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    lea rdi, [rel matrix_desc0]',10,'    lea rsi, [rel matrix_payload0]',10,'    call matrix_user_f',10,'    test rax, rax',10,'    jz .matrix_fail',10,'    lea rcx, [rel matrix_desc0]',10,'    cmp rax, rcx',10,'    jne .matrix_fail',10,'    mov rdi, rax',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    ret',10
function_return_publish_len equ $-function_return_publish
composition_user_function: db 'section .text',10,'matrix_user_f_'
composition_user_function_len equ $-composition_user_function
composition_parameter_function_tail: db ':',10,'    call nebo_matrix_i64_borrow_sum',10,'    ret',10
composition_parameter_function_tail_len equ $-composition_parameter_function_tail
composition_return_function_tail: db ':',10,'    push r12',10,'    mov r12, rdi',10
composition_return_function_tail_len equ $-composition_return_function_tail
composition_return_publish: db '    mov r9, 4',10,'    call nebo_matrix_i64_filled',10,'    test eax, eax',10,'    jnz .sret_fail',10,'    mov rax, r12',10,'    pop r12',10,'    ret',10,'.sret_fail:',10,'    xor eax, eax',10,'    pop r12',10,'    ret',10
composition_return_publish_len equ $-composition_return_publish
composition_user_call: db '    call matrix_user_f_'
composition_user_call_len equ $-composition_user_call
composition_user_call_tail: db 10
composition_user_call_tail_len equ $-composition_user_call_tail
composition_parameter_call_tail: db '    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_parameter_call_tail_len equ $-composition_parameter_call_tail
composition_return_call_prefix: db '    lea rdi, [rel matrix_desc0]',10,'    lea rsi, [rel matrix_payload0]',10
composition_return_call_prefix_len equ $-composition_return_call_prefix
composition_return_call_tail: db '    test rax, rax',10,'    jz .matrix_fail',10,'    lea rcx, [rel matrix_desc0]',10,'    cmp rax, rcx',10,'    jne .matrix_fail',10,'    mov rdi, rax',10,'    call nebo_matrix_i64_sum',10,'    test eax, eax',10,'    jnz .matrix_fail',10,'    mov rax, rdx',10,'    xor edx, edx',10,'    ret',10
composition_return_call_tail_len equ $-composition_return_call_tail
tensor_function_common: db 10
 db 'extern nebo_tensor_i64_borrow_sum',10
 db 'extern nebo_tensor_i64_sret_filled',10
 db 'extern nebo_tensor_i64_sum_all',10
 db 'section .bss align=16',10
 db 'tensor_desc0: resb 168',10
 db 'tensor_payload0: resb 512',10
 db 'section .data align=8',10
 db 'tensor_shape:',10
tensor_function_common_len equ $-tensor_function_common
tensor_parameter_text: db 'section .text',10,'tensor_user_f:',10,'    call nebo_tensor_i64_borrow_sum',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    lea rdi, [rel tensor_desc0]',10,'    lea rsi, [rel tensor_payload0]',10
tensor_parameter_text_len equ $-tensor_parameter_text
tensor_parameter_tail: db '    call nebo_tensor_i64_sret_filled',10,'    test rax, rax',10,'    jz .tensor_fail',10,'    test edx, edx',10,'    jnz .tensor_fail',10,'    lea rdi, [rel tensor_desc0]',10,'    call tensor_user_f',10,'    test edx, edx',10,'    jnz .tensor_fail',10,'    ret',10,'.tensor_fail:',10,'    mov rax, 1',10,'    ret',10
tensor_parameter_tail_len equ $-tensor_parameter_tail
tensor_return_text: db 'section .text',10,'tensor_user_f:',10,'    call nebo_tensor_i64_sret_filled',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    lea rdi, [rel tensor_desc0]',10,'    lea rsi, [rel tensor_payload0]',10
tensor_return_text_len equ $-tensor_return_text
tensor_return_tail: db '    call tensor_user_f',10,'    test rax, rax',10,'    jz .tensor_fail',10,'    test edx, edx',10,'    jnz .tensor_fail',10,'    lea rcx, [rel tensor_desc0]',10,'    cmp rax, rcx',10,'    jne .tensor_fail',10,'    mov rdi, rax',10,'    call nebo_tensor_i64_sum_all',10,'    test edx, edx',10,'    jnz .tensor_fail',10,'    ret',10,'.tensor_fail:',10,'    mov rax, 1',10,'    ret',10
tensor_return_tail_len equ $-tensor_return_tail
tensor_shape_r0: db '    dq 0',10
tensor_shape_r0_len equ $-tensor_shape_r0
tensor_shape_rcx: db '    lea rcx, [rel tensor_shape]',10
tensor_shape_rcx_len equ $-tensor_shape_rcx
tensor_storage: db '    mov r9, 1',10
tensor_storage_len equ $-tensor_storage
tensor_composition_desc_prefix: db 'section .bss align=16',10,'tensor_desc_'
tensor_composition_desc_prefix_len equ $-tensor_composition_desc_prefix
tensor_composition_desc_tail: db ': resb 168',10
tensor_composition_desc_tail_len equ $-tensor_composition_desc_tail
tensor_composition_payload_prefix: db 'tensor_payload_'
tensor_composition_payload_prefix_len equ $-tensor_composition_payload_prefix
tensor_composition_payload_tail: db ': resb 512',10
tensor_composition_payload_tail_len equ $-tensor_composition_payload_tail
tensor_composition_shape_prefix: db 'section .data align=8',10,'tensor_shape_'
tensor_composition_shape_prefix_len equ $-tensor_composition_shape_prefix
tensor_composition_shape_tail: db ':',10
tensor_composition_shape_tail_len equ $-tensor_composition_shape_tail
tensor_composition_user_prefix: db 'section .text',10,'tensor_user_f_'
tensor_composition_user_prefix_len equ $-tensor_composition_user_prefix
tensor_composition_parameter_user_tail: db ':',10,'    call nebo_tensor_i64_borrow_sum',10,'    ret',10
tensor_composition_parameter_user_tail_len equ $-tensor_composition_parameter_user_tail
tensor_composition_return_user_tail: db ':',10,'    call nebo_tensor_i64_sret_filled',10,'    ret',10
tensor_composition_return_user_tail_len equ $-tensor_composition_return_user_tail
tensor_composition_desc_rdi_prefix: db '    lea rdi, [rel tensor_desc_'
tensor_composition_desc_rdi_prefix_len equ $-tensor_composition_desc_rdi_prefix
tensor_composition_desc_rdi_tail: db ']',10
tensor_composition_desc_rdi_tail_len equ $-tensor_composition_desc_rdi_tail
tensor_composition_payload_rsi_prefix: db '    lea rsi, [rel tensor_payload_'
tensor_composition_payload_rsi_prefix_len equ $-tensor_composition_payload_rsi_prefix
tensor_composition_payload_rsi_tail: db ']',10
tensor_composition_payload_rsi_tail_len equ $-tensor_composition_payload_rsi_tail
tensor_composition_shape_rcx_prefix: db '    lea rcx, [rel tensor_shape_'
tensor_composition_shape_rcx_prefix_len equ $-tensor_composition_shape_rcx_prefix
tensor_composition_shape_rcx_tail: db ']',10
tensor_composition_shape_rcx_tail_len equ $-tensor_composition_shape_rcx_tail
tensor_composition_user_call_prefix: db '    call tensor_user_f_'
tensor_composition_user_call_prefix_len equ $-tensor_composition_user_call_prefix
tensor_composition_user_call_tail: db 10
tensor_composition_user_call_tail_len equ $-tensor_composition_user_call_tail
tensor_composition_parameter_tail: db '    call nebo_tensor_i64_sret_filled',10,'    test rax, rax',10,'    jz .tensor_fail',10,'    test edx, edx',10,'    jnz .tensor_fail',10
tensor_composition_parameter_tail_len equ $-tensor_composition_parameter_tail
tensor_composition_parameter_result_tail: db '    test edx, edx',10,'    jnz .tensor_fail',10,'    ret',10,'.tensor_fail:',10,'    xor eax, eax',10,'    mov edx, 1',10,'    ret',10
tensor_composition_parameter_result_tail_len equ $-tensor_composition_parameter_result_tail
tensor_composition_return_result_tail: db '    test rax, rax',10,'    jz .tensor_fail',10,'    test edx, edx',10,'    jnz .tensor_fail',10
tensor_composition_return_result_tail_len equ $-tensor_composition_return_result_tail
tensor_composition_identity_prefix: db '    lea rcx, [rel tensor_desc_'
tensor_composition_identity_prefix_len equ $-tensor_composition_identity_prefix
tensor_composition_identity_tail: db ']',10,'    cmp rax, rcx',10,'    jne .tensor_fail',10,'    mov rdi, rax',10,'    call nebo_tensor_i64_sum_all',10,'    test edx, edx',10,'    jnz .tensor_fail',10,'    ret',10,'.tensor_fail:',10,'    xor eax, eax',10,'    mov edx, 1',10,'    ret',10
tensor_composition_identity_tail_len equ $-tensor_composition_identity_tail
imm_rdx: db '    mov rdx, '
imm_rdx_len equ $-imm_rdx
imm_rcx: db '    mov rcx, '
imm_rcx_len equ $-imm_rcx
imm_r8: db '    mov r8, '
imm_r8_len equ $-imm_r8
newline: db 10

section .data
value: db '0x0000000000000000'
value_len equ $-value
digits: db '0123456789abcdef'

section .text
append:
 mov rax,[rdi+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 test rax,rax
 jz .bad
 mov rdi,rax
 jmp neboc_assembly_writer_append_bytes
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

format_hex:
 add rdi,18
 lea rsi,[rel digits]
 mov ecx,16
.loop:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .loop
 ret

; request, prefix, prefix length, immediate -> append one deterministic line.
append_immediate:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call append
 test eax,eax
 jnz .done
 mov rax,r15
 lea rdi,[rel value]
 call format_hex
 mov rdi,r12
 lea rsi,[rel value]
 mov edx,value_len
 call append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,1
 call append
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret

%macro MATRIX_EMIT 2
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%2
 call append
 test eax,eax
 jnz .writer
%endmacro

%macro MATRIX_IMMEDIATE 2
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%1_len
 mov rcx,[r13+%2]
 call append_immediate
 test eax,eax
 jnz .writer
%endmacro

%macro MATRIX_MODE_EMIT 4
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 jne %%standalone
 MATRIX_EMIT %3,%4
 jmp %%done
%%standalone:
 MATRIX_EMIT %1,%2
%%done:
%endmacro

%macro MATRIX_MODE_FAIL_TAIL 0
 MATRIX_MODE_EMIT matrix_fail_tail,matrix_fail_tail_len,composition_matrix_fail_tail,composition_matrix_fail_tail_len
%endmacro

; Emit one internal symbol fragment whose decimal owner ordinal is the only
; varying component.  Composition owners therefore never share mutable
; Tensor workspaces or private helper symbols.
%macro OWNER_FRAGMENT 4
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%2
 call append
 test eax,eax
 jnz .writer
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel %3]
 mov edx,%4
 call append
 test eax,eax
 jnz .writer
%endmacro

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_vector_codegen_emit_start
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_PRELUDE
 je .composition_prelude
 mov r13,[r12+NEBOC_VECTOR_CODEGEN_VERTICAL_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .source
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 jne .source
 mov rax,[r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET]
 cmp rax,NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .composition_owner_gate
 test rax,rax
 jnz .invalid
 jmp .mode_ready
.composition_owner_gate:
 mov rax,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,64
 ja .invalid
.mode_ready:
 mov r14,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET]
 test r14,r14
 jz .legacy
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_GENERIC_VALUE_PLAN
 je .generic_matrix
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FUNCTION_PARAMETER
 je .function_parameter
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FUNCTION_RETURN
 je .function_return
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_TENSOR_FUNCTION_PARAMETER
 je .tensor_function_parameter
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_TENSOR_FUNCTION_RETURN
 je .tensor_function_return
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_ZEROS_SUM
 ja .source
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 cmp rax,8
 ja .source
 imul rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 jo .source
 cmp rax,64
 ja .source
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .composition_simple_text
 mov rdi,r12
 lea rsi,[rel matrix_common]
 mov edx,matrix_common_len
 call append
 test eax,eax
 jnz .writer
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_BUFFER_SUM
 je .source_data
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_ROWS_SUM
 jne .matrix_text
.source_data:
 mov rdi,r12
 lea rsi,[rel matrix_data]
 mov edx,matrix_data_len
 call append
 test eax,eax
 jnz .writer
 xor r15d,r15d
.source_value_loop:
 cmp r15,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_VALUE_COUNT_OFFSET]
 jae .matrix_text
 cmp r15,NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 jae .source
 mov rdi,r12
 lea rsi,[rel dq_prefix]
 mov edx,dq_prefix_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_VALUES_OFFSET+r15*8]
 call append_immediate
 test eax,eax
 jnz .writer
 inc r15
 jmp .source_value_loop
.matrix_text:
 mov rdi,r12
 lea rsi,[rel matrix_text]
 mov edx,matrix_text_len
 call append
 test eax,eax
 jnz .writer
 jmp .simple_dispatch
.composition_simple_text:
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_BUFFER_SUM
 je .composition_source_data
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_ROWS_SUM
 jne .composition_simple_label
.composition_source_data:
 call .emit_composition_source_data
 test eax,eax
 jnz .writer
.composition_simple_label:
 call .emit_composition_label
 test eax,eax
 jnz .writer
.simple_dispatch:
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_ZEROS_ADD_SUM
 je .zeros_add
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FILLED_SUM
 je .filled
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_BUFFER_SUM
 je .from_buffer
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_FROM_ROWS_SUM
 je .from_rows
 cmp r14,NEBOC_VECTOR_MATRIX_KIND_ZEROS_SUM
 je .zeros_sum
 jmp .source

.emit_desc0_dimensions:
 mov rdi,r12
 lea rsi,[rel desc0]
 mov edx,desc0_len
 call append
 test eax,eax
 jnz .emit_return
 mov rdi,r12
 lea rsi,[rel imm_rdx]
 mov edx,imm_rdx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .emit_return
 mov rdi,r12
 lea rsi,[rel imm_rcx]
 mov edx,imm_rcx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 call append_immediate
.emit_return:
 ret

.zeros_sum:
 call .emit_desc0_dimensions
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel zeros0_call]
 mov edx,zeros0_call_len
 call append
 test eax,eax
 jnz .writer
 jmp .reduce0

.filled:
 call .emit_desc0_dimensions
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_r8]
 mov edx,imm_r8_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel filled_call]
 mov edx,filled_call_len
 call append
 test eax,eax
 jnz .writer
 jmp .reduce0

.from_buffer:
 call .emit_desc0_dimensions
 test eax,eax
 jnz .writer
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .from_buffer_composition_source
 mov rdi,r12
 lea rsi,[rel copy_source]
 mov edx,copy_source_len
 call append
 jmp .from_buffer_source_done
.from_buffer_composition_source:
 call .emit_composition_source_pointer
.from_buffer_source_done:
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_rcx]
 mov edx,imm_rcx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_r8]
 mov edx,imm_r8_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel from_buffer_call]
 mov edx,from_buffer_call_len
 call append
 test eax,eax
 jnz .writer
 jmp .reduce0

.from_rows:
 call .emit_desc0_dimensions
 test eax,eax
 jnz .writer
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .from_rows_composition_source
 mov rdi,r12
 lea rsi,[rel copy_source]
 mov edx,copy_source_len
 call append
 jmp .from_rows_source_done
.from_rows_composition_source:
 call .emit_composition_source_pointer
.from_rows_source_done:
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_rcx]
 mov edx,imm_rcx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_r8]
 mov edx,imm_r8_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel from_rows_call]
 mov edx,from_rows_call_len
 call append
 test eax,eax
 jnz .writer
 jmp .reduce0

.zeros_add:
 call .emit_desc0_dimensions
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel zeros0_call]
 mov edx,zeros0_call_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel desc1]
 mov edx,desc1_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_rdx]
 mov edx,imm_rdx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel imm_rcx]
 mov edx,imm_rcx_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 call append_immediate
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel zeros1_call]
 mov edx,zeros1_call_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel add_call]
 mov edx,add_call_len
 call append
 test eax,eax
 jnz .writer
 jmp .reduce_finish

.reduce0:
 mov rdi,r12
 lea rsi,[rel sum0]
 mov edx,sum0_len
 call append
 test eax,eax
 jnz .writer
.reduce_finish:
 MATRIX_MODE_EMIT sum_finish,sum_finish_len,composition_sum_finish,composition_sum_finish_len
 jmp .success

.generic_matrix:
 ; One generic typed Matrix value plan, bounded to the authenticated 8x8/64
 ; element public profile.  Constructor, operation, arguments and result
 ; category came from structural tokens, never from a fixture discriminator.
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 cmp rax,8
 ja .source
 imul rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 jo .source
 cmp rax,64
 ja .source
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .generic_composition_text
 MATRIX_EMIT matrix_r2_common,matrix_r2_common_len
 MATRIX_EMIT matrix_text,matrix_text_len
 jmp .generic_text_ready
.generic_composition_text:
 call .emit_composition_label
 test eax,eax
 jnz .writer
.generic_text_ready:
 ; Primary caller-owned descriptor and payload.
 MATRIX_EMIT desc0,desc0_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT filled_call,filled_call_len
 test qword [r13+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_SECONDARY
 jz .generic_operation
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_ROWS_OFFSET]
 cmp rax,8
 ja .source
 imul rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET]
 jo .source
 cmp rax,64
 ja .source
 MATRIX_EMIT desc1,desc1_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_FILL_OFFSET
 MATRIX_EMIT filled1_call,filled1_call_len
.generic_operation:
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION0_OFFSET]
 cmp rax,NEBOC_MATRIX_OPERATION_ROWS
 je .generic_rows
 cmp rax,NEBOC_MATRIX_OPERATION_COLUMNS
 je .generic_columns
 cmp rax,NEBOC_MATRIX_OPERATION_LAYOUT
 je .generic_layout
 cmp rax,NEBOC_MATRIX_OPERATION_AT
 je .generic_at
 cmp rax,NEBOC_MATRIX_OPERATION_SET
 je .generic_set
 cmp rax,NEBOC_MATRIX_OPERATION_ROW
 je .generic_row
 cmp rax,NEBOC_MATRIX_OPERATION_COLUMN
 je .generic_column
 cmp rax,NEBOC_MATRIX_OPERATION_SLICE
 je .generic_slice
 cmp rax,NEBOC_MATRIX_OPERATION_TRANSPOSE_VIEW
 je .generic_transpose
 cmp rax,NEBOC_MATRIX_OPERATION_ADD
 je .generic_add
 cmp rax,NEBOC_MATRIX_OPERATION_SUBTRACT
 je .generic_subtract
 cmp rax,NEBOC_MATRIX_OPERATION_MULTIPLY_ELEMENTS
 je .generic_multiply
 cmp rax,NEBOC_MATRIX_OPERATION_SCALE
 je .generic_scale
 cmp rax,NEBOC_MATRIX_OPERATION_MIN
 je .generic_min
 cmp rax,NEBOC_MATRIX_OPERATION_MAX
 je .generic_max
 cmp rax,NEBOC_MATRIX_OPERATION_TRACE
 je .generic_trace
 cmp rax,NEBOC_MATRIX_OPERATION_IS_SQUARE
 je .generic_square
 cmp rax,NEBOC_MATRIX_OPERATION_MATMUL
 je .generic_matmul
 cmp rax,NEBOC_MATRIX_OPERATION_MATMUL_INTO
 je .generic_matmul_into
 cmp rax,NEBOC_MATRIX_OPERATION_SERIALIZED_SIZE_NBM1
 je .generic_serialized_size
 cmp rax,NEBOC_MATRIX_OPERATION_SERIALIZE_NBM1
 je .generic_serialize
 jmp .source

.generic_scalar_finish:
 MATRIX_MODE_EMIT status_to_scalar_tail,status_to_scalar_tail_len,composition_status_to_scalar_tail,composition_status_to_scalar_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_rows:
 MATRIX_EMIT scalar_rows,scalar_rows_len
 jmp .generic_scalar_finish
.generic_columns:
 MATRIX_EMIT scalar_columns,scalar_columns_len
 jmp .generic_scalar_finish
.generic_layout:
 MATRIX_EMIT scalar_layout,scalar_layout_len
 jmp .generic_scalar_finish
.generic_at:
 MATRIX_EMIT scalar_at,scalar_at_len
 MATRIX_IMMEDIATE arg_rsi,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG1_OFFSET
 MATRIX_EMIT scalar_at_call,scalar_at_call_len
 jmp .generic_scalar_finish
.generic_min:
 MATRIX_EMIT scalar_min,scalar_min_len
 jmp .generic_scalar_finish
.generic_max:
 MATRIX_EMIT scalar_max,scalar_max_len
 jmp .generic_scalar_finish
.generic_trace:
 MATRIX_EMIT scalar_trace,scalar_trace_len
 jmp .generic_scalar_finish
.generic_square:
 MATRIX_EMIT scalar_square,scalar_square_len
 jmp .generic_scalar_finish
.generic_serialized_size:
 MATRIX_EMIT scalar_size,scalar_size_len
 jmp .generic_scalar_finish

.generic_set:
 MATRIX_EMIT set_call,set_call_len
 MATRIX_IMMEDIATE arg_rsi,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG1_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG2_OFFSET
 MATRIX_EMIT set_finish,set_finish_len
 MATRIX_MODE_EMIT sum_desc0_tail,sum_desc0_tail_len,composition_sum_desc0_tail,composition_sum_desc0_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_row:
 MATRIX_EMIT row_view_start,row_view_start_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_EMIT row_view_call,row_view_call_len
 MATRIX_MODE_EMIT sum_desc2_tail,sum_desc2_tail_len,composition_sum_desc2_tail,composition_sum_desc2_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_column:
 MATRIX_EMIT row_view_start,row_view_start_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_EMIT column_view_call,column_view_call_len
 MATRIX_MODE_EMIT sum_desc2_tail,sum_desc2_tail_len,composition_sum_desc2_tail,composition_sum_desc2_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_slice:
 MATRIX_EMIT row_view_start,row_view_start_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG1_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_ARG2_OFFSET
 MATRIX_IMMEDIATE arg_r9,NEBOC_VECTOR_VERTICAL_MATRIX_ARG3_OFFSET
 MATRIX_EMIT slice_view_call,slice_view_call_len
 MATRIX_MODE_EMIT sum_desc2_tail,sum_desc2_tail_len,composition_sum_desc2_tail,composition_sum_desc2_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_transpose:
 MATRIX_EMIT transpose_call,transpose_call_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION1_OFFSET],NEBOC_MATRIX_OPERATION_CONTIGUOUS
 jne .generic_transpose_sum
 MATRIX_EMIT contiguous_call,contiguous_call_len
 MATRIX_MODE_EMIT sum_desc2_tail,sum_desc2_tail_len,composition_sum_desc2_tail,composition_sum_desc2_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_transpose_sum:
 MATRIX_MODE_EMIT sum_desc1_tail,sum_desc1_tail_len,composition_sum_desc1_tail,composition_sum_desc1_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success

.generic_add:
 MATRIX_EMIT binary_start,binary_start_len
 MATRIX_EMIT binary_add_call,binary_add_call_len
 jmp .generic_binary_sum
.generic_subtract:
 MATRIX_EMIT binary_start,binary_start_len
 MATRIX_EMIT binary_subtract_call,binary_subtract_call_len
 jmp .generic_binary_sum
.generic_multiply:
 MATRIX_EMIT binary_start,binary_start_len
 MATRIX_EMIT binary_multiply_call,binary_multiply_call_len
 jmp .generic_binary_sum
.generic_matmul:
 MATRIX_EMIT binary_start,binary_start_len
 MATRIX_EMIT binary_matmul_call,binary_matmul_call_len
.generic_binary_sum:
 MATRIX_MODE_EMIT sum_desc2_tail,sum_desc2_tail_len,composition_sum_desc2_tail,composition_sum_desc2_tail_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_scale:
 MATRIX_EMIT scale_start,scale_start_len
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET
 MATRIX_EMIT scale_finish,scale_finish_len
 jmp .generic_binary_sum
.generic_matmul_into:
 ; The public expression result is explicit caller-owned storage; no hidden
 ; allocation is introduced for the into route.
 MATRIX_EMIT desc2,desc2_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET
 MATRIX_EMIT zeros2_call,zeros2_call_len
 MATRIX_EMIT matmul_into_call,matmul_into_call_len
 jmp .generic_binary_sum
.generic_serialize:
 MATRIX_EMIT serialize_start,serialize_start_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION1_OFFSET],NEBOC_MATRIX_OPERATION_DESERIALIZE_NBM1
 je .generic_deserialize
 MATRIX_MODE_EMIT serialize_length_return,serialize_length_return_len,composition_serialize_length_return,composition_serialize_length_return_len
 MATRIX_MODE_FAIL_TAIL
 jmp .success
.generic_deserialize:
 MATRIX_EMIT deserialize_finish,deserialize_finish_len
 jmp .generic_binary_sum

.emit_composition_label:
 mov rdi,r12
 lea rsi,[rel matrix_composition_text]
 mov edx,matrix_composition_text_len
 call append
 test eax,eax
 jnz .emit_composition_label_done
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_composition_label_done
 mov rdi,r12
 lea rsi,[rel matrix_composition_label_tail]
 mov edx,matrix_composition_label_tail_len
 call append
.emit_composition_label_done:
 ret

.emit_composition_user_label:
 mov rdi,r12
 lea rsi,[rel composition_user_function]
 mov edx,composition_user_function_len
 call append
 test eax,eax
 jnz .emit_composition_user_label_done
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
.emit_composition_user_label_done:
 ret

.emit_composition_user_call:
 mov rdi,r12
 lea rsi,[rel composition_user_call]
 mov edx,composition_user_call_len
 call append
 test eax,eax
 jnz .emit_composition_user_call_done
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_composition_user_call_done
 mov rdi,r12
 lea rsi,[rel composition_user_call_tail]
 mov edx,composition_user_call_tail_len
 call append
.emit_composition_user_call_done:
 ret

.emit_composition_source_data:
 mov rdi,r12
 lea rsi,[rel matrix_composition_data]
 mov edx,matrix_composition_data_len
 call append
 test eax,eax
 jnz .emit_composition_source_data_done
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_composition_source_data_done
 mov rdi,r12
 lea rsi,[rel matrix_composition_data_tail]
 mov edx,matrix_composition_data_tail_len
 call append
 test eax,eax
 jnz .emit_composition_source_data_done
 xor r15d,r15d
.emit_composition_source_value_loop:
 cmp r15,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_VALUE_COUNT_OFFSET]
 jae .emit_composition_source_data_done
 cmp r15,NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 jae .emit_composition_source_data_invalid
 mov rdi,r12
 lea rsi,[rel dq_prefix]
 mov edx,dq_prefix_len
 mov rcx,[r13+NEBOC_VECTOR_VERTICAL_MATRIX_VALUES_OFFSET+r15*8]
 call append_immediate
 test eax,eax
 jnz .emit_composition_source_data_done
 inc r15
 jmp .emit_composition_source_value_loop
.emit_composition_source_data_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.emit_composition_source_data_done:
 ret

.emit_composition_source_pointer:
 mov rdi,r12
 lea rsi,[rel copy_composition_source]
 mov edx,copy_composition_source_len
 call append
 test eax,eax
 jnz .emit_composition_source_pointer_done
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_composition_source_pointer_done
 mov rdi,r12
 lea rsi,[rel copy_composition_source_tail]
 mov edx,copy_composition_source_tail_len
 call append
.emit_composition_source_pointer_done:
 ret

.composition_prelude:
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET],0
 je .invalid
 mov rdi,r12
 lea rsi,[rel matrix_r2_common]
 mov edx,matrix_r2_common_len
 call append
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_VECTOR_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done

.function_parameter:
 ; The user function receives one borrowed, nonescaping descriptor and the
 ; runtime snapshots only the descriptor metadata before reducing its payload.
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .function_parameter_composition
 MATRIX_EMIT matrix_r2_common,matrix_r2_common_len
 MATRIX_EMIT function_parameter_text,function_parameter_text_len
 MATRIX_EMIT desc0,desc0_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT filled_call,filled_call_len
 MATRIX_EMIT function_parameter_call,function_parameter_call_len
 MATRIX_EMIT matrix_fail_tail,matrix_fail_tail_len
 jmp .success
.function_parameter_composition:
 call .emit_composition_user_label
 test eax,eax
 jnz .writer
 MATRIX_EMIT composition_parameter_function_tail,composition_parameter_function_tail_len
 call .emit_composition_label
 test eax,eax
 jnz .writer
 MATRIX_EMIT desc0,desc0_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT filled_call,filled_call_len
 MATRIX_EMIT sum0,sum0_len
 call .emit_composition_user_call
 test eax,eax
 jnz .writer
 MATRIX_EMIT composition_parameter_call_tail,composition_parameter_call_tail_len
 MATRIX_EMIT composition_matrix_fail_tail,composition_matrix_fail_tail_len
 jmp .success
.function_return:
 ; Hidden RDI descriptor plus explicit RSI payload; the callee returns the
 ; identical descriptor pointer in RAX and the typed caller binding consumes it.
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .function_return_composition
 MATRIX_EMIT matrix_r2_common,matrix_r2_common_len
 MATRIX_EMIT function_return_prefix,function_return_prefix_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT function_return_publish,function_return_publish_len
 MATRIX_EMIT matrix_fail_tail,matrix_fail_tail_len
 jmp .success
.function_return_composition:
 call .emit_composition_user_label
 test eax,eax
 jnz .writer
 MATRIX_EMIT composition_return_function_tail,composition_return_function_tail_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET
 MATRIX_IMMEDIATE imm_rcx,NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT composition_return_publish,composition_return_publish_len
 call .emit_composition_label
 test eax,eax
 jnz .writer
 MATRIX_EMIT composition_return_call_prefix,composition_return_call_prefix_len
 call .emit_composition_user_call
 test eax,eax
 jnz .writer
 MATRIX_EMIT composition_return_call_tail,composition_return_call_tail_len
 MATRIX_EMIT composition_matrix_fail_tail,composition_matrix_fail_tail_len
 jmp .success
.tensor_function_parameter:
 ; One descriptor pointer crosses the user boundary.  The helper performs the
 ; contract's exact-once metadata snapshot and never retains or copies payload.
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .tensor_parameter_composition
 MATRIX_EMIT tensor_function_common,tensor_function_common_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],0
 je .tensor_parameter_rank_zero
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],1
 je .tensor_parameter_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],2
 je .tensor_parameter_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET
 jmp .tensor_parameter_shape_done
.tensor_parameter_rank_zero:
 MATRIX_EMIT tensor_shape_r0,tensor_shape_r0_len
.tensor_parameter_shape_done:
 MATRIX_EMIT tensor_parameter_text,tensor_parameter_text_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET
 MATRIX_EMIT tensor_shape_rcx,tensor_shape_rcx_len
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT tensor_storage,tensor_storage_len
 MATRIX_EMIT tensor_parameter_tail,tensor_parameter_tail_len
 jmp .success
.tensor_parameter_composition:
 OWNER_FRAGMENT tensor_composition_desc_prefix,tensor_composition_desc_prefix_len,tensor_composition_desc_tail,tensor_composition_desc_tail_len
 OWNER_FRAGMENT tensor_composition_payload_prefix,tensor_composition_payload_prefix_len,tensor_composition_payload_tail,tensor_composition_payload_tail_len
 OWNER_FRAGMENT tensor_composition_shape_prefix,tensor_composition_shape_prefix_len,tensor_composition_shape_tail,tensor_composition_shape_tail_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],0
 je .tensor_parameter_composition_rank_zero
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],1
 je .tensor_parameter_composition_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],2
 je .tensor_parameter_composition_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET
 jmp .tensor_parameter_composition_shape_done
.tensor_parameter_composition_rank_zero:
 MATRIX_EMIT tensor_shape_r0,tensor_shape_r0_len
.tensor_parameter_composition_shape_done:
 OWNER_FRAGMENT tensor_composition_user_prefix,tensor_composition_user_prefix_len,tensor_composition_parameter_user_tail,tensor_composition_parameter_user_tail_len
 call .emit_composition_label
 test eax,eax
 jnz .writer
 OWNER_FRAGMENT tensor_composition_desc_rdi_prefix,tensor_composition_desc_rdi_prefix_len,tensor_composition_desc_rdi_tail,tensor_composition_desc_rdi_tail_len
 OWNER_FRAGMENT tensor_composition_payload_rsi_prefix,tensor_composition_payload_rsi_prefix_len,tensor_composition_payload_rsi_tail,tensor_composition_payload_rsi_tail_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET
 OWNER_FRAGMENT tensor_composition_shape_rcx_prefix,tensor_composition_shape_rcx_prefix_len,tensor_composition_shape_rcx_tail,tensor_composition_shape_rcx_tail_len
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT tensor_storage,tensor_storage_len
 MATRIX_EMIT tensor_composition_parameter_tail,tensor_composition_parameter_tail_len
 OWNER_FRAGMENT tensor_composition_desc_rdi_prefix,tensor_composition_desc_rdi_prefix_len,tensor_composition_desc_rdi_tail,tensor_composition_desc_rdi_tail_len
 OWNER_FRAGMENT tensor_composition_user_call_prefix,tensor_composition_user_call_prefix_len,tensor_composition_user_call_tail,tensor_composition_user_call_tail_len
 MATRIX_EMIT tensor_composition_parameter_result_tail,tensor_composition_parameter_result_tail_len
 jmp .success
.tensor_function_return:
 ; The caller supplies both fixed destinations.  Success is accepted only if
 ; the callee returns the identical hidden descriptor pointer in RAX.
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 je .tensor_return_composition
 MATRIX_EMIT tensor_function_common,tensor_function_common_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],0
 je .tensor_return_rank_zero
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],1
 je .tensor_return_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],2
 je .tensor_return_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET
 jmp .tensor_return_shape_done
.tensor_return_rank_zero:
 MATRIX_EMIT tensor_shape_r0,tensor_shape_r0_len
.tensor_return_shape_done:
 MATRIX_EMIT tensor_return_text,tensor_return_text_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET
 MATRIX_EMIT tensor_shape_rcx,tensor_shape_rcx_len
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT tensor_storage,tensor_storage_len
 MATRIX_EMIT tensor_return_tail,tensor_return_tail_len
 jmp .success
.tensor_return_composition:
 OWNER_FRAGMENT tensor_composition_desc_prefix,tensor_composition_desc_prefix_len,tensor_composition_desc_tail,tensor_composition_desc_tail_len
 OWNER_FRAGMENT tensor_composition_payload_prefix,tensor_composition_payload_prefix_len,tensor_composition_payload_tail,tensor_composition_payload_tail_len
 OWNER_FRAGMENT tensor_composition_shape_prefix,tensor_composition_shape_prefix_len,tensor_composition_shape_tail,tensor_composition_shape_tail_len
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],0
 je .tensor_return_composition_rank_zero
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],1
 je .tensor_return_composition_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET
 cmp qword [r13+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],2
 je .tensor_return_composition_shape_done
 MATRIX_IMMEDIATE dq_prefix,NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET
 jmp .tensor_return_composition_shape_done
.tensor_return_composition_rank_zero:
 MATRIX_EMIT tensor_shape_r0,tensor_shape_r0_len
.tensor_return_composition_shape_done:
 OWNER_FRAGMENT tensor_composition_user_prefix,tensor_composition_user_prefix_len,tensor_composition_return_user_tail,tensor_composition_return_user_tail_len
 call .emit_composition_label
 test eax,eax
 jnz .writer
 OWNER_FRAGMENT tensor_composition_desc_rdi_prefix,tensor_composition_desc_rdi_prefix_len,tensor_composition_desc_rdi_tail,tensor_composition_desc_rdi_tail_len
 OWNER_FRAGMENT tensor_composition_payload_rsi_prefix,tensor_composition_payload_rsi_prefix_len,tensor_composition_payload_rsi_tail,tensor_composition_payload_rsi_tail_len
 MATRIX_IMMEDIATE imm_rdx,NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET
 OWNER_FRAGMENT tensor_composition_shape_rcx_prefix,tensor_composition_shape_rcx_prefix_len,tensor_composition_shape_rcx_tail,tensor_composition_shape_rcx_tail_len
 MATRIX_IMMEDIATE imm_r8,NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET
 MATRIX_EMIT tensor_storage,tensor_storage_len
 OWNER_FRAGMENT tensor_composition_user_call_prefix,tensor_composition_user_call_prefix_len,tensor_composition_user_call_tail,tensor_composition_user_call_tail_len
 MATRIX_EMIT tensor_composition_return_result_tail,tensor_composition_return_result_tail_len
 OWNER_FRAGMENT tensor_composition_identity_prefix,tensor_composition_identity_prefix_len,tensor_composition_identity_tail,tensor_composition_identity_tail_len
 jmp .success

.legacy:
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_OUTPUT_VALUE_OFFSET]
 lea rdi,[rel value]
 call format_hex
 cmp qword [r12+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 jne .legacy_standalone
 mov rdi,r12
 lea rsi,[rel composition_legacy_prefix]
 mov edx,composition_legacy_prefix_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,[r12+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel composition_legacy_mid]
 mov edx,composition_legacy_mid_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel value]
 mov edx,value_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel composition_legacy_suffix]
 mov edx,composition_legacy_suffix_len
 call append
 test eax,eax
 jnz .writer
 jmp .success
.legacy_standalone:
 mov rdi,r12
 lea rsi,[rel legacy_prefix]
 mov edx,legacy_prefix_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel value]
 mov edx,value_len
 call append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel legacy_suffix]
 mov edx,legacy_suffix_len
 call append
 test eax,eax
 jnz .writer
.success:
 mov qword [r12+NEBOC_VECTOR_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_VECTOR_VERTICAL_HASH_OFFSET]
 mov [r12+NEBOC_VECTOR_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+NEBOC_VECTOR_CODEGEN_ERROR_OFFSET],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.source:
 mov qword [r12+NEBOC_VECTOR_CODEGEN_ERROR_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
