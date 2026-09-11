; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF002 isolated Text/Char/Bytes API contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"

section .rodata
n_byte_length: db "byteLength"
n_byte_length_len equ $-n_byte_length
n_codepoint_count: db "codepointCount"
n_codepoint_count_len equ $-n_codepoint_count
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
n_hash_text: db "hash"
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
n_normalize_whitespace: db "normalizeWhitespace"
n_normalize_whitespace_len equ $-n_normalize_whitespace
n_normalize_newlines: db "normalizeNewlines"
n_normalize_newlines_len equ $-n_normalize_newlines
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

n_len: db "len"
n_len_len equ $-n_len
n_length: db "length"
n_length_len equ $-n_length
n_count: db "count"
n_count_len equ $-n_count
n_scalar_unicode: db "scalarUnicode"
n_scalar_unicode_len equ $-n_scalar_unicode

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
n_normalize_nfc_legacy: db "normalizeNFC"
n_normalize_nfc_legacy_len equ $-n_normalize_nfc_legacy
n_concat: db "concat"
n_concat_len equ $-n_concat
n_slice: db "slice"
n_slice_len equ $-n_slice
n_decode_utf8: db "decodeUtf8"
n_decode_utf8_len equ $-n_decode_utf8
n_encode_utf8: db "encodeUtf8"
n_encode_utf8_len equ $-n_encode_utf8

n_text: db "Text"
n_text_len equ $-n_text
n_char: db "Char"
n_char_len equ $-n_char
n_bytes: db "Bytes"
n_bytes_len equ $-n_bytes
n_string: db "String"
n_string_len equ $-n_string
n_rune: db "Rune"
n_rune_len equ $-n_rune
n_codepoint_type: db "CodePoint"
n_codepoint_type_len equ $-n_codepoint_type
n_byte_string: db "ByteString"
n_byte_string_len equ $-n_byte_string
n_buffer: db "Buffer"
n_buffer_len equ $-n_buffer
n_blob: db "Blob"
n_blob_len equ $-n_blob

section .text

text_char_unicode_e_bytes_name_equal:
 cmp rsi,rcx
 jne .no
 test rsi,rsi
 jz .no
 mov rcx,rsi
 mov rsi,rdi
 mov rdi,rdx
 repe cmpsb
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

text_char_unicode_e_bytes_api_hash:
 mov r8,[rdi+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_API_RECEIVER_FORM_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET]
 imul rax,r10
 mov [rdi+neboc_text_char_unicode_e_bytes_API_HASH_OFFSET],rax
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
text_char_unicode_e_bytes_api_error:
 mov [rdi+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET]
 mov [rdi+neboc_text_char_unicode_e_bytes_API_ERROR_START_OFFSET],rax
 add rax,[rdi+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET]
 mov [rdi+neboc_text_char_unicode_e_bytes_API_ERROR_END_OFFSET],rax
 call text_char_unicode_e_bytes_api_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; neboc_text_char_bytes_api_contract(request*) -> StatusCode
%undef call
NEBOC_ABI_FUNCTION neboc_text_char_bytes_api_contract
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET]
 mov r14,[r12+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 mov ecx,(neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE-neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET)/8
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET]
 cmp rax,neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 je .method
 cmp rax,NEBOC_API_OPERATION_TYPE_REFERENCE
 je .type_reference
 cmp rax,NEBOC_API_OPERATION_BYTES_LITERAL
 je .bytes_literal
 jmp .invalid_argument

.method:
 ; Canonical methods.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .byte_length
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_codepoint_count]
 mov ecx,n_codepoint_count_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .codepoint_count
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_grapheme_count]
 mov ecx,n_grapheme_count_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_grapheme_count
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_nfc]
 mov ecx,n_normalize_nfc_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_normalize_nfc
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_nfd]
 mov ecx,n_normalize_nfd_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_normalize_nfd
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_case_fold]
 mov ecx,n_case_fold_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_case_fold
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_slice_codepoints]
 mov ecx,n_slice_codepoints_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_slice_codepoints
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_slice_graphemes]
 mov ecx,n_slice_graphemes_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_slice_graphemes
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .codepoint
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_hash_text]
 mov ecx,4
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_hash
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_empty_text]
 mov ecx,n_is_empty_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_empty
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_equals_text]
 mov ecx,n_equals_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_equals
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_equals_ascii_ignore_case]
 mov ecx,n_equals_ascii_ignore_case_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_equals_ascii_ignore_case
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_starts_with_text]
 mov ecx,n_starts_with_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_starts_with
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_ends_with_text]
 mov ecx,n_ends_with_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_ends_with
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_contains_text]
 mov ecx,n_contains_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_contains
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_index_of]
 mov ecx,n_index_of_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_index_of
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_last_index_of]
 mov ecx,n_last_index_of_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_last_index_of
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_ascii]
 mov ecx,n_is_ascii_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_ascii
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_utf8]
 mov ecx,n_is_utf8_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_utf8
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_blank]
 mov ecx,n_is_blank_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_blank
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_digits]
 mov ecx,n_is_digits_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_digits
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_alpha_ascii]
 mov ecx,n_is_alpha_ascii_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_alpha_ascii
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_alnum_ascii]
 mov ecx,n_is_alnum_ascii_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_alnum_ascii
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_concat]
 mov ecx,n_concat_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_concat
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_trim]
 mov ecx,n_trim_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_trim
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_trim_start]
 mov ecx,n_trim_start_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_trim_start
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_trim_end]
 mov ecx,n_trim_end_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_trim_end
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_lower_text]
 mov ecx,n_lower_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_lower
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_upper_text]
 mov ecx,n_upper_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_upper
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_byte_slice_text]
 mov ecx,n_byte_slice_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_byte_slice
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_take_bytes]
 mov ecx,n_take_bytes_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_take_bytes
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_drop_bytes]
 mov ecx,n_drop_bytes_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_drop_bytes
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_replace_once]
 mov ecx,n_replace_once_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_replace_once
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_replace_all]
 mov ecx,n_replace_all_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_replace_all
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_split_text]
 mov ecx,n_split_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_split
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_join_text]
 mov ecx,n_join_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_join
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_pad_start]
 mov ecx,n_pad_start_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_pad_start
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_pad_end]
 mov ecx,n_pad_end_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_pad_end
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_whitespace]
 mov ecx,n_normalize_whitespace_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_normalize_whitespace
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_newlines]
 mov ecx,n_normalize_newlines_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_normalize_newlines
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_parse_int_text]
 mov ecx,n_parse_int_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_parse_int
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_parse_float_text]
 mov ecx,n_parse_float_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_parse_float
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_parse_bool_text]
 mov ecx,n_parse_bool_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_parse_bool
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_split_checked]
 mov ecx,n_split_checked_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_split_checked
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_replace_all_checked]
 mov ecx,n_replace_all_checked_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_replace_all_checked
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_to_text]
 mov ecx,n_to_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .to_text
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_nebo_identifier]
 mov ecx,n_is_nebo_identifier_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .text_is_nebo_identifier
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .empty
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .from_byte
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .from_values
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_at]
 mov ecx,n_at_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .at
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_get]
 mov ecx,n_get_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .get
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel text_char_bytes_codegen_n_slice]
 mov ecx,text_char_bytes_codegen_n_slice_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .slice
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_some]
 mov ecx,n_is_some_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .is_some
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_none]
 mov ecx,n_is_none_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .is_none
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_unwrap_or]
 mov ecx,n_unwrap_or_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .unwrap_or
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_ok]
 mov ecx,n_is_ok_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .result_is_ok
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_is_err]
 mov ecx,n_is_err_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .result_is_err
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .bit_and
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .bit_or
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .bit_xor
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .bit_not
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .shift_left
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .shift_right
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .test_bit
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .with_bit
 ; Forbidden method aliases.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_len]
 mov ecx,n_len_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_length]
 mov ecx,n_length_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_count]
 mov ecx,n_count_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_scalar_unicode]
 mov ecx,n_scalar_unicode_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_nfc_legacy]
 mov ecx,n_normalize_nfc_legacy_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 ; Deferred methods.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_slice]
 mov ecx,n_slice_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_decode_utf8]
 mov ecx,n_decode_utf8_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_encode_utf8]
 mov ecx,n_encode_utf8_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 jmp .unknown

.byte_length:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 mov rax,[r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rax,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 je .ok_text_byte_length
 cmp rax,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 je .ok_bytes_byte_length
 mov esi,NEBOC_API_DIAG_RECEIVER_MUST_BE_TEXT
 jmp .error
.ok_text_byte_length:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_BYTE_LENGTH
 jmp .ok_int_instance
.ok_bytes_byte_length:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_BYTE_LENGTH
 jmp .ok_int_instance
.codepoint_count:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_CODEPOINT_COUNT
 jmp .ok_int_instance
.text_grapheme_count:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_unicode_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_GRAPHEME_COUNT
 jmp .ok_int_instance
.text_normalize_nfc:
 mov eax,NEBOC_API_METHOD_TEXT_NORMALIZE_NFC
 jmp .text_unicode_zero
.text_normalize_nfd:
 mov eax,NEBOC_API_METHOD_TEXT_NORMALIZE_NFD
 jmp .text_unicode_zero
.text_case_fold:
 mov eax,NEBOC_API_METHOD_TEXT_CASE_FOLD
.text_unicode_zero:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_unicode_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 jmp .ok_bounded_instance
.text_slice_codepoints:
 mov eax,NEBOC_API_METHOD_TEXT_SLICE_CODEPOINTS
 jmp .text_unicode_slice
.text_slice_graphemes:
 mov eax,NEBOC_API_METHOD_TEXT_SLICE_GRAPHEMES
.text_unicode_slice:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],2
 jne .text_unicode_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE
 jmp .ok
.codepoint:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 jne .receiver_char
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_CHAR_CODEPOINT
 jmp .ok_int_instance
.text_hash:
 ; Int.hash(Hasher) shares this spelling. Establish the receiver owner before
 ; reporting Text.hash arity, including speculative typed method queries.
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_HASH
 jmp .ok_int_instance
.text_is_empty:
 mov eax,NEBOC_API_METHOD_TEXT_IS_EMPTY
 jmp .text_zero_bool
.text_is_ascii:
 mov eax,NEBOC_API_METHOD_TEXT_IS_ASCII
 jmp .text_zero_bool
.text_is_utf8:
 mov eax,NEBOC_API_METHOD_TEXT_IS_UTF8
 jmp .text_zero_bool
.text_is_blank:
 mov eax,NEBOC_API_METHOD_TEXT_IS_BLANK
 jmp .text_zero_bool
.text_is_digits:
 mov eax,NEBOC_API_METHOD_TEXT_IS_DIGITS
 jmp .text_zero_bool
.text_is_alpha_ascii:
 mov eax,NEBOC_API_METHOD_TEXT_IS_ALPHA_ASCII
 jmp .text_zero_bool
.text_is_alnum_ascii:
 mov eax,NEBOC_API_METHOD_TEXT_IS_ALNUM_ASCII
.text_zero_bool:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.text_equals:
 mov eax,NEBOC_API_METHOD_TEXT_EQUALS
 jmp .text_one_bool
.text_equals_ascii_ignore_case:
 mov eax,NEBOC_API_METHOD_TEXT_EQUALS_ASCII_IGNORE_CASE
 jmp .text_one_bool
.text_starts_with:
 mov eax,NEBOC_API_METHOD_TEXT_STARTS_WITH
 jmp .text_one_bool
.text_ends_with:
 mov eax,NEBOC_API_METHOD_TEXT_ENDS_WITH
 jmp .text_one_bool
.text_contains:
 mov eax,NEBOC_API_METHOD_TEXT_CONTAINS
.text_one_bool:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_query_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.text_index_of:
 mov eax,NEBOC_API_METHOD_TEXT_INDEX_OF
 jmp .text_one_option
.text_last_index_of:
 mov eax,NEBOC_API_METHOD_TEXT_LAST_INDEX_OF
.text_one_option:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_query_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_OPTION_INT
 jmp .ok_instance
.text_trim:
 mov eax,NEBOC_API_METHOD_TEXT_TRIM
 jmp .text_zero_transform
.text_trim_start:
 mov eax,NEBOC_API_METHOD_TEXT_TRIM_START
 jmp .text_zero_transform
.text_trim_end:
 mov eax,NEBOC_API_METHOD_TEXT_TRIM_END
 jmp .text_zero_transform
.text_lower:
 mov eax,NEBOC_API_METHOD_TEXT_LOWER
 jmp .text_zero_transform
.text_upper:
 mov eax,NEBOC_API_METHOD_TEXT_UPPER
 jmp .text_zero_transform
.text_normalize_newlines:
 mov eax,NEBOC_API_METHOD_TEXT_NORMALIZE_NEWLINES
 jmp .text_zero_transform
.text_normalize_whitespace:
 mov eax,NEBOC_API_METHOD_TEXT_NORMALIZE_WHITESPACE
.text_zero_transform:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_transform_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 jmp .ok_text_transform
.text_concat:
 mov eax,NEBOC_API_METHOD_TEXT_CONCAT
 jmp .text_one_text_transform
.text_split:
 mov eax,NEBOC_API_METHOD_TEXT_SPLIT
.text_one_text_transform:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_transform_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 cmp rax,NEBOC_API_METHOD_TEXT_SPLIT
 jne .ok_text_transform
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT_SPLIT
 jmp .ok_bounded_instance
.text_join:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_transform_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT_SPLIT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_JOIN
 jmp .ok_text_transform
.text_take_bytes:
 mov eax,NEBOC_API_METHOD_TEXT_TAKE_BYTES
 jmp .text_one_int_transform
.text_drop_bytes:
 mov eax,NEBOC_API_METHOD_TEXT_DROP_BYTES
.text_one_int_transform:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_transform_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 jmp .ok_text_transform
.text_byte_slice:
 mov eax,NEBOC_API_METHOD_TEXT_BYTE_SLICE
 jmp .text_two_transform
.text_replace_once:
 mov eax,NEBOC_API_METHOD_TEXT_REPLACE_ONCE
 jmp .text_two_transform
.text_replace_all:
 mov eax,NEBOC_API_METHOD_TEXT_REPLACE_ALL
 jmp .text_two_transform
.text_pad_start:
 mov eax,NEBOC_API_METHOD_TEXT_PAD_START
 jmp .text_two_transform
.text_pad_end:
 mov eax,NEBOC_API_METHOD_TEXT_PAD_END
.text_two_transform:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],2
 jne .text_transform_arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
.ok_text_transform:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
.ok_bounded_instance:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|NEBOC_API_FLAG_BOUNDED_ALLOCATION
 jmp .ok
.text_parse_int:
 mov eax,NEBOC_API_METHOD_TEXT_PARSE_INT
 mov edx,NEBOC_TYPE_ID_RESULT_INT_TEXT_ERROR
 jmp .text_parse_zero
.text_parse_float:
 mov eax,NEBOC_API_METHOD_TEXT_PARSE_FLOAT
 mov edx,NEBOC_TYPE_ID_RESULT_FLOAT_TEXT_ERROR
 jmp .text_parse_zero
.text_parse_bool:
 mov eax,NEBOC_API_METHOD_TEXT_PARSE_BOOL
 mov edx,NEBOC_TYPE_ID_RESULT_BOOL_TEXT_ERROR
.text_parse_zero:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_parse_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],rdx
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE
 jmp .ok
.text_split_checked:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .text_parse_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_SPLIT_CHECKED
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 jmp .ok_checked_result
.text_replace_all_checked:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],2
 jne .text_parse_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_REPLACE_ALL_CHECKED
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_RESULT_TEXT_TEXT_ERROR
.ok_checked_result:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|NEBOC_API_FLAG_BOUNDED_ALLOCATION
 jmp .ok
.to_text:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_parse_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 mov rax,[r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .to_text_ok
 cmp rax,NEBOC_TYPE_ID_INT
 je .to_text_ok
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .conversion_receiver
.to_text_ok:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TO_TEXT
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|NEBOC_API_FLAG_BOUNDED_ALLOCATION
 jmp .ok
.text_is_nebo_identifier:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_parse_arity
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 jne .receiver_text
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_TEXT_IS_NEBO_IDENTIFIER
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.result_is_ok:
 mov eax,NEBOC_API_METHOD_RESULT_IS_OK
 jmp .result_predicate
.result_is_err:
 mov eax,NEBOC_API_METHOD_RESULT_IS_ERR
.result_predicate:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .text_parse_arity
 mov rdx,[r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rdx,NEBOC_TYPE_ID_RESULT_INT_TEXT_ERROR
 jb .unknown
 cmp rdx,NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 ja .unknown
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.empty:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
 jne .type_required
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_EMPTY
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_STATIC|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jmp .ok
.from_byte:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .from_byte_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
 jne .type_required
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_FROM_BYTE
 jmp .ok_bytes_static
.from_values:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],4
 jne .from_values_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
 jne .type_required
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_FROM_VALUES
.ok_bytes_static:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_STATIC|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jmp .ok
.at:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .arguments
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_AT
 jmp .ok_int_instance
.get:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .arguments
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_GET
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_OPTION_INT
 jmp .ok_instance
.slice:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],2
 jne .slice_range
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .receiver_bytes
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_BYTES_SLICE
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jmp .ok_instance
.is_some:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_OPTION_INT
 jne .unknown
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_OPTION_IS_SOME
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.is_none:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_OPTION_INT
 jne .unknown
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_OPTION_IS_NONE
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.unwrap_or:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .arguments
 mov rax,[r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_ID_OPTION_INT
 je .option_unwrap_or
 cmp rax,NEBOC_TYPE_ID_RESULT_INT_TEXT_ERROR
 je .result_unwrap_int
 cmp rax,NEBOC_TYPE_ID_RESULT_FLOAT_TEXT_ERROR
 je .result_unwrap_float
 cmp rax,NEBOC_TYPE_ID_RESULT_TEXT_TEXT_ERROR
 je .result_unwrap_text
 cmp rax,NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 je .result_unwrap_split
 cmp rax,NEBOC_TYPE_ID_RESULT_BOOL_TEXT_ERROR
 jne .unknown
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_RESULT_UNWRAP_OR
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.result_unwrap_int:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_RESULT_UNWRAP_OR
 jmp .ok_int_instance
.result_unwrap_float:
 mov edx,NEBOC_TYPE_ID_FLOAT
 jmp .result_unwrap_value
.result_unwrap_text:
 mov edx,NEBOC_TYPE_ID_TEXT
 jmp .result_unwrap_value
.result_unwrap_split:
 mov edx,NEBOC_TYPE_ID_TEXT_SPLIT
.result_unwrap_value:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_RESULT_UNWRAP_OR
 mov [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],rdx
 jmp .ok_instance
.option_unwrap_or:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_OPTION_UNWRAP_OR
 jmp .ok_int_instance
.bit_and:
 mov rax,NEBOC_API_METHOD_INT_BIT_AND
 jmp .bit_binary
.bit_or:
 mov rax,NEBOC_API_METHOD_INT_BIT_OR
 jmp .bit_binary
.bit_xor:
 mov rax,NEBOC_API_METHOD_INT_BIT_XOR
.bit_binary:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .bit_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .bit_receiver
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 jmp .ok_int_instance
.bit_not:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .bit_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .bit_receiver
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_BIT_NOT
 jmp .ok_int_instance
.shift_left:
 mov rax,NEBOC_API_METHOD_INT_SHIFT_LEFT
 jmp .bit_position_unary
.shift_right:
 mov rax,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 jmp .bit_position_unary
.test_bit:
 mov rax,NEBOC_API_METHOD_INT_TEST_BIT
.bit_position_unary:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],1
 jne .bit_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .bit_receiver
 mov [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],rax
 cmp rax,NEBOC_API_METHOD_INT_TEST_BIT
 jne .ok_int_instance
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jmp .ok_instance
.with_bit:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],2
 jne .bit_arity
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .bit_receiver
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_WITH_BIT
 jmp .ok_int_instance
.ok_instance:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jmp .ok
.ok_int_instance:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jmp .ok_instance
.ok:
 mov rdi,r12
 call text_char_unicode_e_bytes_api_hash
 xor eax,eax
 jmp .done

.type_reference:
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .type_text
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .type_char
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .type_bytes
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_string]
 mov ecx,n_string_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_rune]
 mov ecx,n_rune_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_codepoint_type]
 mov ecx,n_codepoint_type_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_byte_string]
 mov ecx,n_byte_string_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_buffer]
 mov ecx,n_buffer_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_blob]
 mov ecx,n_blob_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .alias
 jmp .unknown
.type_text:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jmp .type_ok
.type_char:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 jmp .type_ok
.type_bytes:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
.type_ok:
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_TYPE_REFERENCE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jmp .ok
.bytes_literal:
 mov esi,NEBOC_API_DIAG_BYTES_LITERAL_UNAVAILABLE
 jmp .error
.from_byte_arity:
 mov esi,NEBOC_DIAG_FROM_BYTE_ARITY
 jmp .error
.from_values_arity:
 mov esi,NEBOC_DIAG_FROM_VALUES_ARITY
 jmp .error
.slice_range:
 mov esi,NEBOC_DIAG_SLICE_INVALID_RANGE
 jmp .error
.bit_receiver:
 mov esi,NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 jmp .error
.bit_arity:
 mov esi,NEBOC_DIAG_BITWISE_WRONG_ARITY
 jmp .error
.text_query_arguments:
 mov esi,NEBOC_API_DIAG_TEXT_QUERY_ARITY
 jmp .error
.text_transform_arguments:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_ARITY
 jmp .error
.text_parse_arity:
 mov esi,NEBOC_API_DIAG_TEXT_PARSE_ARITY
 jmp .error
.conversion_receiver:
 mov esi,NEBOC_API_DIAG_TEXT_CONVERSION_RECEIVER
 jmp .error
.text_unicode_arity:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_ARITY
 jmp .error
.arguments:
 mov esi,neboc_text_char_unicode_e_bytes_API_DIAG_ARGUMENTS_NOT_ALLOWED
 jmp .error
.receiver_text:
 mov esi,NEBOC_API_DIAG_RECEIVER_MUST_BE_TEXT
 jmp .error
.receiver_char:
 mov esi,NEBOC_API_DIAG_RECEIVER_MUST_BE_CHAR
 jmp .error
.receiver_bytes:
 mov esi,NEBOC_API_DIAG_RECEIVER_MUST_BE_BYTES
 jmp .error
.type_required:
 mov esi,NEBOC_API_DIAG_TYPE_RECEIVER_REQUIRED
 jmp .error
.instance_required:
 mov esi,NEBOC_API_DIAG_INSTANCE_RECEIVER_REQUIRED
 jmp .error
.alias:
 mov esi,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 jmp .error
.deferred:
 mov esi,neboc_text_char_unicode_e_bytes_API_DIAG_DEFERRED_API
 jmp .error
.unknown:
 mov esi,NEBOC_API_DIAG_UNKNOWN
.error:
 mov rdi,r12
 call text_char_unicode_e_bytes_api_error
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
