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
n_normalize_nfc: db "normalizeNFC"
n_normalize_nfc_len equ $-n_normalize_nfc
n_case_fold: db "caseFold"
n_case_fold_len equ $-n_case_fold
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
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .codepoint
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
 ; Deferred methods.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_grapheme_count]
 mov ecx,n_grapheme_count_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_normalize_nfc]
 mov ecx,n_normalize_nfc_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_case_fold]
 mov ecx,n_case_fold_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel n_concat]
 mov ecx,n_concat_len
 call text_char_unicode_e_bytes_name_equal
 test eax,eax
 jnz .deferred
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
.codepoint:
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .instance_required
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 jne .receiver_char
 mov qword [r12+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_CHAR_CODEPOINT
 jmp .ok_int_instance
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
 cmp qword [r12+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_OPTION_INT
 jne .unknown
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
