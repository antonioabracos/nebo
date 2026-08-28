; Nebo Assembly — MF038 receiver-first function/call/.return codegen
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/parser/nominal_types.inc"
%include "compiler/semantic/collections/vector_vertical.inc"
%include "compiler/semantic/types/buffer_freeze.inc"
%include "compiler/semantic/collections/public_slice.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/functions/x86_64/function_codegen.inc"
%include "compiler/codegen/collections/x86_64/vector_codegen.inc"
%include "compiler/codegen/textual/x86_64/text_char_bytes_codegen.inc"
%include "runtime/core/runtime_core.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal
extern neboc_arch_backend_begin_function
extern neboc_arch_backend_begin_private_nested_function
extern neboc_abi_signature_init
extern neboc_abi_adapter_begin_function
extern neboc_abi_adapter_emit_parameter_copy
extern neboc_abi_adapter_emit_prepared_call
extern neboc_abi_adapter_emit_prepared_private_nested_call
extern neboc_abi_adapter_emit_return_rax
extern neboc_function_plan_compute_hash
extern neboc_text_char_bytes_codegen_emit_data
extern neboc_text_char_bytes_codegen_emit_expression
extern neboc_vector_codegen_emit_start
extern neboc_buffer_parse

section .rodata
fcg_type_int: db 'Int'
fcg_type_bool: db 'Bool'
fcg_type_text: db 'Text'
fcg_type_slice: db 'Slice'
fcg_type_slice_len equ $-fcg_type_slice
fcg_name_self: db 'self'
fcg_name_self_len equ $-fcg_name_self
fcg_name_console: db 'console'
fcg_name_console_len equ $-fcg_name_console
fcg_name_scan: db 'scan'
fcg_name_scan_len equ $-fcg_name_scan
fcg_name_byte_length: db 'byteLength'
fcg_name_byte_length_len equ $-fcg_name_byte_length
fcg_name_codepoint_count: db 'codepointCount'
fcg_name_codepoint_count_len equ $-fcg_name_codepoint_count
fcg_name_to_float: db 'toFloat'
fcg_name_to_float_len equ $-fcg_name_to_float
fcg_name_is_finite: db 'isFinite'
fcg_name_is_finite_len equ $-fcg_name_is_finite
fcg_name_is_nan: db 'isNaN'
fcg_name_is_nan_len equ $-fcg_name_is_nan
fcg_name_is_infinite: db 'isInfinite'
fcg_name_is_infinite_len equ $-fcg_name_is_infinite
fcg_name_is_negative_zero: db 'isNegativeZero'
fcg_name_is_negative_zero_len equ $-fcg_name_is_negative_zero
fcg_name_discriminant: db 'discriminant'
fcg_name_discriminant_len equ $-fcg_name_discriminant
fcg_name_unwrap: db 'unwrap'
fcg_name_unwrap_len equ $-fcg_name_unwrap
fcg_name_sizeof: db 'sizeOf'
fcg_name_sizeof_len equ $-fcg_name_sizeof
fcg_name_collection_length: db 'length'
fcg_name_collection_length_len equ $-fcg_name_collection_length
fcg_name_buffer_capacity: db 'capacity'
fcg_name_buffer_capacity_len equ $-fcg_name_buffer_capacity
fcg_name_collection_at: db 'at'
fcg_name_collection_at_len equ $-fcg_name_collection_at
fcg_name_tuple: db 'Tuple'
fcg_name_tuple_len equ $-fcg_name_tuple
fcg_name_tuple_of: db 'of'
fcg_name_tuple_of_len equ $-fcg_name_tuple_of
fcg_name_collection_contains: db 'contains'
fcg_name_collection_contains_len equ $-fcg_name_collection_contains
fcg_name_collection_as_slice: db 'asSlice'
fcg_name_collection_as_slice_len equ $-fcg_name_collection_as_slice
fcg_name_collection_release: db 'release'
fcg_name_collection_release_len equ $-fcg_name_collection_release
fcg_name_collection_sum: db 'sum'
fcg_name_collection_sum_len equ $-fcg_name_collection_sum
fcg_name_bytes_type: db 'Bytes'
fcg_name_bytes_type_len equ $-fcg_name_bytes_type
fcg_name_bytes_empty: db 'empty'
fcg_name_bytes_empty_len equ $-fcg_name_bytes_empty
fcg_name_bytes_from_byte: db 'fromByte'
fcg_name_bytes_from_byte_len equ $-fcg_name_bytes_from_byte
fcg_name_bytes_from_values: db 'fromValues'
fcg_name_bytes_from_values_len equ $-fcg_name_bytes_from_values
fcg_name_bytes_get: db 'get'
fcg_name_bytes_get_len equ $-fcg_name_bytes_get
fcg_name_bytes_slice: db 'slice'
fcg_name_bytes_slice_len equ $-fcg_name_bytes_slice
fcg_name_bit_and: db 'bitAnd'
fcg_name_bit_and_len equ $-fcg_name_bit_and
fcg_name_bit_or: db 'bitOr'
fcg_name_bit_or_len equ $-fcg_name_bit_or
fcg_name_bit_xor: db 'bitXor'
fcg_name_bit_xor_len equ $-fcg_name_bit_xor
fcg_name_bit_not: db 'bitNot'
fcg_name_bit_not_len equ $-fcg_name_bit_not
fcg_name_shift_left: db 'shiftLeft'
fcg_name_shift_left_len equ $-fcg_name_shift_left
fcg_name_shift_right: db 'shiftRight'
fcg_name_shift_right_len equ $-fcg_name_shift_right
fcg_name_test_bit: db 'testBit'
fcg_name_test_bit_len equ $-fcg_name_test_bit
fcg_name_with_bit: db 'withBit'
fcg_name_with_bit_len equ $-fcg_name_with_bit
fcg_name_codepoint: db 'codepoint'
fcg_name_codepoint_len equ $-fcg_name_codepoint
fcg_name_is_some: db 'isSome'
fcg_name_is_some_len equ $-fcg_name_is_some
fcg_name_is_none: db 'isNone'
fcg_name_is_none_len equ $-fcg_name_is_none
fcg_name_unwrap_or: db 'unwrapOr'
fcg_name_unwrap_or_len equ $-fcg_name_unwrap_or
fcg_text_bit_and: db '    mov rcx, rax',10,'    pop rax',10,'    and rax, rcx',10
fcg_text_bit_and_len equ $-fcg_text_bit_and
fcg_text_bit_or: db '    mov rcx, rax',10,'    pop rax',10,'    or rax, rcx',10
fcg_text_bit_or_len equ $-fcg_text_bit_or
fcg_text_bit_xor: db '    mov rcx, rax',10,'    pop rax',10,'    xor rax, rcx',10
fcg_text_bit_xor_len equ $-fcg_text_bit_xor
fcg_text_bit_not: db '    not rax',10
fcg_text_bit_not_len equ $-fcg_text_bit_not
fcg_text_shift_left: db '    mov rcx, rax',10,'    pop rax',10,'    shl rax, cl',10
fcg_text_shift_left_len equ $-fcg_text_shift_left
fcg_text_shift_right: db '    mov rcx, rax',10,'    pop rax',10,'    sar rax, cl',10
fcg_text_shift_right_len equ $-fcg_text_shift_right
fcg_text_test_bit: db '    mov rcx, rax',10,'    pop rax',10,'    bt rax, rcx',10,'    setc al',10,'    movzx eax, al',10
fcg_text_test_bit_len equ $-fcg_text_test_bit
fcg_text_with_bit: db '    mov rdx, rax',10,'    pop rcx',10,'    pop rax',10,'    btr rax, rcx',10,'    mov r10, 1',10,'    shl r10, cl',10,'    and rdx, 1',10,'    neg rdx',10,'    and r10, rdx',10,'    or rax, r10',10
fcg_text_with_bit_len equ $-fcg_text_with_bit
fcg_text_bytes_byte_length: db '    mov rdi, rax',10,'    call nebo_runtime_textual_bytes_byte_length',10
fcg_text_bytes_byte_length_len equ $-fcg_text_bytes_byte_length
fcg_numeric_to_float: db '    mov rdi, rax',10,'    call nebo_runtime_numeric_safety_int_to_float',10,'    movq rax, xmm0',10
fcg_numeric_to_float_len equ $-fcg_numeric_to_float
fcg_numeric_is_finite: db '    call nebo_runtime_numeric_safety_is_finite',10
fcg_numeric_is_finite_len equ $-fcg_numeric_is_finite
fcg_numeric_is_nan: db '    call nebo_runtime_numeric_safety_is_nan',10
fcg_numeric_is_nan_len equ $-fcg_numeric_is_nan
fcg_numeric_is_infinite: db '    call nebo_runtime_numeric_safety_is_infinite',10
fcg_numeric_is_infinite_len equ $-fcg_numeric_is_infinite
fcg_numeric_is_negative_zero: db '    call nebo_runtime_numeric_safety_is_negative_zero',10
fcg_numeric_is_negative_zero_len equ $-fcg_numeric_is_negative_zero

fcg_mov_rax: db '    mov rax, '
fcg_mov_rax_len equ $-fcg_mov_rax
fcg_mov_true: db '    mov eax, 1',10
fcg_mov_true_len equ $-fcg_mov_true
fcg_mov_false: db '    xor eax, eax',10
fcg_mov_false_len equ $-fcg_mov_false
fcg_load_slot: db '    mov rax, [rbp - '
fcg_load_slot_len equ $-fcg_load_slot
fcg_close_bracket: db ']',10
fcg_close_bracket_len equ $-fcg_close_bracket
fcg_newline: db 10
fcg_newline_len equ $-fcg_newline
fcg_push_rax: db '    push rax',10
fcg_push_rax_len equ $-fcg_push_rax
fcg_restore_binary: db '    mov rcx, rax',10,'    pop rax',10
fcg_restore_binary_len equ $-fcg_restore_binary
fcg_add: db '    add rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_add_len equ $-fcg_add
fcg_sub: db '    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_sub_len equ $-fcg_sub
fcg_mul: db '    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_mul_len equ $-fcg_mul
fcg_neg: db '    neg rax',10,'    jo .nebo_trap_overflow',10
fcg_neg_len equ $-fcg_neg
fcg_not: db '    test rax, rax',10,'    sete al',10,'    movzx eax, al',10
fcg_not_len equ $-fcg_not
fcg_cmp_eq: db '    cmp rax, rcx',10,'    sete al',10,'    movzx eax, al',10
fcg_cmp_eq_len equ $-fcg_cmp_eq
fcg_cmp_ne: db '    cmp rax, rcx',10,'    setne al',10,'    movzx eax, al',10
fcg_cmp_ne_len equ $-fcg_cmp_ne
fcg_cmp_lt: db '    cmp rax, rcx',10,'    setl al',10,'    movzx eax, al',10
fcg_cmp_lt_len equ $-fcg_cmp_lt
fcg_cmp_le: db '    cmp rax, rcx',10,'    setle al',10,'    movzx eax, al',10
fcg_cmp_le_len equ $-fcg_cmp_le
fcg_cmp_gt: db '    cmp rax, rcx',10,'    setg al',10,'    movzx eax, al',10
fcg_cmp_gt_len equ $-fcg_cmp_gt
fcg_cmp_ge: db '    cmp rax, rcx',10,'    setge al',10,'    movzx eax, al',10
fcg_cmp_ge_len equ $-fcg_cmp_ge
fcg_div_prefix: db '    test rcx, rcx',10,'    jz .nebo_trap_division_by_zero',10,'    mov rdx, 0x8000000000000000',10,'    cmp rax, rdx',10,'    jne .nebo_div_ok_'
fcg_div_prefix_len equ $-fcg_div_prefix
fcg_div_mid: db 10,'    cmp rcx, -1',10,'    je .nebo_trap_overflow',10,'.nebo_div_ok_'
fcg_div_mid_len equ $-fcg_div_mid
fcg_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10
fcg_div_tail_len equ $-fcg_div_tail
fcg_mod_tail: db '    mov rax, rdx',10
fcg_mod_tail_len equ $-fcg_mod_tail
fcg_and_branch: db '    test rax, rax',10,'    jz .nebo_bool_false_'
fcg_and_branch_len equ $-fcg_and_branch
fcg_or_branch: db '    test rax, rax',10,'    jnz .nebo_bool_true_'
fcg_or_branch_len equ $-fcg_or_branch
fcg_bool_canon_done: db '    test rax, rax',10,'    setne al',10,'    movzx eax, al',10,'    jmp .nebo_bool_end_'
fcg_bool_canon_done_len equ $-fcg_bool_canon_done
fcg_false_label: db 10,'.nebo_bool_false_'
fcg_false_label_len equ $-fcg_false_label
fcg_false_body: db ':',10,'    xor eax, eax',10,'.nebo_bool_end_'
fcg_false_body_len equ $-fcg_false_body
fcg_true_label: db 10,'.nebo_bool_true_'
fcg_true_label_len equ $-fcg_true_label
fcg_true_body: db ':',10,'    mov eax, 1',10,'.nebo_bool_end_'
fcg_true_body_len equ $-fcg_true_body
fcg_label_end: db ':',10
fcg_label_end_len equ $-fcg_label_end
fcg_store_slot: db '    mov [rbp - '
fcg_store_slot_len equ $-fcg_store_slot
fcg_store_slot_suffix: db '], rax',10
fcg_store_slot_suffix_len equ $-fcg_store_slot_suffix
fcg_sub_rsp: db '    sub rsp, '
fcg_sub_rsp_len equ $-fcg_sub_rsp
fcg_if_test: db '    test rax, rax',10,'    jz .nebo_if_else_'
fcg_if_test_len equ $-fcg_if_test
fcg_if_jump_end: db '    jmp .nebo_if_end_'
fcg_if_jump_end_len equ $-fcg_if_jump_end
fcg_if_else_label: db '.nebo_if_else_'
fcg_if_else_label_len equ $-fcg_if_else_label
fcg_if_end_label: db '.nebo_if_end_'
fcg_if_end_label_len equ $-fcg_if_end_label
fcg_loop_header_label: db '.nebo_function_loop_'
fcg_loop_header_label_len equ $-fcg_loop_header_label
fcg_loop_exit_label: db '.nebo_function_loop_exit_'
fcg_loop_exit_label_len equ $-fcg_loop_exit_label
fcg_loop_test_exit: db '    test rax, rax',10,'    jz .nebo_function_loop_exit_'
fcg_loop_test_exit_len equ $-fcg_loop_test_exit
fcg_loop_jump_header: db '    jmp .nebo_function_loop_'
fcg_loop_jump_header_len equ $-fcg_loop_jump_header
fcg_loop_jump_exit: db '    jmp .nebo_function_loop_exit_'
fcg_loop_jump_exit_len equ $-fcg_loop_jump_exit
fcg_return_jump: db '    jmp .nebo_function_return_'
fcg_return_jump_len equ $-fcg_return_jump
fcg_return_label: db '.nebo_function_return_'
fcg_return_label_len equ $-fcg_return_label
fcg_lea_text_desc: db '    lea rax, [rel nebo_text_desc_'
fcg_lea_text_desc_len equ $-fcg_lea_text_desc
fcg_lea_text_desc_suffix: db ']',10
fcg_lea_text_desc_suffix_len equ $-fcg_lea_text_desc_suffix
fcg_text_equal_extern: db 'extern nebo_runtime_text_equal',10
fcg_text_equal_extern_len equ $-fcg_text_equal_extern
fcg_text_equal_call: db '    mov rsi, rax',10,'    pop rdi',10,'    call nebo_runtime_text_equal',10
fcg_text_equal_call_len equ $-fcg_text_equal_call
fcg_text_not_equal: db '    xor eax, 1',10
fcg_text_not_equal_len equ $-fcg_text_not_equal
fcg_console_publish_text: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_text',10
fcg_console_publish_text_len equ $-fcg_console_publish_text
fcg_console_publish_int: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_int',10
fcg_console_publish_int_len equ $-fcg_console_publish_int
fcg_console_publish_bool: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_bool',10
fcg_console_publish_bool_len equ $-fcg_console_publish_bool
fcg_scan_sequence_decl: db 10,'section .bss',10,'align 8',10,'nebo_function_scan_sequence_'
fcg_scan_sequence_decl_len equ $-fcg_scan_sequence_decl
fcg_scan_sequence_decl_local: db 10,'section .bss',10,'align 8',10,'.nebo_function_scan_sequence_'
fcg_scan_sequence_decl_local_len equ $-fcg_scan_sequence_decl_local
fcg_scan_sequence_decl_tail: db ': resq 1',10,'section .text',10,'    inc qword [rel nebo_function_scan_sequence_'
fcg_scan_sequence_decl_tail_len equ $-fcg_scan_sequence_decl_tail
fcg_scan_sequence_decl_tail_local: db ': resq 1',10,'section .text',10,'    inc qword [rel .nebo_function_scan_sequence_'
fcg_scan_sequence_decl_tail_local_len equ $-fcg_scan_sequence_decl_tail_local
fcg_scan_sequence_load: db ']',10,'    mov rsi, '
fcg_scan_sequence_load_len equ $-fcg_scan_sequence_load
fcg_scan_sequence_tail: db 10,'    shl rsi, 32',10,'    mov r10, [rel nebo_function_scan_sequence_'
fcg_scan_sequence_tail_len equ $-fcg_scan_sequence_tail
fcg_scan_sequence_tail_local: db 10,'    shl rsi, 32',10,'    mov r10, [rel .nebo_function_scan_sequence_'
fcg_scan_sequence_tail_local_len equ $-fcg_scan_sequence_tail_local
fcg_scan_sequence_finish: db ']',10,'    or rsi, r10',10,'    mov rdx, rsi',10,'    mov rcx, rsi',10
fcg_scan_sequence_finish_len equ $-fcg_scan_sequence_finish
fcg_scan_stdin: db '    mov rdi, rax',10,'    call nebo_runtime_scan_stdin_text',10
fcg_scan_stdin_len equ $-fcg_scan_stdin
fcg_scan_console_handle: db '    mov rdi, rax',10,'    call nebo_runtime_scan_console_handle',10
fcg_scan_console_handle_len equ $-fcg_scan_console_handle
fcg_text_byte_length: db '    mov rdi, rax',10,'    call nebo_runtime_textual_text_byte_length',10
fcg_text_byte_length_len equ $-fcg_text_byte_length
fcg_text_codepoint_count: db '    mov rdi, rax',10,'    call nebo_runtime_textual_text_codepoint_count',10
fcg_text_codepoint_count_len equ $-fcg_text_codepoint_count
fcg_rodata_header: db 10,'section .rodata align=8',10
fcg_rodata_header_len equ $-fcg_rodata_header
fcg_align8: db 'align 8',10
fcg_align8_len equ $-fcg_align8
fcg_text_data_prefix: db 'nebo_text_data_'
fcg_text_data_prefix_len equ $-fcg_text_data_prefix
fcg_text_data_mid: db ': db '
fcg_text_data_mid_len equ $-fcg_text_data_mid
fcg_text_desc_prefix: db 'nebo_text_desc_'
fcg_text_desc_prefix_len equ $-fcg_text_desc_prefix
fcg_text_desc_mid: db ':',10,'    dq nebo_text_data_'
fcg_text_desc_mid_len equ $-fcg_text_desc_mid
fcg_text_desc_length: db 10,'    dq '
fcg_text_desc_length_len equ $-fcg_text_desc_length
fcg_text_desc_tail: db 10,'    dd 0',10,'    dw 1',10,'    dw 1',10
fcg_text_desc_tail_len equ $-fcg_text_desc_tail
fcg_comma: db ','
fcg_comma_len equ $-fcg_comma
fcg_zero: db '0'
fcg_zero_len equ $-fcg_zero
fcg_text_section: db 10,'section .text',10
fcg_text_section_len equ $-fcg_text_section
fcg_trap_overflow: db '.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
fcg_trap_overflow_len equ $-fcg_trap_overflow
fcg_trap_divzero: db '.nebo_trap_division_by_zero:',10,'    jmp nebo_runtime_trap_division_by_zero',10
fcg_trap_divzero_len equ $-fcg_trap_divzero

fcg_collection_rodata: db 10,'section .rodata align=8',10,'align 8',10
fcg_collection_rodata_len equ $-fcg_collection_rodata
fcg_collection_data_label: db 'nebo_collection_data_'
fcg_collection_data_label_len equ $-fcg_collection_data_label
fcg_array_data_label: db 'nebo_array_data_'
fcg_array_data_label_len equ $-fcg_array_data_label
fcg_slice_descriptor_label: db 'nebo_slice_descriptor_'
fcg_slice_descriptor_label_len equ $-fcg_slice_descriptor_label
fcg_collection_dq: db '    dq '
fcg_collection_dq_len equ $-fcg_collection_dq
fcg_array_descriptor_base: db '    dq nebo_array_data_'
fcg_array_descriptor_base_len equ $-fcg_array_descriptor_base
fcg_plus: db ' + '
fcg_plus_len equ $-fcg_plus
fcg_collection_header: db '.nebo_function_loop_'
fcg_collection_header_len equ $-fcg_collection_header
fcg_collection_latch: db '.nebo_collection_loop_latch_'
fcg_collection_latch_len equ $-fcg_collection_latch
fcg_collection_jump_latch: db '    jmp .nebo_collection_loop_latch_'
fcg_collection_jump_latch_len equ $-fcg_collection_jump_latch
fcg_collection_exit: db '.nebo_function_loop_exit_'
fcg_collection_exit_len equ $-fcg_collection_exit
fcg_collection_load_cursor: db '    mov rcx, [rbp - '
fcg_collection_load_cursor_len equ $-fcg_collection_load_cursor
fcg_collection_cmp: db '    cmp rcx, '
fcg_collection_cmp_len equ $-fcg_collection_cmp
fcg_collection_jae: db 10,'    jae .nebo_function_loop_exit_'
fcg_collection_jae_len equ $-fcg_collection_jae
fcg_collection_range_a: db '    mov rax, rcx',10,'    imul rax, '
fcg_collection_range_a_len equ $-fcg_collection_range_a
fcg_collection_range_b: db 10,'    add rax, '
fcg_collection_range_b_len equ $-fcg_collection_range_b
fcg_collection_array_a: db '    lea rdx, [rel nebo_collection_data_'
fcg_collection_array_a_len equ $-fcg_collection_array_a
fcg_collection_array_b: db ']',10,'    mov rax, [rdx + rcx*8]',10
fcg_collection_array_b_len equ $-fcg_collection_array_b
fcg_collection_canonical_array_a: db '    lea rdx, [rel nebo_array_data_'
fcg_collection_canonical_array_a_len equ $-fcg_collection_canonical_array_a
fcg_collection_canonical_slice_a: db '    mov rdx, [rel nebo_slice_descriptor_'
fcg_collection_canonical_slice_a_len equ $-fcg_collection_canonical_slice_a
fcg_collection_inc: db '    inc qword [rbp - '
fcg_collection_inc_len equ $-fcg_collection_inc
fcg_collection_param_cmp: db '    mov rax, [rbp - '
fcg_collection_param_cmp_len equ $-fcg_collection_param_cmp
fcg_collection_param_cmp_tail: db ']',10,'    cmp rcx, [rax + 8]',10
fcg_collection_param_cmp_tail_len equ $-fcg_collection_param_cmp_tail
fcg_collection_param_load_tail: db ']',10,'    mov rdx, [rax]',10,'    mov rax, [rdx + rcx*8]',10
fcg_collection_param_load_tail_len equ $-fcg_collection_param_load_tail

; Borrowed Slice descriptor materialization and dynamic callee reads.
fcg_slice_data_label: db 'nebo_slice_data_'
fcg_slice_data_label_len equ $-fcg_slice_data_label
fcg_slice_desc_base: db '    lea rax, [rel nebo_slice_data_'
fcg_slice_desc_base_len equ $-fcg_slice_desc_base
fcg_slice_desc_canonical_base: db '    mov rax, [rel nebo_slice_descriptor_'
fcg_slice_desc_canonical_base_len equ $-fcg_slice_desc_canonical_base
fcg_slice_desc_store: db ']',10,'    mov [rbp - '
fcg_slice_desc_store_len equ $-fcg_slice_desc_store
fcg_slice_desc_length: db '    mov qword [rbp - '
fcg_slice_desc_length_len equ $-fcg_slice_desc_length
fcg_slice_desc_assign: db '], '
fcg_slice_desc_assign_len equ $-fcg_slice_desc_assign
fcg_slice_desc_pointer: db '    lea rax, [rbp - '
fcg_slice_desc_pointer_len equ $-fcg_slice_desc_pointer
fcg_slice_param_load: db '    mov rax, [rbp - '
fcg_slice_param_load_len equ $-fcg_slice_param_load
fcg_slice_length_load: db ']',10,'    mov rax, [rax + 8]',10
fcg_slice_length_load_len equ $-fcg_slice_length_load
fcg_slice_base_load: db ']',10,'    mov rax, [rax]',10,'    mov rax, [rax + '
fcg_slice_base_load_len equ $-fcg_slice_base_load
; A Slice parameter has a runtime length even when the public at() operand is
; parser-bounded to an integer literal.  Authenticate that literal against the
; borrowed descriptor before loading its base.  The existing deterministic
; numeric trap is used as the generated-program safety edge; no runtime/API
; surface is widened by NPT-LANG-21.
fcg_slice_at_guard: db ']',10,'    cmp qword [rax + 8], '
fcg_slice_at_guard_len equ $-fcg_slice_at_guard
fcg_slice_at_guard_branch: db 10,'    jbe nebo_slice_bounds_'
fcg_slice_at_guard_branch_len equ $-fcg_slice_at_guard_branch
fcg_slice_at_guard_tail: db 10,'    mov rax, [rax]',10,'    mov rax, [rax + '
fcg_slice_at_guard_tail_len equ $-fcg_slice_at_guard_tail
fcg_slice_bounds_label: db 'nebo_slice_bounds_'
fcg_slice_bounds_label_len equ $-fcg_slice_bounds_label
fcg_slice_bounds_body: db ':',10,'    jmp nebo_runtime_trap_overflow',10
fcg_slice_bounds_body_len equ $-fcg_slice_bounds_body

; NPT-LANG-24 checked dynamic at() fragments.  The receiver is established in
; R10 before the material index expression is emitted.  Arrays use their one
; canonical qword payload; local Slices use their one canonical descriptor.
; Every failure edge reaches the existing per-function bounds trap.
fcg_dynamic_array_receiver: db '    lea r10, [rel nebo_array_data_'
fcg_dynamic_array_receiver_len equ $-fcg_dynamic_array_receiver
fcg_dynamic_local_slice_receiver: db '    lea r10, [rel nebo_slice_descriptor_'
fcg_dynamic_local_slice_receiver_len equ $-fcg_dynamic_local_slice_receiver
fcg_dynamic_mutable_receiver: db '    lea r10, [rbp - '
fcg_dynamic_mutable_receiver_len equ $-fcg_dynamic_mutable_receiver
fcg_dynamic_borrowed_receiver: db '    mov r10, [rbp - '
fcg_dynamic_borrowed_receiver_len equ $-fcg_dynamic_borrowed_receiver
fcg_dynamic_receiver_tail: db ']',10
fcg_dynamic_receiver_tail_len equ $-fcg_dynamic_receiver_tail
fcg_dynamic_index_lower: db '    mov rcx, rax',10,'    test rcx, rcx',10,'    js nebo_slice_bounds_'
fcg_dynamic_index_lower_len equ $-fcg_dynamic_index_lower
fcg_dynamic_local_upper: db 10,'    cmp rcx, '
fcg_dynamic_local_upper_len equ $-fcg_dynamic_local_upper
fcg_dynamic_borrowed_upper: db 10,'    cmp rcx, [r10 + 8]',10,'    jae nebo_slice_bounds_'
fcg_dynamic_borrowed_upper_len equ $-fcg_dynamic_borrowed_upper
fcg_dynamic_upper_branch: db 10,'    jae nebo_slice_bounds_'
fcg_dynamic_upper_branch_len equ $-fcg_dynamic_upper_branch
fcg_dynamic_local_stride: db 10,'    mov rdx, '
fcg_dynamic_local_stride_len equ $-fcg_dynamic_local_stride
fcg_dynamic_borrowed_stride: db 10,'    mov rdx, [r10 + 16]'
fcg_dynamic_borrowed_stride_len equ $-fcg_dynamic_borrowed_stride
fcg_dynamic_borrowed_base: db 10,'    mov r10, [r10]'
fcg_dynamic_borrowed_base_len equ $-fcg_dynamic_borrowed_base
fcg_dynamic_checked_multiply: db 10,'    imul rcx, rdx',10,'    jo nebo_slice_bounds_'
fcg_dynamic_checked_multiply_len equ $-fcg_dynamic_checked_multiply
fcg_dynamic_checked_add: db 10,'    mov rax, r10',10,'    add rax, rcx',10,'    jc nebo_slice_bounds_'
fcg_dynamic_checked_add_len equ $-fcg_dynamic_checked_add
fcg_dynamic_checked_sub: db 10,'    sub r10, rcx',10,'    jc nebo_slice_bounds_'
fcg_dynamic_checked_sub_len equ $-fcg_dynamic_checked_sub
fcg_dynamic_checked_frame_add: db 10,'    add r10, rcx',10,'    jc nebo_slice_bounds_'
fcg_dynamic_checked_frame_add_len equ $-fcg_dynamic_checked_frame_add
fcg_dynamic_address_to_rax: db 10,'    mov rax, r10',10
fcg_dynamic_address_to_rax_len equ $-fcg_dynamic_address_to_rax
fcg_push_r10: db '    push r10',10
fcg_push_r10_len equ $-fcg_push_r10
fcg_pop_r10: db '    pop r10',10
fcg_pop_r10_len equ $-fcg_pop_r10
fcg_pop_store_r10: db '    pop r10',10,'    mov [r10], rax',10
fcg_pop_store_r10_len equ $-fcg_pop_store_r10
fcg_collection_frame_load: db '    lea rdx, [rbp - '
fcg_collection_frame_load_len equ $-fcg_collection_frame_load
fcg_collection_frame_index: db ']',10,'    mov rax, [rdx + rcx*8]',10
fcg_collection_frame_index_len equ $-fcg_collection_frame_index
fcg_slice_desc_frame_base: db '    lea rax, [rbp - '
fcg_slice_desc_frame_base_len equ $-fcg_slice_desc_frame_base
fcg_dynamic_element_load_int: db 10,'    mov rax, [rax]',10
fcg_dynamic_element_load_int_len equ $-fcg_dynamic_element_load_int
fcg_dynamic_element_load_bool: db 10,'    movzx eax, byte [rax]',10
fcg_dynamic_element_load_bool_len equ $-fcg_dynamic_element_load_bool
fcg_dynamic_element_load_char: db 10,'    mov eax, dword [rax]',10
fcg_dynamic_element_load_char_len equ $-fcg_dynamic_element_load_char

fcg_pop_rdi: db '    pop rdi',10
fcg_pop_rdi_len equ $-fcg_pop_rdi
fcg_pop_rsi: db '    pop rsi',10
fcg_pop_rsi_len equ $-fcg_pop_rsi
fcg_pop_rdx: db '    pop rdx',10
fcg_pop_rdx_len equ $-fcg_pop_rdx
fcg_pop_rcx: db '    pop rcx',10
fcg_pop_rcx_len equ $-fcg_pop_rcx
fcg_pop_r8: db '    pop r8',10
fcg_pop_r8_len equ $-fcg_pop_r8
fcg_pop_r9: db '    pop r9',10
fcg_pop_r9_len equ $-fcg_pop_r9
fcg_pop_r10_value: db '    pop r10',10
fcg_pop_r10_value_len equ $-fcg_pop_r10_value
fcg_pop_ptrs: dq fcg_pop_rdi,fcg_pop_rsi,fcg_pop_rdx,fcg_pop_rcx,fcg_pop_r8,fcg_pop_r9
fcg_pop_lens: dq fcg_pop_rdi_len,fcg_pop_rsi_len,fcg_pop_rdx_len,fcg_pop_rcx_len,fcg_pop_r8_len,fcg_pop_r9_len
fcg_sret_pop_ptrs: dq fcg_pop_rsi,fcg_pop_rdx,fcg_pop_rcx,fcg_pop_r8,fcg_pop_r9
fcg_sret_pop_lens: dq fcg_pop_rsi_len,fcg_pop_rdx_len,fcg_pop_rcx_len,fcg_pop_r8_len,fcg_pop_r9_len

; NPT-LANG-35 B01 compiler-private depth transport.  The public receiver has
; already been evaluated exactly once into RDI when these fragments run.
fcg_recursion_root_prefix: db '    sub rsp, 16',10,'    mov qword [rsp], 63',10,'    mov qword [rsp + 8], 0',10
fcg_recursion_root_prefix_len equ $-fcg_recursion_root_prefix
fcg_recursion_self_guard_prefix: db '    mov r10, [rbp + 16]',10,'    test r10, r10',10,'    jz .nebo_recursion_depth_exhausted_47_'
fcg_recursion_self_guard_prefix_len equ $-fcg_recursion_self_guard_prefix
fcg_recursion_self_guard_success: db 10,'    dec r10',10,'    sub rsp, 16',10,'    mov [rsp], r10',10,'    mov qword [rsp + 8], 0',10
fcg_recursion_self_guard_success_len equ $-fcg_recursion_self_guard_success
fcg_recursion_call_prefix: db '    call nebo_fn_'
fcg_recursion_call_prefix_len equ $-fcg_recursion_call_prefix
fcg_recursion_call_restore: db 10,'    add rsp, 16',10
fcg_recursion_call_restore_len equ $-fcg_recursion_call_restore
fcg_recursion_self_jump_done: db '    jmp .nebo_recursion_call_done_'
fcg_recursion_self_jump_done_len equ $-fcg_recursion_self_jump_done
fcg_recursion_self_failure_prefix: db 10,'.nebo_recursion_depth_exhausted_47_'
fcg_recursion_self_failure_prefix_len equ $-fcg_recursion_self_failure_prefix
fcg_recursion_self_failure_body: db ':',10,'    mov eax, 60',10,'    mov edi, 175',10,'    syscall',10,'.nebo_recursion_call_done_'
fcg_recursion_self_failure_body_len equ $-fcg_recursion_self_failure_body

; NPT-LANG-29 B01 caller-owned Array result lowering fragments.
fcg_sret_load_r11: db '    mov r11, [rbp - '
fcg_sret_load_r11_len equ $-fcg_sret_load_r11
fcg_sret_imm_r10: db '    mov r10, '
fcg_sret_imm_r10_len equ $-fcg_sret_imm_r10
fcg_sret_frame_r10: db '    mov r10, [rbp - '
fcg_sret_frame_r10_len equ $-fcg_sret_frame_r10
fcg_sret_store_prefix: db '    mov [r11 + '
fcg_sret_store_prefix_len equ $-fcg_sret_store_prefix
fcg_sret_store_suffix: db '], r10',10
fcg_sret_store_suffix_len equ $-fcg_sret_store_suffix
fcg_sret_rax: db '    mov rax, r11',10
fcg_sret_rax_len equ $-fcg_sret_rax
fcg_sret_dest_rdi: db '    lea rdi, [rbp - '
fcg_sret_dest_rdi_len equ $-fcg_sret_dest_rdi
fcg_sret_stack_arg: db '    sub rsp, 16',10,'    mov [rsp], r10',10
fcg_sret_stack_arg_len equ $-fcg_sret_stack_arg
fcg_sret_stack_restore: db '    add rsp, 16',10
fcg_sret_stack_restore_len equ $-fcg_sret_stack_restore
fcg_sret_call_prefix: db '    call nebo_fn_'
fcg_sret_call_prefix_len equ $-fcg_sret_call_prefix
; NPT-LANG-32 five-qword Slice descriptor sret fragments.
fcg_slice_sret_source: db '    mov rdx, [rbp - '
fcg_slice_sret_source_len equ $-fcg_slice_sret_source
fcg_slice_sret_load: db '    mov r10, [rdx + '
fcg_slice_sret_load_len equ $-fcg_slice_sret_load
fcg_slice_sret_load_end: db ']',10
fcg_slice_sret_load_end_len equ $-fcg_slice_sret_load_end
fcg_slice_sret_guard: db '    cmp qword [rdx + 8], '
fcg_slice_sret_guard_len equ $-fcg_slice_sret_guard
fcg_slice_sret_guard_tail: db 10,'    jb nebo_slice_bounds_'
fcg_slice_sret_guard_tail_len equ $-fcg_slice_sret_guard_tail
fcg_slice_sret_add: db '    add r10, '
fcg_slice_sret_add_len equ $-fcg_slice_sret_add
fcg_slice_sret_imm: db '    mov r10, '
fcg_slice_sret_imm_len equ $-fcg_slice_sret_imm
fcg_slice_result_lea: db '    lea rax, [rbp - '
fcg_slice_result_lea_len equ $-fcg_slice_result_lea
fcg_slice_result_copy_source: db '    lea rdx, [rbp - '
fcg_slice_result_copy_source_len equ $-fcg_slice_result_copy_source
fcg_slice_result_copy_load: db '    mov rax, [rdx + '
fcg_slice_result_copy_load_len equ $-fcg_slice_result_copy_load
fcg_slice_result_copy_store: db ']',10,'    mov [rbp - '
fcg_slice_result_copy_store_len equ $-fcg_slice_result_copy_store
fcg_slice_result_copy_store_tail: db '], rax',10
fcg_slice_result_copy_store_tail_len equ $-fcg_slice_result_copy_store_tail
fcg_slice_result_length_tail: db ']',10,'    mov rax, [rax + 8]',10
fcg_slice_result_length_tail_len equ $-fcg_slice_result_length_tail
fcg_dynamic_frame_slice_receiver: db '    lea r10, [rbp - '
fcg_dynamic_frame_slice_receiver_len equ $-fcg_dynamic_frame_slice_receiver
fcg_science_call_save: db '    push rax',10,'    sub rsp, 8',10
fcg_science_call_save_len equ $-fcg_science_call_save
fcg_science_call: db '    call nebo_scientific_owner_'
fcg_science_call_len equ $-fcg_science_call
fcg_science_test: db 10,'    test rdx, rdx',10,'    jz .nebo_scientific_ok_'
fcg_science_test_len equ $-fcg_science_test
fcg_science_fail: db 10,'    add rsp, 16',10,'    mov eax, 1',10,'    jmp .nebo_function_return_1',10,'.nebo_scientific_ok_'
fcg_science_fail_len equ $-fcg_science_fail
fcg_science_label_tail: db ':',10
fcg_science_label_tail_len equ $-fcg_science_label_tail
fcg_science_restore: db '    add rsp, 8',10,'    pop rax',10
fcg_science_restore_len equ $-fcg_science_restore
fcg_science_discard_saved: db '    add rsp, 16',10
fcg_science_discard_saved_len equ $-fcg_science_discard_saved

section .text

; Emit one shared bounded Matrix workspace plus one private helper for every
; independently authenticated scientific owner.  Helpers reuse the public
; runtime ABI and are distinguished only by their compiler-private ordinal.
; state* -> status
fcg_emit_scientific_helpers:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET]
 test r14,r14
 jz .ok
 lea rdi,[rsp]
 mov ecx,NEBOC_VECTOR_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov [rsp+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET],rax
 mov qword [rsp+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_PRELUDE
 lea rdi,[rsp]
 call neboc_vector_codegen_emit_start
 test eax,eax
 jnz .done
 xor r15d,r15d
.helper_loop:
 cmp r15,r14
 jae .ok
 lea rdi,[rsp]
 mov ecx,NEBOC_VECTOR_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,r15
 imul rax,NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNERS_OFFSET]
 mov [rsp+NEBOC_VECTOR_CODEGEN_VERTICAL_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov [rsp+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET],rax
 mov qword [rsp+NEBOC_VECTOR_CODEGEN_MODE_OFFSET],NEBOC_VECTOR_CODEGEN_MODE_COMPOSITION_HELPER
 lea rax,[r15+1]
 mov [rsp+NEBOC_VECTOR_CODEGEN_OWNER_ORDINAL_OFFSET],rax
 lea rdi,[rsp]
 call neboc_vector_codegen_emit_start
 test eax,eax
 jnz .done
 inc r15
 jmp .helper_loop
.ok:
 xor eax,eax
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Append stable calls to every pending private scientific helper whose exact
; source start is before RSI.  The monotonic cursor makes successive AST
; statement boundaries reproduce source order after the scientific intervals
; have been removed from the private parser view.  RAX is preserved.
; A helper reports runtime failure only in RDX and branches through the normal
; start epilogue with status 1; successful public scalar results stay unused.
; state* -> status
fcg_emit_scientific_calls:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r13,rsi
 mov qword [rsp],0
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET]
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_EMITTED_COUNT_OFFSET]
 cmp r15,r14
 jae .ok
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_SOURCE_STARTS_OFFSET]
 cmp qword [rax+r15*8],r13
 jae .ok
 mov rdi,rbx
 lea rsi,[rel fcg_science_call_save]
 mov edx,fcg_science_call_save_len
 call fcg_append
 test eax,eax
 jnz .done
.call_loop:
 cmp r15,r14
 jae .restore
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_SOURCE_STARTS_OFFSET]
 cmp qword [rax+r15*8],r13
 jae .restore
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_RESULT_STARTS_OFFSET]
 cmp qword [rax+r15*8],r13
 jne .ordinary_result
 mov qword [rsp],1
.ordinary_result:
 lea r12,[r15+1]
 mov rdi,rbx
 lea rsi,[rel fcg_science_call]
 mov edx,fcg_science_call_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_science_test]
 mov edx,fcg_science_test_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_science_fail]
 mov edx,fcg_science_fail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_science_label_tail]
 mov edx,fcg_science_label_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_EMITTED_COUNT_OFFSET],r15
 jmp .call_loop
.restore:
 mov rdi,rbx
 cmp qword [rsp],0
 jne .discard_saved
 lea rsi,[rel fcg_science_restore]
 mov edx,fcg_science_restore_len
 call fcg_append
 jmp .done
.discard_saved:
 lea rsi,[rel fcg_science_discard_saved]
 mov edx,fcg_science_discard_saved_len
 ; Align only the new discard path; the older calls in this function are
 ; authenticated baseline debt and remain deliberately outside this front.
 NEBOC_ABI_ALIGNED_CALL fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; function_codegen_init(state*, request*)
NEBOC_ABI_FUNCTION neboc_function_codegen_init
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ERROR_CODE_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUILDER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ROOT_ID_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET],1
 jb .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET],1
 jb .invalid
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_FLAGS_OFFSET]
 test rax,~NEBOC_FUNCTION_CODEGEN_FLAG_KNOWN_MASK
 jnz .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_CODEGEN_QWORDS
 rep stosq
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUILDER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ROOT_ID_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURES_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_PLANS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ARRAY_RANGE_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUFFER_OWNERS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNERS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUFFER_OWNER_COUNT_OFFSET]
 cmp rax,256
 ja .invalid
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNER_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_NOMINAL_OWNER_COUNT_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS
 ja .invalid
 test rax,rax
 jz .nominal_owners_ready
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_NOMINAL_OWNERS_OFFSET],0
 je .invalid
.nominal_owners_ready:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNER_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_NOMINAL_OWNERS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNERS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_OWNER_COUNT_OFFSET]
 cmp rax,64
 ja .invalid
 test rax,rax
 jz .scientific_owners_ready
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_OWNERS_OFFSET],0
 je .invalid
.scientific_owners_ready:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_OWNERS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNERS_OFFSET],rax
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET],0
 je .scientific_ranges_ready
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_STARTS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_ENDS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_RESULT_STARTS_OFFSET],0
 je .invalid
.scientific_ranges_ready:
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_STARTS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_SOURCE_STARTS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_ENDS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_SOURCE_ENDS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_RESULT_STARTS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_RESULT_STARTS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_FLAGS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_FLAGS_OFFSET],rax
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_ARGUMENT
 mov qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ERROR_CODE_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret

; function_codegen_emit(state*)
NEBOC_ABI_FUNCTION neboc_function_codegen_emit
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0              ; function count
 mov qword [rsp+8],0            ; start node id
.first_pass:
 test r12,r12
 jz .first_done
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .check_start
 inc qword [rsp]
 cmp qword [rsp],NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS
 ja .limit
 jmp .first_next
.check_start:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .ast
 cmp qword [rsp+8],0
 jne .ast
 mov [rsp+8],r12
.first_next:
 mov r12,r13
 jmp .first_pass
.first_done:
 cmp qword [rsp+8],0
 jne .start_policy_ready
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_FLAG_ALLOW_NO_START
 jz .ast
.start_policy_ready:
 mov rax,[rsp]
 inc rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET]
 ja .limit
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET]
 ja .limit
 mov rax,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_FUNCTION_COUNT_OFFSET],rax
 ; Freeze every selected private owner/ordinal and validate the complete B01
 ; surface before any text/rodata byte is appended.
 mov rdi,rbx
 call fcg_collect_nested_private
 test eax,eax
 jnz .done
 mov rdi,rbx
 call fcg_program_has_slice_parameter
 mov [rbx+NEBOC_FUNCTION_CODEGEN_HAS_SLICE_PARAMETERS_OFFSET],rax
 mov rdi,rbx
 call fcg_emit_text_literals
 test eax,eax
 jnz .done
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_FLAG_TEXTUAL_VALIDATED
 jz .textual_data_ready
 mov rdi,rbx
 call fcg_emit_textual_data
 test eax,eax
 jnz .done
.textual_data_ready:
 mov rdi,rbx
 call fcg_emit_collection_data
 test eax,eax
 jnz .done
 mov rdi,rbx
 call fcg_emit_scientific_helpers
 test eax,eax
 jnz .done

 ; Emit receiver-first functions in stable source order. This is a valid
 ; topological order because forward/self calls are rejected by resolve_call.
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r14,2                    ; symbol id, start reserves 1
 mov r15,1                    ; source order
.emit_functions:
 test r12,r12
 jz .emit_start
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .emit_next
 mov rdi,rbx
 mov rsi,r14
 call fcg_nested_decl_for_owner
 test rax,rax
 jz .emit_public_function
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_NESTED_OWNER_ID_OFFSET],r14
 mov rdi,rbx
 mov rsi,rax
 lea rdx,[r14+NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS]
 mov rcx,r15
 call fcg_emit_function
 test eax,eax
 jnz .done
.emit_public_function:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 mov rcx,r15
 call fcg_emit_function
 test eax,eax
 jnz .done
 inc r14
 inc r15
.emit_next:
 mov r12,r13
 jmp .emit_functions
.emit_start:
 cmp qword [rsp+8],0
 je .emit_done
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov rcx,r15
 call fcg_emit_start
 test eax,eax
 jnz .done
.emit_done:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, function_decl_id, symbol_id, source_order
fcg_emit_function:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],r13
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_RETURN_LABEL_REFERENCE_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .ast
 mov rax,[r15+NEBOC_AST_NODE_FLAGS_OFFSET]
 and rax,NEBOC_AST_FLAG_NESTED_PRIVATE
 setnz al
 movzx eax,al
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_IS_NESTED_OFFSET],rax
 test eax,eax
 jnz .nested_owner_ready
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_NESTED_OWNER_ID_OFFSET],0
.nested_owner_ready:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rax
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS
 ja .parameter
 mov [rsp],rax               ; total parameter count
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .ast
 mov [rsp+8],rax             ; block id
 mov rdi,rbx
 mov rsi,rax
 mov rdx,[rsp]
 call fcg_prepare_bindings
 cmp rax,-1
 je .binding_error
 mov [rsp+40],rax            ; total local slots (parameters + bindings)
 mov [rsp+48],rdx            ; binding count
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SLICE_TEMP_BASE_OFFSET],rax
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_HAS_SLICE_PARAMETERS_OFFSET],0
 je .function_locals_ready
 add qword [rsp+40],NEBOC_FUNCTION_CODEGEN_SLICE_TEMP_SLOTS
.function_locals_ready:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_function_return_type
 test rax,rax
 jz .flow_error
 mov [rsp+56],rax            ; inferred Void/scalar return type
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET],rax
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET],0
 mov rcx,[rsp]
 mov [rsp+80],rcx            ; physical ABI parameter count
 mov rcx,[rsp+40]
 mov [rsp+88],rcx            ; physical ABI local count
 mov rdi,rax
 call fcg_array_type_decode
 test eax,eax
 jnz .sret_return_contract
 mov rdi,[rsp+56]
 call fcg_slice_type_decode
 test eax,eax
 jz .return_contract_ready
.sret_return_contract:
 inc qword [rsp+80]          ; hidden sret precedes the source receiver
 mov rax,[rsp+88]
 inc rax
 cmp rax,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .parameter
 mov [rsp+88],rax
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET],rax
.return_contract_ready:
 mov rdi,rbx
 mov rsi,[rsp+8]
 xor edx,edx
 call fcg_count_calls
 cmp rax,-1
 je .depth
 cmp rax,NEBOC_ABI_MAX_RUNTIME_CALLS
 ja .call_limit
 mov [rsp+16],rax            ; call count
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r14
 mov rcx,[rsp+80]
 mov r8,[rsp+88]
 mov r9,[rsp+16]
 call fcg_prepare_contracts
 test rax,rax
 jz .abi
 mov [rsp+24],rax            ; signature ptr
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET]
 cmp r13,rdx
 jne .recursion_frame_ready
 cmp qword [rax+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET],NEBOC_FUNCTION_RECURSION_FRAME_BYTES
 jne .recursion_frame
.recursion_frame_ready:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_IS_NESTED_OFFSET],0
 jne .begin_private_nested
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET]
 mov rsi,r13
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .abi
 jmp .begin_adapter
.begin_private_nested:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_NESTED_OWNER_ID_OFFSET]
 mov edx,1
 mov rcx,r13
 call neboc_arch_backend_begin_private_nested_function
 test eax,eax
 jnz .abi
.begin_adapter:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .abi
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_emit_mutable_frame_reserve
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET],0
 je .copy_source_params
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 xor esi,esi
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET]
 call neboc_abi_adapter_emit_parameter_copy
 test eax,eax
 jnz .abi
.copy_source_params:
 xor r15d,r15d
.copy_params:
 cmp r15,[rsp]
 jae .body
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,r15
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET],0
 je .copy_param_index_ready
 inc rsi
.copy_param_index_ready:
 lea rdx,[r15+1]
 call neboc_abi_adapter_emit_parameter_copy
 test eax,eax
 jnz .abi
 inc r15
 jmp .copy_params
.body:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_emit_mutable_array_initializers_for_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test r12,r12
 jz .body_done
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rdx,NEBOC_AST_EXPRESSION_STMT
 je .expression_stmt
 cmp rdx,NEBOC_AST_BINDING_STMT
 je .binding_stmt
 cmp rdx,NEBOC_AST_ASSIGNMENT_STMT
 je .assignment_stmt
 cmp rdx,NEBOC_AST_RETURN_STMT
 je .return_stmt
 cmp rdx,NEBOC_AST_IF_STMT
 je .if_stmt
 cmp rdx,NEBOC_AST_WHILE_STMT
 je .loop_stmt
 cmp rdx,NEBOC_AST_LOOP_STMT
 je .loop_stmt
 cmp rdx,NEBOC_AST_RANGE_FOR_STMT
 je .collection_loop_stmt
 cmp rdx,NEBOC_AST_FUNCTION_DECL
 jne .unsupported
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jz .unsupported
 mov r12,r15
 jmp .statement_loop
.expression_stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 xor edx,edx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.binding_stmt:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPED_BINDING_DECLARATION
 jnz .buffer_binding_noop
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_scientific_binding
 test eax,eax
 jnz .scientific_binding
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_collection_binding
 cmp eax,2
 je .buffer_binding_noop
 test eax,eax
 jnz .binding_noop
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_binding
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.scientific_binding:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_scientific_binding
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.buffer_binding_noop:
 mov r12,r15
 jmp .statement_loop
.binding_noop:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_collection_binding
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.assignment_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_assignment
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.if_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_if
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.loop_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_loop
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.collection_loop_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_collection_loop
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.return_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_return_statement
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.body_done:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 ; A natural Void Function Scan fallthrough has no scalar result.  Scan
 ; legitimately leaves its internal Text descriptor in RAX, so canonicalize
 ; the new composition before the shared epilogue without changing Assembly
 ; for pre-existing Void functions that do not contain Scan.
 cmp qword [rsp+56],NEBOC_TYPE_ID_VOID
 jne .return_label
 mov rdi,rbx
 mov rsi,[rsp+8]
 xor edx,edx
 call fcg_contains_scan_call
 cmp rax,-1
 je .depth
 test eax,eax
 jz .return_label
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 test eax,eax
 jnz .done
.return_label:
 mov rdi,rbx
 lea rsi,[rel fcg_return_label]
 mov edx,fcg_return_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 call neboc_abi_adapter_emit_return_rax
 test eax,eax
 jnz .abi
 mov rdi,rbx
 call fcg_emit_traps
 jmp .done
.binding_error:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 je .parameter
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.recursion_frame:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_FRAME
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.call_limit:
 mov rdi,rbx
 call fcg_capture_call_limit_span
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CALL_LIMIT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.flow_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, start_decl_id, source_order
fcg_emit_start:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov r14,rcx
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],1
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_RETURN_LABEL_REFERENCE_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_VOID
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_EMITTED_COUNT_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 xor edx,edx
 call fcg_prepare_bindings
 cmp rax,-1
 je .binding_error
 mov [rsp+32],rax            ; total local slots
 mov [rsp+40],rdx            ; binding count
 ; C03-F04 validates every normal process-status terminal before any start
 ; function bytes are emitted. Mixed Int/Bool/Char paths are deliberately
 ; valid; descriptors, pointers and aggregates fail closed without reaching
 ; the runtime bridge in RAX.
 mov rdi,rbx
 mov rsi,[rsp]
 xor edx,edx
 call fcg_validate_start_status_block
 test eax,eax
 jnz .done
 mov rax,[rsp+32]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SLICE_TEMP_BASE_OFFSET],rax
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_HAS_SLICE_PARAMETERS_OFFSET],0
 je .start_locals_ready
 add qword [rsp+32],NEBOC_FUNCTION_CODEGEN_SLICE_TEMP_SLOTS
.start_locals_ready:
 mov rdi,rbx
 mov rsi,[rsp]
 xor edx,edx
 call fcg_count_calls
 cmp rax,-1
 je .depth
 cmp rax,NEBOC_ABI_MAX_RUNTIME_CALLS
 ja .call_limit
 mov [rsp+8],rax
 mov rdi,rbx
 mov esi,1
 mov rdx,r14
 xor ecx,ecx
 mov r8,[rsp+32]
 mov r9,[rsp+8]
 call fcg_prepare_contracts
 test rax,rax
 jz .abi
 mov [rsp+16],rax
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .abi
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .abi
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_emit_mutable_frame_reserve
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_emit_mutable_array_initializers_for_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+24],0
.statement_loop:
 test r12,r12
 jz .tail
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov [rsp+48],rax
 mov rsi,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov rdi,rbx
 call fcg_emit_scientific_calls
 test eax,eax
 jnz .done
 mov rax,[rsp+48]
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rdx,NEBOC_AST_EXPRESSION_STMT
 je .expression_stmt
 cmp rdx,NEBOC_AST_BINDING_STMT
 je .binding_stmt
 cmp rdx,NEBOC_AST_ASSIGNMENT_STMT
 je .assignment_stmt
 cmp rdx,NEBOC_AST_RETURN_STMT
 je .return_stmt
 cmp rdx,NEBOC_AST_IF_STMT
 je .if_stmt
 cmp rdx,NEBOC_AST_WHILE_STMT
 je .loop_stmt
 cmp rdx,NEBOC_AST_LOOP_STMT
 je .loop_stmt
 cmp rdx,NEBOC_AST_RANGE_FOR_STMT
 je .collection_loop_stmt
 jmp .unsupported
.expression_stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 xor edx,edx
 call fcg_emit_expr
 jmp .emitted
.binding_stmt:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPED_BINDING_DECLARATION
 jnz .buffer_binding_noop
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_scientific_binding
 test eax,eax
 jnz .scientific_binding
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_collection_binding
 cmp eax,2
 je .buffer_binding_noop
 test eax,eax
 jnz .binding_noop
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_binding
 jmp .emitted
.scientific_binding:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_scientific_binding
 jmp .emitted
.buffer_binding_noop:
 xor eax,eax
 jmp .emitted
.binding_noop:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_collection_binding
 jmp .emitted
.assignment_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_assignment
 jmp .emitted
.return_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_return_statement
 jmp .emitted
.if_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_if
 jmp .emitted
.loop_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_loop
 jmp .emitted
.collection_loop_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_collection_loop
.emitted:
 test eax,eax
 jnz .done
 inc qword [rsp+24]
 mov r12,r15
 jmp .statement_loop
.tail:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET]
 inc rsi
 mov rdi,rbx
 call fcg_emit_scientific_calls
 test eax,eax
 jnz .done
 cmp qword [rsp+24],0
 jne .return_label_gate
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 test eax,eax
 jnz .done
.return_label_gate:
 ; A successfully emitted return jump is the authoritative per-function
 ; reason for this definition.  Retain the pre-existing gates below for
 ; general-body, recursion, and nested-helper byte compatibility.
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_RETURN_LABEL_REFERENCE_COUNT_OFFSET],0
 jne .emit_return_label
 ; Preserve the pre-NPT35 general-body label gate byte-for-byte, and add only
 ; the selected recursive root as the second causal reason for this label.
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .return_label_recursion_gate
 test qword [rax+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jnz .emit_return_label
.return_label_recursion_gate:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET],0
 jne .emit_return_label
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET],0
 jne .emit_return_label
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET],0
 je .return
.emit_return_label:
 mov rdi,rbx
 lea rsi,[rel fcg_return_label]
 mov edx,fcg_return_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
.return:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 call neboc_abi_adapter_emit_return_rax
 test eax,eax
 jnz .abi
 mov rdi,rbx
 call fcg_emit_traps
 jmp .done
.binding_error:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 je .parameter
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.call_limit:
 mov rdi,rbx
 call fcg_capture_call_limit_span
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CALL_LIMIT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth -> status. Validate all start-owned `.return`
; terminals without imposing ordinary-function homogeneous return typing.
; Lexical scopes are reconstructed exactly so returned identifiers/calls use
; the same type owner as emission.
fcg_validate_start_status_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test r14,r14
 jz .ok
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_RETURN_STMT
 je .return_statement
 cmp rax,NEBOC_AST_IF_STMT
 je .if_statement
 cmp rax,NEBOC_AST_WHILE_STMT
 je .loop_statement
 cmp rax,NEBOC_AST_LOOP_STMT
 je .loop_statement
 cmp rax,NEBOC_AST_RANGE_FOR_STMT
 je .loop_statement
 jmp .next
.return_statement:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov [rsp],rsi
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 je .next
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .next
 cmp rax,NEBOC_TYPE_ID_CHAR
 je .next
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .invalid_source
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ENTRYPOINT_STATUS
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_capture_node_span
 jmp .invalid_source
.if_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_validate_start_status_if
 test eax,eax
 jnz .done
 jmp .next
.loop_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_validate_start_status_loop
 test eax,eax
 jnz .done
.next:
 mov r14,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .statement_loop
.ok:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 xor eax,eax
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, if_node_id, depth -> status.
fcg_validate_start_status_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r13
 mov rcx,r12
 call fcg_validate_start_status_scoped_block
 test eax,eax
 jnz .done
 test r15,r15
 jz .ok
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_validate_start_status_if
 jmp .done
.else_block:
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 mov rcx,r12
 call fcg_validate_start_status_scoped_block
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, while/loop/range-for node_id, depth -> status.
fcg_validate_start_status_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 cmp r15,NEBOC_AST_LOOP_STMT
 je .body_ready
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 cmp r15,NEBOC_AST_WHILE_STMT
 je .body_ready
 cmp r15,NEBOC_AST_RANGE_FOR_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
.body_ready:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r13
 mov rcx,r12
 call fcg_validate_start_status_scoped_block
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth, exact parent statement -> status.
fcg_validate_start_status_scoped_block:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 call fcg_scope_push
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_validate_start_status_block
 mov r12,rax
 mov rdi,rbx
 call fcg_scope_pop
 test r12d,r12d
 jnz .validation_status
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.validation_status:
 mov eax,r12d
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, symbol_id, source_order, parameter_count, local_count, call_count
; returns signature pointer or zero.
fcg_prepare_contracts:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 mov rax,r12
 dec rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET]
 jae .bad
 mov rdx,NEBOC_ABI_SIGNATURE_SIZE
 imul rax,rdx
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURES_OFFSET]
 mov [rsp+8],rax
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
 rep stosq
 mov rdi,[rsp+8]
 mov rsi,r12
 mov rdx,r14
 mov rcx,r15
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 mov r9,[rsp]
 call neboc_abi_signature_init
 test eax,eax
 jnz .bad
 mov rax,r12
 dec rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET]
 jae .bad
 mov rdx,NEBOC_FUNCTION_PLAN_SIZE
 imul rax,rdx
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLANS_OFFSET]
 mov [rsp+16],rax
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_PLAN_QWORDS
 rep stosq
 mov rax,[rsp+16]
 mov [rax+NEBOC_FUNCTION_PLAN_ID_OFFSET],r12
 mov [rax+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET],r12
 mov [rax+NEBOC_FUNCTION_PLAN_SOURCE_ORDER_OFFSET],r13
 mov qword [rax+NEBOC_FUNCTION_PLAN_FIRST_OPERATION_ID_OFFSET],0
 mov rdx,[rsp]
 inc rdx
 mov [rax+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET],rdx
 mov qword [rax+NEBOC_FUNCTION_PLAN_FIRST_CONTINUATION_ID_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_CONTINUATION_COUNT_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET],1
 mov qword [rax+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_FLAG_TARGET_INDEPENDENT|NEBOC_LOWERING_PLAN_FLAG_SOURCE_ORDERED
 mov qword [rax+NEBOC_FUNCTION_PLAN_CANCELLATION_POLICY_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_STATE_OFFSET],NEBOC_FUNCTION_PLAN_STATE_FROZEN
 mov [rax+NEBOC_FUNCTION_PLAN_PARAMETER_COUNT_OFFSET],r14
 mov [rax+NEBOC_FUNCTION_PLAN_LOCAL_BINDING_COUNT_OFFSET],r15
 mov rdi,rax
 call neboc_function_plan_compute_hash
 test eax,eax
 jnz .bad
 mov rax,[rsp+8]
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, frozen signature -> status. Reserve a separately bounded, aligned
; mutable-Array payload below the ABI-owned scalar frame. `leave` remains the
; shared epilogue, so no ABI or runtime contract changes.
fcg_emit_mutable_frame_reserve:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rax,[r12+NEBOC_ABI_SIGNATURE_FRAME_SIZE_OFFSET]
 shr rax,3
 mov [rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET]
 test rax,rax
 jz .ok
 shl rax,3
 add rax,15
 and rax,-16
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_sub_rsp]
 mov edx,fcg_sub_rsp_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, expression_node_id, depth -> status
fcg_emit_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .integer
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .boolean
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .integer
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text_literal
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unsupported
.integer:
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.boolean:
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 je .bool_false
 mov rdi,rbx
 lea rsi,[rel fcg_mov_true]
 mov edx,fcg_mov_true_len
 call fcg_append
 jmp .done
.bool_false:
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 jmp .done
.text_literal:
 mov rdi,rbx
 lea rsi,[rel fcg_lea_text_desc]
 mov edx,fcg_lea_text_desc_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_lea_text_desc_suffix]
 mov edx,fcg_lea_text_desc_suffix_len
 call fcg_append
 jmp .done
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .identifier_undefined
 mov r15,rax
 shl r15,3
 mov rdi,rbx
 lea rsi,[rel fcg_load_slot]
 mov edx,fcg_load_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 jmp .done
.identifier_undefined:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_slice_descriptor
 cmp eax,1
 je .ok
 test eax,eax
 jnz .done
 ; The collection-general path owns loop-local iterator lifetime.  Once that
 ; lifetime has ended, report the exact identifier as an undefined name rather
 ; than falling through to the legacy catch-all unsupported-node diagnostic.
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .unsupported
 test qword [rax+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .unsupported
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .ok
 cmp rax,NEBOC_TOKEN_MINUS
 je .unary_minus
 cmp rax,NEBOC_TOKEN_BANG
 je .unary_not
 jmp .unsupported
.unary_minus:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_neg]
 mov edx,fcg_neg_len
 call fcg_append
 jmp .done
.unary_not:
 mov rdi,rbx
 lea rsi,[rel fcg_not]
 mov edx,fcg_not_len
 call fcg_append
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .ast
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_AND_AND
 je .logical_and
 cmp rax,NEBOC_TOKEN_OR_OR
 je .logical_or
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .maybe_text_equality
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .maybe_text_equality
 jmp .generic_binary
.maybe_text_equality:
 mov [rsp+40],rax
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .generic_binary
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .unsupported
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_equal_call]
 mov edx,fcg_text_equal_call_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+40],NEBOC_TOKEN_BANG_EQUAL
 jne .ok
 mov rdi,rbx
 lea rsi,[rel fcg_text_not_equal]
 mov edx,fcg_text_not_equal_len
 call fcg_append
 jmp .done
.generic_binary:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_restore_binary]
 mov edx,fcg_restore_binary_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .add
 cmp rax,NEBOC_TOKEN_MINUS
 je .sub
 cmp rax,NEBOC_TOKEN_STAR
 je .mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .div
 cmp rax,NEBOC_TOKEN_PERCENT
 je .mod
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .eq
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .ne
 cmp rax,NEBOC_TOKEN_LESS
 je .lt
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .le
 cmp rax,NEBOC_TOKEN_GREATER
 je .gt
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 je .ge
 jmp .unsupported
.add:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_add]
 mov edx,fcg_add_len
 call fcg_append
 jmp .done
.sub:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_sub]
 mov edx,fcg_sub_len
 call fcg_append
 jmp .done
.mul:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_mul]
 mov edx,fcg_mul_len
 call fcg_append
 jmp .done
.div:
 xor r15d,r15d
 jmp .division_common
.mod:
 mov r15d,1
.division_common:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW|NEBOC_FUNCTION_CODEGEN_TRAP_DIV_ZERO
 mov rdi,rbx
 lea rsi,[rel fcg_div_prefix]
 mov edx,fcg_div_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_div_mid]
 mov edx,fcg_div_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_div_tail]
 mov edx,fcg_div_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 test r15d,r15d
 jz .ok
 mov rdi,rbx
 lea rsi,[rel fcg_mod_tail]
 mov edx,fcg_mod_tail_len
 call fcg_append
 jmp .done
.eq:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_eq]
 mov edx,fcg_cmp_eq_len
 call fcg_append
 jmp .done
.ne:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_ne]
 mov edx,fcg_cmp_ne_len
 call fcg_append
 jmp .done
.lt:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_lt]
 mov edx,fcg_cmp_lt_len
 call fcg_append
 jmp .done
.le:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_le]
 mov edx,fcg_cmp_le_len
 call fcg_append
 jmp .done
.gt:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_gt]
 mov edx,fcg_cmp_gt_len
 call fcg_append
 jmp .done
.ge:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_ge]
 mov edx,fcg_cmp_ge_len
 call fcg_append
 jmp .done
.logical_and:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_and_branch]
 mov edx,fcg_and_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_bool_canon_done]
 mov edx,fcg_bool_canon_done_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_false_label]
 mov edx,fcg_false_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_false_body]
 mov edx,fcg_false_body_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 jmp .done
.logical_or:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_or_branch]
 mov edx,fcg_or_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_bool_canon_done]
 mov edx,fcg_bool_canon_done_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_true_label]
 mov edx,fcg_true_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_true_body]
 mov edx,fcg_true_body_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 jmp .done
.call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_tuple_expr_info
 test eax,eax
 jz .call_not_tuple
 mov [rsp+56],rdx
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.call_not_tuple:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .type_constructor
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_console_call
 test eax,eax
 jnz .console_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_scan_call
 test eax,eax
 jnz .scan_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_buffer_call_info
 test eax,eax
 jnz .collection_access_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_textual_call_info
 test eax,eax
 jnz .textual_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_nominal_call_info
 test eax,eax
 jnz .nominal_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_byte_length_call
 test eax,eax
 jnz .byte_length_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_codepoint_count_call
 test eax,eax
 jnz .codepoint_count_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_numeric_call_info
 test eax,eax
 jnz .numeric_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_release_info
 test eax,eax
 jnz .collection_release_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_sum_info
 test eax,eax
 jnz .collection_access_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_access_info
 test eax,eax
 jnz .collection_access_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 test rax,rax
 jz .unsupported
 mov [rsp],rax              ; callee symbol
 mov [rsp+8],rdx            ; return type
 mov rcx,[rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_RECURSION_KIND_OFFSET]
 mov [rsp+72],rcx           ; call-site-local recursion kind
 mov rcx,[rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_NESTED_OWNER_ID_OFFSET]
 mov [rsp+80],rcx           ; zero or exact private outer owner
 mov rdi,rdx
 call fcg_array_type_decode
 test eax,eax
 jnz .unsupported          ; Array calls require a direct typed owner binding.
 mov rdi,[rsp+8]
 call fcg_slice_type_decode
 test eax,eax
 jnz .unsupported          ; Slice calls require a direct typed reborrow binding.
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rax
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS
 ja .parameter
 mov [rsp+16],rax           ; total receiver + args
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+24],0
.call_eval_loop:
 mov rax,[rsp+24]
 cmp rax,[rsp+16]
 jae .call_pop_start
 test r15,r15
 jz .ast
 mov rax,[rsp+24]
 test rax,rax
 jz .call_temp_ready
 dec rax
.call_temp_ready:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET],rax
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+24]
 jmp .call_eval_loop
.call_pop_start:
 mov rax,[rsp+16]
 mov [rsp+32],rax
.call_pop_loop:
 cmp qword [rsp+32],0
 je .call_emit
 dec qword [rsp+32]
 mov r10,[rsp+32]
 lea rax,[rel fcg_pop_ptrs]
 mov rsi,[rax+r10*8]
 lea rax,[rel fcg_pop_lens]
 mov rdx,[rax+r10*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 jmp .call_pop_loop
.call_emit:
 cmp qword [rsp+72],NEBOC_FUNCTION_RECURSION_CALL_ORDINARY
 je .call_emit_ordinary
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 mov rcx,[rsp+72]
 call fcg_emit_selected_recursive_call
 jmp .call_emit_done
.call_emit_ordinary:
 cmp qword [rsp+80],0
 je .call_emit_public
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp+80]
 mov edx,1
 call neboc_abi_adapter_emit_prepared_private_nested_call
 jmp .call_emit_done
.call_emit_public:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp]
 call neboc_abi_adapter_emit_prepared_call
.call_emit_done:
 test eax,eax
 jnz .abi
 xor eax,eax
 jmp .done
.console_call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_console_call
 jmp .done
.scan_call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_scan_call
 jmp .done
.textual_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_textual_call
 jmp .done
.nominal_call:
 mov [rsp+56],rdx
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.byte_length_call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 lea rcx,[rel fcg_text_byte_length]
 mov r8d,fcg_text_byte_length_len
 call fcg_emit_text_count_call
 jmp .done
.codepoint_count_call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 lea rcx,[rel fcg_text_codepoint_count]
 mov r8d,fcg_text_codepoint_count_len
 call fcg_emit_text_count_call
 jmp .done
.numeric_call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_numeric_call
 jmp .done
.collection_release_call:
 ; Array/Slice semantic ownership has already authenticated the exactly-once
 ; lifecycle transition.  Immutable local descriptors require no runtime
 ; destructor; publish a deterministic Void expression value for sequencing.
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 jmp .done
.collection_access_call:
 mov [rsp+64],rax
 mov [rsp+32],rcx
 mov [rsp+56],rdx
 mov [rsp+72],r8
 mov [rsp+48],r9
 mov [rsp+40],r10
 cmp qword [rsp+64],-1
 je .collection_invalid_at
 cmp qword [rsp+64],2
 je .collection_dynamic_length
 cmp qword [rsp+64],3
 je .collection_dynamic_at
 cmp qword [rsp+64],4
 je .collection_dynamic_local_at
 cmp qword [rsp+64],5
 je .collection_dynamic_borrowed_at
 cmp qword [rsp+64],6
 je .collection_dynamic_local_slice_at
 cmp qword [rsp+64],7
 je .collection_dynamic_mutable_at
 cmp qword [rsp+64],8
 je .collection_result_length
 cmp qword [rsp+64],9
 je .collection_result_constant_at
 cmp qword [rsp+64],10
 je .collection_result_dynamic_at
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.collection_dynamic_length:
 mov rdi,rbx
 lea rsi,[rel fcg_slice_param_load]
 mov edx,fcg_slice_param_load_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_length_load]
 mov edx,fcg_slice_length_load_len
 call fcg_append
 jmp .done
.collection_result_length:
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_lea]
 mov edx,fcg_slice_result_lea_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_length_tail]
 mov edx,fcg_slice_result_length_tail_len
 call fcg_append
 jmp .done
.collection_result_constant_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_lea]
 mov edx,fcg_slice_result_lea_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard]
 mov edx,fcg_slice_at_guard_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+72]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard_branch]
 mov edx,fcg_slice_at_guard_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard_tail]
 mov edx,fcg_slice_at_guard_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+72]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 jmp .done
.collection_result_dynamic_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_frame_slice_receiver]
 mov edx,fcg_dynamic_frame_slice_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .collection_dynamic_eval
.collection_dynamic_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_slice_param_load]
 mov edx,fcg_slice_param_load_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard]
 mov edx,fcg_slice_at_guard_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+72]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard_branch]
 mov edx,fcg_slice_at_guard_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_at_guard_tail]
 mov edx,fcg_slice_at_guard_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+72]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 jmp .done
.collection_dynamic_local_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_array_receiver]
 mov edx,fcg_dynamic_array_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .collection_dynamic_eval
.collection_dynamic_local_slice_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_local_slice_receiver]
 mov edx,fcg_dynamic_local_slice_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .collection_dynamic_eval
.collection_dynamic_borrowed_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_borrowed_receiver]
 mov edx,fcg_dynamic_borrowed_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+56]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .collection_dynamic_eval
.collection_dynamic_mutable_at:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rax,[rsp+56]
 mov eax,eax
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 cmp rax,[rdx+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .collection_invalid_at
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[rdx+NEBOC_AR_BINDINGS_OFFSET]
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .collection_invalid_at
 mov rdx,[rsp+56]
 shr rdx,32
 shl rdx,3
 sub rax,rdx
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_mutable_receiver]
 mov edx,fcg_dynamic_mutable_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_r10]
 mov edx,fcg_push_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .collection_dynamic_mutable_eval
.collection_dynamic_eval:
 mov rdi,rbx
 mov rsi,[rsp+72]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .collection_dynamic_index_ready
.collection_dynamic_mutable_eval:
 mov rdi,rbx
 mov rsi,[rsp+72]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_pop_r10]
 mov edx,fcg_pop_r10_len
 call fcg_append
 test eax,eax
 jnz .done
.collection_dynamic_index_ready:
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_index_lower]
 mov edx,fcg_dynamic_index_lower_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 cmp qword [rsp+64],4
 je .collection_dynamic_local_upper_path
 cmp qword [rsp+64],7
 jne .collection_dynamic_borrowed_upper
.collection_dynamic_local_upper_path:
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_local_upper]
 mov edx,fcg_dynamic_local_upper_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+48]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_upper_branch]
 mov edx,fcg_dynamic_upper_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_local_stride]
 mov edx,fcg_dynamic_local_stride_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+40]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 jmp .collection_dynamic_multiply
.collection_dynamic_borrowed_upper:
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_borrowed_upper]
 mov edx,fcg_dynamic_borrowed_upper_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_borrowed_stride]
 mov edx,fcg_dynamic_borrowed_stride_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_borrowed_base]
 mov edx,fcg_dynamic_borrowed_base_len
 call fcg_append
 test eax,eax
 jnz .done
.collection_dynamic_multiply:
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_checked_multiply]
 mov edx,fcg_dynamic_checked_multiply_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 cmp qword [rsp+64],7
 je .collection_dynamic_mutable_address
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_checked_add]
 mov edx,fcg_dynamic_checked_add_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 jmp .collection_dynamic_load
.collection_dynamic_mutable_address:
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_checked_frame_add]
 mov edx,fcg_dynamic_checked_frame_add_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_address_to_rax]
 mov edx,fcg_dynamic_address_to_rax_len
 call fcg_append
 test eax,eax
 jnz .done
.collection_dynamic_load:
 mov rdi,rbx
 cmp qword [rsp+32],NEBOC_TYPE_ID_BOOL
 je .collection_dynamic_load_bool
 cmp qword [rsp+32],NEBOC_TYPE_ID_CHAR
 je .collection_dynamic_load_char
 lea rsi,[rel fcg_dynamic_element_load_int]
 mov edx,fcg_dynamic_element_load_int_len
 jmp .collection_dynamic_load_append
.collection_dynamic_load_bool:
 lea rsi,[rel fcg_dynamic_element_load_bool]
 mov edx,fcg_dynamic_element_load_bool_len
 jmp .collection_dynamic_load_append
.collection_dynamic_load_char:
 lea rsi,[rel fcg_dynamic_element_load_char]
 mov edx,fcg_dynamic_element_load_char_len
.collection_dynamic_load_append:
 call fcg_append
 jmp .done
.collection_invalid_at:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.type_constructor:
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .unsupported
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .unsupported
 mov [rsp+48],rax
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,[rsp+48]
 jne .type_assertion
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 jmp .done
.type_assertion:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .unsupported_status
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
.unsupported_status:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_node_id -> EAX 1 only for the existing zero-option
; receiver-first console() spelling.  This classifier does not validate the
; receiver type; fcg_emit_console_call owns that exact public-surface check.
fcg_is_console_call:
 sub rsp,8
 lea rdx,[rel fcg_name_console]
 mov ecx,fcg_name_console_len
 call fcg_call_name_matches
 add rsp,8
 ret

fcg_is_scan_call:
 sub rsp,8
 lea rdx,[rel fcg_name_scan]
 mov ecx,fcg_name_scan_len
 call fcg_call_name_matches
 add rsp,8
 ret

fcg_is_byte_length_call:
 sub rsp,8
 lea rdx,[rel fcg_name_byte_length]
 mov ecx,fcg_name_byte_length_len
 call fcg_call_name_matches
 add rsp,8
 ret

fcg_is_codepoint_count_call:
 sub rsp,8
 lea rdx,[rel fcg_name_codepoint_count]
 mov ecx,fcg_name_codepoint_count_len
 call fcg_call_name_matches
 add rsp,8
 ret

; state*, call node id -> EAX exact numeric operation kind and ECX result
; type.  The receiver is recursively typed through the shared expression
; oracle, so method spelling alone can never manufacture a numeric intrinsic.
; Kinds: 1=Int.toFloat, 2=isFinite, 3=isNaN, 4=isInfinite,
; 5=isNegativeZero.
fcg_numeric_call_info:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_to_float]
 mov ecx,fcg_name_to_float_len
 call fcg_call_name_matches
 test eax,eax
 jnz .to_float
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_is_finite]
 mov ecx,fcg_name_is_finite_len
 call fcg_call_name_matches
 test eax,eax
 jnz .finite
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_is_nan]
 mov ecx,fcg_name_is_nan_len
 call fcg_call_name_matches
 test eax,eax
 jnz .nan
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_is_infinite]
 mov ecx,fcg_name_is_infinite_len
 call fcg_call_name_matches
 test eax,eax
 jnz .infinite
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_is_negative_zero]
 mov ecx,fcg_name_is_negative_zero_len
 call fcg_call_name_matches
 test eax,eax
 jnz .negative_zero
 jmp .no
.to_float:
 mov qword [rsp],1
 mov ecx,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_FLOAT
 jmp .receiver
.finite:
 mov qword [rsp],2
 jmp .classifier
.nan:
 mov qword [rsp],3
 jmp .classifier
.infinite:
 mov qword [rsp],4
 jmp .classifier
.negative_zero:
 mov qword [rsp],5
.classifier:
 mov ecx,NEBOC_TYPE_ID_FLOAT
 mov edx,NEBOC_TYPE_ID_BOOL
.receiver:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov [rsp+16],rdx
 mov [rsp+8],rcx
 mov rdi,rbx
 xor edx,edx
 call fcg_infer_type
 cmp rax,[rsp+8]
 jne .no
 mov eax,[rsp]
 mov rcx,[rsp+16]
 jmp .done
.no:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],r13
 xor eax,eax
 xor ecx,ecx
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, authenticated numeric call id, depth -> status.  The Int conversion
; leaves both canonical Float bits in RAX (for a direct binding) and the ABI
; value in XMM0 (for a following classifier).
fcg_emit_numeric_call:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_numeric_call_info
 test eax,eax
 jz .unsupported
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r14,rax
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[rsp]
 cmp rax,1
 je .to_float
 cmp rax,2
 je .finite
 cmp rax,3
 je .nan
 cmp rax,4
 je .infinite
 cmp rax,5
 jne .unsupported
 lea rsi,[rel fcg_numeric_is_negative_zero]
 mov edx,fcg_numeric_is_negative_zero_len
 jmp .append
.to_float:
 lea rsi,[rel fcg_numeric_to_float]
 mov edx,fcg_numeric_to_float_len
 jmp .append
.finite:
 lea rsi,[rel fcg_numeric_is_finite]
 mov edx,fcg_numeric_is_finite_len
 jmp .append
.nan:
 lea rsi,[rel fcg_numeric_is_nan]
 mov edx,fcg_numeric_is_nan_len
 jmp .append
.infinite:
 lea rsi,[rel fcg_numeric_is_infinite]
 mov edx,fcg_numeric_is_infinite_len
.append:
 mov rdi,rbx
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node id -> EAX 1 for canonical runtime intrinsics that do not
; consume the bounded receiver-first user-function call budget.
fcg_is_runtime_intrinsic_call:
 sub rsp,24
 mov [rsp],rdi
 mov [rsp+8],rsi
 call fcg_is_console_call
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_is_scan_call
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_buffer_call_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_textual_call_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_nominal_call_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_nominal_constructor_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_is_byte_length_call
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_is_codepoint_count_call
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_numeric_call_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_collection_result_as_slice_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_collection_release_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_collection_sum_info
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 call fcg_collection_access_info
.done:
 add rsp,24
 ret

; state*, expression_node_id -> EAX 1 only when the expression is a direct
; reference to a prior binding whose initializer is the canonical Scan call.
; NPT-LANG-12 publishes Text count operations for scanned values; it does not
; publish general Text byteLength/codepointCount composition inside functions.
fcg_is_scan_result_reference:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test r13,r13
 jz .no
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .no
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_scan_call
 test eax,eax
 jz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_node_id, exact_name*, exact_name_len -> EAX 1/0.
; Intrinsic classifiers share the same zero-option receiver-first contract;
; receiver types remain owned by their dedicated emitters.
fcg_call_name_matches:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r14
 jne .no
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r13
 mov rcx,r14
 cld
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

%define FCG_TEXTUAL_OPTION_INT 4096

; state*, request* -> status. Build the existing textual-codegen request from
; the immutable Program/FunctionTable state; no public descriptor is widened.
fcg_init_textual_codegen_request:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 mov ecx,neboc_text_char_unicode_e_bytes_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 cld
 rep stosq
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 mov [r12+NEBOC_CODEGEN_LITERAL_BYTES_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 mov [r12+NEBOC_CODEGEN_LITERAL_LENGTH_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ROOT_ID_OFFSET],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_DEFAULT
 xor eax,eax
 pop r12
 pop rbx
 ret

; state* -> status. Emit only the immutable Text/Bytes data already discovered
; in the shared AST. The textual owner uses a disjoint historical label family,
; so function Text literals and textual Bytes descriptors cannot collide.
fcg_emit_textual_data:
 push rbx
 push r12
 sub rsp,136
 mov rbx,rdi
 mov r12,rsp
 mov rdi,rbx
 mov rsi,r12
 call fcg_init_textual_codegen_request
 test eax,eax
 jnz .done
 mov rdi,r12
 call neboc_text_char_bytes_codegen_emit_data
.done:
 add rsp,136
 pop r12
 pop rbx
 ret

; state*, expression node -> status. Delegation is gated by the exact
; classifier below and by cli_driver's semantic-validation proof flag.
fcg_emit_textual_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 call fcg_textual_expr_type
 cmp eax,NEBOC_TYPE_ID_BYTES
 je .bytes_receiver
 cmp eax,NEBOC_TYPE_ID_INT
 jne .delegate
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_and]
 mov ecx,fcg_name_bit_and_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .binary_and
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_or]
 mov ecx,fcg_name_bit_or_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .binary_or
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_xor]
 mov ecx,fcg_name_bit_xor_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .binary_xor
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_shift_left]
 mov ecx,fcg_name_shift_left_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .shift_left
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_shift_right]
 mov ecx,fcg_name_shift_right_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .shift_right
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_test_bit]
 mov ecx,fcg_name_test_bit_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .test_bit
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_with_bit]
 mov ecx,fcg_name_with_bit_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .with_bit
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_not]
 mov ecx,fcg_name_bit_not_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bit_not
 jmp .delegate
.bytes_receiver:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_byte_length]
 mov ecx,fcg_name_byte_length_len
 call fcg_token_matches_literal
 test eax,eax
 jz .delegate
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_bytes_byte_length]
 mov edx,fcg_text_bytes_byte_length_len
 call fcg_append
 jmp .done
.binary_and:
 lea r13,[rel fcg_text_bit_and]
 mov r15,fcg_text_bit_and_len
 jmp .binary
.binary_or:
 lea r13,[rel fcg_text_bit_or]
 mov r15,fcg_text_bit_or_len
 jmp .binary
.binary_xor:
 lea r13,[rel fcg_text_bit_xor]
 mov r15,fcg_text_bit_xor_len
 jmp .binary
.shift_left:
 lea r13,[rel fcg_text_shift_left]
 mov r15,fcg_text_shift_left_len
 jmp .binary
.shift_right:
 lea r13,[rel fcg_text_shift_right]
 mov r15,fcg_text_shift_right_len
 jmp .binary
.test_bit:
 lea r13,[rel fcg_text_test_bit]
 mov r15,fcg_text_test_bit_len
.binary:
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r15
 call fcg_append
 jmp .done
.bit_not:
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_bit_not]
 mov edx,fcg_text_bit_not_len
 call fcg_append
 jmp .done
.with_bit:
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r13,r13
 jz .bad
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 mov edx,1
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_with_bit]
 mov edx,fcg_text_with_bit_len
 call fcg_append
 jmp .done
.delegate:
 mov r13,rsp
 mov rdi,rbx
 mov rsi,r13
 call fcg_init_textual_codegen_request
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r12
 call neboc_text_char_bytes_codegen_emit_expression
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX bool, RCX exact textual result TypeId. This never
; claims a call unless the existing textual vertical accepted the Program.
fcg_textual_call_info:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_FLAG_TEXTUAL_VALIDATED
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 ; Counts on a public Scan result require the dynamic descriptor in the shared
 ; backend.  The textual vertical owns static Text/Bytes counts, so exclude
 ; only this exact receiver provenance before consulting its classifier.
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_byte_length_call
 test eax,eax
 jnz .maybe_scan_count
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_codepoint_count_call
 test eax,eax
 jz .type
.maybe_scan_count:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_is_scan_result_reference
 test eax,eax
 jnz .no
.type:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_textual_expr_type
 test eax,eax
 jz .no
 mov rcx,rax
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, call node -> EAX bool, RCX exact result TypeId, RDX exact value.
; The receiver's first source token is the public nominal Type identifier.
; Its stable FNV-1a TypeKey selects exactly one previously authenticated
; top-level owner record; no filename, fixture or literal dispatch is used.
fcg_nominal_call_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNER_COUNT_OFFSET],0
 je .no
 lea rdx,[rel fcg_name_discriminant]
 mov ecx,fcg_name_discriminant_len
 call fcg_call_name_matches
 test eax,eax
 jz .nominal_name_unwrap
 mov qword [rsp],1
 jmp .nominal_name_ready
.nominal_name_unwrap:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_unwrap]
 mov ecx,fcg_name_unwrap_len
 call fcg_call_name_matches
 test eax,eax
 jz .nominal_name_sizeof
 mov qword [rsp],2
 jmp .nominal_name_ready
.nominal_name_sizeof:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_sizeof]
 mov ecx,fcg_name_sizeof_len
 call fcg_call_name_matches
 test eax,eax
 jz .no
 mov qword [rsp],3
.nominal_name_ready:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_START_OFFSET]
 xor r14d,r14d
.find_token:
 cmp r14,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_token_ptr
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_START_OFFSET],r13
 je .hash_token
 inc r14
 jmp .find_token
.hash_token:
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 test rcx,rcx
 jz .no
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r13,14695981039346656037
 mov r14,1099511628211
 xor r15d,r15d
.hash_loop:
 cmp r15,rcx
 jae .hash_done
 movzx eax,byte [rsi+r15]
 xor r13,rax
 imul r13,r14
 inc r15
 jmp .hash_loop
.hash_done:
 test r13,r13
 jnz .find_owner
 mov r13,1
.find_owner:
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNERS_OFFSET]
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNER_COUNT_OFFSET]
.owner_loop:
 test r15,r15
 jz .no
 ; Semantic analysis intentionally domain-separates nominal TypeKeys (and an
 ; alias adopts its underlying identity), so owner selection must compare the
 ; preserved declaration-name token rather than the lowered TypeKey.
 mov rax,[r14+NEBOC_NOM_KIND_OFFSET]
 mov r8,1
 cmp rax,NEBOC_NOM_KIND_ALIAS
 jne .owner_name_index_ready
 mov r8,2
.owner_name_index_ready:
 cmp r8,[r14+NEBOC_NOM_TOKEN_COUNT_OFFSET]
 jae .next_owner
 imul rax,r8,NEBOC_TOKEN_SIZE
 add rax,[r14+NEBOC_NOM_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next_owner
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[r14+NEBOC_NOM_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r10,14695981039346656037
 mov r9,1099511628211
 xor edx,edx
.owner_name_hash_loop:
 cmp rdx,rcx
 jae .owner_name_hash_done
 movzx eax,byte [rsi+rdx]
 xor r10,rax
 imul r10,r9
 inc rdx
 jmp .owner_name_hash_loop
.owner_name_hash_done:
 test r10,r10
 jnz .owner_name_nonzero
 mov r10,1
.owner_name_nonzero:
 cmp r10,r13
 jne .next_owner
 cmp qword [r14+NEBOC_NOM_FOUND_OFFSET],1
 jne .no
 cmp qword [r14+NEBOC_NOM_DIAGNOSTIC_OFFSET],0
 jne .no
 cmp qword [rsp],1
 je .nominal_discriminant
 cmp qword [rsp],2
 je .nominal_unwrap
 cmp qword [rsp],3
 je .nominal_sizeof
 jmp .no
.nominal_discriminant:
 cmp qword [r14+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 jne .no
 mov rax,[r14+NEBOC_NOM_FLAGS_OFFSET]
 mov rdx,NEBOC_NOM_FLAG_PARSED|NEBOC_NOM_FLAG_ANALYZED|NEBOC_NOM_FLAG_ABI_A0|NEBOC_NOM_FLAG_OP_DISCRIMINANT|NEBOC_NOM_FLAG_CONSTRUCTED
 and rax,rdx
 cmp rax,rdx
 jne .no
 mov rdx,[r14+NEBOC_NOM_RESULT_OFFSET]
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.nominal_unwrap:
 cmp qword [r14+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_NEWTYPE
 jne .no
 test qword [r14+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_UNWRAP
 jz .no
 mov rdx,[r14+NEBOC_NOM_RESULT_OFFSET]
 mov rax,[r14+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 cmp rax,NEBOC_NOM_TYPE_INT
 je .nominal_type_int
 cmp rax,NEBOC_NOM_TYPE_BOOL
 je .nominal_type_bool
 cmp rax,NEBOC_NOM_TYPE_CHAR
 je .nominal_type_char
 cmp rax,NEBOC_NOM_TYPE_FLOAT
 je .nominal_type_float
 cmp rax,NEBOC_NOM_TYPE_TEXT
 je .nominal_type_text
 jmp .no
.nominal_type_int:
 mov ecx,NEBOC_TYPE_ID_INT
 jmp .nominal_value_yes
.nominal_type_bool:
 mov ecx,NEBOC_TYPE_ID_BOOL
 jmp .nominal_value_yes
.nominal_type_char:
 mov ecx,NEBOC_TYPE_ID_CHAR
 jmp .nominal_value_yes
.nominal_type_float:
 mov ecx,NEBOC_TYPE_ID_FLOAT
 jmp .nominal_value_yes
.nominal_type_text:
 mov ecx,NEBOC_TYPE_ID_TEXT
.nominal_value_yes:
 mov eax,1
 jmp .done
.nominal_sizeof:
 test qword [r14+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_SIZEOF
 jz .no
 mov rdx,[r14+NEBOC_NOM_RESULT_OFFSET]
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.next_owner:
 add r14,NEBOC_NOM_REQUEST_SIZE
 dec r15
 jmp .owner_loop
.no:
 xor eax,eax
 xor ecx,ecx
 xor edx,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node -> RAX exact authenticated nominal owner request or zero.  The
; lookup binds the node's first source token to the preserved declaration-name
; token, not to a post-semantic TypeKey whose domain differs by nominal kind.
fcg_nominal_owner_for_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_START_OFFSET]
 xor r14d,r14d
.find_token:
 cmp r14,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_token_ptr
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_START_OFFSET],r13
 je .hash_token
 inc r14
 jmp .find_token
.hash_token:
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r13,14695981039346656037
 mov r14,1099511628211
 xor r15d,r15d
.node_hash_loop:
 cmp r15,rcx
 jae .owner_begin
 movzx eax,byte [rsi+r15]
 xor r13,rax
 imul r13,r14
 inc r15
 jmp .node_hash_loop
.owner_begin:
 test r13,r13
 jnz .node_hash_ready
 mov r13,1
.node_hash_ready:
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNERS_OFFSET]
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_NOMINAL_OWNER_COUNT_OFFSET]
.owner_loop:
 test r15,r15
 jz .no
 mov rax,[r14+NEBOC_NOM_KIND_OFFSET]
 mov r8,1
 cmp rax,NEBOC_NOM_KIND_ALIAS
 jne .owner_index_ready
 mov r8,2
.owner_index_ready:
 cmp r8,[r14+NEBOC_NOM_TOKEN_COUNT_OFFSET]
 jae .next_owner
 imul rax,r8,NEBOC_TOKEN_SIZE
 add rax,[r14+NEBOC_NOM_TOKENS_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[r14+NEBOC_NOM_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r10,14695981039346656037
 mov r9,1099511628211
 xor edx,edx
.owner_hash_loop:
 cmp rdx,rcx
 jae .owner_hash_done
 movzx eax,byte [rsi+rdx]
 xor r10,rax
 imul r10,r9
 inc rdx
 jmp .owner_hash_loop
.owner_hash_done:
 test r10,r10
 jnz .owner_hash_ready
 mov r10,1
.owner_hash_ready:
 cmp r10,r13
 je .yes
.next_owner:
 add r14,NEBOC_NOM_REQUEST_SIZE
 dec r15
 jmp .owner_loop
.yes:
 mov rax,r14
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX 1 only for an enum variant constructor already
; authenticated by the corresponding nominal owner.  It is an internal child
; of the enclosing nominal operation and must not consume a user-call ABI slot.
fcg_nominal_constructor_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_nominal_owner_for_node
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_NOM_FOUND_OFFSET],1
 jne .no
 cmp qword [r13+NEBOC_NOM_DIAGNOSTIC_OFFSET],0
 jne .no
 cmp qword [r13+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 jne .no
 test qword [r13+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_CONSTRUCTED
 jz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r12,14695981039346656037
 mov r15,1099511628211
 xor edx,edx
.variant_hash_loop:
 cmp rdx,rcx
 jae .variant_hash_done
 movzx eax,byte [rsi+rdx]
 xor r12,rax
 imul r12,r15
 inc rdx
 jmp .variant_hash_loop
.variant_hash_done:
 mov r15,[r13+NEBOC_NOM_VARIANT_COUNT_OFFSET]
 mov r13,[r13+NEBOC_NOM_VARIANTS_OFFSET]
.variant_loop:
 test r15,r15
 jz .no
 cmp [r13+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET],r12
 jne .next_variant
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp qword [r13+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET],NEBOC_NOM_TYPE_NONE
 jne .payload_variant
 test rax,rax
 jnz .no
 mov eax,1
 jmp .done
.payload_variant:
 cmp rax,1
 jne .no
 mov eax,1
 jmp .done
.next_variant:
 add r13,NEBOC_NOM_VARIANT_SIZE
 dec r15
 jmp .variant_loop
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression node, depth -> RAX exact textual TypeId or zero.
; Binding recursion walks only a prior lexical initializer and therefore
; cannot create an ownership cycle.
fcg_textual_expr_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .wrapper
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .ordinary_call
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .no
 mov [rsp],rax
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_textual_expr_type
 cmp rax,[rsp]
 jne .no
 mov rax,[rsp]
 jmp .done
.ordinary_call:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_textual_expr_type
 test eax,eax
 jz .no
 mov [rsp],rax
 cmp rax,NEBOC_TYPE_ID_BYTES
 je .bytes_call
 cmp rax,NEBOC_TYPE_ID_INT
 je .int_call
 cmp rax,NEBOC_TYPE_ID_CHAR
 je .char_call
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .text_call
 cmp rax,FCG_TEXTUAL_OPTION_INT
 je .option_call
 jmp .no
.bytes_call:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_empty]
 mov ecx,fcg_name_bytes_empty_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bytes
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_from_byte]
 mov ecx,fcg_name_bytes_from_byte_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bytes
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_from_values]
 mov ecx,fcg_name_bytes_from_values_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bytes
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_slice]
 mov ecx,fcg_name_bytes_slice_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bytes
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_collection_at]
 mov ecx,fcg_name_collection_at_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_get]
 mov ecx,fcg_name_bytes_get_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .option_int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_byte_length]
 mov ecx,fcg_name_byte_length_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 jmp .no
.int_call:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_test_bit]
 mov ecx,fcg_name_test_bit_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bool
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_and]
 mov ecx,fcg_name_bit_and_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_or]
 mov ecx,fcg_name_bit_or_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_xor]
 mov ecx,fcg_name_bit_xor_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bit_not]
 mov ecx,fcg_name_bit_not_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_shift_left]
 mov ecx,fcg_name_shift_left_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_shift_right]
 mov ecx,fcg_name_shift_right_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_with_bit]
 mov ecx,fcg_name_with_bit_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 jmp .no
.char_call:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_codepoint]
 mov ecx,fcg_name_codepoint_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 jmp .no
.text_call:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_byte_length]
 mov ecx,fcg_name_byte_length_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_codepoint_count]
 mov ecx,fcg_name_codepoint_count_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 jmp .no
.option_call:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_is_some]
 mov ecx,fcg_name_is_some_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bool
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_is_none]
 mov ecx,fcg_name_is_none_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bool
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_unwrap_or]
 mov ecx,fcg_name_unwrap_or_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 jmp .no
.wrapper:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_textual_expr_type
 jmp .done
.identifier:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel fcg_name_bytes_type]
 mov ecx,fcg_name_bytes_type_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .bytes
 mov rdi,rbx
 mov rsi,r15
 call fcg_resolve_identifier
 test rax,rax
 jz .identifier_prior
 cmp rdx,NEBOC_TYPE_ID_INT
 je .identifier_resolved_type
 cmp rdx,NEBOC_TYPE_ID_BOOL
 je .identifier_resolved_type
 cmp rdx,NEBOC_TYPE_ID_CHAR
 je .identifier_resolved_type
 cmp rdx,NEBOC_TYPE_ID_TEXT
 je .identifier_resolved_type
 cmp rdx,NEBOC_TYPE_ID_BYTES
 jne .identifier_prior
.identifier_resolved_type:
 mov rax,rdx
 jmp .done
.identifier_prior:
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test rdx,rdx
 jz .no
 mov rdi,rbx
 mov rsi,r15
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_textual_expr_type
 jmp .done
.int:
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.bool:
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.char:
 mov eax,NEBOC_TYPE_ID_CHAR
 jmp .done
.text:
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.bytes:
 mov eax,NEBOC_TYPE_ID_BYTES
 jmp .done
.option_int:
 mov eax,FCG_TEXTUAL_OPTION_INT
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, canonical console call node id, depth -> status.  Function context
; changes only expression/slot lowering; the generated program converges on
; the same public runtime operations used by top-level Console codegen.
fcg_emit_console_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unsupported
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 ; Text(...) is the only currently public Console type-constructor receiver.
 ; Do not publish Int(...), Bool(...), Char(...), or call-result composition.
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .infer_receiver
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .unsupported
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .unsupported
.infer_receiver:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .receiver_ready
 cmp rax,NEBOC_TYPE_ID_INT
 je .receiver_ready
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .unsupported
.receiver_ready:
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 cmp qword [rsp],NEBOC_TYPE_ID_TEXT
 je .emit_text
 cmp qword [rsp],NEBOC_TYPE_ID_INT
 je .emit_int
 lea rsi,[rel fcg_console_publish_bool]
 mov edx,fcg_console_publish_bool_len
 jmp .append
.emit_text:
 lea rsi,[rel fcg_console_publish_text]
 mov edx,fcg_console_publish_text_len
 jmp .append
.emit_int:
 lea rsi,[rel fcg_console_publish_int]
 mov edx,fcg_console_publish_int_len
.append:
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, canonical scan call node id, depth -> status.  The receiver is
; either Text (headless path) or the already-public Console result (live
; path).  Both converge on the same runtime entry points as top-level Scan.
fcg_emit_scan_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unsupported
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_console_call
 test eax,eax
 jnz .console_receiver
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .unsupported
 mov qword [rsp],1
 jmp .receiver_ready
.console_receiver:
 mov qword [rsp],2
.receiver_ready:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_scan_ids
 test eax,eax
 jnz .done
 mov rdi,rbx
 cmp qword [rsp],1
 jne .emit_console
 lea rsi,[rel fcg_scan_stdin]
 mov edx,fcg_scan_stdin_len
 call fcg_append
 jmp .done
.emit_console:
 lea rsi,[rel fcg_scan_console_handle]
 mov edx,fcg_scan_console_handle_len
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, zero-option Text count call, depth, emitted-call*, emitted-call-len.
; This bounded composition is needed only so a function-local scanned Text
; can use the already-public byteLength/codepointCount operations.
fcg_emit_text_count_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rsp],rcx
 mov [rsp+8],r8
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unsupported
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_scan_result_reference
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .unsupported
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,[rsp+8]
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, stable AST call id -> status.  A call-site-local invocation counter
; is combined with the deterministic node id.  This keeps identifiers stable
; in generated Assembly while giving each sequential invocation a fresh
; runtime registry identity (the live registries intentionally retain resolved
; records for lifecycle evidence).
fcg_emit_scan_ids:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad
 sub rsp,8
 mov rdi,r12
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],1
 ja .decl_local
 lea rsi,[rel fcg_scan_sequence_decl]
 mov edx,fcg_scan_sequence_decl_len
 jmp .decl_append
.decl_local:
 lea rsi,[rel fcg_scan_sequence_decl_local]
 mov edx,fcg_scan_sequence_decl_local_len
.decl_append:
 call fcg_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],1
 ja .decl_tail_local
 lea rsi,[rel fcg_scan_sequence_decl_tail]
 mov edx,fcg_scan_sequence_decl_tail_len
 jmp .decl_tail_append
.decl_tail_local:
 lea rsi,[rel fcg_scan_sequence_decl_tail_local]
 mov edx,fcg_scan_sequence_decl_tail_local_len
.decl_tail_append:
 call fcg_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 lea rsi,[rel fcg_scan_sequence_load]
 mov edx,fcg_scan_sequence_load_len
 call fcg_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],1
 ja .tail_local
 lea rsi,[rel fcg_scan_sequence_tail]
 mov edx,fcg_scan_sequence_tail_len
 jmp .tail_append
.tail_local:
 lea rsi,[rel fcg_scan_sequence_tail_local]
 mov edx,fcg_scan_sequence_tail_local_len
.tail_append:
 call fcg_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 lea rsi,[rel fcg_scan_sequence_finish]
 mov edx,fcg_scan_sequence_finish_len
 call fcg_append
.emit_done:
 add rsp,8
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX exact syntactic CallExpr count or -1.  Unlike
; ABI runtime-call accounting, this deliberately includes intrinsics: the B01
; recursive surface admits exactly one call node of any class.
fcg_count_syntactic_calls:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp],rax
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 xor r15d,r15d
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 inc r15
.children:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .ok
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_count_syntactic_calls
 cmp rax,-1
 je .bad
 add r15,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.ok:
 mov rax,r15
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, exact branch block -> RAX sole direct return expression or zero.
fcg_recursion_single_return_expr:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rax,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .no
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, exact self-call node, current symbol -> EAX 1 only for the selected
; top-level Int/0-parameter/Int-return, one-if/else, one-tail-call surface.
fcg_validate_selected_self_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rsp],r12
 mov [rsp+8],r13
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET]
 test r14,r14
 jz .selected_available
 cmp r14,r13
 jne .shape
.selected_available:
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 test r14,r14
 jz .shape
 mov [rsp+16],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .surface
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .surface
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .shape
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .surface
 mov [rsp+24],rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .surface
 mov rax,[rsp+24]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .shape
 mov [rsp+32],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .shape
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .shape
 mov [rsp+40],r14
 mov rdi,rbx
 mov rsi,[rsp+32]
 call fcg_recursion_block_has_collection_record
 test eax,eax
 jnz .shape
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .shape
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .shape
 mov [rsp+48],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .shape
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .shape
 mov [rsp+56],r15
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .shape
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .shape
 mov [rsp+64],r15
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .shape
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .shape
 mov rdi,rbx
 mov rsi,[rsp+48]
 xor edx,edx
 call fcg_count_syntactic_calls
 test rax,rax
 jne .shape
 mov rdi,rbx
 mov rsi,[rsp+48]
 xor edx,edx
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .surface
 mov rdi,rbx
 mov rsi,[rsp+56]
 call fcg_recursion_single_return_expr
 test rax,rax
 jz .shape
 mov [rsp+72],rax
 mov rdi,rbx
 mov rsi,[rsp+64]
 call fcg_recursion_single_return_expr
 test rax,rax
 jz .shape
 mov [rsp+80],rax
 mov rdi,rbx
 mov rsi,[rsp+72]
 xor edx,edx
 call fcg_count_syntactic_calls
 cmp rax,-1
 je .shape
 mov [rsp+88],rax
 mov rdi,rbx
 mov rsi,[rsp+80]
 xor edx,edx
 call fcg_count_syntactic_calls
 cmp rax,-1
 je .shape
 mov [rsp+96],rax
 mov rdx,[rsp+88]
 add rdx,rax
 cmp rdx,1
 jne .shape
 cmp qword [rsp+88],1
 je .then_recursive
 cmp qword [rsp+88],0
 jne .shape
 cmp qword [rsp+96],1
 jne .shape
 mov rax,[rsp+80]
 mov [rsp+104],rax
 mov rax,[rsp+72]
 mov [rsp+112],rax
 jmp .tail
.then_recursive:
 cmp qword [rsp+96],0
 jne .shape
 mov rax,[rsp+72]
 mov [rsp+104],rax
 mov rax,[rsp+80]
 mov [rsp+112],rax
.tail:
 mov rax,[rsp+104]
 cmp rax,[rsp]
 jne .nontail
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .shape
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .nontail
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .shape
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .surface
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .surface
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .shape
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 call fcg_count_syntactic_calls
 test rax,rax
 jne .nontail
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .surface
 mov rdi,rbx
 mov rsi,[rsp+112]
 xor edx,edx
 call fcg_count_syntactic_calls
 test rax,rax
 jne .shape
 mov rdi,rbx
 mov rsi,[rsp+112]
 xor edx,edx
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .surface
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET]
 test rax,rax
 jnz .selected
 mov rax,[rsp+8]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_DECL_OFFSET],rax
.selected:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 mov eax,1
 jmp .done
.surface:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_SURFACE
 jmp .reject
.shape:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_SHAPE
 jmp .reject
.nontail:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_NONTAIL
.reject:
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_capture_node_span
 xor eax,eax
.done:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, selected symbol, call node, recursion kind -> status.  The receiver is
; already in RDI.  Root and self edges alone receive the private outgoing
; block; accounting remains identical to one adapter-owned prepared call.
fcg_emit_selected_recursive_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rax,[rdx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 mov [rsp+8],rax
 mov rax,[rdx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov [rsp+16],rax
 mov rax,[rdx+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 test rax,rax
 jz .abi
 mov rcx,[rdx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rcx,[rax+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jae .abi
 cmp r14,NEBOC_FUNCTION_RECURSION_CALL_ROOT
 je .root
 cmp r14,NEBOC_FUNCTION_RECURSION_CALL_SELF
 jne .abi
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_self_guard_prefix]
 mov edx,fcg_recursion_self_guard_prefix_len
 call fcg_append
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_restore
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_self_guard_success]
 mov edx,fcg_recursion_self_guard_success_len
 call fcg_append
 test eax,eax
 jnz .restore
 jmp .call
.root:
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_root_prefix]
 mov edx,fcg_recursion_root_prefix_len
 call fcg_append
 test eax,eax
 jnz .restore
.call:
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_call_prefix]
 mov edx,fcg_recursion_call_prefix_len
 call fcg_append
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_restore
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_call_restore]
 mov edx,fcg_recursion_call_restore_len
 call fcg_append
 test eax,eax
 jnz .restore
 cmp r14,NEBOC_FUNCTION_RECURSION_CALL_SELF
 jne .commit
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_self_jump_done]
 mov edx,fcg_recursion_self_jump_done_len
 call fcg_append
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_restore
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_self_failure_prefix]
 mov edx,fcg_recursion_self_failure_prefix_len
 call fcg_append
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_restore
 mov rdi,rbx
 lea rsi,[rel fcg_recursion_self_failure_body]
 mov edx,fcg_recursion_self_failure_body_len
 call fcg_append
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_restore
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .restore
.commit:
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 inc qword [rdx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET]
 inc qword [rdx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 mov qword [rdx+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_NONE
 xor eax,eax
 jmp .done
.writer_restore:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.restore:
 mov r11d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rax,[rsp+8]
 mov [rdx+NEBOC_ABI_ADAPTER_EMITTED_CALLS_OFFSET],rax
 mov rax,[rsp+16]
 mov [rdx+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET],rax
 mov eax,r11d
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_node_id -> RAX symbol id, RDX return TypeId, zero on failure.
fcg_resolve_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov rbx,rdi
 mov r12,rsi
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_RECURSION_KIND_OFFSET],NEBOC_FUNCTION_RECURSION_CALL_ORDINARY
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_NESTED_OWNER_ID_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad_ast
 mov r14,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS-1
 ja .parameter
 mov rax,r14
 inc rax
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad_ast
 mov r15,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad_ast
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .failed
 mov [rsp],rax              ; receiver type
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 xor ecx,ecx
.arg_types:
 cmp rcx,r14
 jae .search
 test r15,r15
 jz .bad_ast
 mov [rsp+120],rcx
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .failed
 mov rcx,[rsp+120]
 mov [rsp+8+rcx*8],rax
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rsp+120]
 inc rcx
 jmp .arg_types
.search:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rsp]
 mov rcx,r14
 call fcg_resolve_nested_call
 test rax,rax
 jnz .nested_success
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET]
 cmp rdx,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CALL_BEFORE
 je .nested_pending
 cmp rdx,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 je .nested_pending
 mov qword [rsp+56],0       ; matched symbol
 mov qword [rsp+64],0       ; matched return type
 mov qword [rsp+72],0       ; candidate count
 mov qword [rsp+120],NEBOC_FUNCTION_RECURSION_CALL_ORDINARY
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+80],2
.candidate_loop:
 test r15,r15
 jz .search_done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov [rsp+88],rax
 mov rdx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+96],rdx
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .candidate_next
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .candidate_advance
 mov rax,[rsp+88]
 cmp r14,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jne .candidate_advance
 mov rdx,r14
 add rdx,2
 cmp rdx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .bad_ast
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,[rsp]
 jne .candidate_advance
 mov r11,[rsp+88]
 mov rsi,[r11+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+112],0
 xor ecx,ecx
.param_compare:
 cmp rcx,r14
 jae .candidate_match
 test rsi,rsi
 jz .bad_ast
 mov [rsp+104],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PARAMETER
 jne .candidate_advance
 mov rdi,rbx
 mov rsi,[rsp+104]
 call fcg_decl_type_from_node
 mov rcx,[rsp+112]
 cmp rax,[rsp+8+rcx*8]
 je .param_type_match
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_INT
 jb .check_actual_slice_mismatch
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 jbe .slice_type_mismatch
.check_actual_slice_mismatch:
 mov rdx,[rsp+8+rcx*8]
 cmp rdx,NEBOC_FUNCTION_TYPE_SLICE_INT
 jb .candidate_advance
 cmp rdx,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 ja .candidate_advance
.slice_type_mismatch:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_SLICE_ELEMENT_MISMATCH
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 jmp .failed
.param_type_match:
 mov rsi,[rsp+104]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+112]
 mov rcx,[rsp+112]
 jmp .param_compare
.candidate_match:
 inc qword [rsp+72]
 cmp qword [rsp+72],1
 jne .undefined
 mov rax,[rsp+80]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 cmp rax,rdx
 je .candidate_self
 cmp rdx,1
 je .candidate_type
 cmp rax,rdx
 ja .forward
.candidate_type:
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rsp+80]
 call fcg_function_return_type
 test rax,rax
 jz .failed
 mov [rsp+64],rax
 jmp .candidate_advance
.candidate_self:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rsp+80]
 call fcg_validate_selected_self_call
 test eax,eax
 jz .failed
 mov rax,[rsp+80]
 mov [rsp+56],rax
 mov qword [rsp+64],NEBOC_TYPE_ID_INT
 mov qword [rsp+120],NEBOC_FUNCTION_RECURSION_CALL_SELF
.candidate_advance:
 inc qword [rsp+80]
.candidate_next:
 mov r15,[rsp+96]
 mov qword [rsp+112],0
 jmp .candidate_loop
.search_done:
 cmp qword [rsp+72],1
 jne .undefined
 mov rax,[rsp+56]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 cmp rax,rdx
 je .success
 cmp rdx,1
 je .success
 cmp rax,rdx
 ja .forward
.success:
 cmp qword [rsp+120],NEBOC_FUNCTION_RECURSION_CALL_SELF
 je .success_type
 mov rcx,[rbx+NEBOC_FUNCTION_CODEGEN_SELECTED_RECURSIVE_SYMBOL_OFFSET]
 cmp rax,rcx
 jne .success_type
 mov qword [rsp+120],NEBOC_FUNCTION_RECURSION_CALL_ROOT
.success_type:
 ; Return-type analysis is re-entrant and may inspect a private call inside
 ; the public callee.  That transient owner must never relabel this call site.
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_NESTED_OWNER_ID_OFFSET],0
 mov rcx,[rsp+120]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_RECURSION_KIND_OFFSET],rcx
 mov rdx,[rsp+64]
 jmp .done
.nested_success:
 mov edx,NEBOC_TYPE_ID_INT
 jmp .done
.nested_pending:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 xor eax,eax
 xor edx,edx
 jmp .done
.forward:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_FORWARD_CALL
 xor eax,eax
 xor edx,edx
 jmp .done
.undefined:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET]
 test rax,rax
 jz .undefined_public
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 xor eax,eax
 xor edx,edx
 jmp .done
.undefined_public:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNDEFINED_CALL
 xor eax,eax
 xor edx,edx
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 xor eax,eax
 xor edx,edx
 jmp .done
.bad_ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, root block id. Reset the bounded lexical function-scope stack.
fcg_scope_reset:
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],1
 mov [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET],rsi
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET],0
 mov [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rsi
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 xor eax,eax
 ret

; state*, child block id, exact parent statement id -> status.
fcg_scope_push:
 mov rax,[rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_SCOPE_DEPTH
 jae .limit
 mov [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+rax*8],rsi
 mov [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+rax*8],rdx
 inc rax
 mov [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],rax
 mov [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rsi
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 xor eax,eax
 ret
.limit:
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

; state* -> status. Restore the exact parent visibility boundary.
fcg_scope_pop:
 mov rax,[rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
 cmp rax,1
 jbe .bad
 dec rax
 mov [rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],rax
 mov rdx,[rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+rax*8]
 mov [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rdx
 dec rax
 mov rdx,[rdi+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+rax*8]
 mov [rdi+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rdx
 xor eax,eax
 ret
.bad:
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; state*, identifier_token_index -> RAX one-based local slot, RDX TypeId.
fcg_resolve_identifier:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 test r13,r13
 jz .bindings
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bindings
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .bindings
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15,1
.parameter_loop:
 test r14,r14
 jz .bindings
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bindings
 mov [rsp],rax
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BLOCK
 je .bindings
 cmp rcx,NEBOC_AST_RECEIVER
 je .candidate
 cmp rcx,NEBOC_AST_PARAMETER
 jne .bindings
.candidate:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .parameter_found
 mov rax,[rsp]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .parameter_loop
.parameter_found:
 mov rdi,rbx
 mov rsi,r14
 call fcg_decl_type_from_node
 test rax,rax
 jz .bindings
 mov rdx,rax
 mov rax,r15
 jmp .done
.bindings:
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test rdx,rdx
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_prior_binding
 test rax,rax
 jz .iterators
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,ecx
 mov rdx,rcx
 shr rdx,32
 test rax,rax
 jz .no
 test rdx,rdx
 jz .no
 jmp .done
.iterators:
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_active_iterator
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, identifier token -> RAX iterator slot, RDX TypeId.  The lexical
; scope-parent stack is the authority: after the loop scope is popped no
; RangeFor parent remains visible, and sibling loops cannot capture it.
fcg_resolve_active_iterator:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
.scope:
 cmp r13,1
 jbe .no
 dec r13
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+r13*8]
 test r14,r14
 jz .scope
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .scope
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 jne .scope
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,edx
 test eax,eax
 jz .scope
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .scope
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .scope
 mov rdi,rbx
 mov rsi,r14
 ; recover the owning RangeFor through the current scope parent
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+r13*8]
 call fcg_collection_record_for_node
 test rax,rax
 jz .no
 mov rax,[rsp]
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth, allow_direct_bindings -> RAX path-set, RDX return
; TypeId.  Zero is structural/type failure.  The path-set retains both facts
; for a partial return until a later statement closes every fallthrough path.
fcg_analyze_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp+40],rax
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],NEBOC_FUNCTION_EXIT_FALLTHROUGH
 mov qword [rsp+8],0
.loop:
 test r15,r15
 jz .finish
 test qword [rsp],NEBOC_FUNCTION_EXIT_FALLTHROUGH
 jz .unreachable
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r15
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rcx
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_EXPRESSION_STMT
 je .fallthrough_statement
 cmp rcx,NEBOC_AST_BINDING_STMT
 je .binding_statement
 cmp rcx,NEBOC_AST_ASSIGNMENT_STMT
 je .fallthrough_statement
 cmp rcx,NEBOC_AST_IF_STMT
 je .if_statement
 cmp rcx,NEBOC_AST_WHILE_STMT
 je .loop_statement
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .loop_statement
 cmp rcx,NEBOC_AST_RANGE_FOR_STMT
 je .collection_loop_statement
 cmp rcx,NEBOC_AST_BREAK_STMT
 je .break_statement
 cmp rcx,NEBOC_AST_CONTINUE_STMT
 je .continue_statement
 cmp rcx,NEBOC_AST_RETURN_STMT
 je .return_statement
 cmp rcx,NEBOC_AST_FUNCTION_DECL
 jne .unsupported
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jz .unsupported
 mov eax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 xor edx,edx
 jmp .merge_sequence
.fallthrough_statement:
 mov eax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 xor edx,edx
 jmp .merge_sequence
.binding_statement:
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_collection_binding
 test eax,eax
 jnz .fallthrough_statement
 test r14,r14
 jz .binding_scope
 mov eax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 xor edx,edx
 jmp .merge_sequence
.if_statement:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_analyze_if
 test rax,rax
 jz .failed
 jmp .merge_sequence
.loop_statement:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_analyze_loop
 test rax,rax
 jz .failed
 jmp .merge_sequence
.collection_loop_statement:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_analyze_collection_loop
 test rax,rax
 jz .failed
 jmp .merge_sequence
.break_statement:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET],0
 je .control
 mov eax,NEBOC_FUNCTION_EXIT_BREAK
 xor edx,edx
 jmp .merge_sequence
.continue_statement:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET],0
 je .control
 mov eax,NEBOC_FUNCTION_EXIT_CONTINUE
 xor edx,edx
 jmp .merge_sequence
.return_statement:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .type
 mov rdx,rax
 mov eax,NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
.merge_sequence:
 mov [rsp+24],rax
 mov [rsp+32],rdx
 test qword [rsp],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jz .take_statement_type
 test qword [rsp+24],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jz .merge_mask
 mov rax,[rsp+8]
 cmp rax,[rsp+32]
 jne .inconsistent
 jmp .merge_mask
.take_statement_type:
 test qword [rsp+24],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jz .merge_mask
 mov rax,[rsp+32]
 mov [rsp+8],rax
.merge_mask:
 mov rax,[rsp]
 and rax,~NEBOC_FUNCTION_EXIT_FALLTHROUGH
 or rax,[rsp+24]
 mov [rsp],rax
 mov r15,[rsp+16]
 jmp .loop
.finish:
 mov rax,[rsp]
 mov rdx,[rsp+8]
 jmp .restore
.unreachable:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_MULTIPLE_RETURN
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.inconsistent:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_INCONSISTENT_RETURN
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.binding_scope:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.type:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .failed
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_TYPE
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 jmp .failed
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.restore:
 mov rcx,[rsp+40]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rcx
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, loop_node_id, depth -> RAX path-set, RDX return TypeId. While always
; retains the condition-false fallthrough path. A canonical loop is terminal
; only when its complete body path-set is already a scalar return; otherwise
; analysis stays conservative and admits loop exit/fallthrough.
fcg_analyze_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 cmp r14,NEBOC_AST_LOOP_STMT
 je .have_body
 cmp r14,NEBOC_AST_WHILE_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .control
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .bad
.have_body:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_LOOP_DEPTH
 jae .depth
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_analyze_scoped_block
 mov [rsp],rax
 mov [rsp+8],rdx
 dec qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 test qword [rsp],-1
 jz .failed
 mov rcx,[rsp]
 and qword [rsp],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 cmp r14,NEBOC_AST_WHILE_STMT
 je .falls
 test rcx,NEBOC_FUNCTION_EXIT_BREAK
 jnz .falls
 test qword [rsp],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jnz .result
.falls:
 or qword [rsp],NEBOC_FUNCTION_EXIT_FALLTHROUGH
.result:
 mov rax,[rsp]
 mov rdx,[rsp+8]
 jmp .done
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov rdi,rbx
 mov rsi,r15
 call fcg_capture_node_span
 jmp .failed
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 jmp .failed
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, RangeFor node id, depth -> path-set/type.  Material collections may
; be empty, therefore fallthrough always remains reachable; scalar returns in
; the body are retained for exact type merging by the surrounding block.
fcg_analyze_collection_loop:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_record_for_node
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_analyze_scoped_block
 mov [rsp],rax
 mov [rsp+8],rdx
 dec qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 test qword [rsp],-1
 jz .failed
 mov rax,[rsp]
 and rax,NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 or rax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 mov rdx,[rsp+8]
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 jmp .failed
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, if_node_id, depth -> RAX merged path-set, RDX return TypeId.
; Scoped block analysis preserves the lexical resolver state while returning
; the original two-register exit-flow result.
fcg_analyze_scoped_block:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 call fcg_scope_push
 test eax,eax
 jnz .failed
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 mov ecx,1
 call fcg_analyze_block
 mov [rsp],rax
 mov [rsp+8],rdx
 mov rdi,rbx
 call fcg_scope_pop
 test qword [rsp],-1
 jz .failed
 test eax,eax
 jnz .failed
 mov rax,[rsp]
 mov rdx,[rsp+8]
 jmp .done
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_analyze_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov [rsp],r15
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .control
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 mov [rsp+8],r14
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_analyze_scoped_block
 test rax,rax
 jz .failed
 mov [rsp+24],rax
 mov [rsp+32],rdx
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],r14
 test r14,r14
 jz .implicit_else
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_analyze_if
 jmp .else_done
.else_block:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_analyze_scoped_block
 jmp .else_done
.implicit_else:
 mov eax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 xor edx,edx
.else_done:
 test rax,rax
 jz .failed
 mov [rsp+40],rax
 mov [rsp+48],rdx
 test qword [rsp+24],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jz .use_else_type
 test qword [rsp+40],NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jz .use_then_type
 mov rax,[rsp+32]
 cmp rax,[rsp+48]
 jne .inconsistent
.use_then_type:
 mov rdx,[rsp+32]
 jmp .merge
.use_else_type:
 mov rdx,[rsp+48]
.merge:
 mov rax,[rsp+24]
 or rax,[rsp+40]
 jmp .done
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_capture_node_span
 jmp .failed
.inconsistent:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_INCONSISTENT_RETURN
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 jmp .failed
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 jmp .failed
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Array semantic record -> exact compiler-internal Array<T,N> TypeId or zero.
fcg_array_type_from_record:
 cmp qword [rdi+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .no
 mov rax,[rdi+NEBOC_AR_BIND_COUNT_OFFSET]
 cmp rax,NEBOC_AR_MAX_LENGTH
 ja .no
 mov rdx,[rdi+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rdx,NEBOC_AR_TYPE_INT
 jb .no
 cmp rdx,NEBOC_AR_TYPE_CHAR
 ja .no
 shl rdx,NEBOC_FUNCTION_TYPE_ARRAY_ELEMENT_SHIFT
 or rax,rdx
 or rax,NEBOC_FUNCTION_TYPE_ARRAY_BASE
 ret
.no:
 xor eax,eax
 ret

; TypeId -> EAX valid, RDX element type, RCX exact length.  The encoding is
; accepted only when a canonical re-encode is byte-exact, preventing another
; internal TypeId from being mistaken for an Array.
fcg_array_type_decode:
 mov rax,rdi
 and rax,NEBOC_FUNCTION_TYPE_ARRAY_LENGTH_MASK
 mov rcx,rax
 cmp rcx,NEBOC_AR_MAX_LENGTH
 ja .no
 mov rax,rdi
 shr rax,NEBOC_FUNCTION_TYPE_ARRAY_ELEMENT_SHIFT
 and rax,NEBOC_FUNCTION_TYPE_ARRAY_ELEMENT_MASK
 mov rdx,rax
 cmp rdx,NEBOC_AR_TYPE_INT
 jb .no
 cmp rdx,NEBOC_AR_TYPE_CHAR
 ja .no
 mov rax,rdx
 shl rax,NEBOC_FUNCTION_TYPE_ARRAY_ELEMENT_SHIFT
 or rax,rcx
 or rax,NEBOC_FUNCTION_TYPE_ARRAY_BASE
 cmp rax,rdi
 jne .no
 mov eax,1
 ret
.no:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 ret

; TypeId -> EAX valid, RDX exact Slice element identity.
fcg_slice_type_decode:
 cmp rdi,NEBOC_FUNCTION_TYPE_SLICE_INT
 je .int
 cmp rdi,NEBOC_FUNCTION_TYPE_SLICE_BOOL
 je .bool
 cmp rdi,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 jne .no
 mov edx,NEBOC_AR_TYPE_CHAR
 mov eax,1
 ret
.int:
 mov edx,NEBOC_AR_TYPE_INT
 mov eax,1
 ret
.bool:
 mov edx,NEBOC_AR_TYPE_BOOL
 mov eax,1
 ret
.no:
 xor eax,eax
 xor edx,edx
 ret

; state*, function_decl_id, symbol_id -> RAX inferred Void/scalar/Array TypeId or
; zero.  Missing-return is exactly the mixed path-set at function end.
fcg_function_return_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 ; Return-type analysis may be re-entered while resolving a call from start()
 ; or from a nested caller scope.  Keep the caller's complete lexical stack:
 ; branch/loop analysis below must use a fresh root for the callee and must not
 ; leave that root (or any pushed child) in the caller after it returns.
 sub rsp,1088
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 mov [rsp+24],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 mov [rsp+32],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp+40],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
 mov [rsp+16],rax
 xor r14d,r14d
.save_scope:
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_SCOPE_DEPTH
 jae .scope_saved
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+r14*8]
 mov [rsp+48+r14*8],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+r14*8]
 mov [rsp+560+r14*8],rax
 inc r14
 jmp .save_scope
.scope_saved:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET],0
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],r13
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,rax
 call fcg_scope_reset
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 xor edx,edx
 mov ecx,1
 call fcg_analyze_block
 test rax,rax
 jz .failed
 cmp rax,NEBOC_FUNCTION_EXIT_FALLTHROUGH
 je .void
 cmp rax,NEBOC_FUNCTION_EXIT_RETURNS_SCALAR
 jne .missing
 test rdx,rdx
 jz .bad
 mov r15,rdx
 cmp rdx,NEBOC_TYPE_ID_INT
 je .scalar_return
 cmp rdx,NEBOC_TYPE_ID_BOOL
 je .scalar_return
 cmp rdx,NEBOC_TYPE_ID_CHAR
 je .scalar_return
 mov rdi,rdx
 call fcg_array_type_decode
 test eax,eax
 jnz .scalar_return
 mov rdi,r15
 call fcg_slice_type_decode
 test eax,eax
 jnz .scalar_return
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_TYPE
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 jmp .failed
.scalar_return:
 mov rax,r15
 jmp .restore
.void:
 mov eax,NEBOC_TYPE_ID_VOID
 jmp .restore
.missing:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_MISSING_RETURN
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 jmp .failed
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
.restore:
 mov r15,rax
 xor r14d,r14d
.restore_scope:
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_SCOPE_DEPTH
 jae .scope_restored
 mov rax,[rsp+48+r14*8]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+r14*8],rax
 mov rax,[rsp+560+r14*8]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+r14*8],rax
 inc r14
 jmp .restore_scope
.scope_restored:
 mov rdx,[rsp+16]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET],rdx
 mov rdx,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],rdx
 mov rdx,[rsp+32]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rdx
 mov rdx,[rsp+40]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rdx
 mov rdx,[rsp+8]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET],rdx
 mov rax,r15
 add rsp,1088
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX TypeId or zero.
fcg_infer_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .terminal
 jmp .bad
.int:
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.bool:
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.char:
 mov eax,NEBOC_TYPE_ID_CHAR
 jmp .done
.text:
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.identifier:
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .identifier_no_collection
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .identifier_collection_found
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jnz .identifier_resolved
 mov rax,[rsp]
 jmp .identifier_collection_found
.identifier_no_collection:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jnz .identifier_resolved
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_direct_array_binding_for_node
 test rax,rax
 jz .identifier_unresolved
.identifier_collection_found:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .identifier_array
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .identifier_unresolved
 mov rdx,[rax+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rdx,NEBOC_AR_TYPE_INT
 je .identifier_slice_int
 cmp rdx,NEBOC_AR_TYPE_BOOL
 je .identifier_slice_bool
 cmp rdx,NEBOC_AR_TYPE_CHAR
 jne .identifier_unresolved
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 jmp .done
.identifier_slice_int:
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_INT
 jmp .done
.identifier_slice_bool:
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_BOOL
 jmp .done
.identifier_array:
 mov rdi,rax
 call fcg_array_type_from_record
 jmp .done
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .identifier_unresolved
 test qword [rax+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .identifier_unresolved
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
.identifier_unresolved:
 xor eax,eax
 jmp .done
.identifier_resolved:
 mov rax,rdx
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 cmp r15,NEBOC_TOKEN_BANG
 je .unary_bool
 cmp r15,NEBOC_TOKEN_PLUS
 je .unary_int
 cmp r15,NEBOC_TOKEN_MINUS
 jne .bad
.unary_int:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.unary_bool:
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rax,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,[rsp]
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 cmp r15,NEBOC_TOKEN_AND_AND
 je .logical
 cmp r15,NEBOC_TOKEN_OR_OR
 je .logical
 cmp r15,NEBOC_TOKEN_EQUAL_EQUAL
 je .equality
 cmp r15,NEBOC_TOKEN_BANG_EQUAL
 je .equality
 cmp r15,NEBOC_TOKEN_LESS
 je .relational
 cmp r15,NEBOC_TOKEN_LESS_EQUAL
 je .relational
 cmp r15,NEBOC_TOKEN_GREATER
 je .relational
 cmp r15,NEBOC_TOKEN_GREATER_EQUAL
 je .relational
 cmp r15,NEBOC_TOKEN_PLUS
 je .arithmetic
 cmp r15,NEBOC_TOKEN_MINUS
 je .arithmetic
 cmp r15,NEBOC_TOKEN_STAR
 je .arithmetic
 cmp r15,NEBOC_TOKEN_SLASH
 je .arithmetic
 cmp r15,NEBOC_TOKEN_PERCENT
 jne .bad
.arithmetic:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.equality:
 mov rax,[rsp+16]
 cmp rax,[rsp+24]
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.relational:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.logical:
 cmp qword [rsp+16],NEBOC_TYPE_ID_BOOL
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.call:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_tuple_expr_info
 test eax,eax
 jz .infer_call_not_tuple
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.infer_call_not_tuple:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .normal_call
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,[rsp]
 jne .type_assert_bad
 mov rax,[rsp]
 jmp .done
.type_assert_bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 xor eax,eax
 jmp .done
.normal_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_buffer_call_info
 test eax,eax
 jz .not_buffer_call
 mov eax,ecx
 jmp .done
.not_buffer_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_textual_call_info
 test eax,eax
 jz .not_textual_call
 mov rax,rcx
 jmp .done
.not_textual_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_nominal_call_info
 test eax,eax
 jz .not_nominal_call
 mov rax,rcx
 jmp .done
.not_nominal_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_result_as_slice_info
 test eax,eax
 jz .not_result_as_slice
 mov rax,rcx
 jmp .done
.not_result_as_slice:
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_release_info
 test eax,eax
 jz .not_collection_release
 mov eax,NEBOC_TYPE_ID_VOID
 jmp .done
.not_collection_release:
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_sum_info
 test eax,eax
 jz .not_collection_sum
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.not_collection_sum:
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_access_info
 test eax,eax
 jz .not_collection_access
 mov rax,rcx
 jmp .done
.not_collection_access:
 mov rdi,rbx
 mov rsi,r12
 call fcg_numeric_call_info
 test eax,eax
 jz .not_numeric_call
 mov rax,rcx
 jmp .done
.not_numeric_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_scan_call
 test eax,eax
 jnz .scan_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_byte_length_call
 test eax,eax
 jnz .text_count_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_codepoint_count_call
 test eax,eax
 jnz .text_count_call
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 mov rax,rdx
 jmp .done
.scan_call:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_console_call
 test eax,eax
 jnz .text
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .bad
 jmp .text
.text_count_call:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_is_scan_result_reference
 test eax,eax
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .bad
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.terminal:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
.bad:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, declaration_node_id -> RAX block node id or zero.
fcg_find_block:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .yes
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.yes:
 mov rax,r12
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, node_id.  Preserve the exact causal AST half-open span for the
; canonical diagnostic adapter.
fcg_capture_node_span:
 push rbx
 mov rbx,rdi
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET],0
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .done
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET],rdx
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET],rdx
.done:
 pop rbx
 ret

; Capture the public source span of the first call beyond the bounded ABI
; contract.  The capacity condition is user-reachable, so its causal span is
; owned here rather than reconstructed later by the CLI serializer.
; state*
fcg_capture_call_limit_span:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET],0
 mov r12,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test r12,r12
 jz .done
 mov r13,[r12+NEBOC_AST_BUILDER_DATA_OFFSET]
 test r13,r13
 jz .done
 mov r10,[r12+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r11d,r11d
 xor r9d,r9d
.scan:
 cmp r11,r10
 jae .done
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 lea r8,[r13+rax]
 cmp qword [r8+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .next
 test qword [r8+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .next
 mov [rsp],r11
 mov [rsp+8],r9
 mov rdi,rbx
 lea rsi,[r11+1]
 call fcg_is_runtime_intrinsic_call
 mov r11,[rsp]
 mov r9,[rsp+8]
 test eax,eax
 jnz .next
 mov rax,r11
 imul rax,NEBOC_AST_NODE_SIZE
 lea r8,[r13+rax]
 inc r9
 cmp r9,NEBOC_ABI_MAX_RUNTIME_CALLS+1
 jne .next
 mov rax,[r8+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET],rax
 mov rax,[r8+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET],rax
 jmp .done
.next:
 inc r11
 jmp .scan
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX 1 when the subtree contains a canonical Scan
; intrinsic, 0 when it does not, or -1 on an invalid/deep AST.
fcg_contains_scan_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp],rax
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_scan_call
 test eax,eax
 jnz .found
.children:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .not_found
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_contains_scan_call
 cmp rax,-1
 je .bad
 test eax,eax
 jnz .found
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.found:
 mov eax,1
 jmp .done
.not_found:
 xor eax,eax
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Record one causal NPT-LANG-37 error without emitting any bytes.
; state*, error_code, node_id -> invalid-source status.
fcg_nested_reject:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rdx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, owner_function_id -> RAX exact private declaration id or zero.
fcg_nested_decl_for_owner:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 xor r13d,r13d
.loop:
 cmp r13,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET]
 jae .no
 cmp r12,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_OWNER_IDS_OFFSET+r13*8]
 je .yes
 inc r13
 jmp .loop
.yes:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_DECLS_OFFSET+r13*8]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, name_token, depth -> RAX 1/0/-1 and RDX matched node.
; Private declarations are compile-time islands and are never searched as
; outer bindings.
fcg_nested_name_collision_scan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .check_named
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jnz .no
.check_named:
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_RECEIVER
 je .decl_name
 cmp rax,NEBOC_AST_PARAMETER
 je .decl_name
 cmp rax,NEBOC_AST_BINDING_STMT
 je .binding_name
 cmp rax,NEBOC_AST_RANGE_FOR_STMT
 jne .children
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 jmp .compare
.decl_name:
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jmp .compare
.binding_name:
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
.compare:
 mov rdi,rbx
 mov rdx,r13
 call fcg_names_equal
 test eax,eax
 jnz .yes
.children:
 mov r12,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .no
 mov [rsp],r12
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 lea rcx,[r14+1]
 call fcg_nested_name_collision_scan
 cmp rax,-1
 je .bad
 test rax,rax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.yes:
 mov eax,1
 mov rdx,r12
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 jmp .done
.bad:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, function_name_token, depth -> RAX 1/0/-1, RDX call id.
; Do not traverse the lifted private declaration when proving whether the
; declaring outer is recursively connected to itself.
fcg_nested_named_call_scan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .call_check
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jnz .no
.call_check:
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r13
 call fcg_names_equal
 test eax,eax
 jnz .yes
.children:
 mov r12,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .no
 mov [rsp],r12
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 lea rcx,[r14+1]
 call fcg_nested_named_call_scan
 cmp rax,-1
 je .bad
 test rax,rax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.yes:
 mov eax,1
 mov rdx,r12
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 jmp .done
.bad:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, function_name_token, depth -> exact matching call count or
; -1.  The private declaration is a compile-time island: only calls owned by
; the direct outer body contribute to the selected one-call-site bound.
fcg_nested_named_call_count:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .call_check
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jnz .zero
.call_check:
 mov qword [rsp+8],0
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r13
 call fcg_names_equal
 test eax,eax
 jz .children
 mov qword [rsp+8],1
.children:
 mov r15,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r15,r15
 jz .counted
 mov [rsp],r15
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 lea rcx,[r14+1]
 call fcg_nested_named_call_count
 test rax,rax
 js .bad
 add [rsp+8],rax
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.counted:
 mov rax,[rsp+8]
 jmp .done
.zero:
 xor eax,eax
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, private_name_token, depth -> RAX 1/0/-1, RDX identifier.
; Calls keep the method name in CallExpr.payload0, so an IdentifierExpr with
; the private name is necessarily an attempted value/escape.
fcg_nested_escape_scan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .children
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r13
 call fcg_names_equal
 test eax,eax
 jnz .yes
.children:
 mov r12,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .no
 mov [rsp],r12
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 lea rcx,[r14+1]
 call fcg_nested_escape_scan
 cmp rax,-1
 je .bad
 test rax,rax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.yes:
 mov eax,1
 mov rdx,r12
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 jmp .done
.bad:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression_id, depth -> exact scalar TypeId or zero.  This is the
; complete B01 helper expression surface: self, scalar literals and existing
; unary/binary scalar operators.  Calls and all free identifiers are closed.
fcg_validate_nested_expression:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .capacity
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .surface
.int:
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.bool:
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.char:
 mov eax,NEBOC_TYPE_ID_CHAR
 jmp .done
.text:
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_self]
 mov ecx,fcg_name_self_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .int
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPTURE
 mov rdx,r12
 call fcg_nested_reject
 xor eax,eax
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .surface
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_validate_nested_expression
 test rax,rax
 jz .done
 cmp r15,NEBOC_TOKEN_PLUS
 je .unary_int
 cmp r15,NEBOC_TOKEN_MINUS
 jne .surface
.unary_int:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .surface
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rax,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .surface
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .surface
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,[rsp]
 lea rdx,[r13+1]
 call fcg_validate_nested_expression
 test rax,rax
 jz .done
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 lea rdx,[r13+1]
 call fcg_validate_nested_expression
 test rax,rax
 jz .done
 mov [rsp+24],rax
 cmp r15,NEBOC_TOKEN_PLUS
 je .binary_arithmetic
 cmp r15,NEBOC_TOKEN_MINUS
 je .binary_arithmetic
 cmp r15,NEBOC_TOKEN_STAR
 je .binary_arithmetic
 cmp r15,NEBOC_TOKEN_SLASH
 je .binary_arithmetic
 cmp r15,NEBOC_TOKEN_PERCENT
 je .binary_arithmetic
 cmp r15,NEBOC_TOKEN_LESS
 je .binary_relation
 cmp r15,NEBOC_TOKEN_LESS_EQUAL
 je .binary_relation
 cmp r15,NEBOC_TOKEN_GREATER
 je .binary_relation
 cmp r15,NEBOC_TOKEN_GREATER_EQUAL
 je .binary_relation
 cmp r15,NEBOC_TOKEN_EQUAL_EQUAL
 je .binary_equality
 cmp r15,NEBOC_TOKEN_BANG_EQUAL
 jne .surface
.binary_equality:
 mov rax,[rsp+16]
 cmp rax,[rsp+24]
 jne .surface
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.binary_relation:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .surface
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .surface
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.binary_arithmetic:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .surface
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .surface
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.call:
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .surface
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECURSION
 mov rdx,r12
 call fcg_nested_reject
 xor eax,eax
 jmp .done
.capacity:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPACITY
 mov rdx,r12
 call fcg_nested_reject
 xor eax,eax
 jmp .done
.surface:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 mov rdx,r12
 call fcg_nested_reject
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, target_token, depth -> EAX 1/0, or -1 on malformed input.
; A nested helper may refer only to `self` and bindings declared inside that
; same helper.  The ordinary lexical pass remains responsible for declaration
; order and branch visibility; this bounded walk distinguishes a free outer
; name from a helper-owned local before that pass reports a generic type error.
fcg_nested_local_name_exists:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .children
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r13
 call fcg_names_equal
 test eax,eax
 jnz .yes
.children:
 mov r15,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r15,r15
 jz .no
 mov [rsp],r15
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 lea rcx,[r14+1]
 call fcg_nested_local_name_exists
 test eax,eax
 js .bad
 jnz .yes
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> status.  Authenticate the complete durable B01
; helper body: immutable Int locals, Int scalar expressions/comparisons,
; if/else and return flow.  Every call, mutation, loop, collection and deeper
; declaration remains closed.  Name/type/flow resolution is performed by the
; ordinary lexical analyzer immediately after this structural pass.
fcg_validate_nested_surface:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .capacity
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 cmp rax,NEBOC_AST_BLOCK
 je .children
 cmp rax,NEBOC_AST_BINDING_STMT
 je .binding
 cmp rax,NEBOC_AST_BINDING_TERMINAL
 je .binding_terminal
 cmp rax,NEBOC_AST_RETURN_STMT
 je .children
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .children
 cmp rax,NEBOC_AST_IF_STMT
 je .children
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .ok
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .ok
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .children
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .children
 jmp .surface
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_self]
 mov ecx,fcg_name_self_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .ok
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 mov rdx,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor ecx,ecx
 call fcg_nested_local_name_exists
 test eax,eax
 js .surface
 jnz .ok
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPTURE
 mov rdx,r12
 call fcg_nested_reject
 jmp .done
.binding:
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 shr rax,32
 cmp rax,NEBOC_TYPE_ID_INT
 jne .surface
 jmp .children
.binding_terminal:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jnz .surface
 jmp .children
.call:
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .surface
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECURSION
 mov rdx,r12
 call fcg_nested_reject
 jmp .done
.children:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r15,r15
 jz .ok
 mov [rsp],r15
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_validate_nested_surface
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.capacity:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPACITY
 mov rdx,r12
 call fcg_nested_reject
 jmp .done
.surface:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 mov rdx,r12
 call fcg_nested_reject
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, nested_decl_id, owner_decl_id, owner_function_id -> status.
fcg_validate_nested_decl:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_NESTED_OWNER_ID_OFFSET],r14
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_IS_NESTED_OFFSET],1
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .surface
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jz .surface
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .parameter
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .surface
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+56],rax
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .surface
 mov [rsp],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .surface
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .receiver
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .receiver
 mov rax,[rsp+8]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 lea rdx,[rel fcg_name_self]
 mov ecx,fcg_name_self_len
 call fcg_token_matches_literal
 test eax,eax
 jz .receiver
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .surface
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .surface
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],0
 je .return_type
 ; Collections are registered outside the shared statement AST; authenticate
 ; their absence by the established semantic-record span oracle.
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_recursion_block_has_collection_record
 test eax,eax
 jnz .surface
 ; Assign only helper-owned immutable lexical slots before type/flow analysis.
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_prepare_bindings
 cmp rax,-1
 jne .bindings_ready
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 je .capture
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 je .capture
 jmp .surface
.bindings_ready:
 mov rdi,rbx
 mov rsi,[rsp+16]
 xor edx,edx
 call fcg_validate_nested_surface
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r14+NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS]
 call fcg_function_return_type
 test rax,rax
 jnz .nested_return_known
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 je .capture
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 je .capture
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_MISSING_RETURN
 je .return_type
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_INCONSISTENT_RETURN
 je .return_type
 jmp .surface
.nested_return_known:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .return_type
 ; The private name cannot collide with any receiver, parameter, local or
 ; iterator owned by its outer lexical frame.
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[rsp+56]
 xor ecx,ecx
 call fcg_nested_name_collision_scan
 cmp rax,-1
 je .capacity
 test rax,rax
 jnz .collision
 ; A selected nested helper and an outer self-edge cannot coexist.
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .surface
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 xor ecx,ecx
 call fcg_nested_named_call_scan
 cmp rax,-1
 je .capacity
 test rax,rax
 jnz .recursive_outer
 ; The selected outer contains exactly one private-helper call site.  Repeated
 ; executions arise only by calling the outer repeatedly; they do not publish
 ; a broader multi-call nested surface.
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[rsp+56]
 xor ecx,ecx
 call fcg_nested_named_call_count
 cmp rax,-1
 je .capacity
 cmp rax,1
 jne .surface
 xor eax,eax
 jmp .done
.parameter:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_PARAMETER
 mov rdx,r12
 jmp .reject
.receiver:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECEIVER
 mov rdx,r12
 jmp .reject
.return_type:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RETURN
 mov rdx,r12
 jmp .reject
.capture:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPTURE
 mov rdx,r12
 jmp .reject
.collision:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SYMBOL_COLLISION
 jmp .reject
.recursive_outer:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECURSIVE_OUTER
 jmp .reject
.capacity:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPACITY
 mov rdx,r12
 jmp .reject
.surface:
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 mov rdx,r12
.reject:
 mov rdi,rbx
 call fcg_nested_reject
 jmp .done
.failed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Collect/freeze direct nested declarations in stable outer FunctionId order.
; The complete pass, including escape scans, precedes every writer operation.
fcg_collect_nested_private:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_STATE_OFFSET],NEBOC_FUNCTION_CODEGEN_NESTED_STATE_COLLECTING
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r13d,2
.outer_loop:
 test r12,r12
 jz .escape_pass
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .outer_next
 mov [rsp],r12
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+24],r14
 mov qword [rsp+8],0
.statement_loop:
 test r14,r14
 jz .outer_registered
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rdx
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .statement_next
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jz .bad
 cmp qword [rsp+8],0
 jne .duplicate
 ; The declaration belongs to the leading declaration section.  Preserve the
 ; dedicated call-before diagnostic when an earlier statement actually names
 ; this helper; otherwise any preceding runtime statement closes placement.
 cmp r14,[rsp+24]
 je .placement_ok
 mov [rsp+32],r14
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+40],rcx
 mov rcx,[rsp+24]
 mov [rsp+48],rcx
 mov [rsp+56],r15
.placement_scan:
 mov rcx,[rsp+48]
 cmp rcx,[rsp+32]
 je .placement_reject
 mov rdi,rbx
 mov rsi,rcx
 mov rdx,[rsp+40]
 xor ecx,ecx
 call fcg_nested_named_call_scan
 cmp rax,-1
 je .placement_bad
 test eax,eax
 jnz .placement_restore
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_node_ptr
 test rax,rax
 jz .placement_bad
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+48],rax
 test rax,rax
 jnz .placement_scan
.placement_reject:
 mov r15,[rsp+56]
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CONTEXT
 mov rdx,r14
 call fcg_nested_reject
 jmp .done
.placement_bad:
 mov r15,[rsp+56]
 jmp .bad
.placement_restore:
 mov r15,[rsp+56]
.placement_ok:
 mov [rsp+8],r14
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS
 jae .capacity
 mov [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_DECLS_OFFSET+rax*8],r14
 mov rdx,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_OWNER_DECLS_OFFSET+rax*8],rdx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_OWNER_IDS_OFFSET+rax*8],r13
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp]
 mov rcx,r13
 call fcg_validate_nested_decl
 test eax,eax
 jnz .done
.statement_next:
 mov r14,[rsp+16]
 jmp .statement_loop
.outer_registered:
 inc r13
.outer_next:
 mov r12,r15
 jmp .outer_loop
.escape_pass:
 xor r14d,r14d
.escape_loop:
 cmp r14,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET]
 jae .freeze
 mov r12,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_DECLS_OFFSET+r14*8]
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 xor ecx,ecx
 call fcg_nested_escape_scan
 cmp rax,-1
 je .capacity
 test rax,rax
 jnz .escape
 inc r14
 jmp .escape_loop
.freeze:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_STATE_OFFSET],NEBOC_FUNCTION_CODEGEN_NESTED_STATE_FROZEN
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_NESTED_OWNER_ID_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_IS_NESTED_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.duplicate:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_DUPLICATE
 mov rdx,r14
 call fcg_nested_reject
 jmp .done
.escape:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_ESCAPE
 call fcg_nested_reject
 jmp .done
.capacity:
 mov rdi,rbx
 mov esi,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPACITY
 mov rdx,r12
 call fcg_nested_reject
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_id, receiver_type, explicit_arg_count -> private symbol or zero.
; Exact owner/position matches are private-first.  Scope misses may still fall
; through to an unrelated public overload; before-declaration never may.
fcg_resolve_nested_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_STATE_OFFSET],NEBOC_FUNCTION_CODEGEN_NESTED_STATE_FROZEN
 jne .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 xor ecx,ecx
.loop:
 cmp rcx,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_COUNT_OFFSET]
 jae .no
 mov [rsp],rcx
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_DECLS_OFFSET+rcx*8]
 mov [rsp+8],rax
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 mov rcx,[rsp]
 test eax,eax
 jz .next
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_OWNER_DECLS_OFFSET+rcx*8]
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 jne .scope_miss
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdx,[r15+NEBOC_AST_NODE_START_OFFSET]
 cmp rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 jb .before
 cmp r13,NEBOC_TYPE_ID_INT
 jne .surface
 test r14,r14
 jnz .surface
 mov rcx,[rsp]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_NESTED_OWNER_IDS_OFFSET+rcx*8]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_NESTED_OWNER_ID_OFFSET],rdx
 lea rax,[rdx+NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS]
 jmp .done
.scope_miss:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SCOPE
 jmp .next
.before:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CALL_BEFORE
 jmp .no
.surface:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_NESTED_PENDING_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 jmp .no
.next:
 inc rcx
 jmp .loop
.no:
 xor eax,eax
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX call count or -1.
fcg_count_calls:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp],rax
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 xor r15d,r15d
 ; Intrinsic classification for a bound receiver must observe the same exact
 ; lexical statement during planning that expression emission observes.  The
 ; recursive walk restores its caller's statement, so sibling scopes and
 ; nested blocks cannot leak binding visibility into one another.
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_EXPRESSION_STMT
 je .statement_context
 cmp rax,NEBOC_AST_BINDING_STMT
 je .statement_context
 cmp rax,NEBOC_AST_ASSIGNMENT_STMT
 je .statement_context
 cmp rax,NEBOC_AST_RETURN_STMT
 je .statement_context
 cmp rax,NEBOC_AST_IF_STMT
 je .statement_context
 cmp rax,NEBOC_AST_WHILE_STMT
 je .statement_context
 cmp rax,NEBOC_AST_LOOP_STMT
 je .statement_context
 cmp rax,NEBOC_AST_RANGE_FOR_STMT
 jne .statement_context_ready
.statement_context:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
.statement_context_ready:
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .count_node
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jnz .ok
.count_node:
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_runtime_intrinsic_call
 test eax,eax
 jnz .children
 ; Tuple constructors, length and positional projections are compiler-time
 ; value operations.  Keep them out of the runtime ABI call count exactly as
 ; fcg_emit_expr keeps them out of the emitted call stream.
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_tuple_expr_info
 test eax,eax
 jnz .children
 inc r15
.children:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .ok
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_count_calls
 cmp rax,-1
 je .bad
 add r15,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.ok:
 mov rax,r15
 jmp .done
.bad:
 mov rax,-1
.done:
 mov rdx,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rdx
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, token_a, token_b -> EAX 1/0.
fcg_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov r8,[r14+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r14+NEBOC_TOKEN_END_OFFSET]
 mov r10,[r15+NEBOC_TOKEN_START_OFFSET]
 mov r11,[r15+NEBOC_TOKEN_END_OFFSET]
 sub r9,r8
 sub r11,r10
 cmp r9,r11
 jne .no
 mov rcx,r9
 cld
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,r8
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rdi,r10
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; state* -> EAX 1 when any authenticated function parameter carries the
; bounded generic marker.  The semantic collection owner has already limited
; this spelling to Slice<Int|Bool|Char>.
fcg_program_has_slice_parameter:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r13d,1
.loop:
 cmp r13,r12
 ja .no
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PARAMETER
 jne .next
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_PARAMETER
 jnz .yes
.next:
 inc r13
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, receiver/parameter AST node id -> exact internal TypeId or zero.
fcg_decl_type_from_node:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_RECEIVER
 je .scalar
 cmp rcx,NEBOC_AST_PARAMETER
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_PARAMETER
 jz .scalar
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_type_slice]
 mov ecx,fcg_type_slice_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 add rsi,2
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 je .slice_int
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .slice_bool
 cmp rax,NEBOC_TYPE_ID_CHAR
 jne .no
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 jmp .done
.slice_int:
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_INT
 jmp .done
.slice_bool:
 mov eax,NEBOC_FUNCTION_TYPE_SLICE_BOOL
 jmp .done
.scalar:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; state*, type_token_index -> RAX TypeId or zero.
fcg_type_from_token:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r13,rax
 mov r8,[r13+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r13+NEBOC_TOKEN_END_OFFSET]
 sub r9,r8
 mov r10,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add r10,r8
 cmp r9,3
 jne .check_bool
 cmp byte [r10],'I'
 jne .no
 cmp byte [r10+1],'n'
 jne .no
 cmp byte [r10+2],'t'
 jne .no
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.check_bool:
 cmp r9,5
 je .check_bytes
 cmp r9,4
 jne .no
 cmp byte [r10],'B'
 jne .check_char
 cmp byte [r10+1],'o'
 jne .check_char
 cmp byte [r10+2],'o'
 jne .check_char
 cmp byte [r10+3],'l'
 jne .check_char
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.check_char:
 cmp byte [r10],'C'
 jne .check_text
 cmp byte [r10+1],'h'
 jne .check_text
 cmp byte [r10+2],'a'
 jne .check_text
 cmp byte [r10+3],'r'
 jne .check_text
 mov eax,NEBOC_TYPE_ID_CHAR
 jmp .done
.check_text:
 cmp byte [r10],'T'
 jne .no
 cmp byte [r10+1],'e'
 jne .no
 cmp byte [r10+2],'x'
 jne .no
 cmp byte [r10+3],'t'
 jne .no
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.check_bytes:
 cmp byte [r10],'B'
 jne .no
 cmp byte [r10+1],'y'
 jne .no
 cmp byte [r10+2],'t'
 jne .no
 cmp byte [r10+3],'e'
 jne .no
 cmp byte [r10+4],'s'
 jne .no
 mov eax,NEBOC_TYPE_ID_BYTES
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, token_index -> token pointer or zero.
fcg_token_ptr:
 xor eax,eax
 test rdi,rdi
 jz .done
 cmp rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .done
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
.done:
 ret

; state*, node_id -> node pointer or zero.
fcg_node_ptr:
 xor eax,eax
 test rdi,rdi
 jz .done
 test rsi,rsi
 jz .done
 mov rcx,[rdi+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rcx,rcx
 jz .done
 cmp rsi,[rcx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .done
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 mov rax,[rcx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rax,rsi
.done:
 ret

; state*, binding statement id -> EAX 1 only for the exact existing public
; two-statement typed-binding pair `Type.name; value.name;`, RDX declared
; TypeId.  This is an internal composition bridge: it introduces no syntax
; and marks only the declaration half after adjacency, name and type agree.
fcg_typed_binding_declaration_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .no
 mov r14,rax
 mov r12,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .no
 mov rax,[rsp+8]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov [rsp+16],rsi
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp],rax
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
 mov rdi,rbx
 xor edx,edx
 call fcg_infer_type
 mov rcx,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rcx
 cmp rax,r14
 jne .no
 or qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPED_BINDING_DECLARATION
 mov rdx,r14
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret



; state*, block_id, parameter_count -> RAX total local slots, RDX binding count.
; Assign one stable frame slot to every binding in the function while retaining
; lexical visibility through the bounded scope stack. Slots are intentionally
; unique across sibling branches; no implicit phi/hoist is introduced.
fcg_prepare_bindings:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_PARAMETER_BASE_OFFSET],r13
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_scope_reset
 mov rdi,rbx
 mov rsi,r12
 call fcg_prepare_mutable_arrays_for_block
 test eax,eax
 jnz .failed
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_prepare_block_bindings
 test eax,eax
 jnz .failed
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 mov rax,r13
 add rax,rdx
 jmp .done
.failed:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth -> status. The caller owns the current lexical scope.
fcg_prepare_block_bindings:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],r12
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r14,r14
 jz .finish
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .binding
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 je .assignment
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .if
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 je .loop_statement
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .loop_statement
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 je .collection_loop_statement
 jmp .next
.if:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_prepare_if_bindings
 test eax,eax
 jnz .done
 jmp .next
.loop_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_prepare_loop_bindings
 test eax,eax
 jnz .done
 jmp .next
.collection_loop_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_prepare_collection_loop_bindings
 test eax,eax
 jnz .done
 jmp .next
.assignment:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_validate_assignment
 test eax,eax
 jnz .done
 jmp .next
.binding:
 mov rdi,rbx
 mov rsi,r14
 call fcg_typed_binding_declaration_info
 test eax,eax
 jnz .next
 mov rdi,rbx
 mov rsi,r14
 call fcg_is_buffer_binding
 test eax,eax
 jnz .next
 mov rdi,rbx
 mov rsi,r14
 call fcg_collection_binding_record
 test rax,rax
 jz .scalar_binding
 mov rdi,rbx
 mov rsi,rax
 call fcg_prepare_mutable_collection_record
 test eax,eax
 jnz .done
 jmp .next
.scalar_binding:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 mov [rsp+16],rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov [rsp+48],rsi
 ; Scientific scalar bindings are private AST anchors paired by their exact
 ; immutable source name with a validated C11/C12 helper.  Allocate their
 ; ordinary lexical slot using the helper's authenticated result type; never
 ; reclassify the original Matrix/Tensor call as a user FunctionTable call.
 mov rdi,rbx
 mov rsi,r14
 call fcg_is_scientific_binding
 test eax,eax
 jz .start_binding_guard
 mov rax,rcx
 jmp .binding_type_ok
.start_binding_guard:
 ; The current public caller oracle permits a scalar call as the terminal
 ; start value, but it does not publish call-result storage followed by later
 ; reuse.  Keep that adjacent composition deferred while allowing ordinary
 ; direct start bindings and Void call sequences.
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 jne .infer_binding_type_reload
 cmp qword [rsp+8],0
 je .infer_binding_type
 ; B01's direct typed Array result is the one bounded exception to the older
 ; start call-result-reuse guard. Resolve it exactly before applying that
 ; scalar guard; every non-Array call retains the prior rejection.
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .start_call_result_guard
 ; Runtime intrinsics have no FunctionTable symbol to resolve.  Their exact
 ; result type is owned by fcg_infer_type below; do not run the speculative
 ; user-function resolver and leave a stale UNDEFINED_CALL diagnostic behind.
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_is_runtime_intrinsic_call
 test eax,eax
 jnz .infer_binding_type_reload
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_collection_result_as_slice_info
 test eax,eax
 jnz .infer_binding_type_reload
 ; C13-PRC-A3: a public Tuple constructor is a bounded compile-time value,
 ; not a user FunctionTable call result.  Its later projection is resolved
 ; from the immutable AST identity and therefore neither allocates result
 ; storage nor crosses the public call ABI.  Admit only the exact Tuple
 ; expression recognized by the shared tuple classifier before applying the
 ; historical start-scope call-result-reuse guard.
 mov rdi,rbx
 mov rsi,[rsp+48]
 xor edx,edx
 call fcg_tuple_expr_info
 test eax,eax
 jnz .infer_binding_type_reload
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_resolve_call
 test rax,rax
 jz .start_call_result_guard
 mov [rsp+24],rdx
 mov rdi,rdx
 call fcg_array_type_decode
 test eax,eax
 jnz .infer_binding_type_reload
 mov rdi,[rsp+24]
 call fcg_slice_type_decode
 test eax,eax
 jnz .infer_binding_type_reload
.start_call_result_guard:
 mov rsi,[rsp+48]
 mov rdi,rbx
 xor edx,edx
 call fcg_count_calls
 cmp rax,-1
 je .type
 test rax,rax
 jnz .start_call_result_scope
 mov rsi,[rsp+48]
.infer_binding_type_reload:
 mov rsi,[rsp+48]
.infer_binding_type:
 mov rdi,rbx
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .type
 mov [rsp+24],rax
 mov rdi,rax
 call fcg_array_type_decode
 test eax,eax
 jnz .array_result_binding
 mov rax,[rsp+24]
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_INT
 je .array_result_slice_binding
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_BOOL
 je .array_result_slice_binding
 cmp rax,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 je .array_result_slice_binding
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 jne .function_binding_type
 cmp rax,NEBOC_TYPE_ID_VOID
 jne .binding_type_ok
 jmp .type
.function_binding_type:
 cmp rax,NEBOC_TYPE_ID_INT
 je .binding_type_ok
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .binding_type_ok
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .type
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_is_scan_call
 test eax,eax
 jz .type
 mov rax,[rsp+56]
.binding_type_ok:
 mov [rsp+24],rax
 ; Mutable function locals retain the current direct-local type boundary.
 ; Text is public here only as an immutable Scan result; Char/Float locals
 ; remain outside this function-local slice.
 mov rax,[rsp+16]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .binding_mutability_ok
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 je .binding_mutability_ok
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 je .binding_mutability_ok
 cmp qword [rsp+24],NEBOC_TYPE_ID_BOOL
 je .binding_mutability_ok
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_MUTABLE_TYPE
 mov rdi,rbx
 mov rsi,r14
 call fcg_capture_node_span
 jmp .fail
.binding_mutability_ok:
 ; Reject duplicate names against receiver, parameters and prior bindings.
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jnz .duplicate
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_PARAMETER_BASE_OFFSET]
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 cmp rax,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 mov [rsp+32],rax
 mov rdx,[rsp+24]
 shl rdx,32
 or rdx,rax
 mov [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
 mov rax,[rsp+16]
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
 jmp .next
.array_result_binding:
 ; B01 publishes only a direct lexical call-result binding.  It deliberately
 ; does not turn arbitrary Array expressions into copy/forwarding syntax.
 test r13,r13
 jnz .type
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .type
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+24]
 call fcg_register_array_result_binding
 test eax,eax
 jnz .done
 jmp .next
.array_result_slice_binding:
 ; Only a start-scope explicit binding of `result.asSlice()` belongs to B01.
 ; Function-local Slice construction and arbitrary Slice-producing calls keep
 ; their existing boundaries.
 test r13,r13
 jnz .type
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_collection_result_as_slice_info
 test eax,eax
 jz .direct_slice_call_result
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+48]
 call fcg_register_array_result_slice_binding
 test eax,eax
 jnz .done
 jmp .next
.direct_slice_call_result:
 ; A returned Slice is a read-only caller reborrow.  The existing `.mutable`
 ; binding suffix must not manufacture write capability for that descriptor.
 mov rax,[rsp+16]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jnz .type
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .type
 mov rdi,rbx
 mov rsi,[rsp+48]
 call fcg_resolve_call
 test rax,rax
 jz .type
 cmp rdx,[rsp+24]
 jne .type
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+24]
 call fcg_register_slice_result_binding
 test eax,eax
 jnz .done
.next:
 mov r14,[rsp+8]
 jmp .loop
.finish:
 xor eax,eax
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 jmp .done
.duplicate:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DUPLICATE_BINDING
 jmp .fail
.start_call_result_scope:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 jmp .fail
.type:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .fail
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_TYPE
 jmp .fail
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 jmp .fail
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 jmp .fail
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, direct binding statement, exact Array TypeId -> status.  Append one
; compiler-only owner record whose payload is allocated in the caller frame.
; The semantic scanner retains original token indices, so translate the
; filtered AST name by exact immutable source occurrence.
fcg_register_array_result_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov [rsp],rdx
 mov rdi,rdx
 call fcg_array_type_decode
 test eax,eax
 jz .bad
 mov [rsp+8],rdx             ; element
 mov [rsp+16],rcx            ; length
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor r15d,r15d
.find_original:
 cmp r15,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .bad
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r15
 call fcg_token_same_ar_occurrence
 test eax,eax
 jnz .name_ready
 inc r15
 jmp .find_original
.name_ready:
 mov rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 cmp rax,[r13+NEBOC_AR_BINDING_CAPACITY_OFFSET]
 jae .limit
 mov rcx,rax
 bts rcx,63
 mov [rsp+24],rcx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rsp+24]
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rcx
 mov rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+24],rax
 mov [rax+NEBOC_AR_BIND_NAME_OFFSET],r15
 mov qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 mov rdx,[rsp+8]
 mov [rax+NEBOC_AR_BIND_TYPE_OFFSET],rdx
 mov rdx,[rsp+16]
 mov [rax+NEBOC_AR_BIND_COUNT_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_STRIDE_OFFSET],8
 mov rcx,rdx
 shl rcx,3
 mov [rax+NEBOC_AR_BIND_SIZE_OFFSET],rcx
 mov qword [rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET],0
 mov qword [rax+NEBOC_AR_BIND_START_OFFSET],0
 mov [rax+NEBOC_AR_BIND_END_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_STEP_OFFSET],1
 mov qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 mov qword [rax+NEBOC_AR_BIND_HASH_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rdx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,rdx
 call fcg_node_ptr
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .frame
 mov rax,[rsp+24]
 or qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
.frame:
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_prepare_mutable_collection_record
 test eax,eax
 jnz .done
 inc qword [r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, direct binding statement, asSlice call node -> status.  Materialize
; one compiler-semantic read-only Slice view whose owner is the exact
; caller-frame Array result.  The public 40-byte descriptor contract remains
; unchanged; no runtime descriptor is introduced for this local view.
fcg_register_array_result_slice_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r14,rdx
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .bad
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .bad
 mov [rsp],rax               ; exact owner record
 sub rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 jc .bad
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .bad
 mov [rsp+8],rax             ; owner ordinal
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor r14d,r14d
.find_original_name:
 cmp r14,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .bad
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r14
 call fcg_token_same_ar_occurrence
 test eax,eax
 jnz .name_ready
 inc r14
 jmp .find_original_name
.name_ready:
 mov rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 cmp rax,[r13+NEBOC_AR_BINDING_CAPACITY_OFFSET]
 jae .limit
 mov [rsp+16],rax
 mov rcx,rax
 bts rcx,63
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rcx
 mov rax,[rsp+16]
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+24],rax
 mov [rax+NEBOC_AR_BIND_NAME_OFFSET],r14
 mov qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 mov rdx,[rsp]
 mov rcx,[rdx+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [rax+NEBOC_AR_BIND_TYPE_OFFSET],rcx
 mov rcx,[rdx+NEBOC_AR_BIND_COUNT_OFFSET]
 mov [rax+NEBOC_AR_BIND_COUNT_OFFSET],rcx
 mov rcx,[rdx+NEBOC_AR_BIND_STRIDE_OFFSET]
 mov [rax+NEBOC_AR_BIND_STRIDE_OFFSET],rcx
 mov qword [rax+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov rcx,[rdx+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 mov [rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET],rcx
 mov rcx,[rsp+8]
 mov [rax+NEBOC_AR_BIND_START_OFFSET],rcx
 mov rcx,[rdx+NEBOC_AR_BIND_START_OFFSET]
 test rcx,rcx
 jnz .generation_ready
 mov ecx,1
 mov [rdx+NEBOC_AR_BIND_START_OFFSET],rcx
.generation_ready:
 mov [rax+NEBOC_AR_BIND_END_OFFSET],rcx
 mov rcx,[rsp+16]
 mov [rax+NEBOC_AR_BIND_STEP_OFFSET],rcx
 mov qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 inc qword [rdx+NEBOC_AR_BIND_END_OFFSET]
 inc qword [r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, direct binding statement, exact Slice TypeId -> status.
fcg_register_slice_result_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov [rsp],rdx
 mov rdi,rdx
 call fcg_slice_type_decode
 test eax,eax
 jz .bad
 mov [rsp+8],rdx
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor r15d,r15d
.find_name:
 cmp r15,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .bad
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r15
 call fcg_token_same_ar_occurrence
 test eax,eax
 jnz .name_ready
 inc r15
 jmp .find_name
.name_ready:
 mov rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 cmp rax,[r13+NEBOC_AR_BINDING_CAPACITY_OFFSET]
 jae .limit
 mov rcx,rax
 bts rcx,63
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rcx
 mov rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+16],rax
 mov [rax+NEBOC_AR_BIND_NAME_OFFSET],r15
 mov qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 mov rdx,[rsp+8]
 mov [rax+NEBOC_AR_BIND_TYPE_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_COUNT_OFFSET],0
 mov qword [rax+NEBOC_AR_BIND_STRIDE_OFFSET],8
 mov qword [rax+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov qword [rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET],0
 mov qword [rax+NEBOC_AR_BIND_START_OFFSET],0
 mov qword [rax+NEBOC_AR_BIND_END_OFFSET],0
 mov rdx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov [rax+NEBOC_AR_BIND_STEP_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],(NEBOC_AR_SLICE_LIVE | NEBOC_AR_SLICE_CALL_RESULT)
 mov qword [rax+NEBOC_AR_BIND_HASH_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rsp+16]
 call fcg_mark_slice_result_static_length
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_prepare_mutable_collection_record
 test eax,eax
 jnz .done
 inc qword [r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, direct result binding statement, result record -> status. Preserve a
; compile-time length only when every authenticated callee return source has
; one identical provable length. A direct S04 return can inherit that fact
; only from one exact statically-sized Slice argument at this call site.
fcg_mark_slice_result_static_length:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 test rax,rax
 jz .bad
 mov [rsp],rax                 ; exact callee symbol id
 mov rdi,rbx
 mov rsi,r12
 call fcg_slice_call_unique_argument_length
 mov [rsp+48],rax
 mov [rsp+56],rdx
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15d,2
.decl_loop:
 test r14,r14
 jz .unknown
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov [rsp+40],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .decl_next
 cmp r15,[rsp]
 jne .decl_count_next
 mov rdi,rbx
 mov rsi,r14
 call fcg_find_block
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp+8],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rsp+16],rcx
 jmp .scan_returns
.decl_count_next:
 inc r15
.decl_next:
 mov rax,[rsp+40]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .decl_loop
.scan_returns:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 mov qword [rsp+32],0          ; matched/known return count
 xor r14d,r14d
.return_loop:
 mov rax,[rsp+24]
 cmp r14,[rax+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .return_done
 mov r15,r14
 imul r15,NEBOC_AR_BIND_SIZE
 add r15,[rax+NEBOC_AR_BINDINGS_OFFSET]
 test qword [r15+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RETURN_SOURCE
 jz .return_next
 mov rdx,[r15+NEBOC_AR_BIND_NAME_OFFSET]
 cmp qword [r15+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 jne .scope_token_ready
 mov rdx,[r15+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
.scope_token_ready:
 cmp rdx,[rax+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .return_next
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,[rax+NEBOC_AR_TOKENS_OFFSET]
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,[rsp+8]
 jb .return_next
 cmp rcx,[rsp+16]
 jae .return_next
 test qword [r15+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jnz .derived_length
 cmp qword [r15+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 jne .unknown
 cmp qword [rsp+56],1
 jne .unknown
 mov rax,[rsp+48]
 jmp .merge_length
.derived_length:
 mov rax,[r15+NEBOC_AR_BIND_COUNT_OFFSET]
.merge_length:
 cmp qword [rsp+32],0
 jne .compare_length
 mov [rsp+40],rax
 mov qword [rsp+32],1
 jmp .return_next
.compare_length:
 cmp rax,[rsp+40]
 jne .unknown
.return_next:
 inc r14
 jmp .return_loop
.return_done:
 cmp qword [rsp+32],1
 jne .unknown
 mov rax,[rsp+40]
 mov [r13+NEBOC_AR_BIND_COUNT_OFFSET],rax
 or qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RESULT_LENGTH_KNOWN
.unknown:
 xor eax,eax
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> RAX exact static length and RDX=1 only for one exact
; statically-sized Slice argument; otherwise RDX=0.
fcg_slice_call_unique_argument_length:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 xor r13d,r13d
.arg_loop:
 test r12,r12
 jz .finish
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .arg_next
 mov rcx,[rax+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rcx,NEBOC_AR_KIND_SLICE
 je .slice_arg
 cmp rcx,NEBOC_AR_KIND_SLICE_PARAMETER
 jne .arg_next
.slice_arg:
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .length_ready
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RESULT_LENGTH_KNOWN
 jz .no
.length_ready:
 inc r13
 cmp r13,1
 jne .no
 mov rcx,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 mov [rsp],rcx
.arg_next:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .arg_loop
.finish:
 cmp r13,1
 jne .no
 mov rax,[rsp]
 mov edx,1
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, collection record -> status. Only named mutable local Arrays reserve
; writable cells. The high half of the internal flags word carries a one-based
; relative cell offset for this emission pass.
fcg_prepare_mutable_collection_record:
 cmp qword [rsi+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .check_array
 test qword [rsi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .ok
 mov edx,5
 jmp .allocate_cells
.check_array:
 cmp qword [rsi+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .ok
 test qword [rsi+NEBOC_AR_BIND_FLAGS_OFFSET],(NEBOC_AR_ARRAY_MUTABLE | NEBOC_AR_ARRAY_CALL_RESULT)
 jz .ok
 mov rdx,[rsi+NEBOC_AR_BIND_COUNT_OFFSET]
 test rdx,rdx
 jnz .allocate_cells
 mov edx,1                 ; E02 distinct aligned empty-result anchor.
.allocate_cells:
 mov rax,[rdi+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET]
 mov rcx,[rsi+NEBOC_AR_BIND_FLAGS_OFFSET]
 mov ecx,ecx
 inc rax
 shl rax,NEBOC_AR_ARRAY_FRAME_SHIFT
 or rcx,rax
 mov [rsi+NEBOC_AR_BIND_FLAGS_OFFSET],rcx
 dec rax
 shr rax,NEBOC_AR_ARRAY_FRAME_SHIFT
 add rax,rdx
 jc .limit
 cmp rax,NEBOC_AR_MAX_VALUES
 ja .limit
 mov [rdi+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET],rax
.ok:
 xor eax,eax
 ret
.limit:
 mov qword [rdi+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

; state*, declaration block -> status. Collection declarations are omitted
; from the shared parser's filtered token view, so reserve mutable owner cells
; directly from authenticated semantic records whose name token lies in this
; exact declaration body.
fcg_prepare_mutable_arrays_for_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .ok
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rsp+8],rcx
 xor r14d,r14d
.loop:
 cmp r14,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .ok
 mov r15,r14
 imul r15,NEBOC_AR_BIND_SIZE
 add r15,[r13+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r15+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .next
 test qword [r15+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jz .next
 test qword [r15+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jnz .next
 mov rax,[r15+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rax,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rax,[rsp]
 jb .next
 cmp rax,[rsp+8]
 jae .next
 mov rdi,rbx
 mov rsi,r15
 call fcg_prepare_mutable_collection_record
 test eax,eax
 jnz .done
.next:
 inc r14
 jmp .loop
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, loop_node_id, depth -> status. Prepare the concrete loop body in one
; child lexical scope; the loop statement itself is the exact parent boundary.
fcg_prepare_loop_bindings:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .body
 cmp rcx,NEBOC_AST_WHILE_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
.body:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r13
 mov rcx,r12
 call fcg_prepare_scoped_block
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, RangeFor node id, depth -> status.  Allocate two distinct stable
; slots before entering the lexical body: visible iterator and hidden cursor.
fcg_prepare_collection_loop_bindings:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_record_for_node
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 call fcg_resolve_identifier
 test rax,rax
 jnz .duplicate
 ; iterator slot
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_PARAMETER_BASE_OFFSET]
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 cmp rax,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 mov r14,rax
 ; hidden cursor slot
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_PARAMETER_BASE_OFFSET]
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 cmp rax,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 shl rax,32
 or rax,r14
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdx,[rsp+8]
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
 ; item -> collection -> block
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 mov rdx,r13
 mov rcx,r12
 call fcg_prepare_scoped_block
 jmp .done
.duplicate:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DUPLICATE_BINDING
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, if_node_id, depth -> status. Prepare each branch in its own lexical
; scope. Else-if nodes recursively open scopes only for their concrete blocks.
fcg_prepare_if_bindings:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 mov rcx,r12
 call fcg_prepare_scoped_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .ok
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 call fcg_prepare_if_bindings
 jmp .done
.else_block:
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r13
 mov rcx,r12
 call fcg_prepare_scoped_block
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth, parent_if_id -> status.
fcg_prepare_scoped_block:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 call fcg_scope_push
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_prepare_block_bindings
 mov r12,rax
 mov rdi,rbx
 call fcg_scope_pop
 test r12d,r12d
 jnz .prepared_status
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.prepared_status:
 mov eax,r12d
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, name_token, current_statement -> RAX nearest visible binding statement
; or zero. Search the current lexical block first, then each parent only up to
; the exact if statement that opened the child scope.
fcg_find_prior_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
 test r14,r14
 jz .current_block
 dec r14
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+r14*8]
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 jne .current_block
.scope_loop:
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+r14*8]
 mov rdi,rbx
 mov rdx,r13
 mov rcx,rsi
 mov rsi,r12
 call fcg_find_prior_binding_in_block
 test rax,rax
 jnz .done
 test r14,r14
 jz .no
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_PARENTS_OFFSET+r14*8]
 dec r14
 jmp .scope_loop
.current_block:
 mov rcx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_find_prior_binding_in_block
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, name_token, stop_statement, block_id -> RAX prior binding or zero.
fcg_find_prior_binding_in_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rsi,rcx
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r14,r14
 jz .no
 cmp r14,r13
 je .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .next
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPED_BINDING_DECLARATION
 jnz .next
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .yes
.next:
 mov r14,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.yes:
 mov rax,r14
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, assignment_statement_id, depth -> status.  Binding preparation has
; already assigned stable lexical slots to all prior declarations.  Mutation
; deliberately resolves binding statements only, so receiver/parameter slots
; cannot become mutable by accident.
fcg_validate_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 jne .bad
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_COLLECTION_ELEMENT_ASSIGNMENT
 jz .scalar_assignment
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_validate_collection_assignment
 jmp .done
.scalar_assignment:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r12
 call fcg_find_prior_binding
 test rax,rax
 jz .undeclared
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdx,rcx
 shr rdx,32
 test rdx,rdx
 jz .bad
 mov [rsp+8],rdx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .immutable
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+16],rax
 test rax,rax
 jz .operator_ok
 cmp qword [rsp+8],NEBOC_TYPE_ID_INT
 jne .compound
 cmp rax,NEBOC_TOKEN_PLUS
 je .operator_ok
 cmp rax,NEBOC_TOKEN_MINUS
 jne .compound
.operator_ok:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .type_failed
 cmp rax,[rsp+8]
 jne .type
 xor eax,eax
 jmp .done
.undeclared:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 jmp .diagnostic
.immutable:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_IMMUTABLE
 jmp .diagnostic
.compound:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_COMPOUND
 jmp .diagnostic
.type:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
 jmp .diagnostic
.type_failed:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .failed
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
.diagnostic:
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
.failed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, assignment statement, depth -> status for the exact existing-token
; `mutableArray.at(Int) = scalar` surface. Slice/borrowed/immutable targets and
; compound/whole-collection forms remain rejected.
fcg_validate_collection_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .bad
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_at]
 mov ecx,fcg_name_collection_at_len
 call fcg_token_matches_literal
 test eax,eax
 jz .bad
 mov r14,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .undeclared
 mov [rsp],rax
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .immutable
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jz .immutable
 mov rcx,[rax+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rcx,NEBOC_AR_TYPE_INT
 je .type_int
 cmp rcx,NEBOC_AR_TYPE_BOOL
 je .type_bool
 cmp rcx,NEBOC_AR_TYPE_CHAR
 jne .type
 mov qword [rsp+8],NEBOC_TYPE_ID_CHAR
 jmp .index
.type_int:
 mov qword [rsp+8],NEBOC_TYPE_ID_INT
 jmp .index
.type_bool:
 mov qword [rsp+8],NEBOC_TYPE_ID_BOOL
.index:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 mov [rsp+16],r14
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_dynamic_index_is_material
 test eax,eax
 jz .type
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .type
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .rhs
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rsp]
 cmp rcx,[rdx+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .bounds
.rhs:
 mov rsi,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov [rsp+24],rsi
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .type_failed
 cmp rax,[rsp+8]
 jne .type
 xor eax,eax
 jmp .done
.undeclared:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 jmp .diagnostic_statement
.immutable:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_IMMUTABLE
 jmp .diagnostic_statement
.bounds:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_capture_node_span
 jmp .failed
.type:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
 jmp .failed
.type_failed:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .failed
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
.diagnostic_statement:
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
.failed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> EAX 1 when an if/else subtree contains a binding.
fcg_contains_nested_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .yes
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .yes
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .yes
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r15,r15
 jz .no
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_contains_nested_binding
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .yes
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.no:
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, binding_statement_id, depth -> status.
; state*, declaration block -> status. Emit literal initialization once per
; invocation for every authenticated mutable Array owned by this body.
fcg_emit_mutable_array_initializers_for_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .ok
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET],0
 je .ok
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rsp+8],rcx
 xor r14d,r14d
.loop:
 cmp r14,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .ok
 mov r15,r14
 imul r15,NEBOC_AR_BIND_SIZE
 add r15,[r13+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r15+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .next
 test qword [r15+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jz .next
 mov rax,[r15+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rax,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rax,[rsp]
 jb .next
 cmp rax,[rsp+8]
 jae .next
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r12
 call fcg_collection_record_in_exact_block
 test eax,eax
 jz .next
 mov rdi,rbx
 mov rsi,r15
 call fcg_emit_mutable_record_initializer
 test eax,eax
 jnz .done
.next:
 inc r14
 jmp .loop
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, collection record, block id -> EAX 1 only when the supplied block is
; the smallest AST block containing the record's declaration token.
fcg_collection_record_in_exact_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .no
 mov rcx,[r12+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rcx,[rax+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,[rax+NEBOC_AR_TOKENS_OFFSET]
 mov r12,[rcx+NEBOC_TOKEN_START_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .no
 mov r15,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov qword [rsp],0
 mov qword [rsp+8],-1
 mov r14,1
.loop:
 cmp r14,r15
 ja .found
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .next
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp r12,rcx
 jb .next
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp r12,rdx
 jae .next
 sub rdx,rcx
 cmp rdx,[rsp+8]
 jae .next
 mov [rsp+8],rdx
 mov [rsp],r14
.next:
 inc r14
 jmp .loop
.found:
 cmp [rsp],r13
 je .yes
 ; The driver materializes the same top-level body through two bounded AST
 ; views when collection/function verticals compose.  Those block nodes have
 ; distinct internal ids but the same immutable source span.  Treat that
 ; exact span identity as the same lexical block; otherwise a preceding
 ; Slice-return function can suppress initialization of a mutable owner in
 ; `start`.  Nested/sibling scopes remain distinct because either endpoint
 ; differs.
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rcx,[r14+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 jne .no
 mov rcx,[r14+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 jne .no
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, exact recursive body block -> EAX 1 when any authenticated
; Array/Range/Slice/Bytes collection record belongs to that body.  Collection
; declarations are deliberately filtered from the shared statement AST, so
; the NPT-LANG-35 exact-one-if/else gate must also consult their semantic
; owner records to keep the selected scalar-only surface closed.
fcg_recursion_block_has_collection_record:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 xor r14d,r14d
.loop:
 cmp r14,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov r15,r14
 imul r15,NEBOC_AR_BIND_SIZE
 add r15,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 mov rdx,r12
 call fcg_collection_record_in_exact_block
 test eax,eax
 jnz .yes
 inc r14
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, mutable Array record -> status.
fcg_emit_mutable_record_initializer:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp],rax
 xor r13d,r13d
.loop:
 cmp r13,[r12+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .ok
 mov rax,[r12+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r13
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 cmp rax,[rdx+NEBOC_AR_VALUE_COUNT_OFFSET]
 jae .bad
 mov rcx,[rdx+NEBOC_AR_VALUES_OFFSET]
 mov r14,[rcx+rax*8]
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r14
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 shl rsi,3
 mov rax,[rsp]
 sub rax,rsi
 mov rsi,rax
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r13
 jmp .loop
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, collection binding statement -> status. Immutable records remain
; emission no-ops; a mutable Array copies its authenticated literal values
; once into its invocation-owned qword payload.
fcg_emit_collection_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_binding_record
 test rax,rax
 jz .bad
 mov r13,rax
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .check_array_binding
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_array_result_binding
 jmp .done
.check_array_binding:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .ok
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .literal_array
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_array_result_binding
 jmp .done
.literal_array:
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jz .ok
 mov rdi,rbx
 mov rsi,r13
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp],rax
 xor r14d,r14d
.loop:
 cmp r14,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .ok
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r14
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 cmp rax,[rdx+NEBOC_AR_VALUE_COUNT_OFFSET]
 jae .bad
 mov rcx,[rdx+NEBOC_AR_VALUES_OFFSET]
 mov r15,[rcx+rax*8]
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r14
 shl rsi,3
 mov rax,[rsp]
 sub rax,rsi
 mov rsi,rax
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r14
 jmp .loop
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, binding statement, authenticated caller-owned result record -> status.
; Evaluate source receiver/arguments once left-to-right, prepend the hidden
; destination pointer, and preserve the established register order.  The only
; stack case is source arity six (hidden + six physical arguments).
fcg_emit_array_result_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_resolve_call
 test rax,rax
 jz .unsupported
 mov [rsp],rax               ; callee symbol
 mov [rsp+8],rdx             ; exact return type
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .validate_array_result
 mov rdi,[rsp+8]
 call fcg_slice_type_decode
 test eax,eax
 jz .bad
 cmp rdx,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 jne .bad
 jmp .result_type_valid
.validate_array_result:
 mov rdi,r13
 call fcg_array_type_from_record
 cmp rax,[rsp+8]
 jne .bad
.result_type_valid:
 mov rdi,rbx
 mov rsi,r13
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp+16],rax            ; caller destination displacement
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rax
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS
 ja .parameter
 mov [rsp+24],rax            ; source receiver + explicit args
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+32],0
.eval:
 mov rax,[rsp+32]
 cmp rax,[rsp+24]
 jae .prepare_registers
 test r15,r15
 jz .bad
 mov rax,[rsp+32]
 test rax,rax
 jz .eval_temp_ready
 dec rax
.eval_temp_ready:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET],rax
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+32]
 jmp .eval
.prepare_registers:
 mov qword [rsp+40],0        ; has physical stack argument
 cmp qword [rsp+24],6
 jne .pop_registers
 mov rdi,rbx
 lea rsi,[rel fcg_pop_r10_value]
 mov edx,fcg_pop_r10_value_len
 call fcg_append
 test eax,eax
 jnz .done
 mov qword [rsp+40],1
 dec qword [rsp+24]
.pop_registers:
 mov rax,[rsp+24]
 mov [rsp+32],rax
.pop_loop:
 cmp qword [rsp+32],0
 je .destination
 dec qword [rsp+32]
 mov r10,[rsp+32]
 lea rax,[rel fcg_sret_pop_ptrs]
 mov rsi,[rax+r10*8]
 lea rax,[rel fcg_sret_pop_lens]
 mov rdx,[rax+r10*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 jmp .pop_loop
.destination:
 cmp qword [rsp+40],0
 je .dest_lea
 mov rdi,rbx
 lea rsi,[rel fcg_sret_stack_arg]
 mov edx,fcg_sret_stack_arg_len
 call fcg_append
 test eax,eax
 jnz .done
.dest_lea:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_dest_rdi]
 mov edx,fcg_sret_dest_rdi_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp]
 call neboc_abi_adapter_emit_prepared_call
 test eax,eax
 jnz .abi
 cmp qword [rsp+40],0
 je .ok
 mov rdi,rbx
 lea rsi,[rel fcg_sret_stack_restore]
 mov edx,fcg_sret_stack_restore_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, BindingStmt id -> EAX boolean for the exact compiler-private scalar
; anchor paired with one authenticated scientific helper result.
fcg_is_scientific_binding:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp r12,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 imul r12,NEBOC_TOKEN_SIZE
 add r12,[rbx+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
 mov r13,[r12+NEBOC_TOKEN_START_OFFSET]
 mov r12,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_RESULT_STARTS_OFFSET]
 test r12,r12
 jz .no
 xor r14d,r14d
.loop:
 cmp r14,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNER_COUNT_OFFSET]
 jae .no
 mov rax,[r12+r14*8]
 test rax,rax
 jz .next
 cmp rax,r13
 je .yes
.next:
 inc r14
 jmp .loop
.yes:
 mov ecx,NEBOC_TYPE_ID_INT
 mov rax,r14
 imul rax,NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCIENTIFIC_OWNERS_OFFSET]
 cmp qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_NONE
 je .typed
 cmp qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION0_OFFSET],NEBOC_MATRIX_OPERATION_IS_SQUARE
 je .bool
 cmp qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION1_OFFSET],NEBOC_MATRIX_OPERATION_IS_SQUARE
 jne .typed
.bool:
 mov ecx,NEBOC_TYPE_ID_BOOL
.typed:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, scientific BindingStmt id -> status.  The immediately preceding
; helper call leaves the authenticated scalar in RAX, so emit only the normal
; lexical-slot store and never evaluate the private zero-shaped AST anchor.
fcg_emit_scientific_binding:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .bad
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,eax
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

fcg_emit_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,eax
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, assignment_statement_id, depth -> status.  Validation has proved an
; exact mutable lexical local and compatible RHS.  Evaluate the RHS once and
; emit exactly one store to the existing frame slot.
fcg_emit_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 jne .bad
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_COLLECTION_ELEMENT_ASSIGNMENT
 jz .scalar_assignment
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_collection_assignment
 jmp .done
.scalar_assignment:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r12
 call fcg_find_prior_binding
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,ecx
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+8],rax
 test rax,rax
 jz .rhs
 mov rdi,rbx
 lea rsi,[rel fcg_load_slot]
 mov edx,fcg_load_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
.rhs:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[rsp+8]
 test rax,rax
 jz .store
 mov rdi,rbx
 lea rsi,[rel fcg_restore_binary]
 mov edx,fcg_restore_binary_len
 call fcg_append
 test eax,eax
 jnz .done
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 cmp qword [rsp+8],NEBOC_TOKEN_PLUS
 je .add
 mov rdi,rbx
 lea rsi,[rel fcg_sub]
 mov edx,fcg_sub_len
 call fcg_append
 jmp .compound_done
.add:
 mov rdi,rbx
 lea rsi,[rel fcg_add]
 mov edx,fcg_add_len
 call fcg_append
.compound_done:
 test eax,eax
 jnz .done
.store:
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, element assignment, depth -> status. Validation has frozen exact
; target/index/RHS types. Emit base, index and all guards before evaluating the
; RHS, then perform exactly one qword element store.
fcg_emit_collection_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 mov r14,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .bad
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_mutable_receiver]
 mov edx,fcg_dynamic_mutable_receiver_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_receiver_tail]
 mov edx,fcg_dynamic_receiver_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_r10]
 mov edx,fcg_push_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_pop_r10]
 mov edx,fcg_pop_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_index_lower]
 mov edx,fcg_dynamic_index_lower_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_local_upper]
 mov edx,fcg_dynamic_local_upper_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,[rsp]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_upper_branch]
 mov edx,fcg_dynamic_upper_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_local_stride]
 mov edx,fcg_dynamic_local_stride_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,8
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_checked_multiply]
 mov edx,fcg_dynamic_checked_multiply_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_dynamic_checked_frame_add]
 mov edx,fcg_dynamic_checked_frame_add_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 ; Preserve the proven address while evaluating the RHS exactly once.
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_r10]
 mov edx,fcg_push_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rsi,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_pop_store_r10]
 mov edx,fcg_pop_store_r10_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, return_statement_id, depth -> status.  Exit-flow analysis has already
; proved that every scalar path is type-consistent and that no statement is
; reachable after this terminal.
fcg_emit_return_statement:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 mov rdi,rax
 call fcg_array_type_decode
 test eax,eax
 jnz .array
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 call fcg_slice_type_decode
 test eax,eax
 jz .scalar
 mov rdi,rbx
 call fcg_emit_slice_return
 test eax,eax
 jnz .done
 jmp .jump
.array:
 mov rdi,rbx
 ; RSI remains the exact return expression node.
 call fcg_emit_array_return
 test eax,eax
 jnz .done
 jmp .jump
.scalar:
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
.jump:
 mov rdi,rbx
 lea rsi,[rel fcg_return_jump]
 mov edx,fcg_return_jump_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_RETURN_LABEL_REFERENCE_COUNT_OFFSET]
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, identifier expression naming the callee-owned Array -> status.
; Copy exactly N qwords into the hidden caller destination, return its exact
; address in RAX, and perform zero payload memory operations for N=0.
fcg_emit_array_return:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jnz .record_found
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_direct_array_binding_for_node
 test rax,rax
 jz .bad
.record_found:
 mov r13,rax
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jnz .unsupported             ; forwarding remains deliberately closed.
 mov rdi,r13
 call fcg_array_type_from_record
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 jne .bad
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET]
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_sret_load_r11]
 mov edx,fcg_sret_load_r11_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r13
 call fcg_mutable_record_frame_byte
 mov [rsp+8],rax              ; zero means immutable semantic payload.
 xor r14d,r14d
.copy_loop:
 cmp r14,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .return_pointer
 cmp qword [rsp+8],0
 jne .frame_load
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r14
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 cmp rax,[rdx+NEBOC_AR_VALUE_COUNT_OFFSET]
 jae .bad
 mov rcx,[rdx+NEBOC_AR_VALUES_OFFSET]
 mov r15,[rcx+rax*8]
 mov rdi,rbx
 lea rsi,[rel fcg_sret_imm_r10]
 mov edx,fcg_sret_imm_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 jmp .load_tail
.frame_load:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_frame_r10]
 mov edx,fcg_sret_frame_r10_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,r14
 shl rax,3
 mov rsi,[rsp+8]
 sub rsi,rax
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store
.load_tail:
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
.store:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_store_prefix]
 mov edx,fcg_sret_store_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r14
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_sret_store_suffix]
 mov edx,fcg_sret_store_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r14
 jmp .copy_loop
.return_pointer:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_rax]
 mov edx,fcg_sret_rax_len
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, identifier naming an authenticated S04 input/derivative -> status.
; Copy exactly the canonical five descriptor qwords to the hidden destination.
fcg_emit_slice_return:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 mov r13,rax
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RETURN_SOURCE
 jz .unsupported
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .direct
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .unsupported
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jz .unsupported
 mov qword [rsp+24],1
 mov rax,[r13+NEBOC_AR_BIND_START_OFFSET]
 mov [rsp+16],rax
 jmp .root
.direct:
 mov qword [rsp+24],0
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 mov rax,r13
 sub rax,[rdx+NEBOC_AR_BINDINGS_OFFSET]
 jc .bad
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .bad
 mov [rsp+16],rax
.root:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 mov rcx,[rsp+16]
 cmp rcx,[rax+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .bad
 imul rcx,NEBOC_AR_BIND_SIZE
 add rcx,[rax+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rcx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 jne .unsupported
 mov [rsp+8],rcx
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_RETURN_TYPE_OFFSET]
 call fcg_slice_type_decode
 test eax,eax
 jz .bad
 mov rcx,[rsp+8]
 cmp rdx,[rcx+NEBOC_AR_BIND_TYPE_OFFSET]
 jne .bad
 mov rdi,rbx
 mov rsi,[rcx+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_resolve_ar_name_slot
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SRET_SLOT_OFFSET]
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp+32],rax
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_source]
 mov edx,fcg_slice_sret_source_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_sret_load_r11]
 mov edx,fcg_sret_load_r11_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+32]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+24],0
 je .copy
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jc .bad
 mov [rsp+40],rax
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_guard]
 mov edx,fcg_slice_sret_guard_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+40]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_guard_tail]
 mov edx,fcg_slice_sret_guard_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
.copy:
 xor r14d,r14d
.copy_loop:
 cmp r14,5
 jae .return_pointer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_load]
 mov edx,fcg_slice_sret_load_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r14
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_load_end]
 mov edx,fcg_slice_sret_load_end_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+24],0
 je .store
 cmp r14,0
 jne .derived_length
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 shl rax,3
 test rax,rax
 jz .store
 mov [rsp+40],rax
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_add]
 mov edx,fcg_slice_sret_add_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+40]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store
.derived_length:
 cmp r14,1
 jne .store
 mov rdi,rbx
 lea rsi,[rel fcg_slice_sret_imm]
 mov edx,fcg_slice_sret_imm_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
.store:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_store_prefix]
 mov edx,fcg_sret_store_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r14
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_sret_store_suffix]
 mov edx,fcg_sret_store_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r14
 jmp .copy_loop
.return_pointer:
 mov rdi,rbx
 lea rsi,[rel fcg_sret_rax]
 mov edx,fcg_sret_rax_len
 call fcg_append
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, original semantic token index -> local slot/type via exact source
; occurrence in the filtered AST token view.
fcg_resolve_ar_name_slot:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 xor r13d,r13d
.scan:
 cmp r13,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r12
 call fcg_token_same_ar_occurrence
 test eax,eax
 jnz .found
 inc r13
 jmp .scan
.found:
 mov rdi,rbx
 mov rsi,r13
 call fcg_resolve_identifier
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, loop_node_id, depth -> status. Stable AST ids name the exact lexical
; header/exit pair, while the bounded target stack owns break/continue.
fcg_emit_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 cmp r14,NEBOC_AST_LOOP_STMT
 je .body_known
 cmp r14,NEBOC_AST_WHILE_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp],rax
 jmp .push_target
.body_known:
 mov [rsp],r15
.push_target:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_LOOP_DEPTH
 jae .depth
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_STACK_OFFSET+rax*8],r12
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,rbx
 lea rsi,[rel fcg_loop_header_label]
 mov edx,fcg_loop_header_label_len
 call fcg_append
 test eax,eax
 jnz .pop
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .pop
 cmp r14,NEBOC_AST_WHILE_STMT
 jne .emit_body
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .pop
 mov rdi,rbx
 lea rsi,[rel fcg_loop_test_exit]
 mov edx,fcg_loop_test_exit_len
 call fcg_append
 test eax,eax
 jnz .pop
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .pop
.emit_body:
 mov rdi,rbx
 mov rsi,[rsp]
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_emit_scoped_block
 test eax,eax
 jnz .pop
 mov rdi,rbx
 lea rsi,[rel fcg_loop_jump_header]
 mov edx,fcg_loop_jump_header_len
 call fcg_append
 test eax,eax
 jnz .pop
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .pop
 mov rdi,rbx
 lea rsi,[rel fcg_loop_exit_label]
 mov edx,fcg_loop_exit_label_len
 call fcg_append
 test eax,eax
 jnz .pop
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .pop
 xor eax,eax
.pop:
 mov [rsp+8],rax
 dec qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rax,[rsp+8]
 jmp .done
.writer_pop:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .pop
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, RangeFor node id, depth -> status.  The semantic record is immutable;
; frame slots carry only the current cursor and iterator value.
fcg_emit_collection_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_collection_record_for_node
 test rax,rax
 jz .bad
 mov r14,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov edx,ecx
 shr rcx,32
 test edx,edx
 jz .bad
 test ecx,ecx
 jz .bad
 mov [rsp],rdx                 ; iterator slot
 mov [rsp+8],rcx               ; cursor slot
 ; locate the body (item -> collection -> block)
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+24],0
 mov qword [rsp+32],0
 cmp qword [r14+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 jne .collection_slot_ready
 test qword [r14+NEBOC_FOR_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jnz .result_collection_slot
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 jmp .collection_slot_ready
.result_collection_slot:
 mov rdi,rbx
 mov rsi,r15
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .bad
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 mov qword [rsp+32],1
.collection_slot_ready:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .bad
 ; cursor = 0
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 ; header and bounded count test
 mov rdi,rbx
 lea rsi,[rel fcg_collection_header]
 mov edx,fcg_collection_header_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_collection_load_cursor]
 mov edx,fcg_collection_load_cursor_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [r14+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .dynamic_count
 mov rdi,rbx
 lea rsi,[rel fcg_collection_cmp]
 mov edx,fcg_collection_cmp_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_FOR_COUNT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_jae]
 mov edx,fcg_collection_jae_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .count_done
.dynamic_count:
 ; Dynamic Slice length comes from the call-bounded descriptor.
 mov rdi,rbx
 cmp qword [rsp+32],0
 jne .dynamic_result_count
 lea rsi,[rel fcg_collection_param_cmp]
 mov edx,fcg_collection_param_cmp_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 jmp .dynamic_count_offset_done
.dynamic_result_count:
 lea rsi,[rel fcg_slice_desc_frame_base]
 mov edx,fcg_slice_desc_frame_base_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_assembly_writer_append_u64_decimal
.dynamic_count_offset_done:
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_param_cmp_tail]
 mov edx,fcg_collection_param_cmp_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_collection_jae]
 mov edx,fcg_collection_jae_len
 call fcg_append
 test eax,eax
 jnz .done
.count_done:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 ; one element materialization
 cmp qword [r14+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .array
 mov rdi,rbx
 lea rsi,[rel fcg_collection_range_a]
 mov edx,fcg_collection_range_a_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_FOR_STEP_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_range_b]
 mov edx,fcg_collection_range_b_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_FOR_START_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store_item
.array:
 cmp qword [r14+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_array
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test qword [rax+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_DYNAMIC_AT
 jz .legacy_array
 mov rcx,[r14+NEBOC_FOR_COLLECTION_INDEX_OFFSET]
 cmp rcx,[rax+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .bad
 mov [rsp+32],rcx
 imul rcx,NEBOC_AR_BIND_SIZE
 add rcx,[rax+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+40],rcx
 mov rdi,rbx
 mov rsi,rcx
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .immutable_collection_loop_load
 mov [rsp+40],rax
 mov rdi,rbx
 lea rsi,[rel fcg_collection_frame_load]
 mov edx,fcg_collection_frame_load_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+40]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_frame_index]
 mov edx,fcg_collection_frame_index_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store_item
.immutable_collection_loop_load:
 mov rcx,[rsp+40]
 cmp qword [rcx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .canonical_array_loop_load
 cmp qword [rcx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .bad
 mov rdi,rbx
 lea rsi,[rel fcg_collection_canonical_slice_a]
 mov edx,fcg_collection_canonical_slice_a_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .canonical_loop_label
.canonical_array_loop_load:
 mov rdi,rbx
 lea rsi,[rel fcg_collection_canonical_array_a]
 mov edx,fcg_collection_canonical_array_a_len
 call fcg_append
 test eax,eax
 jnz .done
.canonical_loop_label:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+32]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_array_b]
 mov edx,fcg_collection_array_b_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store_item
.legacy_array:
 mov rdi,rbx
 lea rsi,[rel fcg_collection_array_a]
 mov edx,fcg_collection_array_a_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_array_b]
 mov edx,fcg_collection_array_b_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .store_item
.parameter_array:
 mov rdi,rbx
 cmp qword [rsp+32],0
 jne .result_parameter_array
 lea rsi,[rel fcg_collection_param_cmp]
 mov edx,fcg_collection_param_cmp_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 jmp .parameter_array_offset_done
.result_parameter_array:
 lea rsi,[rel fcg_slice_desc_frame_base]
 mov edx,fcg_slice_desc_frame_base_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_assembly_writer_append_u64_decimal
.parameter_array_offset_done:
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_collection_param_load_tail]
 mov edx,fcg_collection_param_load_tail_len
 call fcg_append
 test eax,eax
 jnz .done
.store_item:
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 ; bounded target stack and lexical body
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_LOOP_DEPTH
 jae .depth
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_STACK_OFFSET+rax*8],r12
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_emit_scoped_block
 mov [rsp+16],rax
 dec qword [rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rax,[rsp+16]
 test eax,eax
 jnz .done
 ; continue/latch increments exactly once
 mov rdi,rbx
 lea rsi,[rel fcg_collection_latch]
 mov edx,fcg_collection_latch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_collection_inc]
 mov edx,fcg_collection_inc_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_loop_jump_header]
 mov edx,fcg_loop_jump_header_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_collection_exit]
 mov edx,fcg_collection_exit_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, break_or_continue_node_id -> status.
fcg_emit_loop_control:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_DEPTH_OFFSET]
 test rax,rax
 jz .control
 dec rax
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_LOOP_STACK_OFFSET+rax*8]
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BREAK_STMT
 je .break
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CONTINUE_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 jne .ordinary_continue
 lea rsi,[rel fcg_collection_jump_latch]
 mov edx,fcg_collection_jump_latch_len
 jmp .emit
.ordinary_continue:
 lea rsi,[rel fcg_loop_jump_header]
 mov edx,fcg_loop_jump_header_len
 jmp .emit
.break:
 lea rsi,[rel fcg_loop_jump_exit]
 mov edx,fcg_loop_jump_exit_len
.emit:
 mov rdi,rbx
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth, parent_if_id -> status. Emit a nested block with the
; same lexical visibility used by preparation and exit-flow analysis.
fcg_emit_scoped_block:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 call fcg_scope_push
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_emit_nested_block
 mov r12,rax
 mov rdi,rbx
 call fcg_scope_pop
 test r12d,r12d
 jnz .emission_status
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.emission_status:
 mov eax,r12d
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, if_node_id, depth -> status. Branch labels use the stable AST node ID.
fcg_emit_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .control
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_test]
 mov edx,fcg_if_test_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_emit_scoped_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_jump_end]
 mov edx,fcg_if_jump_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_else_label]
 mov edx,fcg_if_else_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .no_else
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_if
 jmp .after_else
.else_block:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 mov rcx,r12
 call fcg_emit_scoped_block
 jmp .after_else
.no_else:
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
.after_else:
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_end_label]
 mov edx,fcg_if_end_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_BRANCH_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth -> status. Nested branch blocks support bindings,
; expressions, returns and nested if/else within their active lexical scope.
fcg_emit_nested_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_emit_mutable_array_initializers_for_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0
.loop:
 test r14,r14
 jz .finish
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_EXPRESSION_STMT
 je .expr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .binding
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 je .assignment
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .if
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 je .loop_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .loop_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 je .collection_loop_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BREAK_STMT
 je .loop_control
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CONTINUE_STMT
 je .loop_control
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 je .return
 jmp .scope
.expr:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 jmp .emitted
.binding:
 mov rdi,rbx
 mov rsi,r14
 call fcg_is_collection_binding
 cmp eax,2
 je .buffer_binding_noop
 test eax,eax
 jnz .binding_noop
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_binding
 jmp .emitted
.buffer_binding_noop:
 xor eax,eax
 jmp .emitted
.binding_noop:
 mov rdi,rbx
 mov rsi,r14
 call fcg_emit_collection_binding
 jmp .emitted
.assignment:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_assignment
 jmp .emitted
.if:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_if
 jmp .emitted
.loop_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_loop
 jmp .emitted
.collection_loop_statement:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_collection_loop
 jmp .emitted
.loop_control:
 mov rdi,rbx
 mov rsi,r14
 call fcg_emit_loop_control
 jmp .emitted
.return:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_return_statement
.emitted:
 test eax,eax
 jnz .done
 inc qword [rsp]
 mov r14,r15
 jmp .loop
.finish:
 cmp qword [rsp],0
 jne .ok
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.scope:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, token_id, literal*, literal_len -> EAX 1/0.
fcg_token_matches_literal:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,rbx
 mov rsi,r12
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r14
 jne .no
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r13
 cld
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; state*, identifier node -> EAX 1 after materializing exactly one caller-owned
; 40-byte Slice descriptor, zero when the identifier is not a local Slice.
fcg_emit_slice_descriptor:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 mov r13,rax
 mov r14,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 mov rax,r13
 sub rax,[r14+NEBOC_AR_BINDINGS_OFFSET]
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 mov [rsp],rax                 ; deterministic binding ordinal / data label
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET]
 cmp rax,5
 jae .bad
 imul rax,5
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SLICE_TEMP_BASE_OFFSET]
 add rax,5
 shl rax,3
 mov [rsp+8],rax               ; descriptor base frame byte offset
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .materialize_local
 mov rdi,rbx
 mov rsi,r13
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_copy_source]
 mov edx,fcg_slice_result_copy_source_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.result_copy_loop:
 cmp r15,5
 jae .result_copy_pointer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_copy_load]
 mov edx,fcg_slice_result_copy_load_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 shl rsi,3
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_copy_store]
 mov edx,fcg_slice_result_copy_store_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,r15
 shl rax,3
 mov rsi,[rsp+8]
 sub rsi,rax
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_result_copy_store_tail]
 mov edx,fcg_slice_result_copy_store_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 jmp .result_copy_loop
.result_copy_pointer:
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_pointer]
 mov edx,fcg_slice_desc_pointer_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov eax,1
 jmp .done
.materialize_local:
 mov rdi,rbx
 mov rsi,r13
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .static_base
 mov [rsp+16],rax
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_frame_base]
 mov edx,fcg_slice_desc_frame_base_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 jmp .base_store
.static_base:
 test qword [r14+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_DYNAMIC_AT
 jnz .canonical_base
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_base]
 mov edx,fcg_slice_desc_base_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .base_label
.canonical_base:
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_canonical_base]
 mov edx,fcg_slice_desc_canonical_base_len
 call fcg_append
 test eax,eax
 jnz .done
.base_label:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
.base_store:
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_store]
 mov edx,fcg_slice_desc_store_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 test eax,eax
 jnz .done
 ; length, stride, generation and token occupy the remaining four qwords.
 mov rdi,rbx
 mov rsi,[rsp+8]
 sub rsi,8
 mov rdx,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 call fcg_emit_slice_desc_qword
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+8]
 sub rsi,16
 ; Generated Array/Slice payloads are frozen qword cells for every admitted
 ; scalar element family (NPT-LANG-20 CURRENT_ARRAY_ELEMENT_STRIDE=8).
 ; Preserve that physical source stride in the transported descriptor.
 mov edx,8
 call fcg_emit_slice_desc_qword
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+8]
 sub rsi,24
 mov rdx,[r13+NEBOC_AR_BIND_END_OFFSET]
 call fcg_emit_slice_desc_qword
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+8]
 sub rsi,32
 mov rdx,[r13+NEBOC_AR_BIND_STEP_OFFSET]
 call fcg_emit_slice_desc_qword
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_pointer]
 mov edx,fcg_slice_desc_pointer_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+8]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 test eax,eax
 jnz .done
 mov eax,1
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, frame byte offset, immediate qword -> status.
fcg_emit_slice_desc_qword:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_length]
 mov edx,fcg_slice_desc_length_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_desc_assign]
 mov edx,fcg_slice_desc_assign_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; state*, identifier node -> direct function-block Array record or zero.  This
; is the bounded standalone-return lookup: collection receivers already use
; the more general lexical resolver below, while a bare Array identifier had
; no pre-B01 public consumer.  Exact-block authentication prevents publishing
; branch-local escape as a side effect.
fcg_find_direct_array_binding_for_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_find_block
 test rax,rax
 jz .no
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+8],rax
 xor r15d,r15d
.loop:
 cmp r15,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,r15
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .next
 mov rdx,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rdx,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .next
 mov rcx,rdx
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov rcx,[rcx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,[rsp+8]
 jae .next
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+16]
 mov rdx,[rdx+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_token_matches_ar_token
 mov rcx,[rsp+8]
 test eax,eax
 jz .next
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov rdx,[rsp]
 call fcg_collection_record_in_exact_block
 test eax,eax
 jz .next
 mov rax,[rsp+16]
 jmp .done
.next:
 inc r15
 jmp .loop
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, receiver identifier node -> authenticated collection binding record
; or zero. The current declaration block span is the lexical authority.
fcg_find_collection_binding_for_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 test rsi,rsi
 jnz .declaration_scope
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 test rsi,rsi
 jz .no
 jmp .scope_node
.declaration_scope:
 mov rdi,rbx
 call fcg_find_block
 test rax,rax
 jz .no
 mov rsi,rax
.scope_node:
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp],rdx
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rsp+8],rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r14
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+24],rax
 xor r15d,r15d
.loop:
 cmp r15,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,r15
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp+16],rax
 mov rdx,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rdx,NEBOC_AR_UNBOUND_NAME
 je .next
 cmp rdx,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .next
 mov rcx,rdx
 imul rcx,NEBOC_TOKEN_SIZE
 add rcx,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov rax,[rcx+NEBOC_TOKEN_START_OFFSET]
 cmp qword [rsp+16],0
 je .next
 mov rdx,[rsp+16]
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_scope
 cmp rax,[rsp+24]
 jae .next
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 jne .function_local_scope
 ; start() already tracks the exact current lexical block directly.
 cmp rax,[rsp]
 jb .next
 mov rax,[rcx+NEBOC_TOKEN_END_OFFSET]
 cmp rax,[rsp+8]
 ja .next
 jmp .match_name
.function_local_scope:
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov rdx,r12
 call fcg_collection_binding_in_active_scope
 test eax,eax
 jz .next
 jmp .match_name
.parameter_scope:
 ; A parameter is declared immediately before the function block.  The exact
 ; name/type and owning body token were authenticated in both AST and semantic
 ; header scans, preventing same-name parameters from another declaration.
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 je .next
 cmp rax,[rsp]
 jae .next
 mov rdx,[rsp+16]
 mov rdx,[rdx+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 cmp rdx,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .next
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov rax,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,[rsp]
 jb .next
 cmp rax,[rsp+8]
 ja .next
.match_name:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+16]
 mov rdx,[rdx+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_token_matches_ar_token
 test eax,eax
 jz .next
 mov rax,[rsp+16]
 jmp .done
.next:
 inc r15
 jmp .loop
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, semantic collection record, receiver node -> EAX 1 only when the
; record's source declaration belongs to the innermost AST block that is
; currently active, or when a whole-function analysis pass is inspecting a
; receiver in that same exact lexical block.
; The semantic collection scanner retains source tokens but not AST parents;
; choosing the smallest containing block reconstructs that exact lexical
; owner and prevents a sibling/expired branch Slice from resolving through the
; function-root block that also contains it.
fcg_collection_binding_in_active_scope:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+16],rsi
 mov [rsp+24],rdx
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 mov rax,[r12+NEBOC_AR_BIND_NAME_OFFSET]
 cmp rax,[r13+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_AR_TOKENS_OFFSET]
 mov r12,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov qword [rsp],0             ; innermost containing block id
 mov qword [rsp+8],-1          ; smallest containing source span
 mov r14,1
.block_loop:
 cmp r14,r13
 ja .block_done
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .block_next
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .block_next
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp r12,rcx
 jb .block_next
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp r12,rdx
 jae .block_next
 sub rdx,rcx
 cmp rdx,[rsp+8]
 jae .block_next
 mov [rsp+8],rdx
 mov [rsp],r14
.block_next:
 inc r14
 jmp .block_loop
.block_done:
 cmp qword [rsp],0
 je .no
 xor r14d,r14d
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
.active_loop:
 cmp r14,r15
 jae .analysis_fallback
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+r14*8]
 cmp rax,[rsp]
 je .yes
 inc r14
 jmp .active_loop
.analysis_fallback:
 ; Exit-flow/type collection walks can run with only the function-root scope
 ; active.  Authenticate such a receiver by proving that its own innermost
 ; source block is exactly the declaration owner's block reconstructed above.
 ; This cannot leak a sibling or expired branch binding.
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov qword [rsp+24],0
 mov qword [rsp+8],-1
 mov r14,1
.receiver_block_loop:
 cmp r14,r13
 ja .receiver_block_done
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .receiver_block_next
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .receiver_block_next
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp r12,rcx
 jb .receiver_block_next
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp r12,rdx
 jae .receiver_block_next
 sub rdx,rcx
 cmp rdx,[rsp+8]
 jae .receiver_block_next
 mov [rsp+8],rdx
 mov [rsp+24],r14
.receiver_block_next:
 inc r14
 jmp .receiver_block_loop
.receiver_block_done:
 mov rax,[rsp+24]
 cmp rax,[rsp]
 jne .no
 test rax,rax
 jz .no
 jmp .yes
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Pure range-length oracle over an authenticated semantic record.
fcg_collection_range_length:
 mov r8,[rdi+NEBOC_AR_BIND_START_OFFSET]
 mov r9,[rdi+NEBOC_AR_BIND_END_OFFSET]
 mov r10,[rdi+NEBOC_AR_BIND_STEP_OFFSET]
 test r10,r10
 jz .bad
 cmp r8,r9
 je .equal
 jl .ascending
 test r10,r10
 jns .bad
 mov rax,r8
 sub rax,r9
 jo .bad
 mov rcx,r10
 neg rcx
 jo .bad
 jmp .divide
.ascending:
 test r10,r10
 jle .bad
 mov rax,r9
 sub rax,r8
 jo .bad
 mov rcx,r10
.divide:
 xor edx,edx
 div rcx
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .inclusive
 test rdx,rdx
 jz .ok
 inc rax
 jo .bad
 jmp .ok
.inclusive:
 inc rax
 jo .bad
 jmp .ok
.equal:
 xor eax,eax
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jz .ok
 inc eax
.ok:
 xor edx,edx
 ret
.bad:
 xor eax,eax
 mov edx,1
 ret

; Pure membership oracle over the same authenticated Range record.
; RDI=record, RSI=constant candidate -> RAX Bool, EDX status.
fcg_collection_range_contains:
 mov r8,[rdi+NEBOC_AR_BIND_START_OFFSET]
 mov r9,[rdi+NEBOC_AR_BIND_END_OFFSET]
 mov r10,[rdi+NEBOC_AR_BIND_STEP_OFFSET]
 test r10,r10
 jz .contains_bad
 js .contains_descending
 cmp rsi,r8
 jl .contains_no
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .contains_ascending_inclusive
 cmp rsi,r9
 jge .contains_no
 jmp .contains_ascending_delta
.contains_ascending_inclusive:
 cmp rsi,r9
 jg .contains_no
.contains_ascending_delta:
 mov rax,rsi
 sub rax,r8
 jo .contains_bad
 cqo
 idiv r10
 test rdx,rdx
 setz al
 movzx eax,al
 xor edx,edx
 ret
.contains_descending:
 cmp rsi,r8
 jg .contains_no
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .contains_descending_inclusive
 cmp rsi,r9
 jle .contains_no
 jmp .contains_descending_delta
.contains_descending_inclusive:
 cmp rsi,r9
 jl .contains_no
.contains_descending_delta:
 mov rax,r8
 sub rax,rsi
 jo .contains_bad
 mov rcx,r10
 neg rcx
 jo .contains_bad
 cqo
 idiv rcx
 test rdx,rdx
 setz al
 movzx eax,al
 xor edx,edx
 ret
.contains_no:
 xor eax,eax
 xor edx,edx
 ret
.contains_bad:
 xor eax,eax
 mov edx,1
 ret

; state*, node id, depth -> EAX 1 only for the bounded NPT-LANG-24 material
; index surface.  Calls are deliberately excluded so this front cannot publish
; function-call-result reuse through collection indexing.
fcg_dynamic_index_is_material:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .yes
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .yes
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .yes
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .yes
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .yes
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 jne .no
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary
 cmp rax,NEBOC_TOKEN_STAR
 je .binary
 cmp rax,NEBOC_TOKEN_SLASH
 je .binary
 cmp rax,NEBOC_TOKEN_PERCENT
 jne .no
.binary:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_dynamic_index_is_material
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_dynamic_index_is_material
 jmp .done
.unary:
 ; Unary minus remains the established raw-negative syntax rejection. Unary
 ; plus is a material identity expression and remains type-checked below.
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_PLUS
 jne .no
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_dynamic_index_is_material
 jmp .done
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, filtered token index, Buffer request*, Buffer-relative token index
; -> EAX bool.  The declaration-filtered Program view and the semantic owner
; request share immutable source bytes but not token ordinals.
fcg_token_matches_buffer_token:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 cmp r12,[rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 cmp r14,[r13+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .no
 mov r8,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 test r8,r8
 jz .no
 imul r12,NEBOC_TOKEN_SIZE
 add r12,[rbx+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
 imul r14,NEBOC_TOKEN_SIZE
 add r14,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 mov rcx,[r12+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r12+NEBOC_TOKEN_START_OFFSET]
 jbe .no
 mov rax,[r14+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r14+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rax
 jne .no
 mov rsi,r8
 add rsi,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r8
 add rdi,[r14+NEBOC_TOKEN_START_OFFSET]
 cld
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Buffer request*, Buffer-relative token index, Buffer-relative token index
; -> EAX bool.  This comparison deliberately stays inside one authenticated
; request: a broad lexical request must not make an unrelated statement's
; result name part of the Buffer owner graph.
fcg_buffer_tokens_equal:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r12,[rbx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .no
 cmp r13,[rbx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .no
 mov r14,[rbx+NEBOC_BUFFER_SOURCE_OFFSET]
 test r14,r14
 jz .no
 imul r12,NEBOC_TOKEN_SIZE
 add r12,[rbx+NEBOC_BUFFER_TOKENS_OFFSET]
 imul r13,NEBOC_TOKEN_SIZE
 add r13,[rbx+NEBOC_BUFFER_TOKENS_OFFSET]
 mov rcx,[r12+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r12+NEBOC_TOKEN_START_OFFSET]
 jbe .no
 mov rax,[r13+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r13+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rax
 jne .no
 mov rsi,r14
 add rsi,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r14
 add rdi,[r13+NEBOC_TOKEN_START_OFFSET]
 cld
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; state*, CallExpr id, recursion depth -> RAX exact Buffer owner request or 0.
; Prior-binding recursion is strictly lexical and acyclic: each derived
; Bytes/Slice/result receiver must originate in an earlier binding.
fcg_buffer_call_owner:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jb .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 mov rdx,r13
 call fcg_buffer_receiver_owner
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; state*, filtered receiver token, Buffer request* -> EAX bool for an exact
; semantic-operation result binding inside this owner's lexical function.
; The first closing brace bounds the request.  The call-result spelling alone
; is insufficient because the Buffer recognizer retains a broad lexical
; interval: the statement must also start from this request's constructor,
; Buffer owner, frozen Bytes owner, or public Slice owner.
fcg_buffer_receiver_is_owned_result:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 xor r14d,r14d
.scan:
 cmp r14,[r13+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r14
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 mov r15,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r15,NEBOC_TOKEN_RBRACE
 je .no
 cmp r15,NEBOC_TOKEN_IDENTIFIER
 jne .next
 cmp r14,2
 jb .next
 mov rax,r14
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 sub rax,NEBOC_TOKEN_SIZE
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .next
 ; Find the first token of the candidate's statement.  Requests begin at the
 ; Buffer constructor, and later statements are separated by semicolons.
 mov r10,r14
.statement_start:
 test r10,r10
 jz .owned_statement
 mov rax,r10
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 je .statement_ready
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 je .statement_ready
 dec r10
 jmp .statement_start
.statement_ready:
 test r10,r10
 jz .owned_statement
 mov rdi,r13
 mov rsi,r10
 mov rdx,[r13+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 call fcg_buffer_tokens_equal
 test eax,eax
 jnz .owned_statement
 test qword [r13+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FREEZE
 jz .slice_statement
 mov rdi,r13
 mov rsi,r10
 mov rdx,[r13+NEBOC_BUFFER_FROZEN_NAME_TOKEN_OFFSET]
 call fcg_buffer_tokens_equal
 test eax,eax
 jnz .owned_statement
.slice_statement:
 test qword [r13+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .next
 mov rdi,r13
 mov rsi,r10
 mov rdx,[r13+NEBOC_SLICE_NAME_TOKEN_OFFSET]
 call fcg_buffer_tokens_equal
 test eax,eax
 jz .next
.owned_statement:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 mov rcx,r14
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .yes
.next:
 inc r14
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, receiver expression id, recursion depth -> RAX exact Buffer owner.
fcg_buffer_receiver_owner:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNERS_OFFSET]
 test r15,r15
 jz .prior
 mov qword [rsp],0
.owner_loop:
 mov rcx,[rsp]
 cmp rcx,[rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNER_COUNT_OFFSET]
 jae .prior
 mov rax,rcx
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 add rax,r15
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .owner_yes
 mov rax,[rsp+8]
 test qword [rax+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FREEZE
 jz .slice_name
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_BUFFER_FROZEN_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .owner_yes
.slice_name:
 mov rax,[rsp+8]
 test qword [rax+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .derived_name
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_SLICE_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .owner_yes
.derived_name:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+8]
 call fcg_buffer_receiver_is_owned_result
 test eax,eax
 jnz .owner_yes
.owner_next:
 inc qword [rsp]
 jmp .owner_loop
.owner_yes:
 mov rax,[rsp+8]
 jmp .done
.prior:
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test rdx,rdx
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_buffer_call_owner
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX 1, RCX Int, RDX the semantic owner's exact final
; result.  Parse/semantic/lowering already validated every operation and its
; lifecycle; this bridge only prevents cross-kind calls from falling through
; to the user-function resolver in the shared Program backend.
fcg_buffer_call_info:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_buffer_call_owner
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,r12
 mov rdx,rax
 call fcg_buffer_result_at_call
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
 xor edx,edx
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, authenticated Buffer call id, owner request* -> EAX 1, RCX Int and
; RDX the result at this exact call boundary.  Replaying the already-validated
; immutable owner prefix prevents every scalar binding from incorrectly
; inheriting the request's final result while introducing no runtime state.
fcg_buffer_result_at_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,320
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,[rax+NEBOC_AST_NODE_END_OFFSET]
 xor r14d,r14d
.boundary_scan:
 cmp r14,[r13+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r14
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .boundary_next
 cmp qword [rax+NEBOC_TOKEN_START_OFFSET],r15
 jae .boundary_ready
.boundary_next:
 inc r14
 jmp .boundary_scan
.boundary_ready:
 inc r14
 lea rdi,[rsp]
 mov ecx,NEBOC_BUFFER_F11_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r13+NEBOC_BUFFER_SOURCE_OFFSET]
 mov [rsp+NEBOC_BUFFER_SOURCE_OFFSET],rax
 mov rax,[r13+NEBOC_BUFFER_SOURCE_LENGTH_OFFSET]
 mov [rsp+NEBOC_BUFFER_SOURCE_LENGTH_OFFSET],rax
 mov rax,[r13+NEBOC_BUFFER_TOKENS_OFFSET]
 mov [rsp+NEBOC_BUFFER_TOKENS_OFFSET],rax
 mov [rsp+NEBOC_BUFFER_TOKEN_COUNT_OFFSET],r14
 lea rdi,[rsp]
 call neboc_buffer_parse
 test eax,eax
 jnz .no
 cmp qword [rsp+NEBOC_BUFFER_FOUND_OFFSET],1
 jne .no
 cmp qword [rsp+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],0
 jne .no
 mov rdx,[rsp+NEBOC_BUFFER_RESULT_OFFSET]
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
 xor edx,edx
.done:
 add rsp,320
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX 1 and RCX exact Slice TypeId only for the existing
; zero-argument `ownedArray.asSlice()` operation applied to a material B01
; result binding.  Semantic Array declarations continue through their
; existing collection owner and never need this bridge.
fcg_collection_result_as_slice_info:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_as_slice]
 mov ecx,fcg_name_collection_as_slice_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov [rsp],rsi
 mov rdi,rbx
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .no
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .no
 mov rdx,[rax+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rdx,NEBOC_AR_TYPE_INT
 je .int
 cmp rdx,NEBOC_AR_TYPE_BOOL
 je .bool
 cmp rdx,NEBOC_AR_TYPE_CHAR
 jne .no
 mov ecx,NEBOC_FUNCTION_TYPE_SLICE_CHAR
 jmp .yes
.int:
 mov ecx,NEBOC_FUNCTION_TYPE_SLICE_INT
 jmp .yes
.bool:
 mov ecx,NEBOC_FUNCTION_TYPE_SLICE_BOOL
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX 1, RCX Int and RDX the exact constant reduction for
; the existing bounded immutable Array/Slice.sum surface.
fcg_collection_sum_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_sum]
 mov ecx,fcg_name_collection_sum_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .kind_ready
 cmp qword [r14+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
.kind_ready:
 cmp qword [r14+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 jne .no
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rax,rax
 jz .no
 mov r15,[rax+NEBOC_AR_VALUES_OFFSET]
 mov r8,[rax+NEBOC_AR_VALUE_COUNT_OFFSET]
 mov r9,[r14+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 mov r10,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
 mov rax,r9
 add rax,r10
 cmp rax,r8
 ja .no
 xor edx,edx
 xor ecx,ecx
.sum:
 cmp rcx,r10
 jae .yes
 add rdx,[r15+r9*8]
 inc r9
 inc rcx
 jmp .sum
.yes:
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor ecx,ecx
 xor edx,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX 1 only for the existing zero-argument Slice.release
; surface on a semantic collection owner.  The array-range vertical has
; already proved state/lifecycle; this bridge prevents a public intrinsic from
; falling through to user-function resolution in a mixed Program.
fcg_collection_release_info:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_release]
 mov ecx,fcg_name_collection_release_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; state*, call node -> EAX kind and RCX scalar TypeId.
; state*, call_node_id -> EAX 1 and RDX arity/RCX first argument for an exact
; public Tuple constructor, otherwise zero.  Both Tuple(...) and Tuple.of(...)
; converge here without creating runtime allocation or a public descriptor.
fcg_tuple_call_shape:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .of
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_tuple]
 mov ecx,fcg_name_tuple_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp r15,[r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .no
 mov r13,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .yes
.of:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TUPLE_POSITIONAL_PROJECTION
 jnz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_tuple_of]
 mov ecx,fcg_name_tuple_of_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rax,r15
 inc rax
 cmp rax,[r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .no
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_tuple]
 mov ecx,fcg_name_tuple_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.yes:
 mov rdx,r15
 mov rcx,r13
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_node_id -> EAX 1, RDX constant position, RCX receiver node for
; the two authenticated Tuple projection spellings.
fcg_tuple_projection_info:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TUPLE_POSITIONAL_PROJECTION
 jz .generic
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .no
 mov rcx,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,1
 jmp .done
.generic:
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .no
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .no
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_at]
 mov ecx,fcg_name_collection_at_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov r12,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .no
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rcx,r12
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression_node_id, depth -> RAX exact Tuple constructor node or 0.
; Prior bindings are followed lexically and projections may yield a nested
; Tuple, but scalar members never masquerade as aggregate identity.
fcg_tuple_resolve_aggregate:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_call_shape
 test eax,eax
 jnz .self
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_projection_info
 test eax,eax
 jz .no
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,rcx
 lea rdx,[r13+1]
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp qword [rsp],rdx
 jae .no
 mov r14,rcx
 mov r15,[rsp]
.member_walk:
 test r15,r15
 jz .member_ready
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r15
 jmp .member_walk
.member_ready:
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_tuple_resolve_aggregate
 jmp .done
.identifier:
 mov r15,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test r15,r15
 jz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,r15
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_tuple_resolve_aggregate
 jmp .done
.self:
 mov rax,r12
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression_node_id, depth -> EAX 1 scalar/RDX value, EAX 2 bounded
; Tuple aggregate/RDX arity, or zero when this is not an authenticated Tuple
; expression.  The aggregate case emits only an internal compile-time token;
; no hidden heap, copy or materialization is introduced.
fcg_tuple_expr_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .scalar
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .scalar
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .scalar
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .call_operation
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 mov eax,2
 jmp .done
.call_operation:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_collection_length]
 mov ecx,fcg_name_collection_length_len
 call fcg_call_name_matches
 test eax,eax
 jz .projection
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 mov eax,1
 jmp .done
.projection:
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_projection_info
 test eax,eax
 jz .no
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,rcx
 lea rdx,[r13+1]
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp qword [rsp],rdx
 jae .no
 mov r14,rcx
 mov r15,[rsp]
.projection_walk:
 test r15,r15
 jz .projection_ready
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r15
 jmp .projection_walk
.projection_ready:
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_tuple_expr_info
 jmp .done
.scalar:
 mov rdx,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,1
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; 1 = compile-time constant, 2 = borrowed length, 3 = borrowed constant at,
; 4 = local Array dynamic at, 5 = borrowed dynamic at,
; 6 = local Slice dynamic at, -1 = diagnosed invalid at.  Local returns use
; RDX as the canonical binding ordinal; R8 is the index AST id, while R9/R10
; carry the local length/stride for kind 4.  Kinds 5/6 read descriptor fields.
fcg_collection_access_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 test qword [r13+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_collection_length]
 mov ecx,fcg_name_collection_length_len
 call fcg_call_name_matches
 test eax,eax
 jnz .length
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_contains]
 mov ecx,fcg_name_collection_contains_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .contains_name
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .no
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel fcg_name_collection_at]
 mov ecx,fcg_name_collection_at_len
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov qword [rsp+40],2
 jmp .receiver
.contains_name:
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .no
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .no
 mov qword [rsp+40],3
 jmp .receiver
.length:
 mov qword [rsp+40],1
.receiver:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .no
 mov rdi,rbx
 mov rsi,r15
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 mov [rsp+16],rax
 cmp qword [rsp+40],3
 je .contains
 cmp qword [rsp+40],2
 je .at
 mov rcx,[rax+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rcx,NEBOC_AR_KIND_RANGE
 je .range_length
 cmp rcx,NEBOC_AR_KIND_ARRAY
 je .stored_length
 cmp rcx,NEBOC_AR_KIND_SLICE
 je .stored_length
 cmp rcx,NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_length
 jmp .no
.stored_length:
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .static_stored_length
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .no
 mov rdx,rax
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,8
 jmp .done
.static_stored_length:
 mov rdx,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.parameter_length:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov rdx,rax
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,2
 jmp .done
.range_length:
 mov rdi,rax
 call fcg_collection_range_length
 test edx,edx
 jnz .no
 mov rdx,rax
 mov ecx,NEBOC_TYPE_ID_INT
 mov eax,1
 jmp .done
.contains:
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .no
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,[rsp+16]
 call fcg_collection_range_contains
 test edx,edx
 jnz .no
 mov rdx,rax
 mov ecx,NEBOC_TYPE_ID_BOOL
 mov eax,1
 jmp .done
.at:
 mov rcx,[rax+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rcx,NEBOC_AR_KIND_ARRAY
 je .at_kind_ok
 cmp rcx,NEBOC_AR_KIND_SLICE
 je .at_kind_ok
 cmp rcx,NEBOC_AR_KIND_SLICE_PARAMETER
 je .at_kind_ok
 jmp .no
.at_kind_ok:
 mov [rsp+8],r15
 mov rax,[rsp+16]
 mov rcx,[rax+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rcx,NEBOC_AR_TYPE_INT
 je .at_result_int
 cmp rcx,NEBOC_AR_TYPE_BOOL
 je .at_result_bool
 cmp rcx,NEBOC_AR_TYPE_CHAR
 jne .no
 mov qword [rsp+32],NEBOC_TYPE_ID_CHAR
 jmp .at_index
.at_result_int:
 mov qword [rsp+32],NEBOC_TYPE_ID_INT
 jmp .at_index
.at_result_bool:
 mov qword [rsp+32],NEBOC_TYPE_ID_BOOL
.at_index:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .no
 mov [rsp+24],r15
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .dynamic_at
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rax,[rsp+16]
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jnz .result_constant_at
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_constant_at
 cmp rdx,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .no
 mov [rsp],rdx
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_owner_info
 test rax,rax
 jnz .mutable_at
 mov rdx,[rsp]
 mov rax,[rsp+16]
 add rdx,[rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 cmp rdx,[r13+NEBOC_AR_VALUE_COUNT_OFFSET]
 jae .no
 mov r8,[r13+NEBOC_AR_VALUES_OFFSET]
 mov rdx,[r8+rdx*8]
 mov rcx,[rsp+32]
 mov eax,1
 jmp .done
.parameter_constant_at:
 mov [rsp],rdx
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov rdx,rax
 mov r8,[rsp]
 mov rcx,[rsp+32]
 mov eax,3
 jmp .done
.result_constant_at:
 mov rcx,[rsp+16]
 test qword [rcx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RESULT_LENGTH_KNOWN
 jz .result_constant_runtime
 cmp rdx,[rcx+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .constant_result_bounds
.result_constant_runtime:
 mov [rsp],rdx
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .no
 mov rdx,rax
 mov r8,[rsp]
 mov rcx,[rsp+32]
 mov eax,9
 jmp .done
.constant_result_bounds:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_capture_node_span
 jmp .invalid_at
.dynamic_at:
 mov rdi,rbx
 mov rsi,[rsp+24]
 xor edx,edx
 call fcg_dynamic_index_is_material
 test eax,eax
 jz .nonmaterial_index
 mov rdi,rbx
 mov rsi,[rsp+24]
 xor edx,edx
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .index_type
 mov rax,[rsp+16]
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jnz .result_dynamic_at
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_dynamic_at
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_owner_info
 test rax,rax
 jnz .mutable_at
 mov rax,[rsp+16]
 mov r11,rax
 sub rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 jc .no
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .no
 mov rdx,rax
 mov r9,[r11+NEBOC_AR_BIND_COUNT_OFFSET]
 mov r10,[r11+NEBOC_AR_BIND_STRIDE_OFFSET]
 mov r8,[rsp+24]
 mov rcx,[rsp+32]
 cmp qword [r11+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 je .local_slice_dynamic_at
 mov eax,4
 jmp .done
.local_slice_dynamic_at:
 mov eax,6
 jmp .done
.mutable_at:
 ; RAX is the root mutable Array and RDX its live-view element offset.
 mov [rsp],rdx
 sub rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 jc .no
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .no
 mov edx,eax
 mov rax,[rsp]
 shl rax,32
 or rdx,rax                   ; owner ordinal | view offset
 mov rax,[rsp+16]
 mov r9,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 mov r10,[rax+NEBOC_AR_BIND_STRIDE_OFFSET]
 mov r8,[rsp+24]
 mov rcx,[rsp+32]
 mov eax,7
 jmp .done
.parameter_dynamic_at:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov rdx,rax
 mov r8,[rsp+24]
 mov rcx,[rsp+32]
 mov eax,5
 jmp .done
.result_dynamic_at:
 mov rdi,rbx
 mov rsi,rax
 call fcg_mutable_record_frame_byte
 test rax,rax
 jz .no
 mov rdx,rax
 mov r8,[rsp+24]
 mov rcx,[rsp+32]
 mov eax,10
 jmp .done
.nonmaterial_index:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_capture_node_span
 jmp .invalid_at
.index_type:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .invalid_at
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_capture_node_span
.invalid_at:
 mov rcx,[rsp+32]
 mov rax,-1
 xor edx,edx
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, RangeFor node id -> RAX authenticated loop record, RDX TypeId.
; The shared parser consumes a declaration-filtered token view, while Array /
; Range semantic records retain original token indices. Match the immutable
; source spans copied into both token views, never the unstable indices.
fcg_collection_record_for_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 test qword [r13+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r14,r14
 jz .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .no
 mov [rsp+16],r15
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[r13+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .no
 mov rax,rcx
 imul rax,NEBOC_FOR_RECORD_SIZE
 add rax,[r13+NEBOC_AR_LOOPS_OFFSET]
 mov [rsp],rax
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rax+NEBOC_FOR_ITEM_TOKEN_OFFSET]
 call fcg_token_same_ar_occurrence
 test eax,eax
 jz .next_restore
 mov rax,[rsp]
 cmp qword [rax+NEBOC_FOR_COLLECTION_INDEX_OFFSET],-1
 je .deferred_result
 mov r8,[rax+NEBOC_FOR_COLLECTION_INDEX_OFFSET]
 cmp r8,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul r8,NEBOC_AR_BIND_SIZE
 add r8,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp],r8
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[r8+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_token_matches_ar_token
 test eax,eax
 jz .next_restore
 mov r8,[rsp]
 mov rax,[r13+NEBOC_AR_LOOPS_OFFSET]
 mov rcx,[rsp+8]
 imul rcx,NEBOC_FOR_RECORD_SIZE
 add rax,rcx
.binding_ready:
 mov rdx,[r8+NEBOC_AR_BIND_TYPE_OFFSET]
 cmp rdx,NEBOC_AR_TYPE_INT
 je .int
 cmp rdx,NEBOC_AR_TYPE_RANGE_INT
 je .int
 cmp rdx,NEBOC_AR_TYPE_BOOL
 je .bool
 cmp rdx,NEBOC_AR_TYPE_CHAR
 jne .no
 mov edx,NEBOC_TYPE_ID_CHAR
 jmp .done
.int:
 mov edx,NEBOC_TYPE_ID_INT
 jmp .done
.bool:
 mov edx,NEBOC_TYPE_ID_BOOL
 jmp .done
.deferred_result:
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .deferred_array
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .no
 jmp .deferred_kind_ready
.deferred_array:
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .no
.deferred_kind_ready:
 mov r8,rax
 sub rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 jc .no
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .no
 mov rcx,[rsp]
 mov [rcx+NEBOC_FOR_COLLECTION_INDEX_OFFSET],rax
 mov rax,[r8+NEBOC_AR_BIND_KIND_OFFSET]
 test qword [r8+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .deferred_store_kind
 mov eax,NEBOC_AR_KIND_SLICE_PARAMETER
.deferred_store_kind:
 mov [rcx+NEBOC_FOR_KIND_OFFSET],rax
 mov rax,[r8+NEBOC_AR_BIND_FLAGS_OFFSET]
 mov [rcx+NEBOC_FOR_FLAGS_OFFSET],rax
 mov rax,[r8+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 mov [rcx+NEBOC_FOR_DATA_INDEX_OFFSET],rax
 mov rax,[r8+NEBOC_AR_BIND_COUNT_OFFSET]
 mov [rcx+NEBOC_FOR_COUNT_OFFSET],rax
 mov qword [rcx+NEBOC_FOR_START_OFFSET],0
 mov qword [rcx+NEBOC_FOR_STEP_OFFSET],1
 mov rax,rcx
 jmp .binding_ready
.next_restore:
 mov rcx,[rsp+8]
.next:
 inc rcx
 jmp .loop
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, filtered-token index, original Array/Range token index -> EAX bool.
; The iterator declaration is the same lexical occurrence in both token views,
; so source coordinates provide an exact identity even when separate functions
; reuse the same iterator and collection names.
fcg_token_same_ar_occurrence:
 cmp rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rcx,[rdi+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rcx,rcx
 jz .no
 cmp rdx,[rcx+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rsi,NEBOC_TOKEN_SIZE
 add rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,[rcx+NEBOC_AR_TOKENS_OFFSET]
 mov rax,[rsi+NEBOC_TOKEN_START_OFFSET]
 cmp rax,[rdx+NEBOC_TOKEN_START_OFFSET]
 jne .no
 mov rax,[rsi+NEBOC_TOKEN_END_OFFSET]
 cmp rax,[rdx+NEBOC_TOKEN_END_OFFSET]
 jne .no
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; state*, filtered-token index, original Array/Range token index -> EAX bool.
; Both token records point at the same immutable source. A collection use and
; its declaration are distinct occurrences, so compare their bounded source
; bytes rather than their unstable token indices.
fcg_token_matches_ar_token:
 cmp rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov r8,[rdi+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 test r8,r8
 jz .no
 mov rcx,[rdi+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test rcx,rcx
 jz .no
 cmp rdx,[rcx+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .no
 imul rsi,NEBOC_TOKEN_SIZE
 add rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,[rcx+NEBOC_AR_TOKENS_OFFSET]
 mov rcx,[rsi+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rsi+NEBOC_TOKEN_START_OFFSET]
 jbe .no
 mov rax,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rax
 jne .no
 mov rax,[rsi+NEBOC_TOKEN_START_OFFSET]
 mov rsi,r8
 add rsi,rax
 mov rdi,[rdx+NEBOC_TOKEN_START_OFFSET]
 add rdi,r8
 cld
 repe cmpsb
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; state*, binding statement id -> EAX 1 only for a semantic collection
; declaration.  Such statements are represented by immutable semantic data
; and must not consume a scalar frame slot in the shared backend.
; state*, binding statement id -> authenticated semantic record or zero.
fcg_collection_binding_record:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 test qword [r13+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 bt rdx,63
 jnc .scan_name
 btr rdx,63
 cmp rdx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul rdx,NEBOC_AR_BIND_SIZE
 add rdx,[r13+NEBOC_AR_BINDINGS_OFFSET]
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jnz .tag_match
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jnz .tag_match
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 mov rcx,[rdx+NEBOC_AR_BIND_START_OFFSET]
 cmp rcx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul rcx,NEBOC_AR_BIND_SIZE
 add rcx,[r13+NEBOC_AR_BINDINGS_OFFSET]
 test qword [rcx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .no
.tag_match:
 mov rax,rdx
 jmp .done
.scan_name:
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,rcx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp],rax
 mov [rsp+8],rcx
 ; A declaration anchor must be the exact source occurrence retained by the
 ; collection scanner.  Name-only matching aliases identically named locals
 ; in another function and can suppress a caller-owned Array result record.
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_token_same_ar_occurrence
 mov rcx,[rsp+8]
 test eax,eax
 jnz .matched
 inc rcx
 jmp .loop
.matched:
 mov rax,[rsp]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, Array/Slice record -> frame-backed owner Array or zero in RAX and the
; live-view element offset in RDX.  Mutable literals and caller-owned results
; share physical addressing while mutability remains validated separately.
fcg_mutable_owner_info:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 cmp qword [r12+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .array
 cmp qword [r12+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 mov rax,[r12+NEBOC_AR_BIND_START_OFFSET]
 cmp rax,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .no
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],(NEBOC_AR_ARRAY_MUTABLE | NEBOC_AR_ARRAY_CALL_RESULT)
 jz .no
 mov rdx,[r12+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 sub rdx,[rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 jc .no
 jmp .done
.array:
 test qword [r12+NEBOC_AR_BIND_FLAGS_OFFSET],(NEBOC_AR_ARRAY_MUTABLE | NEBOC_AR_ARRAY_CALL_RESULT)
 jz .no
 mov rax,r12
 xor edx,edx
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, Array/Slice record -> RAX byte displacement from RBP to element 0
; of that exact view, or zero when the record is not frame-backed.
fcg_mutable_record_frame_byte:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 cmp qword [r12+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .owner_lookup
 test qword [r12+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .owner_lookup
 mov rax,r12
 xor edx,edx
 jmp .record_ready
.owner_lookup:
 call fcg_mutable_owner_info
 test rax,rax
 jz .no
.record_ready:
 mov rcx,[rax+NEBOC_AR_BIND_FLAGS_OFFSET]
 shr rcx,NEBOC_AR_ARRAY_FRAME_SHIFT
 test rcx,rcx
 jz .no
 dec rcx
 add rcx,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET]
 mov r8,[rax+NEBOC_AR_BIND_COUNT_OFFSET]
 test qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jz .count_ready
 mov r8d,5
.count_ready:
 test r8,r8
 jnz .have_cells
 mov r8d,1
.have_cells:
 add rcx,r8
 shl rcx,3
 shl rdx,3
 sub rcx,rdx
 mov rax,rcx
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; state*, BindingStmt id -> EAX 1 only when the retained scalar-shaped anchor
; represents a Buffer/Bytes/Slice descriptor or an Option result.  Ordinary
; Int results must receive lexical slots because later arithmetic is material.
fcg_is_buffer_binding:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rax,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .no
 mov [rsp+16],rax
 ; Scalar observations are material values even when the semantic Buffer
 ; owner also retains their result spelling.  Let the ordinary lexical
 ; binding path allocate those slots; only descriptor/transition anchors are
 ; compiler-private no-ops.
 mov rdi,rbx
 mov rsi,rax
 call fcg_buffer_call_is_scalar_value
 test eax,eax
 jnz .no
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNERS_OFFSET]
 test r13,r13
 jz .no
 mov qword [rsp],0
.loop:
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUFFER_OWNER_COUNT_OFFSET]
 jae .option_check
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 add rax,r13
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .yes
 mov rax,[rsp+8]
 test qword [rax+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_FREEZE
 jz .slice_name
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_BUFFER_FROZEN_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .yes
.slice_name:
 mov rax,[rsp+8]
 test qword [rax+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 jz .derived_result
 mov rdi,rbx
 mov rsi,r14
 mov rdx,rax
 mov rcx,[rax+NEBOC_SLICE_NAME_TOKEN_OFFSET]
 call fcg_token_matches_buffer_token
 test eax,eax
 jnz .yes
.derived_result:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+8]
 call fcg_buffer_receiver_is_owned_result
 test eax,eax
 jnz .yes
.next_owner:
 inc qword [rsp]
 jmp .loop
.option_check:
 ; Buffer.get returns the established compiler-private Option<Int> value.  It
 ; remains an initializer anchor for the textual Option classifier rather
 ; than being misrepresented as an Int slot.
 mov rdi,rbx
 mov rsi,[rsp+16]
 xor edx,edx
 call fcg_buffer_call_owner
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,[rsp+16]
 lea rdx,[rel fcg_name_bytes_get]
 mov ecx,fcg_name_bytes_get_len
 call fcg_call_name_matches
 jmp .done
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression id -> EAX 1 only for an exact scalar observation on an
; authenticated Buffer/Bytes/Slice owner.  Method spelling alone is never
; sufficient: unrelated user functions keep their ordinary binding rules.
fcg_buffer_call_is_scalar_value:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_buffer_call_owner
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_collection_length]
 mov ecx,fcg_name_collection_length_len
 call fcg_call_name_matches
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_buffer_capacity]
 mov ecx,fcg_name_buffer_capacity_len
 call fcg_call_name_matches
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 lea rdx,[rel fcg_name_collection_at]
 mov ecx,fcg_name_collection_at_len
 call fcg_token_matches_literal
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_collection_sum]
 mov ecx,fcg_name_collection_sum_len
 call fcg_call_name_matches
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel fcg_name_byte_length]
 mov ecx,fcg_name_byte_length_len
 call fcg_call_name_matches
 test eax,eax
 jnz .yes
.no:
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; Return 1 for Array/Range/Slice bindings and 2 for Buffer-owned semantic
; anchors.  Callers that emit Array payloads distinguish the latter and skip
; them; flow analysis may treat either class as a non-scalar declaration.
fcg_is_collection_binding:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_is_buffer_binding
 test eax,eax
 jz .array_range
 mov eax,2
 jmp .done
.array_range:
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r13,r13
 jz .no
 test qword [r13+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .no
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 bt rdx,63
 jnc .scan_name
 btr rdx,63
 cmp rdx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul rdx,NEBOC_AR_BIND_SIZE
 add rdx,[r13+NEBOC_AR_BINDINGS_OFFSET]
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jnz .tag_yes
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_CALL_RESULT
 jnz .tag_yes
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 mov rcx,[rdx+NEBOC_AR_BIND_START_OFFSET]
 cmp rcx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 imul rcx,NEBOC_AR_BIND_SIZE
 add rcx,[r13+NEBOC_AR_BINDINGS_OFFSET]
 test qword [rcx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jz .no
.tag_yes:
 mov eax,1
 jmp .done
.scan_name:
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[r13+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,rcx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r13+NEBOC_AR_BINDINGS_OFFSET]
 mov [rsp],rax
 mov [rsp+8],rcx
 ; Only the exact filtered declaration token may authenticate this semantic
 ; collection record.  Ordinary uses continue to resolve lexically through
 ; fcg_find_collection_binding_for_node.
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 call fcg_token_same_ar_occurrence
 mov rcx,[rsp+8]
 test eax,eax
 jnz .yes
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Emit immutable Array/Slice payloads for the authenticated general loops.
; Range records compute their values and need no data object.
fcg_emit_collection_data:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,[rbx+NEBOC_FUNCTION_CODEGEN_ARRAY_RANGE_OFFSET]
 test r12,r12
 jz .ok
 test qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .ok
 mov rdi,rbx
 lea rsi,[rel fcg_collection_rodata]
 mov edx,fcg_collection_rodata_len
 call fcg_append
 test eax,eax
 jnz .done
 test qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_DYNAMIC_AT
 jnz .canonical_array_bindings
 xor r13d,r13d
.record_loop:
 cmp r13,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .slice_bindings
 mov r14,r13
 imul r14,NEBOC_FOR_RECORD_SIZE
 add r14,[r12+NEBOC_AR_LOOPS_OFFSET]
 cmp qword [r14+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 je .next_record
 mov rdi,rbx
 lea rsi,[rel fcg_collection_data_label]
 mov edx,fcg_collection_data_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_FOR_ID_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.value_loop:
 cmp r15,[r14+NEBOC_FOR_COUNT_OFFSET]
 jae .next_record
 mov rdi,rbx
 lea rsi,[rel fcg_collection_dq]
 mov edx,fcg_collection_dq_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_FOR_DATA_INDEX_OFFSET]
 add rax,r15
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov rsi,[rdx+rax*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 jmp .value_loop
.next_record:
 inc r13
 jmp .record_loop
.canonical_array_bindings:
 ; Dynamic-at programs use one canonical qword payload per source Array.
 ; Derived Slices receive descriptors below and never copy base elements.
 xor r13d,r13d
.canonical_array_loop:
 cmp r13,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .canonical_slice_descriptors
 mov r14,r13
 imul r14,NEBOC_AR_BIND_SIZE
 add r14,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r14+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .next_canonical_array
 test qword [r14+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_CALL_RESULT
 jnz .next_canonical_array
 test qword [r14+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jnz .next_canonical_array
 mov rdi,rbx
 lea rsi,[rel fcg_array_data_label]
 mov edx,fcg_array_data_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.canonical_array_value_loop:
 cmp r15,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .next_canonical_array
 mov rdi,rbx
 lea rsi,[rel fcg_collection_dq]
 mov edx,fcg_collection_dq_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r15
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov rsi,[rdx+rax*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 jmp .canonical_array_value_loop
.next_canonical_array:
 inc r13
 jmp .canonical_array_loop
.canonical_slice_descriptors:
 xor r13d,r13d
.canonical_slice_loop:
 cmp r13,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .text
 mov r14,r13
 imul r14,NEBOC_AR_BIND_SIZE
 add r14,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r14+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .next_canonical_slice
 ; S04-derived records describe a callee-side return source.  They have no
 ; caller-side static descriptor object and their START field is the exact
 ; S04 parameter ordinal, not an Array owner ordinal.  A mutable caller owner
 ; enables the canonical dynamic/mutation data path, so exclude this
 ; compiler-only provenance record here just as the legacy Slice lowerer does.
 test qword [r14+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jnz .next_canonical_slice
 mov rdi,rbx
 mov rsi,r14
 call fcg_mutable_owner_info
 test rax,rax
 jnz .next_canonical_slice
 mov rax,[r14+NEBOC_AR_BIND_START_OFFSET]
 cmp rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .writer
 mov [rsp],rax                 ; exact owner Array binding ordinal
 mov rcx,rax
 imul rcx,NEBOC_AR_BIND_SIZE
 add rcx,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rcx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .writer
 mov [rsp+8],rcx
 mov rax,[r14+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 sub rax,[rcx+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 jc .writer
 shl rax,3
 mov [rsp+16],rax              ; canonical byte offset into owner Array
 mov rdi,rbx
 lea rsi,[rel fcg_slice_descriptor_label]
 mov edx,fcg_slice_descriptor_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_array_descriptor_base]
 mov edx,fcg_array_descriptor_base_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 cmp qword [rsp+16],0
 je .canonical_base_done
 mov rdi,rbx
 lea rsi,[rel fcg_plus]
 mov edx,fcg_plus_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
.canonical_base_done:
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.canonical_descriptor_field_loop:
 cmp r15,4
 jae .next_canonical_slice
 cmp r15,0
 jne .canonical_field_stride
 mov rax,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
 jmp .canonical_field_ready
.canonical_field_stride:
 cmp r15,1
 jne .canonical_field_generation
 mov eax,8
 jmp .canonical_field_ready
.canonical_field_generation:
 cmp r15,2
 jne .canonical_field_token
 mov rax,[r14+NEBOC_AR_BIND_END_OFFSET]
 jmp .canonical_field_ready
.canonical_field_token:
 mov rax,[r14+NEBOC_AR_BIND_STEP_OFFSET]
.canonical_field_ready:
 mov [rsp+24],rax
 mov rdi,rbx
 lea rsi,[rel fcg_collection_dq]
 mov edx,fcg_collection_dq_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 jmp .canonical_descriptor_field_loop
.next_canonical_slice:
 inc r13
 jmp .canonical_slice_loop
.slice_bindings:
 ; Local Slice payload aliases are needed only when this program crosses the
 ; new borrowed-Slice call boundary.  Without a Slice parameter the existing
 ; collection loop payloads above are already canonical; emitting aliases
 ; would perturb previously accepted NPT-LANG-18 Assembly for no semantic
 ; reason.
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_HAS_SLICE_PARAMETERS_OFFSET],0
 je .text
 xor r13d,r13d
.slice_binding_loop:
 cmp r13,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .text
 mov r14,r13
 imul r14,NEBOC_AR_BIND_SIZE
 add r14,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [r14+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .next_slice_binding
 mov rdi,rbx
 mov rsi,r14
 call fcg_mutable_owner_info
 test rax,rax
 jnz .next_slice_binding
 mov rdi,rbx
 lea rsi,[rel fcg_slice_data_label]
 mov edx,fcg_slice_data_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.slice_value_loop:
 cmp r15,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .next_slice_binding
 mov rdi,rbx
 lea rsi,[rel fcg_collection_dq]
 mov edx,fcg_collection_dq_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r15
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov rsi,[rdx+rax*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 jmp .slice_value_loop
.next_slice_binding:
 inc r13
 jmp .slice_binding_loop
.text:
 mov rdi,rbx
 lea rsi,[rel fcg_text_section]
 mov edx,fcg_text_section_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state* -> status. Emit every lexer-backed Text literal as a deterministic
; 24-byte runtime descriptor before function bodies. Labels use AST node IDs,
; so source order and repeated equal contents remain stable and collision-free.
fcg_emit_text_literals:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r13,1
 mov qword [rsp],0
.loop:
 cmp r13,r15
 ja .finish
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .next
 mov [rsp+8],rax
 cmp qword [rsp],0
 jne .header_ready
 mov rdi,rbx
 lea rsi,[rel fcg_text_equal_extern]
 mov edx,fcg_text_equal_extern_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_rodata_header]
 mov edx,fcg_rodata_header_len
 call fcg_append
 test eax,eax
 jnz .done
.header_ready:
 mov rax,[rsp+8]
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,r14d
 mov [rsp+16],rax
 shr r14,32
 mov [rsp+24],r14
 mov rax,[rsp+16]
 mov rdx,[rsp+24]
 add rax,rdx
 jc .text_error
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .text_error
 mov rdi,rbx
 lea rsi,[rel fcg_align8]
 mov edx,fcg_align8_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_data_prefix]
 mov edx,fcg_text_data_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_data_mid]
 mov edx,fcg_text_data_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+16],0
 jne .bytes
 mov rdi,rbx
 lea rsi,[rel fcg_zero]
 mov edx,fcg_zero_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .data_done
.bytes:
 mov qword [rsp+32],0
.byte_loop:
 mov rax,[rsp+32]
 cmp rax,[rsp+16]
 jae .data_done
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 add rdx,[rsp+24]
 movzx esi,byte [rdx+rax]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 inc qword [rsp+32]
 mov rax,[rsp+32]
 cmp rax,[rsp+16]
 jae .byte_loop
 mov rdi,rbx
 lea rsi,[rel fcg_comma]
 mov edx,fcg_comma_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .byte_loop
.data_done:
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_prefix]
 mov edx,fcg_text_desc_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_mid]
 mov edx,fcg_text_desc_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_length]
 mov edx,fcg_text_desc_length_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_tail]
 mov edx,fcg_text_desc_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 inc qword [rsp]
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_TEXT_LITERAL_COUNT_OFFSET]
.next:
 inc r13
 jmp .loop
.finish:
 cmp qword [rsp],0
 je .ok
 mov rdi,rbx
 lea rsi,[rel fcg_text_section]
 mov edx,fcg_text_section_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.text_error:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TEXT_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state* -> status
fcg_emit_traps:
 push rbx
 mov rbx,rdi
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 jz .divzero
 mov rdi,rbx
 lea rsi,[rel fcg_trap_overflow]
 mov edx,fcg_trap_overflow_len
 call fcg_append
 test eax,eax
 jnz .done
.divzero:
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_DIV_ZERO
 jz .slice_bounds
 mov rdi,rbx
 lea rsi,[rel fcg_trap_divzero]
 mov edx,fcg_trap_divzero_len
 call fcg_append
 test eax,eax
 jnz .done
.slice_bounds:
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_SLICE_BOUNDS
 jz .ok
 mov rdi,rbx
 lea rsi,[rel fcg_slice_bounds_label]
 mov edx,fcg_slice_bounds_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_slice_bounds_body]
 mov edx,fcg_slice_bounds_body_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ok:
 xor eax,eax
.done:
 pop rbx
 ret

; state*, bytes*, length -> status
fcg_append:
 push rbx
 mov rbx,rdi
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jz .done
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
.done:
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
