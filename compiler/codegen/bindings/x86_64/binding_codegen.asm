; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF005 public immutable binding codegen
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/core_option_range_flow_registry.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"
%include "compiler/semantic/operators/core_power_xor_ordering_registry.inc"
%include "compiler/codegen/bindings/x86_64/binding_codegen.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal
extern neboc_foundation_float_materialize_literal
extern neboc_scoped_slots_assign

section .rodata
n_bool: db "Bool"
n_bool_len equ $-n_bool
n_int: db "Int"
n_int_len equ $-n_int
n_text: db "Text"
n_text_len equ $-n_text
n_float: db "Float"
n_float_len equ $-n_float
n_char: db "Char"
n_char_len equ $-n_char
n_bytes: db "Bytes"
n_bytes_len equ $-n_bytes
n_console_type: db "Console"
n_console_type_len equ $-n_console_type
n_console: db "console"
n_console_len equ $-n_console
n_scan: db "scan"
n_scan_len equ $-n_scan
n_empty: db "empty"
n_empty_len equ $-n_empty
n_from_byte: db "fromByte"
n_from_byte_len equ $-n_from_byte
n_from_values: db "fromValues"
n_from_values_len equ $-n_from_values
n_bit_and: db "bitAnd"
n_bit_and_len equ $-n_bit_and
n_bit_or: db "bitOr"
n_bit_or_len equ $-n_bit_or
n_bit_xor: db "bitXor"
n_bit_xor_len equ $-n_bit_xor
n_bit_not: db "bitNot"
n_bit_not_len equ $-n_bit_not
n_shift_left: db "shiftLeft"
n_shift_left_len equ $-n_shift_left
n_shift_right: db "shiftRight"
n_shift_right_len equ $-n_shift_right
n_test_bit: db "testBit"
n_test_bit_len equ $-n_test_bit
n_with_bit: db "withBit"
n_with_bit_len equ $-n_with_bit
n_to_float: db "toFloat"
n_to_float_len equ $-n_to_float
n_sqrt: db "sqrt"
n_sqrt_len equ $-n_sqrt
n_cube_root: db "cubeRoot"
n_cube_root_len equ $-n_cube_root
n_fourth_root: db "fourthRoot"
n_fourth_root_len equ $-n_fourth_root
n_factorial: db "factorial"
n_factorial_len equ $-n_factorial
n_floor: db "floor"
n_floor_len equ $-n_floor
n_ceil: db "ceil"
n_ceil_len equ $-n_ceil
n_is_finite: db "isFinite"
n_is_finite_len equ $-n_is_finite
n_is_nan: db "isNaN"
n_is_nan_len equ $-n_is_nan
n_is_infinite: db "isInfinite"
n_is_infinite_len equ $-n_is_infinite
n_is_negative_zero: db "isNegativeZero"
n_is_negative_zero_len equ $-n_is_negative_zero
n_byte_length: db "byteLength"
n_byte_length_len equ $-n_byte_length
n_codepoint_count: db "codepointCount"
n_codepoint_count_len equ $-n_codepoint_count
n_codepoint: db "codepoint"
n_codepoint_len equ $-n_codepoint
n_swap: db "swap"
n_swap_len equ $-n_swap
n_replace: db "replace"
n_replace_len equ $-n_replace
n_checked_add: db "checkedAdd"
n_checked_add_len equ $-n_checked_add
n_wrapping_add: db "wrappingAdd"
n_wrapping_add_len equ $-n_wrapping_add
n_saturating_add: db "saturatingAdd"
n_saturating_add_len equ $-n_saturating_add
n_checked_div: db "checkedDiv"
n_checked_div_len equ $-n_checked_div
n_checked_shift: db "checkedShift"
n_checked_shift_len equ $-n_checked_shift
n_overflowing_mul: db "overflowingMul"
n_overflowing_mul_len equ $-n_overflowing_mul
n_get: db "get"
n_get_len equ $-n_get
n_is_some: db "isSome"
n_is_some_len equ $-n_is_some
n_value: db "value"
n_value_len equ $-n_value
n_overflowed: db "overflowed"
n_overflowed_len equ $-n_overflowed
n_exclusive: db "exclusive"
n_exclusive_len equ $-n_exclusive
n_iterator: db "iterator"
n_iterator_len equ $-n_iterator
n_next: db "next"
n_next_len equ $-n_next
n_size_hint: db "sizeHint"
n_size_hint_len equ $-n_size_hint
n_lower: db "lower"
n_lower_len equ $-n_lower
n_upper: db "upper"
n_upper_len equ $-n_upper
n_unreachable: db "unreachable"
n_unreachable_len equ $-n_unreachable
n_assert: db "assert"
n_assert_len equ $-n_assert
n_assume: db "assume"
n_assume_len equ $-n_assume
n_uncertain_type: db "Uncertain"
n_uncertain_type_len equ $-n_uncertain_type
n_measurement_type: db "Measurement"
n_measurement_type_len equ $-n_measurement_type
n_approx_equals: db "approxEquals"
n_approx_equals_len equ $-n_approx_equals
n_equivalent_to: db "equivalentTo"
n_equivalent_to_len equ $-n_equivalent_to
n_divides: db "divides"
n_divides_len equ $-n_divides
n_proportional_to: db "proportionalTo"
n_proportional_to_len equ $-n_proportional_to
n_add_worst_case: db "addWorstCase"
n_add_worst_case_len equ $-n_add_worst_case
n_add_independent: db "addIndependent"
n_add_independent_len equ $-n_add_independent
n_add_correlated: db "addCorrelated"
n_add_correlated_len equ $-n_add_correlated
n_add_interval: db "addInterval"
n_add_interval_len equ $-n_add_interval
n_measured_value: db "measuredValue"
n_measured_value_len equ $-n_measured_value
n_uncertainty: db "uncertainty"
n_uncertainty_len equ $-n_uncertainty
n_unit_code: db "unitCode"
n_unit_code_len equ $-n_unit_code
n_quality: db "quality"
n_quality_len equ $-n_quality
n_confidence: db "confidence"
n_confidence_len equ $-n_confidence
n_separator_codepoint: db "separatorCodepoint"
n_separator_codepoint_len equ $-n_separator_codepoint
prologue_a: db '    push rbp',10,'    mov rbp, rsp',10,'    sub rsp, '
prologue_a_len equ $-prologue_a
newline: db 10
newline_len equ $-newline
epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    xor eax, eax',10,'    ret',10
epilogue_len equ $-epilogue
return_epilogue: db '.nebo_binding_return:',10,'    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
return_epilogue_len equ $-return_epilogue
return_save: db '    push rax',10
return_save_len equ $-return_save
return_jump: db '    pop rax',10,'    jmp .nebo_binding_return',10
return_jump_len equ $-return_jump
overflow_trap: db '.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
overflow_trap_len equ $-overflow_trap
mov_rax: db '    mov rax, '
mov_rax_len equ $-mov_rax
mov_eax: db '    mov eax, '
mov_eax_len equ $-mov_eax
movq_xmm0: db '    movq xmm0, rax',10
movq_xmm0_len equ $-movq_xmm0
lea_text: db '    lea rax, [rel nebo_text_desc'
lea_text_len equ $-lea_text
lea_bytes: db '    lea rax, [rel nebo_bytes_desc'
lea_bytes_len equ $-lea_bytes
close_bracket: db ']',10
close_bracket_len equ $-close_bracket
binding_codegen_push_rax: db '    push rax',10
push_rax_len equ $-binding_codegen_push_rax
binding_codegen_pop_rax: db '    pop rax',10
pop_rax_len equ $-binding_codegen_pop_rax
binding_codegen_lateral_save_rax: db '    sub rsp, 16',10,'    mov [rsp], rax',10
lateral_save_rax_len equ $-binding_codegen_lateral_save_rax
binding_codegen_lateral_restore_rax: db '    mov rax, [rsp]',10,'    add rsp, 16',10
lateral_restore_rax_len equ $-binding_codegen_lateral_restore_rax
compound_add: db '    mov rcx, rax',10,'    pop rax',10,'    add rax, rcx',10,'    jo .nebo_trap_overflow',10
compound_add_len equ $-compound_add
compound_sub: db '    mov rcx, rax',10,'    pop rax',10,'    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
compound_sub_len equ $-compound_sub
compound_mul: db '    mov rcx, rax',10,'    pop rax',10,'    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
compound_mul_len equ $-compound_mul
compound_div: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_divide',10
compound_div_len equ $-compound_div
compound_rem: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_remainder',10
compound_rem_len equ $-compound_rem
compound_power: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_power',10
compound_power_len equ $-compound_power
bit_and: db '    pop rcx',10,'    and rax, rcx',10
bit_and_len equ $-bit_and
bit_or: db '    pop rcx',10,'    or rax, rcx',10
bit_or_len equ $-bit_or
bit_xor: db '    pop rcx',10,'    xor rax, rcx',10
bit_xor_len equ $-bit_xor
bit_not: db '    not rax',10
bit_not_len equ $-bit_not
shift_left: db '    shl rax, '
shift_left_len equ $-shift_left
shift_right: db '    sar rax, '
shift_right_len equ $-shift_right
test_bit: db '    bt rax, '
test_bit_len equ $-test_bit
binding_codegen_test_bit_suffix: db 10,'    setc al',10,'    movzx rax, al',10
test_bit_suffix_len equ $-binding_codegen_test_bit_suffix
with_bit_position: db '    mov ecx, '
with_bit_position_len equ $-with_bit_position
with_bit_suffix: db 10,'    neg rax',10,'    mov rdx, rax',10,'    pop rax',10,'    btr rax, rcx',10,'    mov r8, 1',10,'    shl r8, cl',10,'    and r8, rdx',10,'    or rax, r8',10
with_bit_suffix_len equ $-with_bit_suffix
store_byte: db '    mov [rbp - '
store_byte_len equ $-store_byte
store_byte_suffix: db '], al',10
store_byte_suffix_len equ $-store_byte_suffix
store_dword_suffix: db '], eax',10
store_dword_suffix_len equ $-store_dword_suffix
store_qword_suffix: db '], rax',10
store_qword_suffix_len equ $-store_qword_suffix
store_rdx_suffix: db '], rdx',10
store_rdx_suffix_len equ $-store_rdx_suffix
store_float_prefix: db '    movsd [rbp - '
store_float_prefix_len equ $-store_float_prefix
store_float_suffix: db '], xmm0',10
store_float_suffix_len equ $-store_float_suffix
load_bool_prefix: db '    movzx eax, byte [rbp - '
load_bool_prefix_len equ $-load_bool_prefix
load_int_prefix: db '    mov rax, [rbp - '
load_int_prefix_len equ $-load_int_prefix
load_rdx_prefix: db '    mov rdx, [rbp - '
load_rdx_prefix_len equ $-load_rdx_prefix
load_char_prefix: db '    mov eax, [rbp - '
load_char_prefix_len equ $-load_char_prefix
load_float_prefix: db '    mov rax, [rbp - '
load_float_prefix_len equ $-load_float_prefix
load_float_suffix: db ']',10,'    movq xmm0, rax',10
load_float_suffix_len equ $-load_float_suffix
mem_suffix: db ']',10
mem_suffix_len equ $-mem_suffix
test_rax: db '    test rax, rax',10,'    jz ._else'
test_rax_len equ $-test_rax
jmp_end: db '    jmp ._end'
jmp_end_len equ $-jmp_end
label_else: db '._else'
label_else_len equ $-label_else
label_end: db '._end'
label_end_len equ $-label_end
colon_nl: db ':',10
colon_nl_len equ $-colon_nl
loop_header: db '._loop_header'
loop_header_len equ $-loop_header
loop_exit: db '._loop_exit'
loop_exit_len equ $-loop_exit
loop_test_exit: db '    test rax, rax',10,'    jz ._loop_exit'
loop_test_exit_len equ $-loop_test_exit
loop_jump_header: db '    jmp ._loop_header'
loop_jump_header_len equ $-loop_jump_header
loop_jump_latch: db '    jmp ._loop_latch'
loop_jump_latch_len equ $-loop_jump_latch
loop_jump_exit: db '    jmp ._loop_exit'
loop_jump_exit_len equ $-loop_jump_exit
loop_latch: db '._loop_latch'
loop_latch_len equ $-loop_latch
loop_test_repeat: db '    test rax, rax',10,'    jnz ._loop_header'
loop_test_repeat_len equ $-loop_test_repeat
mov_rdi_rax: db '    mov rdi, rax',10
mov_rdi_rax_len equ $-mov_rdi_rax
call_to_float: db '    call nebo_runtime_numeric_safety_int_to_float',10
call_to_float_len equ $-call_to_float
call_is_finite: db '    call nebo_runtime_numeric_safety_is_finite',10
call_is_finite_len equ $-call_is_finite
call_is_nan: db '    call nebo_runtime_numeric_safety_is_nan',10
call_is_nan_len equ $-call_is_nan
call_is_infinite: db '    call nebo_runtime_numeric_safety_is_infinite',10
call_is_infinite_len equ $-call_is_infinite
call_is_negative_zero: db '    call nebo_runtime_numeric_safety_is_negative_zero',10
call_is_negative_zero_len equ $-call_is_negative_zero
call_text_byte_length: db '    call nebo_runtime_textual_text_byte_length',10
call_text_byte_length_len equ $-call_text_byte_length
call_text_codepoint_count: db '    call nebo_runtime_textual_text_codepoint_count',10
call_text_codepoint_count_len equ $-call_text_codepoint_count
call_char_codepoint: db '    call nebo_runtime_textual_char_codepoint',10
call_char_codepoint_len equ $-call_char_codepoint
call_bytes_empty: db '    call nebo_runtime_textual_bytes_empty',10
call_bytes_empty_len equ $-call_bytes_empty
call_bytes_byte_length: db '    call nebo_runtime_textual_bytes_byte_length',10
call_bytes_byte_length_len equ $-call_bytes_byte_length
call_console_publish_text: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_text',10
call_console_publish_text_len equ $-call_console_publish_text
call_console_publish_int: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_int',10
call_console_publish_int_len equ $-call_console_publish_int
call_console_publish_bool: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_bool',10
call_console_publish_bool_len equ $-call_console_publish_bool
scan_mov_esi: db '    mov esi, '
scan_mov_esi_len equ $-scan_mov_esi
scan_mov_edx: db '    mov edx, '
scan_mov_edx_len equ $-scan_mov_edx
scan_mov_ecx: db '    mov ecx, '
scan_mov_ecx_len equ $-scan_mov_ecx
call_scan_stdin: db '    mov rdi, rax',10,'    call nebo_runtime_scan_stdin_text',10
call_scan_stdin_len equ $-call_scan_stdin
call_scan_console_handle: db '    mov rdi, rax',10,'    call nebo_runtime_scan_console_handle',10
call_scan_console_handle_len equ $-call_scan_console_handle
binary_restore: db '    mov rcx, rax',10,'    pop rax',10
binary_restore_len equ $-binary_restore
binary_add: db '    add rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_add_len equ $-binary_add
binary_sub: db '    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_sub_len equ $-binary_sub
binary_mul: db '    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_mul_len equ $-binary_mul
binary_runtime_div: db '    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_divide',10
binary_runtime_div_len equ $-binary_runtime_div
binary_runtime_rem: db '    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_remainder',10
binary_runtime_rem_len equ $-binary_runtime_rem
binary_runtime_power: db '    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_power',10
binary_runtime_power_len equ $-binary_runtime_power
binary_runtime_float_power: db '    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_float_power_int',10,'    movq xmm0, rax',10
binary_runtime_float_power_len equ $-binary_runtime_float_power
binary_xor_scalar: db '    xor rax, rcx',10
binary_xor_scalar_len equ $-binary_xor_scalar
binary_xor_bytes: db '    sub rsp, 4128',10,'    mov r8, rsp',10,'    lea rdx, [rsp + 32]',10,'    mov rdi, rax',10,'    mov rsi, rcx',10,'    mov rcx, 4096',10,'    call nebo_runtime_bytes_xor',10
binary_xor_bytes_len equ $-binary_xor_bytes
binary_spaceship_scalar: db '    cmp rax, rcx',10,'    setge al',10,'    setg dl',10,'    movzx eax, al',10,'    movzx edx, dl',10,'    add rax, rdx',10
binary_spaceship_scalar_len equ $-binary_spaceship_scalar
binary_div_prefix: db '    test rcx, rcx',10,'    jz .nebo_trap_division_by_zero',10,'    mov rdx, 0x8000000000000000',10,'    cmp rax, rdx',10,'    jne ._div_ok'
binary_div_prefix_len equ $-binary_div_prefix
binary_div_mid: db 10,'    cmp rcx, -1',10,'    je .nebo_trap_overflow',10,'._div_ok'
binary_div_mid_len equ $-binary_div_mid
binary_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10
binary_div_tail_len equ $-binary_div_tail
binary_mod_tail: db '    mov rax, rdx',10
binary_mod_tail_len equ $-binary_mod_tail
division_trap: db '.nebo_trap_division_by_zero:',10,'    jmp nebo_runtime_trap_division_by_zero',10
division_trap_len equ $-division_trap
neg_rax: db '    neg rax',10,'    jo .nebo_trap_overflow',10
neg_rax_len equ $-neg_rax
neg_float: db '    mov rdx, 0x8000000000000000',10,'    xor rax, rdx',10,'    movq xmm0, rax',10
neg_float_len equ $-neg_float
not_rax: db '    test rax, rax',10,'    sete al',10,'    movzx eax, al',10
not_rax_len equ $-not_rax
binding_quantity_percent: db '    mov rdi, rax',10,'    call nebo_runtime_quantity_percent',10
binding_quantity_percent_len equ $-binding_quantity_percent
binding_quantity_per_mille: db '    mov rdi, rax',10,'    call nebo_runtime_quantity_per_mille',10
binding_quantity_per_mille_len equ $-binding_quantity_per_mille
binding_quantity_angle: db '    mov rdi, rax',10,'    call nebo_runtime_quantity_angle',10
binding_quantity_angle_len equ $-binding_quantity_angle
binding_quantity_celsius: db '    mov rdi, rax',10,'    call nebo_runtime_quantity_celsius',10
binding_quantity_celsius_len equ $-binding_quantity_celsius
binding_quantity_fahrenheit: db '    mov rdi, rax',10,'    call nebo_runtime_quantity_fahrenheit',10
binding_quantity_fahrenheit_len equ $-binding_quantity_fahrenheit
binding_math_square_root: db '    mov rdi, rax',10,'    call nebo_runtime_math_square_root_exact',10
binding_math_square_root_len equ $-binding_math_square_root
binding_math_cube_root: db '    mov rdi, rax',10,'    call nebo_runtime_math_cube_root_exact',10
binding_math_cube_root_len equ $-binding_math_cube_root
binding_math_fourth_root: db '    mov rdi, rax',10,'    call nebo_runtime_math_fourth_root_exact',10
binding_math_fourth_root_len equ $-binding_math_fourth_root
binding_math_factorial: db '    mov rdi, rax',10,'    call nebo_runtime_math_factorial_checked',10
binding_math_factorial_len equ $-binding_math_factorial
binding_math_floor: db '    movq rdi, xmm0',10,'    call nebo_runtime_math_floor',10
binding_math_floor_len equ $-binding_math_floor
binding_math_ceil: db '    movq rdi, xmm0',10,'    call nebo_runtime_math_ceil',10
binding_math_ceil_len equ $-binding_math_ceil
binding_math_infinity: db '    call nebo_runtime_math_infinity',10
binding_math_infinity_len equ $-binding_math_infinity
binding_math_pi: db '    call nebo_runtime_math_pi',10
binding_math_pi_len equ $-binding_math_pi
binding_math_tau: db '    call nebo_runtime_math_tau',10
binding_math_tau_len equ $-binding_math_tau
g131_uncertain_binary: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_uncertain_create',10
g131_uncertain_binary_len equ $-g131_uncertain_binary
g131_binary_prepare: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdi, rax',10,'    mov rsi, rcx',10
g131_binary_prepare_len equ $-g131_binary_prepare
g131_alloc_16: db '    sub rsp, 16',10
g131_alloc_16_len equ $-g131_alloc_16
g131_alloc_48: db '    sub rsp, 48',10
g131_alloc_48_len equ $-g131_alloc_48
g131_store_0: db '    mov [rsp], rax',10
g131_store_0_len equ $-g131_store_0
g131_store_8: db '    mov [rsp + 8], rax',10
g131_store_8_len equ $-g131_store_8
g131_store_16: db '    mov [rsp + 16], rax',10
g131_store_16_len equ $-g131_store_16
g131_store_24: db '    mov [rsp + 24], rax',10
g131_store_24_len equ $-g131_store_24
g131_store_32: db '    mov [rsp + 32], rax',10
g131_store_32_len equ $-g131_store_32
g131_uncertain_load: db '    mov rsi, rax',10,'    mov rdi, [rsp]',10,'    add rsp, 16',10,'    call nebo_runtime_uncertain_create',10
g131_uncertain_load_len equ $-g131_uncertain_load
g131_measurement_load: db '    mov r8, [rsp + 32]',10,'    mov rcx, [rsp + 24]',10,'    mov rdx, [rsp + 16]',10,'    mov rsi, [rsp + 8]',10,'    mov rdi, [rsp]',10,'    add rsp, 48',10,'    call nebo_runtime_measurement_create',10
g131_measurement_load_len equ $-g131_measurement_load
g131_save_receiver: db '    sub rsp, 16',10,'    mov [rsp], rax',10
g131_save_receiver_len equ $-g131_save_receiver
g131_prepare_method: db '    mov rsi, rax',10,'    mov rdi, [rsp]',10,'    add rsp, 16',10
g131_prepare_method_len equ $-g131_prepare_method
g131_prepare_unary: db '    mov rdi, rax',10
g131_prepare_unary_len equ $-g131_prepare_unary
g131_call_approx: db '    call nebo_runtime_uncertain_approx_equal',10
g131_call_approx_len equ $-g131_call_approx
g131_call_not_approx: db '    call nebo_runtime_uncertain_not_approx_equal',10
g131_call_not_approx_len equ $-g131_call_not_approx
g131_call_equivalent: db '    call nebo_runtime_uncertain_equivalent',10
g131_call_equivalent_len equ $-g131_call_equivalent
g131_call_divides: db '    call nebo_runtime_int_divides',10
g131_call_divides_len equ $-g131_call_divides
g131_call_not_divides: db '    call nebo_runtime_int_not_divides',10
g131_call_not_divides_len equ $-g131_call_not_divides
g131_call_proportional: db '    call nebo_runtime_uncertain_proportional',10
g131_call_proportional_len equ $-g131_call_proportional
g131_call_worst: db '    call nebo_runtime_uncertain_add_worst_case',10
g131_call_worst_len equ $-g131_call_worst
g131_call_independent: db '    call nebo_runtime_uncertain_add_independent',10
g131_call_independent_len equ $-g131_call_independent
g131_call_correlated: db '    call nebo_runtime_uncertain_add_correlated',10
g131_call_correlated_len equ $-g131_call_correlated
g131_call_interval: db '    call nebo_runtime_uncertain_add_interval',10
g131_call_interval_len equ $-g131_call_interval
g131_call_value: db '    call nebo_runtime_uncertain_value',10
g131_call_value_len equ $-g131_call_value
g131_call_uncertainty: db '    call nebo_runtime_uncertain_uncertainty',10
g131_call_uncertainty_len equ $-g131_call_uncertainty
g131_call_unit: db '    call nebo_runtime_uncertain_unit',10
g131_call_unit_len equ $-g131_call_unit
g131_call_quality: db '    call nebo_runtime_uncertain_quality',10
g131_call_quality_len equ $-g131_call_quality
g131_call_confidence: db '    call nebo_runtime_uncertain_confidence',10
g131_call_confidence_len equ $-g131_call_confidence
g131_call_separator: db '    call nebo_runtime_uncertain_separator_codepoint',10
g131_call_separator_len equ $-g131_call_separator
cmp_prefix: db '    push rax',10
cmp_prefix_len equ $-cmp_prefix
text_equal_call: db '    mov rsi, rax',10,'    pop rdi',10,'    call nebo_runtime_text_equal',10
text_equal_call_len equ $-text_equal_call
cmp_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    sete al',10,'    movzx eax, al',10
cmp_suffix_len equ $-cmp_suffix
cmp_ne_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setne al',10,'    movzx eax, al',10
cmp_ne_suffix_len equ $-cmp_ne_suffix
cmp_lt_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setl al',10,'    movzx eax, al',10
cmp_lt_suffix_len equ $-cmp_lt_suffix
cmp_le_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setle al',10,'    movzx eax, al',10
cmp_le_suffix_len equ $-cmp_le_suffix
cmp_gt_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setg al',10,'    movzx eax, al',10
cmp_gt_suffix_len equ $-cmp_gt_suffix
cmp_ge_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setge al',10,'    movzx eax, al',10
cmp_ge_suffix_len equ $-cmp_ge_suffix
logical_and_branch: db '    test rax, rax',10,'    jz .nebo_binding_bool_false_'
logical_and_branch_len equ $-logical_and_branch
logical_or_branch: db '    test rax, rax',10,'    jnz .nebo_binding_bool_true_'
logical_or_branch_len equ $-logical_or_branch
logical_bool_canon_done: db '    test rax, rax',10,'    setne al',10,'    movzx eax, al',10,'    jmp .nebo_binding_bool_end_'
logical_bool_canon_done_len equ $-logical_bool_canon_done
logical_false_label: db 10,'.nebo_binding_bool_false_'
logical_false_label_len equ $-logical_false_label
logical_false_body: db ':',10,'    xor eax, eax',10,'.nebo_binding_bool_end_'
logical_false_body_len equ $-logical_false_body
logical_true_label: db 10,'.nebo_binding_bool_true_'
logical_true_label_len equ $-logical_true_label
logical_true_body: db ':',10,'    mov eax, 1',10,'.nebo_binding_bool_end_'
logical_true_body_len equ $-logical_true_body
logical_label_end: db ':',10
logical_label_end_len equ $-logical_label_end
safe_checked_add: db '    mov rcx, rax',10,'    pop rax',10,'    add rax, rcx',10,'    setno dl',10,'    movzx edx, dl',10
safe_checked_add_len equ $-safe_checked_add
safe_wrapping_add: db '    mov rcx, rax',10,'    pop rax',10,'    add rax, rcx',10
safe_wrapping_add_len equ $-safe_wrapping_add
safe_saturating_add: db '    mov rcx, rax',10,'    pop rax',10,'    mov rdx, rax',10,'    xor r9d, r9d',10,'    add rax, rcx',10,'    seto r9b',10,'    mov r8, 0x7fffffffffffffff',10,'    mov r10, 0x8000000000000000',10,'    test rdx, rdx',10,'    cmovs r8, r10',10,'    test r9b, r9b',10,'    cmovne rax, r8',10
safe_saturating_add_len equ $-safe_saturating_add
safe_checked_div_prefix: db '    mov rcx, rax',10,'    pop rax',10,'    xor edx, edx',10,'    test rcx, rcx',10,'    jz .nebo_checked_done_'
safe_checked_div_prefix_len equ $-safe_checked_div_prefix
safe_checked_div_mid: db 10,'    mov r8, 0x8000000000000000',10,'    cmp rax, r8',10,'    jne .nebo_checked_div_ok_'
safe_checked_div_mid_len equ $-safe_checked_div_mid
safe_checked_div_min: db 10,'    cmp rcx, -1',10,'    je .nebo_checked_done_'
safe_checked_div_min_len equ $-safe_checked_div_min
safe_checked_div_ok: db 10,'.nebo_checked_div_ok_'
safe_checked_div_ok_len equ $-safe_checked_div_ok
safe_checked_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10,'    mov edx, 1',10,'.nebo_checked_done_'
safe_checked_div_tail_len equ $-safe_checked_div_tail
safe_checked_shift_prefix: db '    mov rcx, rax',10,'    pop rax',10,'    xor edx, edx',10,'    test rcx, rcx',10,'    js .nebo_checked_done_'
safe_checked_shift_prefix_len equ $-safe_checked_shift_prefix
safe_checked_shift_mid: db 10,'    cmp rcx, 63',10,'    jg .nebo_checked_done_'
safe_checked_shift_mid_len equ $-safe_checked_shift_mid
safe_checked_shift_tail: db 10,'    shl rax, cl',10,'    mov edx, 1',10,'.nebo_checked_done_'
safe_checked_shift_tail_len equ $-safe_checked_shift_tail
safe_overflowing_mul: db '    mov rcx, rax',10,'    pop rax',10,'    imul rax, rcx',10,'    seto dl',10,'    movzx edx, dl',10
safe_overflowing_mul_len equ $-safe_overflowing_mul
option_is_some: db '    mov rax, rdx',10
option_is_some_len equ $-option_is_some
option_get_prefix: db '    test rdx, rdx',10,'    jnz .nebo_option_some_'
option_get_prefix_len equ $-option_get_prefix
option_get_trap: db 10,'    mov edi, 47',10,'    jmp nebo_runtime_trap',10,'.nebo_option_some_'
option_get_trap_len equ $-option_get_trap
range_pair: db '    mov rdx, rax',10,'    pop rax',10
range_pair_len equ $-range_pair
iterator_next: db '    cmp rax, rdx',10,'    setl dl',10,'    movzx edx, dl',10
iterator_next_len equ $-iterator_next
iterator_advance_a: db '    mov rcx, rax',10,'    inc rcx',10,'    cmp rax, rdx',10,'    cmovge rcx, rax',10,'    mov [rbp - '
iterator_advance_a_len equ $-iterator_advance_a
iterator_advance_b: db '], rcx',10
iterator_advance_b_len equ $-iterator_advance_b
iterator_hint: db '    sub rdx, rax',10,'    xor eax, eax',10,'    test rdx, rdx',10,'    cmovs rdx, rax',10,'    mov rax, rdx',10
iterator_hint_len equ $-iterator_hint
move_upper: db '    mov rax, rdx',10
move_upper_len equ $-move_upper
flow_assert_prefix: db '    test rax, rax',10,'    jnz .nebo_flow_assert_ok_'
flow_assert_prefix_len equ $-flow_assert_prefix
flow_assert_trap: db '    mov edi, 47',10,'    jmp nebo_runtime_trap',10,'.nebo_flow_assert_ok_'
flow_assert_trap_len equ $-flow_assert_trap
flow_unreachable_trap: db '    mov edi, 48',10,'    jmp nebo_runtime_trap',10
flow_unreachable_trap_len equ $-flow_unreachable_trap
flow_assume_nop: db '    xor eax, eax',10
flow_assume_nop_len equ $-flow_assume_nop

section .text
NEBOC_ABI_FUNCTION neboc_binding_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 test r14,r14
 jz .invalid
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_NODE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],0
 mov qword [r12+NEBOC_CODEGEN_BRANCH_INDEX_OFFSET],0
 mov qword [r12+NEBOC_CODEGEN_LOOP_INDEX_OFFSET],0
 mov qword [r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET],0
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .depth_ready
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_DEFAULT
.depth_ready:
 mov rdi,r12
 call neboc_scoped_slots_assign
 test eax,eax
 jnz .done
 ; Find start block.
 mov rdi,r12
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ROOT_ID_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 ; Emit frame prologue.
 mov rdi,r12
 lea rsi,[rel prologue_a]
 mov edx,prologue_a_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FRAME_SIZE_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r15
 xor edx,edx
 call g05c_emit_block
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel epilogue]
 mov edx,epilogue_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel return_epilogue]
 mov edx,return_epilogue_len
 call g05c_append
 test eax,eax
 jnz .done
 ; Unary negation as well as compound/binary arithmetic can reference the
 ; checked trap labels, so emit both stable tails unconditionally.
 mov rdi,r12
 lea rsi,[rel overflow_trap]
 mov edx,overflow_trap_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel division_trap]
 mov edx,division_trap_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request* -> assign aligned rbp-relative offsets to final symbols
g05c_assign_slots:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 jae .finish
 mov rax,r13
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .size1
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .size4
 cmp rax,NEBOC_BIND_TYPE_INT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_TEXT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_BYTES
 je .size8
 cmp rax,NEBOC_BIND_TYPE_OPTION_INT
 je .size16
 cmp rax,NEBOC_BIND_TYPE_OVERFLOW_INT
 je .size16
 cmp rax,NEBOC_BIND_TYPE_RANGE_INT
 je .size16
 cmp rax,NEBOC_BIND_TYPE_ITERATOR_INT
 je .size16
 cmp rax,NEBOC_BIND_TYPE_SIZE_HINT
 je .size16
 jmp .bad
.size1: mov ecx,1
 mov edx,1
 jmp .place
.size4: mov ecx,4
 mov edx,4
 jmp .place
.size8: mov ecx,8
 mov edx,8
 jmp .place
.size16: mov ecx,8
 mov edx,16
.place:
 mov eax,r14d
 add eax,edx
 dec ecx
 add eax,ecx
 not ecx
 and eax,ecx
 mov r14d,eax
 mov [rbx+NEBOC_SYMBOL_SLOT_OFFSET],rax
 inc r13
 jmp .loop
.finish:
 mov eax,r14d
 add eax,15
 and eax,-16
 test eax,eax
 jnz .store
 mov eax,16
.store:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FRAME_SIZE_OFFSET],rax
 xor eax,eax
 jmp .done
.bad:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, block id, depth
g05c_emit_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET]
 mov [rsp],rax
 cmp r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET]
 jae .unsupported
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test rbx,rbx
 jz .ok
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BINDING_STMT
 je .binding
 cmp rcx,NEBOC_AST_ASSIGNMENT_STMT
 je .assignment
 cmp rcx,NEBOC_AST_EXPRESSION_STMT
 je .expression
 cmp rcx,NEBOC_AST_IF_STMT
 je .if
 cmp rcx,NEBOC_AST_WHILE_STMT
 je .loop_stmt
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .loop_stmt
 cmp rcx,NEBOC_AST_DO_WHILE_STMT
 je .loop_stmt
 cmp rcx,NEBOC_AST_BREAK_STMT
 je .control
 cmp rcx,NEBOC_AST_CONTINUE_STMT
 je .control
 cmp rcx,NEBOC_AST_DEFER_STMT
 je .defer
 cmp rcx,NEBOC_AST_RETURN_STMT
 je .return
 jmp .unsupported
.binding:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_binding
 jmp .checked
.assignment:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_assignment
 jmp .checked
.expression:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 jmp .checked
.if:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_if
 jmp .checked
.loop_stmt:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_loop
 jmp .checked
.control:
 mov rdi,r12
 mov rsi,rbx
 call g05c_emit_loop_control
 jmp .checked
.defer:
 ; Deferred actions are scheduled by the cleanup-stack path below.
 mov rdi,r12
 mov rsi,rbx
 call g05c_schedule_defer
 jmp .checked
.return:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_return
.checked:
 test eax,eax
 jnz .done
 mov rbx,r15
 jmp .loop
.ok:
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 mov rcx,[rsp]
 mov [r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET],rcx
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, return node id, depth -> emit the Int value, unwind all active
; lexical defers exactly once, then branch to the preserving epilogue.
g05c_emit_return:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne .ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel return_save]
 mov edx,return_save_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 xor esi,esi
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel return_jump]
 mov edx,return_jump_len
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, defer node id -> schedule its expression in the bounded lexical
; cleanup stack.  Emission happens in reverse order at every scope exit.
g05c_schedule_defer:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_DEFER_STMT
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rax,[r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_CODEGEN_DEFER_CAPACITY_OFFSET]
 jae .limit
 mov rcx,[r12+NEBOC_CODEGEN_DEFER_STACK_OFFSET]
 test rcx,rcx
 jz .ast
 mov [rcx+rax*8],rbx
 inc rax
 mov [r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET],rax
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.limit:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, lower-bound -> emit scheduled actions [lower,count) in LIFO order.
g05c_emit_defer_range:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,[r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET]
 cmp r13,rbx
 ja .ast
.loop:
 cmp rbx,r13
 jbe .ok
 dec rbx
 mov rax,[r12+NEBOC_CODEGEN_DEFER_STACK_OFFSET]
 test rax,rax
 jz .ast
 mov rsi,[rax+rbx*8]
 mov rdi,r12
 xor edx,edx
 call g05c_emit_expr
 test eax,eax
 jnz .done
 jmp .loop
.ok:
 xor eax,eax
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, while/loop node id, depth -> status
g05c_emit_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 mov [rsp],rax
 cmp rax,NEBOC_AST_WHILE_STMT
 je .shape
 cmp rax,NEBOC_AST_DO_WHILE_STMT
 je .shape
 cmp rax,NEBOC_AST_LOOP_STMT
 jne .ast
.shape:
 mov rax,[r12+NEBOC_CODEGEN_LOOP_INDEX_OFFSET]
 cmp rax,[r12+NEBOC_CODEGEN_LOOP_SNAPSHOT_COUNT_OFFSET]
 jae .ast
 mov [rsp+16],rax
 inc qword [r12+NEBOC_CODEGEN_LOOP_INDEX_OFFSET]
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov [rsp+24],rax
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 mov [rsp+32],rax
 mov rax,NEBOC_VERTICAL_LOOP_SNAPSHOT_BYTES
 imul rax,[rsp+16]
 add rax,[r12+NEBOC_CODEGEN_LOOP_BODIES_OFFSET]
 mov [rsp+40],rax
 mov rax,[r12+NEBOC_CODEGEN_LOOP_BODY_COUNTS_OFFSET]
 mov rcx,[rsp+16]
 mov rax,[rax+rcx*8]
 mov [rsp+48],rax
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 cmp rax,NEBOC_CODEGEN_MAX_LOOP_DEPTH
 jae .unsupported
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_STACK_OFFSET]
 test rcx,rcx
 jz .ast
 mov [rcx+rax*8],r13
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_DEFER_BASES_OFFSET]
 test rcx,rcx
 jz .ast
 mov rdx,[r12+NEBOC_CODEGEN_DEFER_COUNT_OFFSET]
 mov [rcx+rax*8],rdx
 inc qword [r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,r12
 lea rsi,[rel loop_header]
 mov edx,loop_header_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 cmp qword [rsp],NEBOC_AST_WHILE_STMT
 je .while_condition
 cmp qword [rsp],NEBOC_AST_DO_WHILE_STMT
 je .do_body
 jmp .explicit_body
.while_condition:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast_pop
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 lea rsi,[rel loop_test_exit]
 mov edx,loop_test_exit_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast_pop
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast_pop
 jmp .emit_body
.explicit_body:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast_pop
.do_body:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast_pop
.emit_body:
 mov rax,[rsp+40]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+48]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_block
 test eax,eax
 jnz .pop_done
 cmp qword [rsp],NEBOC_AST_DO_WHILE_STMT
 jne .ordinary_latch
 mov rdi,r12
 lea rsi,[rel loop_latch]
 mov edx,loop_latch_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast_pop
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast_pop
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 lea rsi,[rel loop_test_repeat]
 mov edx,loop_test_repeat_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 jmp .emit_exit
.ordinary_latch:
 mov rdi,r12
 lea rsi,[rel loop_jump_header]
 mov edx,loop_jump_header_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .pop_done
.emit_exit:
 mov rdi,r12
 lea rsi,[rel loop_exit]
 mov edx,loop_exit_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
.pop_done:
 mov [rsp+8],rax
 mov rax,[rsp+24]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 dec qword [r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rax,[rsp+8]
 jmp .done
.writer_pop:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .pop_done
.ast_pop:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .pop_done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, break/continue node id -> status
g05c_emit_loop_control:
 push rbx
 push r12
 push r13
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 test rax,rax
 jz .unsupported
 dec rax
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_STACK_OFFSET]
 test rcx,rcx
 jz .ast
 mov rbx,[rcx+rax*8]
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rax,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_BREAK_STMT
 je .break
 cmp rax,NEBOC_AST_CONTINUE_STMT
 jne .ast
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 dec rax
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_DEFER_BASES_OFFSET]
 test rcx,rcx
 jz .ast
 mov rsi,[rcx+rax*8]
 mov rdi,r12
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_DO_WHILE_STMT
 jne .continue_header
 lea rsi,[rel loop_jump_latch]
 mov edx,loop_jump_latch_len
 jmp .emit
.continue_header:
 lea rsi,[rel loop_jump_header]
 mov edx,loop_jump_header_len
 jmp .emit
.break:
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .break_jump
 mov rdi,r12
 xor edx,edx
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rsi,-1
 je .ast
 mov rdi,r12
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov rdi,r12
 mov rsi,rax
 call g05c_emit_store
 test eax,eax
 jnz .done
.break_jump:
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 dec rax
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_DEFER_BASES_OFFSET]
 test rcx,rcx
 jz .ast
 mov rsi,[rcx+rax*8]
 mov rdi,r12
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 lea rsi,[rel loop_jump_exit]
 mov edx,loop_jump_exit_len
.emit:
 mov rdi,r12
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,rbx
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r13
 pop r12
 pop rbx
 ret

; request*, binding statement, depth
g05c_emit_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .ast
 ; Preserve the terminal AST node ID.  g05c_node_ptr consumes node IDs, not
 ; materialized pointers; storing RAX here made every initialized binding fail
 ; codegen during `neboc check` after the semantic pass had succeeded.
 mov [rsp],rbx
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_type_ref
 test eax,eax
 jnz .typed_no_code
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05c_emit_store
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.typed_no_code:
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, assignment statement, depth. Semantic validation already proved a
; mutable local scalar; codegen evaluates RHS once and emits exactly one store.
g05c_emit_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 jne .ast
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 test qword [rax+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_MUTABLE
 jz .symbol
 mov [rsp],rax
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+8],rax
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 cmp qword [rsp+8],0
 je .emit_rhs
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_load
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
.emit_rhs:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rax,[rsp+8]
 test rax,rax
 jz .store
 cmp rax,NEBOC_TOKEN_PLUS
 je .add
 cmp rax,NEBOC_TOKEN_MINUS
 je .subtract
 cmp rax,NEBOC_TOKEN_STAR
 je .multiply
 cmp rax,NEBOC_TOKEN_SLASH
 je .divide
 cmp rax,NEBOC_TOKEN_PERCENT
 je .remainder
 cmp rax,NEBOC_TOKEN_CARET
 je .power
 jmp .ast
.subtract:
 mov rdi,r12
 lea rsi,[rel compound_sub]
 mov edx,compound_sub_len
 call g05c_append
 jmp .compound_checked
.add:
 mov rdi,r12
 lea rsi,[rel compound_add]
 mov edx,compound_add_len
 call g05c_append
 jmp .compound_checked
.multiply:
 mov rdi,r12
 lea rsi,[rel compound_mul]
 mov edx,compound_mul_len
 call g05c_append
 jmp .compound_checked
.divide:
 mov rdi,r12
 lea rsi,[rel compound_div]
 mov edx,compound_div_len
 call g05c_append
 jmp .compound_checked
.remainder:
 mov rdi,r12
 lea rsi,[rel compound_rem]
 mov edx,compound_rem_len
 call g05c_append
 jmp .compound_checked
.power:
 mov rdi,r12
 lea rsi,[rel compound_power]
 mov edx,compound_power_len
 call g05c_append
.compound_checked:
 test eax,eax
 jnz .done
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],1
.store:
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_store
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, if node, depth
g05c_emit_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_INDEX_OFFSET]
 cmp rax,[r12+NEBOC_CODEGEN_BRANCH_SNAPSHOT_COUNT_OFFSET]
 jae .ast
 mov [rsp+56],rax
 inc qword [r12+NEBOC_CODEGEN_BRANCH_INDEX_OFFSET]
 mov rcx,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rcx,rax
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 add rdx,rcx
 mov [rsp+24],rdx
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 add rdx,rcx
 mov [rsp+40],rdx
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_A_COUNTS_OFFSET]
 test rdx,rdx
 jz .legacy_counts
 mov rcx,[rdx+rax*8]
 mov [rsp+32],rcx
 mov rdx,[r12+NEBOC_CODEGEN_BRANCH_B_COUNTS_OFFSET]
 test rdx,rdx
 jz .legacy_counts
 mov rcx,[rdx+rax*8]
 mov [rsp+48],rcx
 jmp .snapshots_ready
.legacy_counts:
 cmp qword [rsp+56],0
 jne .ast
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_A_COUNT_OFFSET]
 mov [rsp+32],rax
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_B_COUNT_OFFSET]
 mov [rsp+48],rax
.snapshots_ready:
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov [rsp],rax
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,r12
 mov rsi,r15
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel test_rax]
 mov edx,test_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r15
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 mov rax,[rsp+24]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 call g05c_emit_block
 mov [rsp+16],rax
 mov rax,[rsp]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+16]
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel jmp_end]
 mov edx,jmp_end_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel label_else]
 mov edx,label_else_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .no_else
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .ast
 mov rax,[rsp+40]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+48]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_if
 jmp .else_emitted
.else_block:
 mov rax,[rsp+40]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+48]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_block
.else_emitted:
 mov [rsp+16],rax
 mov rax,[rsp]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+16]
 test eax,eax
 jnz .done
.no_else:
 mov rdi,r12
 lea rsi,[rel label_end]
 mov edx,label_end_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, expression node, depth
g05c_emit_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET]
 jae .unsupported
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .integer
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .boolean
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_MATH_CONSTANT
 je .math_constant
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
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.boolean:
 mov rdi,r12
 lea rsi,[rel mov_eax]
 mov edx,mov_eax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.char:
 mov rdi,r12
 lea rsi,[rel mov_eax]
 mov edx,mov_eax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov esi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.text:
 mov rdi,r12
 lea rsi,[rel lea_text]
 mov edx,lea_text_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel close_bracket]
 mov edx,close_bracket_len
 call g05c_append
 jmp .done
.float:
 mov rbx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_REQUEST_OFFSET]
 test rbx,rbx
 jz .literal_bad
 mov rdi,rbx
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ; FloatLiteral payload0 carries normalized numeric/provenance data. Resolve
 ; the exact source spelling through payload1, the lexer token index, matching
 ; the certified tipos_primitivos_escalares/seguranca_numerica_conversoes_e_overflow Float codegen paths.
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .ast
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKENS_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jbe .literal_bad
 sub rdx,rcx
 add rcx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rcx
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_BITS_OFFSET]
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 mov rdi,rbx
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .literal_bad
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_BITS_OFFSET]
 mov rsi,[rax]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel movq_xmm0]
 mov edx,movq_xmm0_len
 call g05c_append
 jmp .done
.math_constant:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_INFINITY
 je .math_infinity
 cmp rax,NEBOC_TOKEN_PI
 je .math_pi
 cmp rax,NEBOC_TOKEN_TAU
 jne .unsupported
 mov rdi,r12
 lea rsi,[rel binding_math_tau]
 mov edx,binding_math_tau_len
 call g05c_append
 jmp .done
.math_infinity:
 mov rdi,r12
 lea rsi,[rel binding_math_infinity]
 mov edx,binding_math_infinity_len
 call g05c_append
 jmp .done
.math_pi:
 mov rdi,r12
 lea rsi,[rel binding_math_pi]
 mov edx,binding_math_pi_len
 call g05c_append
 jmp .done
.identifier:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov rdi,r12
 mov rsi,rax
 call g05c_emit_load
 jmp .done
.unary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_POSTFIX_PERCENT
 je .quantity_percent
 cmp rax,NEBOC_TOKEN_PER_MILLE
 je .quantity_per_mille
 cmp rax,NEBOC_TOKEN_BASIS_POINTS
 je .done_success
 cmp rax,NEBOC_TOKEN_DEGREE
 je .quantity_angle
 cmp rax,NEBOC_TOKEN_CELSIUS
 je .quantity_celsius
 cmp rax,NEBOC_TOKEN_FAHRENHEIT
 je .quantity_fahrenheit
 cmp rax,NEBOC_TOKEN_SQUARE_ROOT
 je .math_square_root
 cmp rax,NEBOC_TOKEN_CUBE_ROOT
 je .math_cube_root
 cmp rax,NEBOC_TOKEN_FOURTH_ROOT
 je .math_fourth_root
 cmp rax,NEBOC_TOKEN_POSTFIX_FACTORIAL
 je .math_factorial
 cmp rax,NEBOC_TOKEN_FLOOR_OPEN
 je .math_floor
 cmp rax,NEBOC_TOKEN_CEIL_OPEN
 je .math_ceil
 NEBOC_CORE_ORF_CLASSIFY rax,rdx,.not_lateral
 cmp rdx,NEBOC_OPERATOR_ID_NSR_CORE_047
 je .lateral
.not_lateral:
 cmp rax,NEBOC_TOKEN_MINUS
 je .neg
 cmp rax,NEBOC_TOKEN_BANG
 je .not
 xor eax,eax
 jmp .done
.lateral:
 mov rdi,r12
 lea rsi,[rel binding_codegen_lateral_save_rax]
 mov edx,lateral_save_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_lateral_restore_rax]
 mov edx,lateral_restore_rax_len
 call g05c_append
 jmp .done
.neg:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_receiver_type
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 jne .neg_integer
 mov rdi,r12
 lea rsi,[rel neg_float]
 mov edx,neg_float_len
 call g05c_append
 jmp .done
.neg_integer:
 ; The only accepted 9223372036854775808 literal is the unary-minus boundary.
 ; Its AST payload is already INT_MIN; do not negate that payload twice.
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .neg_emit
 mov rdx,0x8000000000000000
 cmp [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rdx
 je .done_success
.neg_emit:
 mov rdi,r12
 lea rsi,[rel neg_rax]
 mov edx,neg_rax_len
 call g05c_append
 jmp .done
.done_success:
 xor eax,eax
 jmp .done
.not:
 mov rdi,r12
 lea rsi,[rel not_rax]
 mov edx,not_rax_len
 call g05c_append
 jmp .done
.quantity_percent:
 mov rdi,r12
 lea rsi,[rel binding_quantity_percent]
 mov edx,binding_quantity_percent_len
 call g05c_append
 jmp .done
.quantity_per_mille:
 mov rdi,r12
 lea rsi,[rel binding_quantity_per_mille]
 mov edx,binding_quantity_per_mille_len
 call g05c_append
 jmp .done
.quantity_angle:
 mov rdi,r12
 lea rsi,[rel binding_quantity_angle]
 mov edx,binding_quantity_angle_len
 call g05c_append
 jmp .done
.quantity_celsius:
 mov rdi,r12
 lea rsi,[rel binding_quantity_celsius]
 mov edx,binding_quantity_celsius_len
 call g05c_append
 jmp .done
.quantity_fahrenheit:
 mov rdi,r12
 lea rsi,[rel binding_quantity_fahrenheit]
 mov edx,binding_quantity_fahrenheit_len
 call g05c_append
 jmp .done
.math_square_root:
 mov rdi,r12
 lea rsi,[rel binding_math_square_root]
 mov edx,binding_math_square_root_len
 call g05c_append
 jmp .done
.math_cube_root:
 mov rdi,r12
 lea rsi,[rel binding_math_cube_root]
 mov edx,binding_math_cube_root_len
 call g05c_append
 jmp .done
.math_fourth_root:
 mov rdi,r12
 lea rsi,[rel binding_math_fourth_root]
 mov edx,binding_math_fourth_root_len
 call g05c_append
 jmp .done
.math_factorial:
 mov rdi,r12
 lea rsi,[rel binding_math_factorial]
 mov edx,binding_math_factorial_len
 call g05c_append
 jmp .done
.math_floor:
 mov rdi,r12
 lea rsi,[rel binding_math_floor]
 mov edx,binding_math_floor_len
 call g05c_append
 jmp .done
.math_ceil:
 mov rdi,r12
 lea rsi,[rel binding_math_ceil]
 mov edx,binding_math_ceil_len
 call g05c_append
 jmp .done
.binary:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 NEBOC_CORE_PXO_CLASSIFY rax,rcx,.binary_registry_miss
 cmp rcx,NEBOC_OPERATOR_ID_NSR_CORE_017
 je .binary_supported
 cmp rcx,NEBOC_OPERATOR_ID_NSR_CORE_023
 je .binary_supported
 cmp rcx,NEBOC_OPERATOR_ID_NSR_CORE_030
 je .binary_supported
.binary_registry_miss:
 cmp rax,NEBOC_TOKEN_PLUS_MINUS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_APPROX_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_NOT_APPROX_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_EQUIVALENT
 je .binary_supported
 cmp rax,NEBOC_TOKEN_DIVIDES
 je .binary_supported
 cmp rax,NEBOC_TOKEN_NOT_DIVIDES
 je .binary_supported
 cmp rax,NEBOC_TOKEN_PROPORTIONAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_AND_AND
 je .logical_and
 cmp rax,NEBOC_TOKEN_OR_OR
 je .logical_or
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_STAR
 je .binary_supported
 cmp rax,NEBOC_TOKEN_SLASH
 je .binary_supported
 cmp rax,NEBOC_TOKEN_PERCENT
 je .binary_supported
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .binary_equality_probe
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .binary_equality_probe
 cmp rax,NEBOC_TOKEN_LESS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_GREATER
 je .binary_supported
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 jne .unsupported
 jmp .binary_supported
.logical_and:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel logical_and_branch]
 mov edx,logical_and_branch_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel logical_bool_canon_done]
 mov edx,logical_bool_canon_done_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_false_label]
 mov edx,logical_false_label_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_false_body]
 mov edx,logical_false_body_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_label_end]
 mov edx,logical_label_end_len
 call g05c_append
 jmp .done
.logical_or:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel logical_or_branch]
 mov edx,logical_or_branch_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel logical_bool_canon_done]
 mov edx,logical_bool_canon_done_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_true_label]
 mov edx,logical_true_label_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_true_body]
 mov edx,logical_true_body_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel logical_label_end]
 mov edx,logical_label_end_len
 call g05c_append
 jmp .done
.binary_equality_probe:
 mov [rsp],rax
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_receiver_type
 cmp eax,NEBOC_BIND_TYPE_TEXT
 jne .binary_supported
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov [rsp+8],rsi
 mov rdi,r12
 call g05c_receiver_type
 cmp eax,NEBOC_BIND_TYPE_TEXT
 jne .unsupported
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel cmp_prefix]
 mov edx,cmp_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel text_equal_call]
 mov edx,text_equal_call_len
 call g05c_append
 test eax,eax
 jnz .done
 cmp qword [rsp],NEBOC_TOKEN_BANG_EQUAL
 jne .done
 mov rdi,r12
 lea rsi,[rel not_rax]
 mov edx,not_rax_len
 call g05c_append
 jmp .done
.binary_supported:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_receiver_type
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel cmp_prefix]
 mov edx,cmp_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS_MINUS
 je .g131_binary_uncertain
 cmp rax,NEBOC_TOKEN_APPROX_EQUAL
 je .g131_binary_approx
 cmp rax,NEBOC_TOKEN_NOT_APPROX_EQUAL
 je .g131_binary_not_approx
 cmp rax,NEBOC_TOKEN_EQUIVALENT
 je .g131_binary_equivalent
 cmp rax,NEBOC_TOKEN_DIVIDES
 je .g131_binary_divides
 cmp rax,NEBOC_TOKEN_NOT_DIVIDES
 je .g131_binary_not_divides
 cmp rax,NEBOC_TOKEN_PROPORTIONAL
 je .g131_binary_proportional
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary_add
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary_sub
 cmp rax,NEBOC_TOKEN_STAR
 je .binary_mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .binary_div
 cmp rax,NEBOC_TOKEN_PERCENT
 je .binary_mod
 cmp rax,NEBOC_TOKEN_CARET
 je .binary_power
 cmp rax,NEBOC_TOKEN_XOR
 je .binary_xor
 cmp rax,NEBOC_TOKEN_SPACESHIP
 je .binary_spaceship
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .cmp_eq
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .cmp_ne
 cmp rax,NEBOC_TOKEN_LESS
 je .cmp_lt
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .cmp_le
 cmp rax,NEBOC_TOKEN_GREATER
 je .cmp_gt
 lea rsi,[rel cmp_ge_suffix]
 mov edx,cmp_ge_suffix_len
 jmp .cmp_emit
.g131_binary_uncertain:
 lea rsi,[rel g131_uncertain_binary]
 mov edx,g131_uncertain_binary_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_approx:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_approx]
 mov edx,g131_call_approx_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_not_approx:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_not_approx]
 mov edx,g131_call_not_approx_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_equivalent:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_equivalent]
 mov edx,g131_call_equivalent_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_divides:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_divides]
 mov edx,g131_call_divides_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_not_divides:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_not_divides]
 mov edx,g131_call_not_divides_len
 call g05c_append
 jmp .binary_checked_done
.g131_binary_proportional:
 lea rsi,[rel g131_binary_prepare]
 mov edx,g131_binary_prepare_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_call_proportional]
 mov edx,g131_call_proportional_len
 call g05c_append
 jmp .binary_checked_done
.binary_add:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_add]
 mov edx,binary_add_len
 call g05c_append
 jmp .binary_checked_done
.binary_sub:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_sub]
 mov edx,binary_sub_len
 call g05c_append
 jmp .binary_checked_done
.binary_mul:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_mul]
 mov edx,binary_mul_len
 call g05c_append
 jmp .binary_checked_done
.binary_div:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_runtime_div]
 mov edx,binary_runtime_div_len
 call g05c_append
 jmp .binary_checked_done
.binary_mod:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_runtime_rem]
 mov edx,binary_runtime_rem_len
 call g05c_append
 jmp .binary_checked_done
.binary_power:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp qword [rsp+16],NEBOC_BIND_TYPE_FLOAT
 je .binary_power_float
 lea rsi,[rel binary_runtime_power]
 mov edx,binary_runtime_power_len
 call g05c_append
 jmp .binary_checked_done
.binary_power_float:
 lea rsi,[rel binary_runtime_float_power]
 mov edx,binary_runtime_float_power_len
 call g05c_append
 jmp .binary_checked_done
.binary_xor:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp qword [rsp+16],NEBOC_BIND_TYPE_BYTES
 je .binary_xor_bytes
 lea rsi,[rel binary_xor_scalar]
 mov edx,binary_xor_scalar_len
 call g05c_append
 jmp .binary_checked_done
.binary_xor_bytes:
 lea rsi,[rel binary_xor_bytes]
 mov edx,binary_xor_bytes_len
 call g05c_append
 jmp .binary_checked_done
.binary_spaceship:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_spaceship_scalar]
 mov edx,binary_spaceship_scalar_len
 call g05c_append
.binary_checked_done:
 test eax,eax
 jnz .done
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],1
 xor eax,eax
 jmp .done
.cmp_eq:
 lea rsi,[rel cmp_suffix]
 mov edx,cmp_suffix_len
 jmp .cmp_emit
.cmp_ne:
 lea rsi,[rel cmp_ne_suffix]
 mov edx,cmp_ne_suffix_len
 jmp .cmp_emit
.cmp_lt:
 lea rsi,[rel cmp_lt_suffix]
 mov edx,cmp_lt_suffix_len
 jmp .cmp_emit
.cmp_le:
 lea rsi,[rel cmp_le_suffix]
 mov edx,cmp_le_suffix_len
 jmp .cmp_emit
.cmp_gt:
 lea rsi,[rel cmp_gt_suffix]
 mov edx,cmp_gt_suffix_len
.cmp_emit:
 call g05c_append
 jmp .done
.call:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .method
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_uncertain_type]
 mov ecx,n_uncertain_type_len
 call g05c_token_match
 test eax,eax
 jnz .g131_ctor_uncertain
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_measurement_type]
 mov ecx,n_measurement_type_len
 call g05c_token_match
 test eax,eax
 jnz .g131_ctor_measurement
 ; Pratt direct-call AST stores the sole constructor argument directly in
 ; first_child; there is no synthetic type-receiver child or next sibling.
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 jmp .done
.g131_ctor_uncertain:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 lea rsi,[rel g131_alloc_16]
 mov edx,g131_alloc_16_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_store_0]
 mov edx,g131_store_0_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_uncertain_load]
 mov edx,g131_uncertain_load_len
 call g05c_append
 jmp .done
.g131_ctor_measurement:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 lea rsi,[rel g131_alloc_48]
 mov edx,g131_alloc_48_len
 call g05c_append
 test eax,eax
 jnz .done
 xor ecx,ecx
.g131_measurement_arg:
 mov [rsp+16],rcx
 mov [rsp+24],rbx
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rcx,[rsp+16]
 mov rdi,r12
 cmp ecx,0
 je .g131_measurement_store_0
 cmp ecx,1
 je .g131_measurement_store_8
 cmp ecx,2
 je .g131_measurement_store_16
 cmp ecx,3
 je .g131_measurement_store_24
 lea rsi,[rel g131_store_32]
 mov edx,g131_store_32_len
 jmp .g131_measurement_store
.g131_measurement_store_0:
 lea rsi,[rel g131_store_0]
 mov edx,g131_store_0_len
 jmp .g131_measurement_store
.g131_measurement_store_8:
 lea rsi,[rel g131_store_8]
 mov edx,g131_store_8_len
 jmp .g131_measurement_store
.g131_measurement_store_16:
 lea rsi,[rel g131_store_16]
 mov edx,g131_store_16_len
 jmp .g131_measurement_store
.g131_measurement_store_24:
 lea rsi,[rel g131_store_24]
 mov edx,g131_store_24_len
.g131_measurement_store:
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [rsp+16]
 cmp qword [rsp+16],5
 je .g131_measurement_finish
 mov rdi,r12
 mov rsi,[rsp+24]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast
 mov rcx,[rsp+16]
 jmp .g131_measurement_arg
.g131_measurement_finish:
 mov rdi,r12
 lea rsi,[rel g131_measurement_load]
 mov edx,g131_measurement_load_len
 call g05c_append
 jmp .done
.method:
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_approx_equals]
 mov ecx,n_approx_equals_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_approx
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_equivalent_to]
 mov ecx,n_equivalent_to_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_equivalent
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_divides]
 mov ecx,n_divides_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_divides
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_proportional_to]
 mov ecx,n_proportional_to_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_proportional
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_add_worst_case]
 mov ecx,n_add_worst_case_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_worst
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_add_independent]
 mov ecx,n_add_independent_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_independent
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_add_correlated]
 mov ecx,n_add_correlated_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_correlated
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_add_interval]
 mov ecx,n_add_interval_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_interval
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_measured_value]
 mov ecx,n_measured_value_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_value
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_uncertainty]
 mov ecx,n_uncertainty_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_uncertainty
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_unit_code]
 mov ecx,n_unit_code_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_unit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_quality]
 mov ecx,n_quality_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_quality
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_confidence]
 mov ecx,n_confidence_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_confidence
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_separator_codepoint]
 mov ecx,n_separator_codepoint_len
 call g05c_token_match
 test eax,eax
 jnz .g131_method_separator
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g05c_token_match
 test eax,eax
 jnz .method_console
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_scan]
 mov ecx,n_scan_len
 call g05c_token_match
 test eax,eax
 jnz .method_scan
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05c_token_match
 test eax,eax
 jnz .method_bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_and
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_or
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_xor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_not
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call g05c_token_match
 test eax,eax
 jnz .method_shift_left
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call g05c_token_match
 test eax,eax
 jnz .method_shift_right
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call g05c_token_match
 test eax,eax
 jnz .method_test_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call g05c_token_match
 test eax,eax
 jnz .method_with_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05c_token_match
 test eax,eax
 jnz .method_bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_swap]
 mov ecx,n_swap_len
 call g05c_token_match
 test eax,eax
 jnz .method_swap
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_replace]
 mov ecx,n_replace_len
 call g05c_token_match
 test eax,eax
 jnz .method_replace
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_checked_add]
 mov ecx,n_checked_add_len
 call g05c_token_match
 test eax,eax
 jnz .method_checked_add
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_wrapping_add]
 mov ecx,n_wrapping_add_len
 call g05c_token_match
 test eax,eax
 jnz .method_wrapping_add
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_saturating_add]
 mov ecx,n_saturating_add_len
 call g05c_token_match
 test eax,eax
 jnz .method_saturating_add
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_checked_div]
 mov ecx,n_checked_div_len
 call g05c_token_match
 test eax,eax
 jnz .method_checked_div
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_checked_shift]
 mov ecx,n_checked_shift_len
 call g05c_token_match
 test eax,eax
 jnz .method_checked_shift
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_overflowing_mul]
 mov ecx,n_overflowing_mul_len
 call g05c_token_match
 test eax,eax
 jnz .method_overflowing_mul
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_get]
 mov ecx,n_get_len
 call g05c_token_match
 test eax,eax
 jnz .method_option_get
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_some]
 mov ecx,n_is_some_len
 call g05c_token_match
 test eax,eax
 jnz .method_option_is_some
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_value]
 mov ecx,n_value_len
 call g05c_token_match
 test eax,eax
 jnz .method_aggregate_value
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_overflowed]
 mov ecx,n_overflowed_len
 call g05c_token_match
 test eax,eax
 jnz .method_option_is_some
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_exclusive]
 mov ecx,n_exclusive_len
 call g05c_token_match
 test eax,eax
 jnz .method_range_exclusive
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_iterator]
 mov ecx,n_iterator_len
 call g05c_token_match
 test eax,eax
 jnz .method_aggregate_value
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_next]
 mov ecx,n_next_len
 call g05c_token_match
 test eax,eax
 jnz .method_iterator_next
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_size_hint]
 mov ecx,n_size_hint_len
 call g05c_token_match
 test eax,eax
 jnz .method_iterator_hint
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_lower]
 mov ecx,n_lower_len
 call g05c_token_match
 test eax,eax
 jnz .method_aggregate_value
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_upper]
 mov ecx,n_upper_len
 call g05c_token_match
 test eax,eax
 jnz .method_aggregate_upper
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_unreachable]
 mov ecx,n_unreachable_len
 call g05c_token_match
 test eax,eax
 jnz .method_flow_unreachable
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_assert]
 mov ecx,n_assert_len
 call g05c_token_match
 test eax,eax
 jnz .method_flow_assert
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_assume]
 mov ecx,n_assume_len
 call g05c_token_match
 test eax,eax
 jnz .method_flow_assume
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05c_token_match
 test eax,eax
 jnz .method_empty
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_to_float]
 mov ecx,n_to_float_len
 call g05c_token_match
 test eax,eax
 jnz .method_to_float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_sqrt]
 mov ecx,n_sqrt_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_sqrt
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_cube_root]
 mov ecx,n_cube_root_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_cube_root
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_fourth_root]
 mov ecx,n_fourth_root_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_fourth_root
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_factorial]
 mov ecx,n_factorial_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_factorial
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_floor]
 mov ecx,n_floor_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_floor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_ceil]
 mov ecx,n_ceil_len
 call g05c_token_match
 test eax,eax
 jnz .method_math_ceil
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_finite]
 mov ecx,n_is_finite_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_finite
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_nan]
 mov ecx,n_is_nan_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_nan
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_infinite]
 mov ecx,n_is_infinite_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_infinite
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_negative_zero]
 mov ecx,n_is_negative_zero_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_negative_zero
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call g05c_token_match
 test eax,eax
 jnz .method_byte_length
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint_count]
 mov ecx,n_codepoint_count_len
 call g05c_token_match
 test eax,eax
 jnz .method_codepoint_count
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call g05c_token_match
 test eax,eax
 jnz .method_codepoint
 jmp .unsupported
.g131_method_approx:
 mov qword [rsp],1
 jmp .g131_method_binary
.g131_method_equivalent:
 mov qword [rsp],2
 jmp .g131_method_binary
.g131_method_divides:
 mov qword [rsp],3
 jmp .g131_method_binary
.g131_method_proportional:
 mov qword [rsp],4
 jmp .g131_method_binary
.g131_method_worst:
 mov qword [rsp],5
 jmp .g131_method_binary
.g131_method_independent:
 mov qword [rsp],6
 jmp .g131_method_binary
.g131_method_correlated:
 mov qword [rsp],7
 jmp .g131_method_binary
.g131_method_interval:
 mov qword [rsp],8
.g131_method_binary:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_save_receiver]
 mov edx,g131_save_receiver_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_prepare_method]
 mov edx,g131_prepare_method_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rax,[rsp]
 cmp eax,1
 je .g131_emit_approx
 cmp eax,2
 je .g131_emit_equivalent
 cmp eax,3
 je .g131_emit_divides
 cmp eax,4
 je .g131_emit_proportional
 cmp eax,5
 je .g131_emit_worst
 cmp eax,6
 je .g131_emit_independent
 cmp eax,7
 je .g131_emit_correlated
 lea rsi,[rel g131_call_interval]
 mov edx,g131_call_interval_len
 jmp .g131_emit_call
.g131_emit_approx:
 lea rsi,[rel g131_call_approx]
 mov edx,g131_call_approx_len
 jmp .g131_emit_call
.g131_emit_equivalent:
 lea rsi,[rel g131_call_equivalent]
 mov edx,g131_call_equivalent_len
 jmp .g131_emit_call
.g131_emit_divides:
 lea rsi,[rel g131_call_divides]
 mov edx,g131_call_divides_len
 jmp .g131_emit_call
.g131_emit_proportional:
 lea rsi,[rel g131_call_proportional]
 mov edx,g131_call_proportional_len
 jmp .g131_emit_call
.g131_emit_worst:
 lea rsi,[rel g131_call_worst]
 mov edx,g131_call_worst_len
 jmp .g131_emit_call
.g131_emit_independent:
 lea rsi,[rel g131_call_independent]
 mov edx,g131_call_independent_len
 jmp .g131_emit_call
.g131_emit_correlated:
 lea rsi,[rel g131_call_correlated]
 mov edx,g131_call_correlated_len
.g131_emit_call:
 mov rdi,r12
 call g05c_append
 jmp .done
.g131_method_value:
 mov qword [rsp],9
 jmp .g131_method_metadata
.g131_method_uncertainty:
 mov qword [rsp],10
 jmp .g131_method_metadata
.g131_method_unit:
 mov qword [rsp],11
 jmp .g131_method_metadata
.g131_method_quality:
 mov qword [rsp],12
 jmp .g131_method_metadata
.g131_method_confidence:
 mov qword [rsp],13
 jmp .g131_method_metadata
.g131_method_separator:
 mov qword [rsp],14
.g131_method_metadata:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel g131_prepare_unary]
 mov edx,g131_prepare_unary_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rax,[rsp]
 cmp eax,9
 je .g131_emit_value
 cmp eax,10
 je .g131_emit_uncertainty
 cmp eax,11
 je .g131_emit_unit
 cmp eax,12
 je .g131_emit_quality
 cmp eax,13
 je .g131_emit_confidence
 lea rsi,[rel g131_call_separator]
 mov edx,g131_call_separator_len
 jmp .g131_emit_call
.g131_emit_value:
 lea rsi,[rel g131_call_value]
 mov edx,g131_call_value_len
 jmp .g131_emit_call
.g131_emit_uncertainty:
 lea rsi,[rel g131_call_uncertainty]
 mov edx,g131_call_uncertainty_len
 jmp .g131_emit_call
.g131_emit_unit:
 lea rsi,[rel g131_call_unit]
 mov edx,g131_call_unit_len
 jmp .g131_emit_call
.g131_emit_quality:
 lea rsi,[rel g131_call_quality]
 mov edx,g131_call_quality_len
 jmp .g131_emit_call
.g131_emit_confidence:
 lea rsi,[rel g131_call_confidence]
 mov edx,g131_call_confidence_len
 jmp .g131_emit_call
.method_console:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_receiver_type
 test eax,eax
 jz .unsupported
 mov ebx,eax
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp ebx,NEBOC_BIND_TYPE_TEXT
 je .method_console_text
 cmp ebx,NEBOC_BIND_TYPE_INT
 je .method_console_int
 cmp ebx,NEBOC_BIND_TYPE_BOOL
 jne .unsupported
 lea rsi,[rel call_console_publish_bool]
 mov edx,call_console_publish_bool_len
 jmp .method_console_emit
.method_console_text:
 lea rsi,[rel call_console_publish_text]
 mov edx,call_console_publish_text_len
 jmp .method_console_emit
.method_console_int:
 lea rsi,[rel call_console_publish_int]
 mov edx,call_console_publish_int_len
.method_console_emit:
 call g05c_append
 jmp .done
.method_scan:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_receiver_type
 cmp eax,NEBOC_BIND_TYPE_TEXT
 je .method_scan_stdin
 cmp eax,NEBOC_BIND_TYPE_CONSOLE
 jne .unsupported
 mov ebx,2
 jmp .method_scan_receiver
.method_scan_stdin:
 mov ebx,1
.method_scan_receiver:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call g05c_emit_scan_ids
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp ebx,1
 jne .method_scan_console_emit
 lea rsi,[rel call_scan_stdin]
 mov edx,call_scan_stdin_len
 call g05c_append
 jmp .done
.method_scan_console_emit:
 lea rsi,[rel call_scan_console_handle]
 mov edx,call_scan_console_handle_len
 call g05c_append
 jmp .done
.method_bytes_constructor:
 mov rdi,r12
 lea rsi,[rel lea_bytes]
 mov edx,lea_bytes_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel close_bracket]
 mov edx,close_bracket_len
 call g05c_append
 jmp .done
.method_swap:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ast
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov [rsp],rax
 mov rax,[rsp+16]
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ast
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_load
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05c_emit_load
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_store
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_pop_rax]
 mov edx,pop_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05c_emit_store
 jmp .done
.method_replace:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ast
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov [rsp],rax
 mov rdi,r12
 mov rsi,rax
 call g05c_emit_load
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rax,[rsp+16]
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_store
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_pop_rax]
 mov edx,pop_rax_len
 call g05c_append
 jmp .done
.method_checked_add:
 mov ebx,1
 jmp .method_safe_binary
.method_wrapping_add:
 mov ebx,2
 jmp .method_safe_binary
.method_saturating_add:
 mov ebx,3
 jmp .method_safe_binary
.method_checked_div:
 mov ebx,4
 jmp .method_safe_binary
.method_checked_shift:
 mov ebx,5
 jmp .method_safe_binary
.method_overflowing_mul:
 mov ebx,6
.method_safe_binary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp ebx,1
 je .method_emit_checked_add
 cmp ebx,2
 je .method_emit_wrapping_add
 cmp ebx,3
 je .method_emit_saturating_add
 cmp ebx,4
 je .method_emit_checked_div
 cmp ebx,5
 je .method_emit_checked_shift
 lea rsi,[rel safe_overflowing_mul]
 mov edx,safe_overflowing_mul_len
 call g05c_append
 jmp .done
.method_emit_checked_add:
 lea rsi,[rel safe_checked_add]
 mov edx,safe_checked_add_len
 call g05c_append
 jmp .done
.method_emit_wrapping_add:
 lea rsi,[rel safe_wrapping_add]
 mov edx,safe_wrapping_add_len
 call g05c_append
 jmp .done
.method_emit_saturating_add:
 lea rsi,[rel safe_saturating_add]
 mov edx,safe_saturating_add_len
 call g05c_append
 jmp .done
.method_emit_checked_div:
 lea rsi,[rel safe_checked_div_prefix]
 mov edx,safe_checked_div_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_div_mid]
 mov edx,safe_checked_div_mid_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_div_min]
 mov edx,safe_checked_div_min_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_div_ok]
 mov edx,safe_checked_div_ok_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_div_tail]
 mov edx,safe_checked_div_tail_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 jmp .done
.method_emit_checked_shift:
 lea rsi,[rel safe_checked_shift_prefix]
 mov edx,safe_checked_shift_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_shift_mid]
 mov edx,safe_checked_shift_mid_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel safe_checked_shift_tail]
 mov edx,safe_checked_shift_tail_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 jmp .done
.method_option_get:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel option_get_prefix]
 mov edx,option_get_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel option_get_trap]
 mov edx,option_get_trap_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 jmp .done
.method_option_is_some:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel option_is_some]
 mov edx,option_is_some_len
 call g05c_append
 jmp .done
.method_aggregate_value:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 jmp .done
.method_aggregate_upper:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel move_upper]
 mov edx,move_upper_len
 call g05c_append
 jmp .done
.method_range_exclusive:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov [rsp],rsi
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel range_pair]
 mov edx,range_pair_len
 call g05c_append
 jmp .done
.method_iterator_next:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 ; A named iterator owns its cursor. Advance that cursor only when next()
 ; returns Some; direct temporary iterators remain pure one-shot values.
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .method_iterator_next_value
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 cmp qword [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_ITERATOR_INT
 jne .method_iterator_next_value
 mov [rsp+8],rax
 mov rdi,r12
 lea rsi,[rel iterator_advance_a]
 mov edx,iterator_advance_a_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[rsp+8]
 mov rsi,[rax+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel iterator_advance_b]
 mov edx,iterator_advance_b_len
 call g05c_append
 test eax,eax
 jnz .done
.method_iterator_next_value:
 mov rdi,r12
 lea rsi,[rel iterator_next]
 mov edx,iterator_next_len
 call g05c_append
 jmp .done
.method_iterator_hint:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel iterator_hint]
 mov edx,iterator_hint_len
 call g05c_append
 jmp .done
.method_flow_assert:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel flow_assert_prefix]
 mov edx,flow_assert_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 xor esi,esi
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel flow_assert_trap]
 mov edx,flow_assert_trap_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 jmp .done
.method_flow_unreachable:
 mov rdi,r12
 xor esi,esi
 call g05c_emit_defer_range
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel flow_unreachable_trap]
 mov edx,flow_unreachable_trap_len
 call g05c_append
 jmp .done
.method_flow_assume:
 mov rdi,r12
 lea rsi,[rel flow_assume_nop]
 mov edx,flow_assume_nop_len
 call g05c_append
 jmp .done
.method_bit_and:
 mov r13d,1
 jmp .method_bit_binary
.method_bit_or:
 mov r13d,2
 jmp .method_bit_binary
.method_bit_xor:
 mov r13d,3
.method_bit_binary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp r13,1
 je .method_emit_and
 cmp r13,2
 je .method_emit_or
 lea rsi,[rel bit_xor]
 mov edx,bit_xor_len
 jmp .method_emit_bit
.method_emit_and:
 lea rsi,[rel bit_and]
 mov edx,bit_and_len
 jmp .method_emit_bit
.method_emit_or:
 lea rsi,[rel bit_or]
 mov edx,bit_or_len
.method_emit_bit:
 call g05c_append
 jmp .done
.method_bit_not:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel bit_not]
 mov edx,bit_not_len
 call g05c_append
 jmp .done
.method_shift_left:
 mov r13d,1
 jmp .method_bit_position
.method_shift_right:
 mov r13d,2
 jmp .method_bit_position
.method_test_bit:
 mov r13d,3
.method_bit_position:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rdi,r12
 cmp r13,1
 je .method_emit_shift_left
 cmp r13,2
 je .method_emit_shift_right
 lea rsi,[rel test_bit]
 mov edx,test_bit_len
 jmp .method_emit_position_prefix
.method_emit_shift_left:
 lea rsi,[rel shift_left]
 mov edx,shift_left_len
 jmp .method_emit_position_prefix
.method_emit_shift_right:
 lea rsi,[rel shift_right]
 mov edx,shift_right_len
.method_emit_position_prefix:
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 cmp r13,3
 jne .method_emit_position_newline
 lea rsi,[rel binding_codegen_test_bit_suffix]
 mov edx,test_bit_suffix_len
 call g05c_append
 jmp .done
.method_emit_position_newline:
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.method_with_bit:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel with_bit_position]
 mov edx,with_bit_position_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel with_bit_suffix]
 mov edx,with_bit_suffix_len
 call g05c_append
 jmp .done
.method_empty:
 mov rdi,r12
 lea rsi,[rel call_bytes_empty]
 mov edx,call_bytes_empty_len
 call g05c_append
 jmp .done
.method_to_float:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_to_float]
 mov edx,call_to_float_len
 call g05c_append
 jmp .done
.method_math_sqrt:
 lea rbx,[rel binding_math_square_root]
 mov r13d,binding_math_square_root_len
 jmp .method_math_unary
.method_math_cube_root:
 lea rbx,[rel binding_math_cube_root]
 mov r13d,binding_math_cube_root_len
 jmp .method_math_unary
.method_math_fourth_root:
 lea rbx,[rel binding_math_fourth_root]
 mov r13d,binding_math_fourth_root_len
 jmp .method_math_unary
.method_math_factorial:
 lea rbx,[rel binding_math_factorial]
 mov r13d,binding_math_factorial_len
 jmp .method_math_unary
.method_math_floor:
 lea rbx,[rel binding_math_floor]
 mov r13d,binding_math_floor_len
 jmp .method_math_unary
.method_math_ceil:
 lea rbx,[rel binding_math_ceil]
 mov r13d,binding_math_ceil_len
.method_math_unary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 mov edx,r13d
 call g05c_append
 jmp .done
.method_is_finite:
 lea rbx,[rel call_is_finite]
 mov r13d,call_is_finite_len
 jmp .method_classifier
.method_is_nan:
 lea rbx,[rel call_is_nan]
 mov r13d,call_is_nan_len
 jmp .method_classifier
.method_is_infinite:
 lea rbx,[rel call_is_infinite]
 mov r13d,call_is_infinite_len
 jmp .method_classifier
.method_is_negative_zero:
 lea rbx,[rel call_is_negative_zero]
 mov r13d,call_is_negative_zero_len
.method_classifier:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 mov edx,r13d
 call g05c_append
 jmp .done
.method_byte_length:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_receiver_is_bytes
 test eax,eax
 jnz .method_bytes_length_call
 mov rdi,r12
 lea rsi,[rel call_text_byte_length]
 mov edx,call_text_byte_length_len
 call g05c_append
 jmp .done
.method_bytes_length_call:
 mov rdi,r12
 lea rsi,[rel call_bytes_byte_length]
 mov edx,call_bytes_byte_length_len
 call g05c_append
 jmp .done
.method_codepoint_count:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_text_codepoint_count]
 mov edx,call_text_codepoint_count_len
 call g05c_append
 jmp .done
.method_codepoint:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_char_codepoint]
 mov edx,call_char_codepoint_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.literal_bad:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, symbol record -> store current value
g05c_emit_store:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .float
 cmp rax,NEBOC_BIND_TYPE_OPTION_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_OVERFLOW_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_RANGE_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_ITERATOR_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_SIZE_HINT
 je .aggregate
 mov rdi,r12
 lea rsi,[rel store_byte]
 mov edx,store_byte_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .byte_suffix
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .dword_suffix
 mov rdi,r12
 lea rsi,[rel store_qword_suffix]
 mov edx,store_qword_suffix_len
 call g05c_append
 jmp .done
.byte_suffix:
 mov rdi,r12
 lea rsi,[rel store_byte_suffix]
 mov edx,store_byte_suffix_len
 call g05c_append
 jmp .done
.dword_suffix:
 mov rdi,r12
 lea rsi,[rel store_dword_suffix]
 mov edx,store_dword_suffix_len
 call g05c_append
 jmp .done
.float:
 mov rdi,r12
 lea rsi,[rel store_float_prefix]
 mov edx,store_float_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel store_float_suffix]
 mov edx,store_float_suffix_len
 call g05c_append
 jmp .done
.aggregate:
 mov rdi,r12
 lea rsi,[rel store_byte]
 mov edx,store_byte_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel store_qword_suffix]
 mov edx,store_qword_suffix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel store_byte]
 mov edx,store_byte_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 sub rsi,8
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel store_rdx_suffix]
 mov edx,store_rdx_suffix_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, symbol record -> load value
g05c_emit_load:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_OPTION_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_OVERFLOW_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_RANGE_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_ITERATOR_INT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_SIZE_HINT
 je .aggregate
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .bool
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .char
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .float
 lea rsi,[rel load_int_prefix]
 mov edx,load_int_prefix_len
 jmp .prefix
.bool: lea rsi,[rel load_bool_prefix]
 mov edx,load_bool_prefix_len
 jmp .prefix
.char: lea rsi,[rel load_char_prefix]
 mov edx,load_char_prefix_len
 jmp .prefix
.float: lea rsi,[rel load_float_prefix]
 mov edx,load_float_prefix_len
.prefix:
 mov rdi,r12
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 cmp qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_FLOAT
 je .float_suffix
 lea rsi,[rel mem_suffix]
 mov edx,mem_suffix_len
 call g05c_append
 jmp .done
.float_suffix:
 lea rsi,[rel load_float_suffix]
 mov edx,load_float_suffix_len
 call g05c_append
 jmp .done
.aggregate:
 mov rdi,r12
 lea rsi,[rel load_int_prefix]
 mov edx,load_int_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel mem_suffix]
 mov edx,mem_suffix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel load_rdx_prefix]
 mov edx,load_rdx_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 sub rsi,8
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel mem_suffix]
 mov edx,mem_suffix_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, name token -> symbol
g05c_find_symbol:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 test r14,r14
 jz .none
 dec r14
.loop:
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_NAME_TOKEN_OFFSET]
 call g05c_names_equal
 test eax,eax
 jnz .yes
 test r14,r14
 jz .none
 dec r14
 jmp .loop
.yes: mov rax,rbx
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, node -> built-in TypeId or zero
g05c_type_ref:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .none
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .none
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05c_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call g05c_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call g05c_token_match
 test eax,eax
 jnz .char
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call g05c_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console_type]
 mov ecx,n_console_type_len
 call g05c_token_match
 test eax,eax
 jnz .console_type
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_uncertain_type]
 mov ecx,n_uncertain_type_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_measurement_type]
 mov ecx,n_measurement_type_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
.none: xor eax,eax
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.float: mov eax,NEBOC_BIND_TYPE_FLOAT
 jmp .done
.char: mov eax,NEBOC_BIND_TYPE_CHAR
 jmp .done
.bytes: mov eax,NEBOC_BIND_TYPE_BYTES
 jmp .done
.uncertain: mov eax,NEBOC_BIND_TYPE_UNCERTAIN_INT
 jmp .done
.console_type: mov eax,NEBOC_BIND_TYPE_CONSOLE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, receiver node -> semantic scalar kind used by typed Console ABI.
g05c_receiver_type:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .none
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rcx,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rcx,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rcx,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rcx,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rcx,NEBOC_AST_MATH_CONSTANT
 je .float
 cmp rcx,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rcx,NEBOC_AST_CALL_EXPR
 je .call
 cmp rcx,NEBOC_AST_BINARY_EXPR
 jne .none
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_LESS
 je .bool
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_GREATER
 je .bool
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_APPROX_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_NOT_APPROX_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_EQUIVALENT
 je .bool
 cmp rcx,NEBOC_TOKEN_DIVIDES
 je .bool
 cmp rcx,NEBOC_TOKEN_NOT_DIVIDES
 je .bool
 cmp rcx,NEBOC_TOKEN_PROPORTIONAL
 je .bool
 cmp rcx,NEBOC_TOKEN_PLUS_MINUS
 je .uncertain
 cmp rcx,NEBOC_TOKEN_SPACESHIP
 je .ordering
 cmp rcx,NEBOC_TOKEN_XOR
 je .binary_same_as_left
 cmp rcx,NEBOC_TOKEN_CARET
 je .binary_same_as_left
 jmp .int
.unary:
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,NEBOC_TOKEN_PLUS
 je .unary_same_as_child
 cmp rcx,NEBOC_TOKEN_MINUS
 je .unary_same_as_child
 cmp rcx,NEBOC_TOKEN_FLOOR_OPEN
 je .int
 cmp rcx,NEBOC_TOKEN_CEIL_OPEN
 je .int
 jmp .int
.unary_same_as_child:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g05c_receiver_type
 jmp .done
.binary_same_as_left:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g05c_receiver_type
 jmp .done
.identifier:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .none
 mov rax,[rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 jmp .done
.call:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .call_method
 ; Semantic validation has already proved constructor arity and argument type.
 ; Preserve that type through codegen receiver classification for the public
 ; Text(...).console() composition route without widening other constructors.
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05c_token_match
 test eax,eax
 jnz .text
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_uncertain_type]
 mov ecx,n_uncertain_type_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_measurement_type]
 mov ecx,n_measurement_type_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 jmp .none
.call_method:
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05c_token_match
 test eax,eax
 jnz .bytes
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05c_token_match
 test eax,eax
 jnz .bytes
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05c_token_match
 test eax,eax
 jnz .bytes
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g05c_token_match
 test eax,eax
 jnz .console
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_approx_equals]
 mov ecx,n_approx_equals_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_equivalent_to]
 mov ecx,n_equivalent_to_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_divides]
 mov ecx,n_divides_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_proportional_to]
 mov ecx,n_proportional_to_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_add_worst_case]
 mov ecx,n_add_worst_case_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_add_independent]
 mov ecx,n_add_independent_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_add_correlated]
 mov ecx,n_add_correlated_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_add_interval]
 mov ecx,n_add_interval_len
 call g05c_token_match
 test eax,eax
 jnz .uncertain
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_measured_value]
 mov ecx,n_measured_value_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_uncertainty]
 mov ecx,n_uncertainty_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_unit_code]
 mov ecx,n_unit_code_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_quality]
 mov ecx,n_quality_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_confidence]
 mov ecx,n_confidence_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 mov rdi,r12
 lea rdx,[rel n_separator_codepoint]
 mov ecx,n_separator_codepoint_len
 call g05c_token_match
 test eax,eax
 jnz .int
 jmp .none
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.float: mov eax,NEBOC_BIND_TYPE_FLOAT
 jmp .done
.bytes: mov eax,NEBOC_BIND_TYPE_BYTES
 jmp .done
.uncertain: mov eax,NEBOC_BIND_TYPE_UNCERTAIN_INT
 jmp .done
.ordering: mov eax,NEBOC_BIND_TYPE_ORDERING
 jmp .done
.console: mov eax,NEBOC_BIND_TYPE_CONSOLE
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, stable AST node id -> deterministic nonzero BindingId, PendingId,
; and source order for the canonical Scan route.  The local emitter aligns its
; nested writer calls explicitly; the outer frame is aligned before each call.
g05c_emit_scan_ids:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad
 lea rbx,[rel scan_mov_esi]
 mov edx,scan_mov_esi_len
 call .emit_one
 test eax,eax
 jnz .done
 lea rbx,[rel scan_mov_edx]
 mov edx,scan_mov_edx_len
 call .emit_one
 test eax,eax
 jnz .done
 lea rbx,[rel scan_mov_ecx]
 mov edx,scan_mov_ecx_len
 call .emit_one
 jmp .done
.emit_one:
 sub rsp,8
 mov rdi,r12
 mov rsi,rbx
 call g05c_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
.emit_done:
 add rsp,8
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, receiver node -> eax=1 when the validated receiver is Bytes.
g05c_receiver_is_bytes:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05c_token_match
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05c_token_match
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05c_token_match
 jmp .done
.identifier:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .no
 cmp qword [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_BYTES
 sete al
 movzx eax,al
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, token -> token*
g05c_token_ptr:
 cmp rsi,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKENS_OFFSET]
 ret
.none: xor eax,eax
 ret

; request*, node -> node*
g05c_node_ptr:
 test rsi,rsi
 jz .none
 mov rcx,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_BUILDER_OFFSET]
 cmp rsi,[rcx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 mov rax,[rcx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rax,rsi
 ret
.none: xor eax,eax
 ret

; request*, token, expected*, length -> 1/0
g05c_token_match:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r14,rcx
 call g05c_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,rdx
 cmp rcx,r14
 jne .no
 add rdx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r14
 jae .yes
 mov al,[rdx+rcx]
 cmp al,[rbx+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, token A, token B -> 1/0
g05c_names_equal:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rsi,r13
 call g05c_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call g05c_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov r8,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 add r9,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r9+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g05c_append:
 mov rdi,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 jmp neboc_assembly_writer_append_bytes
section .note.GNU-stack noalloc noexec nowrite progbits
