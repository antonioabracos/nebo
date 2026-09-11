; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF005 public Text/Char/Bytes x86-64 codegen
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/textual/x86_64/text_char_bytes_codegen.inc"
%include "compiler/lowering/textual/bytes_access_lowering.inc"
%include "compiler/lowering/textual/int_bits_lowering.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal
extern neboc_bytes_access_lower

section .rodata
n_byte_length: db "byteLength"
n_byte_length_len equ $-n_byte_length
n_codepoint_count: db "codepointCount"
n_codepoint_count_len equ $-n_codepoint_count
n_grapheme_count: db "graphemeCount"
n_grapheme_count_len equ $-n_grapheme_count
n_normalize_nfc: db "normalizeNfc"
n_normalize_nfc_len equ $-n_normalize_nfc
n_normalize_nfd: db "normalizeNfd"
n_normalize_nfd_len equ $-n_normalize_nfd
n_case_fold: db "caseFold"
n_case_fold_len equ $-n_case_fold
n_slice_codepoints: db "sliceCodepoints"
n_slice_codepoints_len equ $-n_slice_codepoints
n_slice_graphemes: db "sliceGraphemes"
n_slice_graphemes_len equ $-n_slice_graphemes
n_codepoint: db "codepoint"
n_codepoint_len equ $-n_codepoint
n_is_empty_text: db "isEmpty"
n_is_empty_text_len equ $-n_is_empty_text
n_equals_text: db "equals"
n_equals_text_len equ $-n_equals_text
n_equals_ascii_ignore_case: db "equalsAsciiIgnoreCase"
n_equals_ascii_ignore_case_len equ $-n_equals_ascii_ignore_case
n_starts_with_text: db "startsWith"
n_starts_with_text_len equ $-n_starts_with_text
n_ends_with_text: db "endsWith"
n_ends_with_text_len equ $-n_ends_with_text
n_contains_text: db "contains"
n_contains_text_len equ $-n_contains_text
n_index_of: db "indexOf"
n_index_of_len equ $-n_index_of
n_last_index_of: db "lastIndexOf"
n_last_index_of_len equ $-n_last_index_of
n_is_ascii: db "isAscii"
n_is_ascii_len equ $-n_is_ascii
n_is_utf8: db "isUtf8"
n_is_utf8_len equ $-n_is_utf8
n_is_blank: db "isBlank"
n_is_blank_len equ $-n_is_blank
n_is_digits: db "isDigits"
n_is_digits_len equ $-n_is_digits
n_is_alpha_ascii: db "isAlphaAscii"
n_is_alpha_ascii_len equ $-n_is_alpha_ascii
n_is_alnum_ascii: db "isAlnumAscii"
n_is_alnum_ascii_len equ $-n_is_alnum_ascii
n_concat_text: db "concat"
n_concat_text_len equ $-n_concat_text
n_trim: db "trim"
n_trim_len equ $-n_trim
n_trim_start: db "trimStart"
n_trim_start_len equ $-n_trim_start
n_trim_end: db "trimEnd"
n_trim_end_len equ $-n_trim_end
n_lower_text: db "lower"
n_lower_text_len equ $-n_lower_text
n_upper_text: db "upper"
n_upper_text_len equ $-n_upper_text
n_byte_slice_text: db "byteSlice"
n_byte_slice_text_len equ $-n_byte_slice_text
n_take_bytes: db "takeBytes"
n_take_bytes_len equ $-n_take_bytes
n_drop_bytes: db "dropBytes"
n_drop_bytes_len equ $-n_drop_bytes
n_normalize_newlines: db "normalizeNewlines"
n_normalize_newlines_len equ $-n_normalize_newlines
n_normalize_whitespace: db "normalizeWhitespace"
n_normalize_whitespace_len equ $-n_normalize_whitespace
n_replace_once: db "replaceOnce"
n_replace_once_len equ $-n_replace_once
n_replace_all: db "replaceAll"
n_replace_all_len equ $-n_replace_all
n_split_text: db "split"
n_split_text_len equ $-n_split_text
n_join_text: db "join"
n_join_text_len equ $-n_join_text
n_pad_start: db "padStart"
n_pad_start_len equ $-n_pad_start
n_pad_end: db "padEnd"
n_pad_end_len equ $-n_pad_end
n_parse_int_text: db "parseInt"
n_parse_int_text_len equ $-n_parse_int_text
n_parse_float_text: db "parseFloat"
n_parse_float_text_len equ $-n_parse_float_text
n_parse_bool_text: db "parseBool"
n_parse_bool_text_len equ $-n_parse_bool_text
n_split_checked: db "splitChecked"
n_split_checked_len equ $-n_split_checked
n_replace_all_checked: db "replaceAllChecked"
n_replace_all_checked_len equ $-n_replace_all_checked
n_to_text: db "toText"
n_to_text_len equ $-n_to_text
n_is_nebo_identifier: db "isNeboIdentifier"
n_is_nebo_identifier_len equ $-n_is_nebo_identifier
n_is_ok: db "isOk"
n_is_ok_len equ $-n_is_ok
n_is_err: db "isErr"
n_is_err_len equ $-n_is_err
n_empty: db "empty"
n_empty_len equ $-n_empty
n_from_byte: db "fromByte"
n_from_byte_len equ $-n_from_byte
n_from_values: db "fromValues"
n_from_values_len equ $-n_from_values
n_at: db "at"
n_at_len equ $-n_at
n_get: db "get"
n_get_len equ $-n_get
text_char_bytes_codegen_n_slice: db "slice"
text_char_bytes_codegen_n_slice_len equ $-text_char_bytes_codegen_n_slice
n_is_some: db "isSome"
n_is_some_len equ $-n_is_some
n_is_none: db "isNone"
n_is_none_len equ $-n_is_none
n_unwrap_or: db "unwrapOr"
n_unwrap_or_len equ $-n_unwrap_or
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
n_console: db "console"
n_console_len equ $-n_console
n_scan: db "scan"
n_scan_len equ $-n_scan
n_text: db "Text"
n_text_len equ $-n_text
rodata_header: db 10,'section .rodata',10
rodata_header_len equ $-rodata_header
align8: db 'align 8',10
align8_len equ $-align8
text_data_prefix: db 'nebo_text_data'
text_data_prefix_len equ $-text_data_prefix
text_data_mid: db ': db '
text_data_mid_len equ $-text_data_mid
text_empty_sentinel: db '0'
text_empty_sentinel_len equ $-text_empty_sentinel
text_desc_prefix: db 'nebo_text_desc'
text_desc_prefix_len equ $-text_desc_prefix
text_desc_mid: db ':',10,'    dq nebo_text_data'
text_desc_mid_len equ $-text_desc_mid
text_desc_length: db 10,'    dq '
text_desc_length_len equ $-text_desc_length
; Public static Text ABI tail: immutable/static/validated flags, UTF-8 encoding
; and program lifetime.  The 24-byte public descriptor is the compact static
; counterpart of the 32-byte owned/view runtime descriptor.
text_desc_tail: db 10,'    dd 7',10,'    dw 1',10,'    dw 1',10
text_desc_tail_len equ $-text_desc_tail
bytes_data_prefix: db 'nebo_bytes_data'
bytes_data_prefix_len equ $-bytes_data_prefix
bytes_data_mid: db ': db '
bytes_data_mid_len equ $-bytes_data_mid
bytes_desc_prefix: db 'nebo_bytes_desc'
bytes_desc_prefix_len equ $-bytes_desc_prefix
bytes_desc_mid: db ':',10,'    dq nebo_bytes_data'
bytes_desc_mid_len equ $-bytes_desc_mid
bytes_desc_length: db 10,'    dq '
bytes_desc_length_len equ $-bytes_desc_length
bytes_desc_tail: db 10,'    dd 3',10,'    dw 1',10,'    dw 1',10
bytes_desc_tail_len equ $-bytes_desc_tail
slice_data_prefix: db 'nebo_bytes_slice_data'
slice_data_prefix_len equ $-slice_data_prefix
slice_desc_prefix: db 'nebo_bytes_slice_desc'
slice_desc_prefix_len equ $-slice_desc_prefix
slice_desc_mid: db ':',10,'    dq nebo_bytes_slice_data'
slice_desc_mid_len equ $-slice_desc_mid
text_section: db 10,'section .text',10
text_section_len equ $-text_section
comma_space: db ', '
comma_space_len equ $-comma_space
newline: db 10
newline_len equ $-newline
prologue: db '    push rbp',10,'    mov rbp, rsp',10
prologue_len equ $-prologue
option_frame: db '    sub rsp, 16',10
option_frame_len equ $-option_frame
epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    xor eax, eax',10,'    ret',10
epilogue_len equ $-epilogue
return_epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
return_epilogue_len equ $-return_epilogue
lea_text_prefix: db '    lea rdi, [rel nebo_text_desc'
lea_text_prefix_len equ $-lea_text_prefix
lea_text_suffix: db ']',10
lea_text_suffix_len equ $-lea_text_suffix
lea_bytes_prefix: db '    lea rax, [rel nebo_bytes_desc'
lea_bytes_prefix_len equ $-lea_bytes_prefix
lea_bytes_suffix: db ']',10
lea_bytes_suffix_len equ $-lea_bytes_suffix
lea_slice_prefix: db '    lea rax, [rel nebo_bytes_slice_desc'
lea_slice_prefix_len equ $-lea_slice_prefix
lea_option_slot: db '    lea rdi, [rbp - 16]',10
lea_option_slot_len equ $-lea_option_slot
lea_option_result: db '    lea rax, [rbp - 16]',10
lea_option_result_len equ $-lea_option_result
mov_esi_zero: db '    xor esi, esi',10
mov_esi_zero_len equ $-mov_esi_zero
mov_esi_one: db '    mov esi, 1',10
mov_esi_one_len equ $-mov_esi_one
mov_edx: db '    mov edx, '
mov_edx_len equ $-mov_edx
neg_rax: db '    neg rax',10
neg_rax_len equ $-neg_rax
push_rax: db '    push rax',10
push_rax_len equ $-push_rax
bit_and_rax: db '    pop rcx',10,'    and rax, rcx',10
bit_and_rax_len equ $-bit_and_rax
bit_or_rax: db '    pop rcx',10,'    or rax, rcx',10
bit_or_rax_len equ $-bit_or_rax
bit_xor_rax: db '    pop rcx',10,'    xor rax, rcx',10
bit_xor_rax_len equ $-bit_xor_rax
bit_not_rax: db '    not rax',10
bit_not_rax_len equ $-bit_not_rax
shift_left_rax: db '    shl rax, '
shift_left_rax_len equ $-shift_left_rax
shift_right_rax: db '    sar rax, '
shift_right_rax_len equ $-shift_right_rax
test_bit_rax: db '    bt rax, '
test_bit_rax_len equ $-test_bit_rax
test_bit_suffix: db 10,'    setc al',10,'    movzx rax, al',10
test_bit_suffix_len equ $-test_bit_suffix
with_bit_set_rax: db '    bts rax, '
with_bit_set_rax_len equ $-with_bit_set_rax
with_bit_clear_rax: db '    btr rax, '
with_bit_clear_rax_len equ $-with_bit_clear_rax
mov_edi: db '    mov edi, '
mov_edi_len equ $-mov_edi
mov_rax: db '    mov rax, '
mov_rax_len equ $-mov_rax
mov_eax: db '    mov eax, '
mov_eax_len equ $-mov_eax
mov_rdi_rax: db '    mov rdi, rax',10
mov_rdi_rax_len equ $-mov_rdi_rax
push_rdi: db '    push rdi',10
push_rdi_len equ $-push_rdi
pair_text_arguments: db '    mov rsi, rdi',10,'    pop rdi',10
pair_text_arguments_len equ $-pair_text_arguments
one_int_arguments: db '    mov rsi, rax',10,'    pop rdi',10
one_int_arguments_len equ $-one_int_arguments
two_int_arguments: db '    mov rdx, rax',10,'    pop rsi',10,'    pop rdi',10
two_int_arguments_len equ $-two_int_arguments
two_text_arguments: db '    mov rdx, rdi',10,'    pop rsi',10,'    pop rdi',10
two_text_arguments_len equ $-two_text_arguments
pad_arguments: db '    mov rdx, rdi',10,'    pop rsi',10,'    pop rdi',10
pad_arguments_len equ $-pad_arguments
transform_zero_view_setup: db '    sub rsp, 4128',10,'    lea rsi, [rsp + 4096]',10
transform_zero_view_setup_len equ $-transform_zero_view_setup
transform_zero_buffer_setup: db '    sub rsp, 4128',10,'    lea rsi, [rsp]',10,'    mov edx, 4096',10,'    lea rcx, [rsp + 4096]',10
transform_zero_buffer_setup_len equ $-transform_zero_buffer_setup
transform_one_text_setup: db '    sub rsp, 4128',10,'    lea rdx, [rsp]',10,'    mov ecx, 4096',10,'    lea r8, [rsp + 4096]',10
transform_one_text_setup_len equ $-transform_one_text_setup
transform_split_setup: db '    sub rsp, 4128',10,'    lea rdx, [rsp]',10,'    mov ecx, 254',10,'    lea r8, [rsp + 4096]',10
transform_split_setup_len equ $-transform_split_setup
transform_two_text_setup: db '    sub rsp, 4128',10,'    lea rcx, [rsp]',10,'    mov r8d, 4096',10,'    lea r9, [rsp + 4096]',10
transform_two_text_setup_len equ $-transform_two_text_setup
transform_byte_slice_setup: db '    sub rsp, 4128',10,'    lea rcx, [rsp + 4096]',10
transform_byte_slice_setup_len equ $-transform_byte_slice_setup
transform_one_int_setup: db '    sub rsp, 4128',10,'    lea rdx, [rsp + 4096]',10
transform_one_int_setup_len equ $-transform_one_int_setup
transform_join_setup: db '    sub rsp, 4128',10,'    lea rdx, [rsp]',10,'    mov ecx, 4096',10,'    lea r8, [rsp + 4096]',10
transform_join_setup_len equ $-transform_join_setup
transform_pad_setup: db '    sub rsp, 4128',10,'    lea rcx, [rsp]',10,'    mov r8d, 4096',10,'    lea r9, [rsp + 4096]',10
transform_pad_setup_len equ $-transform_pad_setup
parse_result_setup: db '    sub rsp, 16',10,'    mov rsi, rsp',10
parse_result_setup_len equ $-parse_result_setup
split_checked_setup: db '    sub rsp, 4112',10,'    lea rdx, [rsp + 4064]',10,'    mov rcx, rsp',10,'    mov r8d, 254',10
split_checked_setup_len equ $-split_checked_setup
replace_checked_setup: db '    sub rsp, 4144',10,'    lea rcx, [rsp + 4096]',10,'    mov r8, rsp',10,'    mov r9d, 4096',10
replace_checked_setup_len equ $-replace_checked_setup
text_to_text_setup: db '    sub rsp, 4128',10,'    lea rsi, [rsp]',10,'    mov edx, 4096',10,'    lea rcx, [rsp + 4096]',10
text_to_text_setup_len equ $-text_to_text_setup
int_to_text_setup: db '    mov rdi, rax',10,'    sub rsp, 64',10,'    lea rsi, [rsp]',10,'    mov edx, 32',10,'    lea rcx, [rsp + 32]',10
int_to_text_setup_len equ $-int_to_text_setup
bool_to_text_setup: db '    mov rdi, rax',10,'    sub rsp, 32',10,'    lea rsi, [rsp]',10
bool_to_text_setup_len equ $-bool_to_text_setup
lea_option_out: db '    lea rdx, [rbp - 16]',10
lea_option_out_len equ $-lea_option_out
mov_esi: db '    mov esi, '
mov_esi_len equ $-mov_esi
mov_edx_scan: db '    mov edx, '
mov_edx_scan_len equ $-mov_edx_scan
mov_ecx: db '    mov ecx, '
mov_ecx_len equ $-mov_ecx
call_text_byte_length: db '    call nebo_runtime_textual_text_byte_length',10
call_text_byte_length_len equ $-call_text_byte_length
call_text_codepoint_count: db '    call nebo_runtime_textual_text_codepoint_count',10
call_text_codepoint_count_len equ $-call_text_codepoint_count
call_text_grapheme_count: db '    call nebo_runtime_textual_text_grapheme_count',10
call_text_grapheme_count_len equ $-call_text_grapheme_count
call_text_normalize_nfc: db '    call nebo_runtime_textual_text_normalize_nfc',10
call_text_normalize_nfc_len equ $-call_text_normalize_nfc
call_text_normalize_nfd: db '    call nebo_runtime_textual_text_normalize_nfd',10
call_text_normalize_nfd_len equ $-call_text_normalize_nfd
call_text_case_fold: db '    call nebo_runtime_textual_text_case_fold',10
call_text_case_fold_len equ $-call_text_case_fold
call_text_slice_codepoints: db '    call nebo_runtime_textual_text_slice_codepoints',10
call_text_slice_codepoints_len equ $-call_text_slice_codepoints
call_text_slice_graphemes: db '    call nebo_runtime_textual_text_slice_graphemes',10
call_text_slice_graphemes_len equ $-call_text_slice_graphemes
call_text_is_empty: db '    call nebo_runtime_textual_text_is_empty',10
call_text_is_empty_len equ $-call_text_is_empty
call_text_equals: db '    call nebo_runtime_textual_text_equals',10
call_text_equals_len equ $-call_text_equals
call_text_equals_ascii_ignore_case: db '    call nebo_runtime_textual_text_equals_ascii_ignore_case',10
call_text_equals_ascii_ignore_case_len equ $-call_text_equals_ascii_ignore_case
call_text_starts_with: db '    call nebo_runtime_textual_text_starts_with',10
call_text_starts_with_len equ $-call_text_starts_with
call_text_ends_with: db '    call nebo_runtime_textual_text_ends_with',10
call_text_ends_with_len equ $-call_text_ends_with
call_text_contains: db '    call nebo_runtime_textual_text_contains',10
call_text_contains_len equ $-call_text_contains
call_text_index_of: db '    call nebo_runtime_textual_text_index_of',10
call_text_index_of_len equ $-call_text_index_of
call_text_last_index_of: db '    call nebo_runtime_textual_text_last_index_of',10
call_text_last_index_of_len equ $-call_text_last_index_of
call_text_is_ascii: db '    call nebo_runtime_textual_text_is_ascii',10
call_text_is_ascii_len equ $-call_text_is_ascii
call_text_is_utf8: db '    call nebo_runtime_textual_text_is_utf8',10
call_text_is_utf8_len equ $-call_text_is_utf8
call_text_is_blank: db '    call nebo_runtime_textual_text_is_blank',10
call_text_is_blank_len equ $-call_text_is_blank
call_text_is_digits: db '    call nebo_runtime_textual_text_is_digits',10
call_text_is_digits_len equ $-call_text_is_digits
call_text_is_alpha_ascii: db '    call nebo_runtime_textual_text_is_alpha_ascii',10
call_text_is_alpha_ascii_len equ $-call_text_is_alpha_ascii
call_text_is_alnum_ascii: db '    call nebo_runtime_textual_text_is_alnum_ascii',10
call_text_is_alnum_ascii_len equ $-call_text_is_alnum_ascii
call_text_concat: db '    call nebo_runtime_textual_text_concat',10
call_text_concat_len equ $-call_text_concat
call_text_trim: db '    call nebo_runtime_textual_text_trim',10
call_text_trim_len equ $-call_text_trim
call_text_trim_start: db '    call nebo_runtime_textual_text_trim_start',10
call_text_trim_start_len equ $-call_text_trim_start
call_text_trim_end: db '    call nebo_runtime_textual_text_trim_end',10
call_text_trim_end_len equ $-call_text_trim_end
call_text_lower: db '    call nebo_runtime_textual_text_lower',10
call_text_lower_len equ $-call_text_lower
call_text_upper: db '    call nebo_runtime_textual_text_upper',10
call_text_upper_len equ $-call_text_upper
call_text_byte_slice: db '    call nebo_runtime_textual_text_byte_slice',10
call_text_byte_slice_len equ $-call_text_byte_slice
call_text_take_bytes: db '    call nebo_runtime_textual_text_take_bytes',10
call_text_take_bytes_len equ $-call_text_take_bytes
call_text_drop_bytes: db '    call nebo_runtime_textual_text_drop_bytes',10
call_text_drop_bytes_len equ $-call_text_drop_bytes
call_text_normalize_newlines: db '    call nebo_runtime_textual_text_normalize_newlines',10
call_text_normalize_newlines_len equ $-call_text_normalize_newlines
call_text_normalize_whitespace: db '    call nebo_runtime_textual_text_normalize_whitespace',10
call_text_normalize_whitespace_len equ $-call_text_normalize_whitespace
call_text_replace_once: db '    call nebo_runtime_textual_text_replace_once',10
call_text_replace_once_len equ $-call_text_replace_once
call_text_replace_all: db '    call nebo_runtime_textual_text_replace_all',10
call_text_replace_all_len equ $-call_text_replace_all
call_text_split: db '    call nebo_runtime_textual_text_split',10
call_text_split_len equ $-call_text_split
call_text_join: db '    call nebo_runtime_textual_text_join',10
call_text_join_len equ $-call_text_join
call_text_pad_start: db '    call nebo_runtime_textual_text_pad_start',10
call_text_pad_start_len equ $-call_text_pad_start
call_text_pad_end: db '    call nebo_runtime_textual_text_pad_end',10
call_text_pad_end_len equ $-call_text_pad_end
call_text_parse_int: db '    call nebo_runtime_textual_text_parse_int',10
call_text_parse_int_len equ $-call_text_parse_int
call_text_parse_float: db '    call nebo_runtime_textual_text_parse_float',10
call_text_parse_float_len equ $-call_text_parse_float
call_text_parse_bool: db '    call nebo_runtime_textual_text_parse_bool',10
call_text_parse_bool_len equ $-call_text_parse_bool
call_text_split_checked: db '    call nebo_runtime_textual_text_split_checked',10
call_text_split_checked_len equ $-call_text_split_checked
call_text_replace_all_checked: db '    call nebo_runtime_textual_text_replace_all_checked',10
call_text_replace_all_checked_len equ $-call_text_replace_all_checked
call_text_to_text: db '    call nebo_runtime_textual_text_to_text',10
call_text_to_text_len equ $-call_text_to_text
call_int_to_text: db '    call nebo_runtime_textual_int_to_text',10
call_int_to_text_len equ $-call_int_to_text
call_bool_to_text: db '    call nebo_runtime_textual_bool_to_text',10
call_bool_to_text_len equ $-call_bool_to_text
call_text_is_nebo_identifier: db '    call nebo_runtime_textual_text_is_nebo_identifier',10
call_text_is_nebo_identifier_len equ $-call_text_is_nebo_identifier
call_char_codepoint: db '    call nebo_runtime_textual_char_codepoint',10
call_char_codepoint_len equ $-call_char_codepoint
call_bytes_empty: db '    call nebo_runtime_textual_bytes_empty',10
call_bytes_empty_len equ $-call_bytes_empty
call_bytes_byte_length: db '    call nebo_runtime_textual_bytes_byte_length',10
call_bytes_byte_length_len equ $-call_bytes_byte_length
call_option_zero: db '    call neboc_runtime_store_zero_payload',10
call_option_zero_len equ $-call_option_zero
call_option_integer: db '    call neboc_runtime_store_integer',10
call_option_integer_len equ $-call_option_integer
call_option_tag_test: db '    call neboc_runtime_tag_test',10
call_option_tag_test_len equ $-call_option_tag_test
call_option_unwrap: db '    call neboc_runtime_unwrap_integer',10
call_option_unwrap_len equ $-call_option_unwrap
call_console_publish_text: db '    call nebo_runtime_console_publish_text',10
call_console_publish_text_len equ $-call_console_publish_text
call_console_publish_int: db '    call nebo_runtime_console_publish_int',10
call_console_publish_int_len equ $-call_console_publish_int
call_console_publish_bool: db '    call nebo_runtime_console_publish_bool',10
call_console_publish_bool_len equ $-call_console_publish_bool
call_scan_anonymous: db '    call nebo_runtime_contract_3',10
call_scan_anonymous_len equ $-call_scan_anonymous

section .text
; Emit deterministic Text descriptors before the backend opens start().
NEBOC_ABI_FUNCTION neboc_text_char_bytes_codegen_emit_function_data
 mov esi,1
 jmp g04c_emit_data_mode
NEBOC_ABI_FUNCTION neboc_text_char_bytes_codegen_emit_data
 xor esi,esi
g04c_emit_data_mode:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov [rsp+56],rsi
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov r15,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r14,1
 mov qword [rsp],0
.loop:
 cmp r14,r15
 ja .finish
 mov rdi,r13
 mov rsi,r14
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .text_literal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .next
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_index_of]
 mov ecx,n_index_of_len
 call g04c_token_match
 test eax,eax
 jnz .option_get
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_last_index_of]
 mov ecx,n_last_index_of_len
 call g04c_token_match
 test eax,eax
 jnz .option_get
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_get]
 mov ecx,n_get_len
 call g04c_token_match
 test eax,eax
 jnz .option_get
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_slice
 jmp .next
.option_get:
 mov dword [r12+NEBOC_CODEGEN_OPTION_USED_OFFSET],1
 jmp .next
.bytes_slice:
 ; A homonymous method on Matrix or a user receiver is not Bytes data.
 ; Authenticate the expression's constructor chain before pre-emitting it;
 ; the ordinary typed owner still validates all unrelated calls.
 mov rdi,r12
 mov rsi,r14
 call g04c_is_bytes_expression
 test eax,eax
 jz .next
 cmp qword [rsp],0
 jne .slice_header_done
 mov rdi,r12
 lea rsi,[rel rodata_header]
 mov edx,rodata_header_len
 call g04c_append
 test eax,eax
 jnz .done
 mov qword [rsp],1
.slice_header_done:
 mov rdi,r12
 mov rsi,r14
 call g04c_emit_bytes_slice_data
 test eax,eax
 jnz .done
 jmp .next
.bytes_constructor:
 mov rdi,r12
 mov rsi,r14
 call g04c_is_bytes_expression
 test eax,eax
 jz .next
 ; FunctionTable owns every Bytes constructor, including constant operands.
 ; The legacy owner still emits its own independent static slice data.
 cmp qword [rsp+56],0
 jnz .next
 cmp qword [rsp],0
 jne .header_done
 mov rdi,r12
 lea rsi,[rel rodata_header]
 mov edx,rodata_header_len
 call g04c_append
 test eax,eax
 jnz .done
 mov qword [rsp],1
.header_done:
 mov rdi,r12
 mov rsi,r14
 call g04c_emit_bytes_constructor_data
 test eax,eax
 jnz .done
 jmp .next
.text_literal:
 cmp qword [rsp],0
 jne .text_header_done
 mov rdi,r12
 lea rsi,[rel rodata_header]
 mov edx,rodata_header_len
 call g04c_append
 test eax,eax
 jnz .done
 mov qword [rsp],1
.text_header_done:
 mov rax,[rsp+8]
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,ebx
 mov [rsp+16],rax
 shr rbx,32
 mov [rsp+24],rbx
 mov rax,[rsp+16]
 add rax,rbx
 jc .literal
 cmp rax,[r12+NEBOC_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .literal
 mov rdi,r12
 lea rsi,[rel align8]
 mov edx,align8_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel text_data_prefix]
 mov edx,text_data_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel text_data_mid]
 mov edx,text_data_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 cmp qword [rsp+16],0
 jne .text_bytes_begin
 ; A Text descriptor with logical length zero still needs a NASM-valid data
 ; declaration.  The physical sentinel is never part of the public value: the
 ; descriptor length remains zero and all runtime operations observe emptiness.
 mov rdi,r12
 lea rsi,[rel text_empty_sentinel]
 mov edx,text_empty_sentinel_len
 call g04c_append
 test eax,eax
 jnz .done
.text_bytes_begin:
 xor ebx,ebx
.bytes:
 cmp rbx,[rsp+16]
 jae .bytes_done
 test rbx,rbx
 jz .byte_value
 mov rdi,r12
 lea rsi,[rel comma_space]
 mov edx,comma_space_len
 call g04c_append
 test eax,eax
 jnz .done
.byte_value:
 mov rax,[r12+NEBOC_CODEGEN_LITERAL_BYTES_OFFSET]
 add rax,[rsp+24]
 movzx esi,byte [rax+rbx]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 inc rbx
 jmp .bytes
.bytes_done:
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel text_desc_prefix]
 mov edx,text_desc_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel text_desc_mid]
 mov edx,text_desc_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel text_desc_length]
 mov edx,text_desc_length_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel text_desc_tail]
 mov edx,text_desc_tail_len
 call g04c_append
 test eax,eax
 jnz .done
.next:
 inc r14
 jmp .loop
.finish:
 cmp qword [rsp],0
 je .ok
 mov rdi,r12
 lea rsi,[rel text_section]
 mov edx,text_section_len
 call g04c_append
 jmp .done
.ok: xor eax,eax
 jmp .done
.literal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, two token ordinals -> EAX boolean for exact source bytes.
g04c_token_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r12,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 cmp r13,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 imul r12,NEBOC_TOKEN_SIZE
 add r12,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET]
 imul r13,NEBOC_TOKEN_SIZE
 add r13,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_TOKEN_END_OFFSET]
 sub r14,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rax,[r13+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r13+NEBOC_TOKEN_START_OFFSET]
 cmp r14,rax
 jne .no
 mov r15,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_OFFSET]
 test r15,r15
 jz .no
 mov rdi,r15
 add rdi,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rsi,r15
 add rsi,[r13+NEBOC_TOKEN_START_OFFSET]
 mov rcx,r14
 cld
 repe cmpsb
 sete al
 movzx eax,al
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
 cld
 ret

; request*, IdentifierExpr id -> RAX nearest prior BindingStmt expression or
; zero.  Static Bytes data may be named before slice/at/get; source order and
; exact UTF-8 token equality provide the lexical, acyclic authority.
g04c_find_prior_binding_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r12
 call g04c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r14,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov r15,1
.scan:
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 cmp r15,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .found
 mov rdi,rax
 mov rsi,r15
 call g04c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .next
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,r14
 jae .next
 cmp rcx,[rsp+8]
 jb .next
 mov rdi,rbx
 mov rsi,r13
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g04c_token_names_equal
 test eax,eax
 jz .next
 mov [rsp],r15
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r15
 call g04c_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rsp+8],rax
.next:
 inc r15
 jmp .scan
.found:
 mov rsi,[rsp]
 test rsi,rsi
 jz .no
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .no
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .no
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .no
 mov rax,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
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

; request*, bounded Bytes expression, out { length, packed }.
g04c_is_bytes_expression:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov r14,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
.walk:
 test r14,r14
 jz .no
 dec r14
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r12
 call g04c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .call
 mov rdi,rbx
 mov rsi,r12
 call g04c_find_prior_binding_expr
 test rax,rax
 jz .no
 mov r12,rax
 jmp .walk
.call:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call g04c_token_match
 test eax,eax
 jz .constructor
 mov r12,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .walk
.constructor:
 mov rdi,[rbx+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel g04c_bytes_namespace]
 mov ecx,5
 call g04c_token_match
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
section .rodata
g04c_bytes_namespace: db 'Bytes'
section .text

g04c_extract_static_bytes:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 mov qword [r14+8],0
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .call
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rdi,r12
 mov rsi,r13
 call g04c_find_prior_binding_expr
 test rax,rax
 jz .bad
 mov rdi,r12
 mov rsi,rax
 mov rdx,r14
 call g04c_extract_static_bytes
 jmp .done
.call:
 mov r15,rax
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g04c_token_match
 test eax,eax
 jnz .ok
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g04c_token_match
 test eax,eax
 jnz .one
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g04c_token_match
 test eax,eax
 jnz .four
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call g04c_token_match
 test eax,eax
 jnz .slice
 jmp .bad
.one: mov qword [rsp],1
 jmp .constructor
.four: mov qword [rsp],4
.constructor:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+8],0
 xor r15d,r15d
.value_loop:
 cmp r15,[rsp]
 jae .values_done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov ecx,r15d
 shl ecx,3
 shl rax,cl
 or [rsp+8],rax
 inc r15
 jmp .value_loop
.values_done:
 mov rax,[rsp]
 mov [r14],rax
 mov rax,[rsp+8]
 mov [r14+8],rax
 jmp .ok
.slice:
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call g04c_extract_static_bytes
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+16],rcx
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rcx,[rsp+16]
 cmp rcx,rdx
 ja .bad
 cmp rdx,[r14]
 ja .bad
 sub rdx,rcx
 mov rax,[r14+8]
 shl rcx,3
 shr rax,cl
 test rdx,rdx
 jz .slice_empty
 mov rcx,rdx
 shl rcx,3
 mov rbx,1
 shl rbx,cl
 dec rbx
 and rax,rbx
 jmp .slice_write
.slice_empty: xor eax,eax
.slice_write:
 mov [r14],rdx
 mov [r14+8],rax
.ok: xor eax,eax
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, slice call node id: emit the bounded slice as another immutable
; Bytes descriptor. A zero-length slice keeps one inert data byte but length 0.
g04c_emit_bytes_slice_data:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call g04c_extract_static_bytes
 test eax,eax
 jnz .bad
 mov rdi,r12
 lea rsi,[rel align8]
 mov edx,align8_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel slice_data_prefix]
 mov edx,slice_data_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_data_mid]
 mov edx,bytes_data_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 xor r14d,r14d
.byte_loop:
 cmp r14,[rsp]
 jae .bytes_done
 test r14,r14
 jz .byte_value
 mov rdi,r12
 lea rsi,[rel comma_space]
 mov edx,comma_space_len
 call g04c_append
 test eax,eax
 jnz .done
.byte_value:
 mov rax,[rsp+8]
 mov ecx,r14d
 shl ecx,3
 shr rax,cl
 and eax,255
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,rax
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 inc r14
 jmp .byte_loop
.bytes_done:
 cmp qword [rsp],0
 jne .data_newline
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 xor esi,esi
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
.data_newline:
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel slice_desc_prefix]
 mov edx,slice_desc_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel slice_desc_mid]
 mov edx,slice_desc_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_desc_length]
 mov edx,bytes_desc_length_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_desc_tail]
 mov edx,bytes_desc_tail_len
 call g04c_append
 jmp .done
.writer: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, constructor call node id: emit one immutable static Bytes descriptor.
g04c_emit_bytes_constructor_data:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,rax
 mov r14,[rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp r14,1
 je .have_count
 cmp r14,4
 jne .bad
.have_count:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rsi,[rel align8]
 mov edx,align8_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel bytes_data_prefix]
 mov edx,bytes_data_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_data_mid]
 mov edx,bytes_data_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 xor ebx,ebx
.value_loop:
 cmp rbx,r14
 jae .values_done
 test r15,r15
 jz .bad
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r15
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp],rax
 test rbx,rbx
 jz .value
 mov rdi,r12
 lea rsi,[rel comma_space]
 mov edx,comma_space_len
 call g04c_append
 test eax,eax
 jnz .done
.value:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 inc rbx
 jmp .value_loop
.values_done:
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel bytes_desc_prefix]
 mov edx,bytes_desc_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_desc_mid]
 mov edx,bytes_desc_mid_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_desc_length]
 mov edx,bytes_desc_length_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel bytes_desc_tail]
 mov edx,bytes_desc_tail_len
 call g04c_append
 jmp .done
.writer:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_text_char_bytes_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DEPTH_OFFSET],0
 mov dword [r12+NEBOC_CODEGEN_RETURN_SEEN_OFFSET],0
 cmp qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .depth_ok
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_DEFAULT
.depth_ok:
 mov rdi,r13
 mov rsi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_ROOT_ID_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test rbx,rbx
 jz .ast
 mov rdi,r13
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 je .unsupported
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov [rsp],rax
 mov rdi,r12
 lea rsi,[rel prologue]
 mov edx,prologue_len
 call g04c_append
 test eax,eax
 jnz .done
 cmp dword [r12+NEBOC_CODEGEN_OPTION_USED_OFFSET],0
 je .frame_ready
 mov rdi,r12
 lea rsi,[rel option_frame]
 mov edx,option_frame_len
 call g04c_append
 test eax,eax
 jnz .done
.frame_ready:
 mov rax,[rsp]
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test rbx,rbx
 jz .tail
 mov rdi,r13
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BINDING_STMT
 je .stmt
 cmp rcx,NEBOC_AST_EXPRESSION_STMT
 je .stmt
 cmp rcx,NEBOC_AST_RETURN_STMT
 jne .unsupported
.stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r13
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 je .unwrap
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .expr_ready
 mov dword [r12+NEBOC_CODEGEN_RETURN_SEEN_OFFSET],1
.unwrap:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.expr_ready:
 mov rdi,r12
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rbx,r15
 jmp .statement_loop
.tail:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_OPERATION_COUNT_OFFSET],0
 je .unsupported
 mov rdi,r12
 cmp dword [r12+NEBOC_CODEGEN_RETURN_SEEN_OFFSET],0
 jne .return_tail
 lea rsi,[rel epilogue]
 mov edx,epilogue_len
 call g04c_append
 jmp .done
.return_tail:
 lea rsi,[rel return_epilogue]
 mov edx,return_epilogue_len
 call g04c_append
 jmp .done
.unsupported:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; C13-PRC-A3 compiler-internal composition entry.  The shared FunctionTable
; backend delegates one expression only after the existing textual semantic
; owner has validated the complete Program AST.  This is not a source/runtime
; API; it reuses the exact lowering routine below.
NEBOC_ABI_FUNCTION neboc_text_char_bytes_codegen_emit_expression
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rdi+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [rdi+neboc_text_char_unicode_e_bytes_CODEGEN_DEPTH_OFFSET],0
 cmp qword [rdi+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .ready
 mov qword [rdi+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_DEFAULT
.ready:
 jmp g04c_emit_any
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

g04c_emit_any:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov [rsp],r13
 inc qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DEPTH_OFFSET]
 mov rax,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_DEPTH_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET]
 ja .unsupported
 mov r14,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,rax
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .integer_literal
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BOOL_LITERAL
 je .bool_literal
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .unary_expr
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CHAR_LITERAL
 je .char_literal
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .unsupported
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call g04c_token_match
 test eax,eax
 jnz .byte_length
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_codepoint_count]
 mov ecx,n_codepoint_count_len
 call g04c_token_match
 test eax,eax
 jnz .codepoint_count
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_grapheme_count]
 mov ecx,n_grapheme_count_len
 call g04c_token_match
 test eax,eax
 jnz .grapheme_count
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_normalize_nfc]
 mov ecx,n_normalize_nfc_len
 call g04c_token_match
 test eax,eax
 jnz .text_normalize_nfc
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_normalize_nfd]
 mov ecx,n_normalize_nfd_len
 call g04c_token_match
 test eax,eax
 jnz .text_normalize_nfd
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_case_fold]
 mov ecx,n_case_fold_len
 call g04c_token_match
 test eax,eax
 jnz .text_case_fold
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_slice_codepoints]
 mov ecx,n_slice_codepoints_len
 call g04c_token_match
 test eax,eax
 jnz .text_slice_codepoints
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_slice_graphemes]
 mov ecx,n_slice_graphemes_len
 call g04c_token_match
 test eax,eax
 jnz .text_slice_graphemes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call g04c_token_match
 test eax,eax
 jnz .codepoint
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_empty_text]
 mov ecx,n_is_empty_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_empty
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_equals_text]
 mov ecx,n_equals_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_equals
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_equals_ascii_ignore_case]
 mov ecx,n_equals_ascii_ignore_case_len
 call g04c_token_match
 test eax,eax
 jnz .text_equals_ascii_ignore_case
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_starts_with_text]
 mov ecx,n_starts_with_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_starts_with
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_ends_with_text]
 mov ecx,n_ends_with_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_ends_with
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_contains_text]
 mov ecx,n_contains_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_contains
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_index_of]
 mov ecx,n_index_of_len
 call g04c_token_match
 test eax,eax
 jnz .text_index_of
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_last_index_of]
 mov ecx,n_last_index_of_len
 call g04c_token_match
 test eax,eax
 jnz .text_last_index_of
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_ascii]
 mov ecx,n_is_ascii_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_ascii
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_utf8]
 mov ecx,n_is_utf8_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_utf8
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_blank]
 mov ecx,n_is_blank_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_blank
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_digits]
 mov ecx,n_is_digits_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_digits
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_alpha_ascii]
 mov ecx,n_is_alpha_ascii_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_alpha_ascii
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_alnum_ascii]
 mov ecx,n_is_alnum_ascii_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_alnum_ascii
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_concat_text]
 mov ecx,n_concat_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_concat
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_trim]
 mov ecx,n_trim_len
 call g04c_token_match
 test eax,eax
 jnz .text_trim
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_trim_start]
 mov ecx,n_trim_start_len
 call g04c_token_match
 test eax,eax
 jnz .text_trim_start
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_trim_end]
 mov ecx,n_trim_end_len
 call g04c_token_match
 test eax,eax
 jnz .text_trim_end
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_lower_text]
 mov ecx,n_lower_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_lower
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_upper_text]
 mov ecx,n_upper_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_upper
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_byte_slice_text]
 mov ecx,n_byte_slice_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_byte_slice
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_take_bytes]
 mov ecx,n_take_bytes_len
 call g04c_token_match
 test eax,eax
 jnz .text_take_bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_drop_bytes]
 mov ecx,n_drop_bytes_len
 call g04c_token_match
 test eax,eax
 jnz .text_drop_bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_normalize_newlines]
 mov ecx,n_normalize_newlines_len
 call g04c_token_match
 test eax,eax
 jnz .text_normalize_newlines
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_normalize_whitespace]
 mov ecx,n_normalize_whitespace_len
 call g04c_token_match
 test eax,eax
 jnz .text_normalize_whitespace
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_replace_once]
 mov ecx,n_replace_once_len
 call g04c_token_match
 test eax,eax
 jnz .text_replace_once
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_replace_all]
 mov ecx,n_replace_all_len
 call g04c_token_match
 test eax,eax
 jnz .text_replace_all
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_split_text]
 mov ecx,n_split_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_split
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_join_text]
 mov ecx,n_join_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_join
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_pad_start]
 mov ecx,n_pad_start_len
 call g04c_token_match
 test eax,eax
 jnz .text_pad_start
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_pad_end]
 mov ecx,n_pad_end_len
 call g04c_token_match
 test eax,eax
 jnz .text_pad_end
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_int_text]
 mov ecx,n_parse_int_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_parse_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_float_text]
 mov ecx,n_parse_float_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_parse_float
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_bool_text]
 mov ecx,n_parse_bool_text_len
 call g04c_token_match
 test eax,eax
 jnz .text_parse_bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_split_checked]
 mov ecx,n_split_checked_len
 call g04c_token_match
 test eax,eax
 jnz .text_split_checked
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_replace_all_checked]
 mov ecx,n_replace_all_checked_len
 call g04c_token_match
 test eax,eax
 jnz .text_replace_all_checked
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_to_text]
 mov ecx,n_to_text_len
 call g04c_token_match
 test eax,eax
 jnz .to_text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_nebo_identifier]
 mov ecx,n_is_nebo_identifier_len
 call g04c_token_match
 test eax,eax
 jnz .text_is_nebo_identifier
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g04c_token_match
 test eax,eax
 jnz .empty
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_constructor
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_constructor
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_at]
 mov ecx,n_at_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_at
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_get]
 mov ecx,n_get_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_get
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_slice
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_some]
 mov ecx,n_is_some_len
 call g04c_token_match
 test eax,eax
 jnz .option_is_some
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_none]
 mov ecx,n_is_none_len
 call g04c_token_match
 test eax,eax
 jnz .option_is_none
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_unwrap_or]
 mov ecx,n_unwrap_or_len
 call g04c_token_match
 test eax,eax
 jnz .option_unwrap_or
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_ok]
 mov ecx,n_is_ok_len
 call g04c_token_match
 test eax,eax
 jnz .result_is_ok
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_is_err]
 mov ecx,n_is_err_len
 call g04c_token_match
 test eax,eax
 jnz .result_is_err
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call g04c_token_match
 test eax,eax
 jnz .bit_and
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call g04c_token_match
 test eax,eax
 jnz .bit_or
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call g04c_token_match
 test eax,eax
 jnz .bit_xor
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call g04c_token_match
 test eax,eax
 jnz .bit_not
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call g04c_token_match
 test eax,eax
 jnz .shift_left
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call g04c_token_match
 test eax,eax
 jnz .shift_right
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call g04c_token_match
 test eax,eax
 jnz .test_bit
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call g04c_token_match
 test eax,eax
 jnz .with_bit
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g04c_token_match
 test eax,eax
 jnz .console
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_scan]
 mov ecx,n_scan_len
 call g04c_token_match
 test eax,eax
 jnz .scan
 jmp .unsupported
.integer_literal:
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 jmp .count
.bool_literal:
 mov rdi,r12
 lea rsi,[rel mov_eax]
 mov edx,mov_eax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 jmp .count
.unary_expr:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsupported
 mov rdi,r12
 lea rsi,[rel neg_rax]
 mov edx,neg_rax_len
 call g04c_append
 jmp .count
.char_literal:
 mov rdi,r12
 lea rsi,[rel mov_edi]
 mov edx,mov_edi_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov esi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 jmp .count
.bytes_slice:
 mov rdi,r12
 lea rsi,[rel lea_slice_prefix]
 mov edx,lea_slice_prefix_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel lea_bytes_suffix]
 mov edx,lea_bytes_suffix_len
 call g04c_append
 jmp .count
.bytes_at:
 mov rdi,r12
 mov rsi,[rsp]
 mov edx,NEBOC_BYTES_ACCESS_AT
 call g04c_evaluate_access
 test eax,eax
 jnz .unsupported
 mov [rsp],rdx
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 jmp .count
.bytes_get:
 mov rdi,r12
 mov rsi,[rsp]
 mov edx,NEBOC_BYTES_ACCESS_GET
 call g04c_evaluate_access
 test eax,eax
 jnz .unsupported
 mov [rsp],rdx
 mov r13,rcx
 mov rdi,r12
 lea rsi,[rel lea_option_slot]
 mov edx,lea_option_slot_len
 call g04c_append
 test eax,eax
 jnz .finish
 test r13,r13
 jz .get_none
 mov rdi,r12
 lea rsi,[rel mov_esi_one]
 mov edx,mov_esi_one_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel mov_edx]
 mov edx,mov_edx_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_option_integer]
 mov edx,call_option_integer_len
 call g04c_append
 jmp .get_address
.get_none:
 mov rdi,r12
 lea rsi,[rel mov_esi_zero]
 mov edx,mov_esi_zero_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_option_zero]
 mov edx,call_option_zero_len
 call g04c_append
.get_address:
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel lea_option_result]
 mov edx,lea_option_result_len
 call g04c_append
 jmp .count
.option_is_some:
 mov r13d,1
 jmp .option_predicate
.option_is_none:
 xor r13d,r13d
 jmp .option_predicate
.result_is_ok:
 xor r13d,r13d
 jmp .option_predicate
.result_is_err:
 mov r13d,1
.option_predicate:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 test r13,r13
 jz .predicate_zero
 lea rsi,[rel mov_esi_one]
 mov edx,mov_esi_one_len
 jmp .predicate_tag
.predicate_zero:
 lea rsi,[rel mov_esi_zero]
 mov edx,mov_esi_zero_len
.predicate_tag:
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_option_tag_test]
 mov edx,call_option_tag_test_len
 call g04c_append
 jmp .count
.option_unwrap_or:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 ; Option success is Some=1; G056 Result success is Ok=0.
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .unwrap_option_tag
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_int_text]
 mov ecx,n_parse_int_text_len
 call g04c_token_match
 test eax,eax
 jnz .unwrap_result_tag
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_bool_text]
 mov ecx,n_parse_bool_text_len
 call g04c_token_match
 test eax,eax
 jnz .unwrap_result_tag
.unwrap_option_tag:
 mov rdi,r12
 lea rsi,[rel mov_esi_one]
 mov edx,mov_esi_one_len
 jmp .unwrap_tag_ready
.unwrap_result_tag:
 mov rdi,r12
 lea rsi,[rel mov_esi_zero]
 mov edx,mov_esi_zero_len
.unwrap_tag_ready:
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r14
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rsi,[rel mov_edx]
 mov edx,mov_edx_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_option_unwrap]
 mov edx,call_option_unwrap_len
 call g04c_append
 jmp .count
.bit_and:
 mov r13d,NEBOC_INT_BITS_AND
 jmp .bit_binary
.bit_or:
 mov r13d,NEBOC_INT_BITS_OR
 jmp .bit_binary
.bit_xor:
 mov r13d,NEBOC_INT_BITS_XOR
.bit_binary:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel push_rax]
 mov edx,push_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 cmp r13,NEBOC_INT_BITS_AND
 je .emit_and
 cmp r13,NEBOC_INT_BITS_OR
 je .emit_or
 lea rsi,[rel bit_xor_rax]
 mov edx,bit_xor_rax_len
 jmp .emit_bit
.emit_and:
 lea rsi,[rel bit_and_rax]
 mov edx,bit_and_rax_len
 jmp .emit_bit
.emit_or:
 lea rsi,[rel bit_or_rax]
 mov edx,bit_or_rax_len
.emit_bit:
 call g04c_append
 jmp .count
.bit_not:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel bit_not_rax]
 mov edx,bit_not_rax_len
 call g04c_append
 jmp .count
.shift_left:
 mov r13d,NEBOC_INT_BITS_SHIFT_LEFT
 jmp .bit_position
.shift_right:
 mov r13d,NEBOC_INT_BITS_SHIFT_RIGHT
 jmp .bit_position
.test_bit:
 mov r13d,NEBOC_INT_BITS_TEST_BIT
 jmp .bit_position
.with_bit:
 mov r13d,NEBOC_INT_BITS_WITH_BIT
.bit_position:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r14
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rdi,r12
 cmp r13,NEBOC_INT_BITS_SHIFT_LEFT
 je .emit_shift_left
 cmp r13,NEBOC_INT_BITS_SHIFT_RIGHT
 je .emit_shift_right
 cmp r13,NEBOC_INT_BITS_TEST_BIT
 je .emit_test_bit
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r14
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 je .emit_with_bit_clear
 mov rdi,r12
 lea rsi,[rel with_bit_set_rax]
 mov edx,with_bit_set_rax_len
 jmp .emit_position_prefix
.emit_with_bit_clear:
 mov rdi,r12
 lea rsi,[rel with_bit_clear_rax]
 mov edx,with_bit_clear_rax_len
 jmp .emit_position_prefix
.emit_shift_left:
 lea rsi,[rel shift_left_rax]
 mov edx,shift_left_rax_len
 jmp .emit_position_prefix
.emit_shift_right:
 lea rsi,[rel shift_right_rax]
 mov edx,shift_right_rax_len
 jmp .emit_position_prefix
.emit_test_bit:
 lea rsi,[rel test_bit_rax]
 mov edx,test_bit_rax_len
.emit_position_prefix:
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 cmp r13,NEBOC_INT_BITS_TEST_BIT
 jne .emit_position_newline
 lea rsi,[rel test_bit_suffix]
 mov edx,test_bit_suffix_len
 call g04c_append
 jmp .count
.emit_position_newline:
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 jmp .count
.byte_length:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g04c_emit_receiver
 test eax,eax
 jnz .finish
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .text_length
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .text_length
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 ; A nested G055 transform is still Text. Only the two public Bytes-producing
 ; receiver calls owned by this bounded backend select the Bytes length symbol.
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g04c_token_match
 test eax,eax
 jnz .bytes_length
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call g04c_token_match
 test eax,eax
 jz .text_length
.bytes_length:
 mov rdi,r12
 lea rsi,[rel call_bytes_byte_length]
 mov edx,call_bytes_byte_length_len
 call g04c_append
 jmp .count
.text_length:
 mov rdi,r12
 lea rsi,[rel call_text_byte_length]
 mov edx,call_text_byte_length_len
 call g04c_append
 jmp .count
.codepoint_count:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_codepoint_count]
 mov edx,call_text_codepoint_count_len
 call g04c_append
 jmp .count
.grapheme_count:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_grapheme_count]
 mov edx,call_text_grapheme_count_len
 call g04c_append
 jmp .count
.codepoint:
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CHAR_LITERAL
 jne .unsupported
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rsi,[rel mov_edi]
 mov edx,mov_edi_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_char_codepoint]
 mov edx,call_char_codepoint_len
 call g04c_append
 jmp .count
.text_is_empty:
 lea rax,[rel call_text_is_empty]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_empty_len
 jmp .text_predicate
.text_is_ascii:
 lea rax,[rel call_text_is_ascii]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_ascii_len
 jmp .text_predicate
.text_is_utf8:
 lea rax,[rel call_text_is_utf8]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_utf8_len
 jmp .text_predicate
.text_is_blank:
 lea rax,[rel call_text_is_blank]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_blank_len
 jmp .text_predicate
.text_is_digits:
 lea rax,[rel call_text_is_digits]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_digits_len
 jmp .text_predicate
.text_is_alpha_ascii:
 lea rax,[rel call_text_is_alpha_ascii]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_alpha_ascii_len
 jmp .text_predicate
.text_is_alnum_ascii:
 lea rax,[rel call_text_is_alnum_ascii]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_alnum_ascii_len
 jmp .text_predicate
.text_is_nebo_identifier:
 lea rax,[rel call_text_is_nebo_identifier]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_is_nebo_identifier_len
.text_predicate:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_equals:
 lea rax,[rel call_text_equals]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_equals_len
 jmp .text_binary_bool
.text_equals_ascii_ignore_case:
 lea rax,[rel call_text_equals_ascii_ignore_case]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_equals_ascii_ignore_case_len
 jmp .text_binary_bool
.text_starts_with:
 lea rax,[rel call_text_starts_with]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_starts_with_len
 jmp .text_binary_bool
.text_ends_with:
 lea rax,[rel call_text_ends_with]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_ends_with_len
 jmp .text_binary_bool
.text_contains:
 lea rax,[rel call_text_contains]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_contains_len
.text_binary_bool:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_query_pair
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_index_of:
 lea rax,[rel call_text_index_of]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_index_of_len
 jmp .text_index
.text_last_index_of:
 lea rax,[rel call_text_last_index_of]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_last_index_of_len
.text_index:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_query_pair
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel lea_option_out]
 mov edx,lea_option_out_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_parse_int:
 lea rax,[rel call_text_parse_int]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_parse_int_len
 jmp .text_parse_scalar
.text_parse_float:
 lea rax,[rel call_text_parse_float]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_parse_float_len
 jmp .text_parse_scalar
.text_parse_bool:
 lea rax,[rel call_text_parse_bool]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_parse_bool_len
.text_parse_scalar:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel parse_result_setup]
 mov edx,parse_result_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_trim:
 lea rax,[rel call_text_trim]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_trim_len
 jmp .text_zero_view
.text_trim_start:
 lea rax,[rel call_text_trim_start]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_trim_start_len
 jmp .text_zero_view
.text_trim_end:
 lea rax,[rel call_text_trim_end]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_trim_end_len
.text_zero_view:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_zero_view_setup]
 mov edx,transform_zero_view_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_lower:
 lea rax,[rel call_text_lower]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_lower_len
 jmp .text_zero_buffer
.text_upper:
 lea rax,[rel call_text_upper]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_upper_len
 jmp .text_zero_buffer
.text_normalize_nfc:
 lea rax,[rel call_text_normalize_nfc]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_normalize_nfc_len
 jmp .text_zero_buffer
.text_normalize_nfd:
 lea rax,[rel call_text_normalize_nfd]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_normalize_nfd_len
 jmp .text_zero_buffer
.text_case_fold:
 lea rax,[rel call_text_case_fold]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_case_fold_len
 jmp .text_zero_buffer
.text_normalize_newlines:
 lea rax,[rel call_text_normalize_newlines]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_normalize_newlines_len
 jmp .text_zero_buffer
.text_normalize_whitespace:
 lea rax,[rel call_text_normalize_whitespace]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_normalize_whitespace_len
.text_zero_buffer:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_zero_buffer_setup]
 mov edx,transform_zero_buffer_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_concat:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_query_pair
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_one_text_setup]
 mov edx,transform_one_text_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_concat]
 mov edx,call_text_concat_len
 call g04c_append
 jmp .count
.text_split:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_query_pair
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_split_setup]
 mov edx,transform_split_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_split]
 mov edx,call_text_split_len
 call g04c_append
 jmp .count
.text_split_checked:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_query_pair
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel split_checked_setup]
 mov edx,split_checked_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_split_checked]
 mov edx,call_text_split_checked_len
 call g04c_append
 jmp .count
.text_join:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_text_join_arguments
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_join_setup]
 mov edx,transform_join_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_join]
 mov edx,call_text_join_len
 call g04c_append
 jmp .count
.text_replace_once:
 lea rax,[rel call_text_replace_once]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_replace_once_len
 jmp .text_replace
.text_replace_all:
 lea rax,[rel call_text_replace_all]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_replace_all_len
.text_replace:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_two_text
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_two_text_setup]
 mov edx,transform_two_text_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_replace_all_checked:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_two_text
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel replace_checked_setup]
 mov edx,replace_checked_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_replace_all_checked]
 mov edx,call_text_replace_all_checked_len
 call g04c_append
 jmp .count
.text_byte_slice:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_two_int
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_byte_slice_setup]
 mov edx,transform_byte_slice_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_byte_slice]
 mov edx,call_text_byte_slice_len
 call g04c_append
 jmp .count
.text_slice_codepoints:
 lea rax,[rel call_text_slice_codepoints]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_slice_codepoints_len
 jmp .text_unicode_slice
.text_slice_graphemes:
 lea rax,[rel call_text_slice_graphemes]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_slice_graphemes_len
.text_unicode_slice:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_two_int
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_byte_slice_setup]
 mov edx,transform_byte_slice_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_take_bytes:
 lea rax,[rel call_text_take_bytes]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_take_bytes_len
 jmp .text_one_int
.text_drop_bytes:
 lea rax,[rel call_text_drop_bytes]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_drop_bytes_len
.text_one_int:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_one_int
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_one_int_setup]
 mov edx,transform_one_int_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.text_pad_start:
 lea rax,[rel call_text_pad_start]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_pad_start_len
 jmp .text_pad
.text_pad_end:
 lea rax,[rel call_text_pad_end]
 mov [rsp+8],rax
 mov qword [rsp+16],call_text_pad_end_len
.text_pad:
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_transform_pad
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel transform_pad_setup]
 mov edx,transform_pad_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+16]
 call g04c_append
 jmp .count
.to_text:
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp r13,NEBOC_AST_TEXT_LITERAL
 je .to_text_text
 cmp r13,NEBOC_AST_INTEGER_LITERAL
 je .to_text_int
 cmp r13,NEBOC_AST_UNARY_EXPR
 je .to_text_int
 cmp r13,NEBOC_AST_BOOL_LITERAL
 je .to_text_bool
 cmp r13,NEBOC_AST_CALL_EXPR
 jne .unsupported
 ; Resolve the scalar type of Result.unwrapOr composition from its parse
 ; receiver.  Other nested calls reaching this branch produce Text.
 mov [rsp+8],rax
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_unwrap_or]
 mov ecx,n_unwrap_or_len
 call g04c_token_match
 test eax,eax
 jz .to_text_text
 mov rax,[rsp+8]
 mov rdi,r14
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .unsupported
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_int_text]
 mov ecx,n_parse_int_text_len
 call g04c_token_match
 test eax,eax
 jnz .to_text_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_parse_bool_text]
 mov ecx,n_parse_bool_text_len
 call g04c_token_match
 test eax,eax
 jnz .to_text_bool
 jmp .unsupported
.to_text_text:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel text_to_text_setup]
 mov edx,text_to_text_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_text_to_text]
 mov edx,call_text_to_text_len
 call g04c_append
 jmp .count
.to_text_int:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel int_to_text_setup]
 mov edx,int_to_text_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_int_to_text]
 mov edx,call_int_to_text_len
 call g04c_append
 jmp .count
.to_text_bool:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel bool_to_text_setup]
 mov edx,bool_to_text_setup_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_bool_to_text]
 mov edx,call_bool_to_text_len
 call g04c_append
 jmp .count
.empty:
 mov rdi,r12
 lea rsi,[rel call_bytes_empty]
 mov edx,call_bytes_empty_len
 call g04c_append
 jmp .count
.bytes_constructor:
 mov rdi,r12
 lea rsi,[rel lea_bytes_prefix]
 mov edx,lea_bytes_prefix_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel lea_bytes_suffix]
 mov edx,lea_bytes_suffix_len
 call g04c_append
 jmp .count
.console:
 mov rdi,r14
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_node_ptr
 test rax,rax
 jz .ast
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_INTEGER_LITERAL
 je .console_int
 cmp rcx,NEBOC_AST_UNARY_EXPR
 je .console_int
 cmp rcx,NEBOC_AST_BOOL_LITERAL
 je .console_bool
 cmp rcx,NEBOC_AST_TEXT_LITERAL
 je .console_text
 cmp rcx,NEBOC_AST_CALL_EXPR
 jne .unsupported
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .unsupported
.console_text:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_console_publish_text]
 mov edx,call_console_publish_text_len
 call g04c_append
 jmp .count
.console_int:
 mov r13d,1
 jmp .console_scalar
.console_bool:
 mov r13d,2
.console_scalar:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_any
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 test eax,eax
 jnz .finish
 mov rdi,r12
 cmp r13d,1
 jne .console_scalar_bool
 lea rsi,[rel call_console_publish_int]
 mov edx,call_console_publish_int_len
 call g04c_append
 jmp .count
.console_scalar_bool:
 lea rsi,[rel call_console_publish_bool]
 mov edx,call_console_publish_bool_len
 call g04c_append
 jmp .count
.scan:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_scan_prompt
 test eax,eax
 jnz .finish
 mov rdi,r12
 mov rsi,[rsp]
 call g04c_emit_scan_ids
 test eax,eax
 jnz .finish
 mov rdi,r12
 lea rsi,[rel call_scan_anonymous]
 mov edx,call_scan_anonymous_len
 call g04c_append
.count:
 test eax,eax
 jnz .finish
 inc qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .finish
.writer:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .finish
.ast:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .finish
.unsupported:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.finish:
 dec qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DEPTH_OFFSET]
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, stable AST node id -> deterministic nonzero BindingId, PendingId,
; and source order.  The same node identity may inhabit the three disjoint ID
; namespaces; uniqueness is enforced independently by the canonical route.
g04c_emit_scan_ids:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad
 lea rbx,[rel mov_esi]
 mov edx,mov_esi_len
 call .emit_one
 test eax,eax
 jnz .done
 lea rbx,[rel mov_edx_scan]
 mov edx,mov_edx_scan_len
 call .emit_one
 test eax,eax
 jnz .done
 lea rbx,[rel mov_ecx]
 mov edx,mov_ecx_len
 call .emit_one
 jmp .done
.emit_one:
 sub rsp,8
 mov rdi,r12
 mov rsi,rbx
 call g04c_append
 test eax,eax
 jnz .emit_done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .emit_done
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g04c_append
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

; request*, receiver node id: materialize the prompt descriptor used by either
; Text.scan() or Text.console().scan().  Console.scan on a named binding keeps
; its existing runtime/headless contract and is outside this frontend slice.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g04c_emit_scan_prompt:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .direct
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04c_emit_text_receiver
 jmp .done
.direct:
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r12
 pop rbx
 ret

; request*, G055 call node id: emit receiver plus one literal Int in RSI.
g04c_emit_transform_one_int:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel one_int_arguments]
 mov edx,one_int_arguments_len
 call g04c_append
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, call node id: receiver, first Int in RSI, second Int in RDX.
g04c_emit_transform_two_int:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rax]
 mov edx,push_rax_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel two_int_arguments]
 mov edx,two_int_arguments_len
 call g04c_append
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, call node id: receiver, first Text in RSI, second Text in RDX.
g04c_emit_transform_two_text:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel two_text_arguments]
 mov edx,two_text_arguments_len
 call g04c_append
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, pad call: receiver, target Int in RSI, fill Text in RDX.
g04c_emit_transform_pad:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rax]
 mov edx,push_rax_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel pad_arguments]
 mov edx,pad_arguments_len
 call g04c_append
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, join call: lower TextSplit receiver to RDI and separator to RSI.
g04c_emit_text_join_arguments:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel pair_text_arguments]
 mov edx,pair_text_arguments_len
 call g04c_append
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, binary Text query call node id: emit receiver in RDI and argument
; in RSI while keeping the generated runtime call stack aligned.
g04c_emit_text_query_pair:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .pair_bad
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .pair_done
 mov rdi,r12
 lea rsi,[rel push_rdi]
 mov edx,push_rdi_len
 call g04c_append
 test eax,eax
 jnz .pair_done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .pair_bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .pair_bad
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 test eax,eax
 jnz .pair_done
 mov rdi,r12
 lea rsi,[rel pair_text_arguments]
 mov edx,pair_text_arguments_len
 call g04c_append
 jmp .pair_done
.pair_bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.pair_done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, node id: emit either Text descriptor address or Bytes.empty().
%undef call
g04c_emit_receiver:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .text
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 jmp .done
.text:
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_text_receiver
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g04c_emit_text_receiver:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .have
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov rdi,r12
 mov rsi,rbx
 call g04c_emit_any
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g04c_append
 jmp .done
.constructor:
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .bad
.have:
 mov rdi,r12
 lea rsi,[rel lea_text_prefix]
 mov edx,lea_text_prefix_len
 call g04c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 mov rsi,rbx
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel lea_text_suffix]
 mov edx,lea_text_suffix_len
 call g04c_append
 jmp .done
.writer: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; request*, access call node id, lowering operation -> status with
; RDX=result value, RCX=Option tag, R8=slice length, R9=slice packed bytes.
%undef call
g04c_evaluate_access:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,112
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+80]
 call g04c_extract_static_bytes
 test eax,eax
 jnz .bad
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g04c_node_ptr
 test rax,rax
 jz .bad
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_BYTES_ACCESS_INDEX_OFFSET],rcx
 cmp r14,NEBOC_BYTES_ACCESS_SLICE
 jne .fill
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET]
 mov rsi,rbx
 call g04c_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_BYTES_ACCESS_END_OFFSET],rcx
.fill:
 mov [rsp+NEBOC_BYTES_ACCESS_OPERATION_OFFSET],r14
 mov rax,[rsp+80]
 mov [rsp+NEBOC_BYTES_ACCESS_LENGTH_OFFSET],rax
 mov rax,[rsp+88]
 mov [rsp+NEBOC_BYTES_ACCESS_PACKED_OFFSET],rax
 lea rdi,[rsp]
 call neboc_bytes_access_lower
 test eax,eax
 jnz .done
 mov rdx,[rsp+NEBOC_BYTES_ACCESS_RESULT_VALUE_OFFSET]
 mov rcx,[rsp+NEBOC_BYTES_ACCESS_OPTION_TAG_OFFSET]
 mov r8,[rsp+NEBOC_BYTES_ACCESS_RESULT_LENGTH_OFFSET]
 mov r9,[rsp+NEBOC_BYTES_ACCESS_RESULT_PACKED_OFFSET]
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,112
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g04c_append:
 mov rax,[rdi+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64]
 test rax,rax
 jz .bad
 mov rdi,rax
 call neboc_assembly_writer_append_bytes
 ret
.bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%undef call
g04c_token_match:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 cmp r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,rbx
 cld
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 cld
 ret

g04c_node_ptr:
 test rdi,rdi
 jz .none
 test rsi,rsi
 jz .none
 cmp rsi,[rdi+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 mov rax,rsi
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[rdi+NEBOC_AST_BUILDER_DATA_OFFSET]
 ret
.none: xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
