; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF005 public Text/Char/Bytes semantic/API validation
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/behavior/behavior_table.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/lowering/textual/bytes_constructor_lowering.inc"
%include "compiler/lowering/textual/bytes_access_lowering.inc"
%include "compiler/lowering/textual/int_bits_lowering.inc"
%include "compiler/semantic/types/text_char_bytes_vertical.inc"
extern neboc_text_char_bytes_api_contract
extern neboc_intrinsic_table_init
extern neboc_intrinsic_table_declare_v0_1
extern neboc_intrinsic_table_freeze
extern neboc_intrinsic_table_validate_runtime_contracts
extern neboc_intrinsic_resolve
extern neboc_bytes_constructor_lower
extern neboc_bytes_access_lower
extern neboc_int_bits_lower

section .rodata
name_text: db "Text"
name_text_len equ $-name_text
name_char: db "Char"
name_char_len equ $-name_char
name_bytes: db "Bytes"
name_bytes_len equ $-name_bytes
name_byte_length: db "byteLength"
name_byte_length_len equ $-name_byte_length
name_codepoint_count: db "codepointCount"
name_codepoint_count_len equ $-name_codepoint_count
name_grapheme_count: db "graphemeCount"
name_grapheme_count_len equ $-name_grapheme_count
name_normalize_nfc: db "normalizeNfc"
name_normalize_nfc_len equ $-name_normalize_nfc
name_normalize_nfd: db "normalizeNfd"
name_normalize_nfd_len equ $-name_normalize_nfd
name_case_fold: db "caseFold"
name_case_fold_len equ $-name_case_fold
name_slice_codepoints: db "sliceCodepoints"
name_slice_codepoints_len equ $-name_slice_codepoints
name_slice_graphemes: db "sliceGraphemes"
name_slice_graphemes_len equ $-name_slice_graphemes
name_codepoint: db "codepoint"
name_codepoint_len equ $-name_codepoint
name_is_empty_text: db "isEmpty"
name_is_empty_text_len equ $-name_is_empty_text
name_equals_text: db "equals"
name_equals_text_len equ $-name_equals_text
name_equals_ascii_ignore_case: db "equalsAsciiIgnoreCase"
name_equals_ascii_ignore_case_len equ $-name_equals_ascii_ignore_case
name_starts_with_text: db "startsWith"
name_starts_with_text_len equ $-name_starts_with_text
name_ends_with_text: db "endsWith"
name_ends_with_text_len equ $-name_ends_with_text
name_contains_text: db "contains"
name_contains_text_len equ $-name_contains_text
name_index_of: db "indexOf"
name_index_of_len equ $-name_index_of
name_last_index_of: db "lastIndexOf"
name_last_index_of_len equ $-name_last_index_of
name_is_ascii: db "isAscii"
name_is_ascii_len equ $-name_is_ascii
name_is_utf8: db "isUtf8"
name_is_utf8_len equ $-name_is_utf8
name_is_blank: db "isBlank"
name_is_blank_len equ $-name_is_blank
name_is_digits: db "isDigits"
name_is_digits_len equ $-name_is_digits
name_is_alpha_ascii: db "isAlphaAscii"
name_is_alpha_ascii_len equ $-name_is_alpha_ascii
name_is_alnum_ascii: db "isAlnumAscii"
name_is_alnum_ascii_len equ $-name_is_alnum_ascii
name_concat_text: db "concat"
name_concat_text_len equ $-name_concat_text
name_trim: db "trim"
name_trim_len equ $-name_trim
name_trim_start: db "trimStart"
name_trim_start_len equ $-name_trim_start
name_trim_end: db "trimEnd"
name_trim_end_len equ $-name_trim_end
name_lower_text: db "lower"
name_lower_text_len equ $-name_lower_text
name_upper_text: db "upper"
name_upper_text_len equ $-name_upper_text
name_byte_slice_text: db "byteSlice"
name_byte_slice_text_len equ $-name_byte_slice_text
name_take_bytes: db "takeBytes"
name_take_bytes_len equ $-name_take_bytes
name_drop_bytes: db "dropBytes"
name_drop_bytes_len equ $-name_drop_bytes
name_normalize_newlines: db "normalizeNewlines"
name_normalize_newlines_len equ $-name_normalize_newlines
name_normalize_whitespace: db "normalizeWhitespace"
name_normalize_whitespace_len equ $-name_normalize_whitespace
name_replace_once: db "replaceOnce"
name_replace_once_len equ $-name_replace_once
name_replace_all: db "replaceAll"
name_replace_all_len equ $-name_replace_all
name_split_text: db "split"
name_split_text_len equ $-name_split_text
name_join_text: db "join"
name_join_text_len equ $-name_join_text
name_pad_start: db "padStart"
name_pad_start_len equ $-name_pad_start
name_pad_end: db "padEnd"
name_pad_end_len equ $-name_pad_end
name_parse_int_text: db "parseInt"
name_parse_int_text_len equ $-name_parse_int_text
name_parse_float_text: db "parseFloat"
name_parse_float_text_len equ $-name_parse_float_text
name_parse_bool_text: db "parseBool"
name_parse_bool_text_len equ $-name_parse_bool_text
name_split_checked: db "splitChecked"
name_split_checked_len equ $-name_split_checked
name_replace_all_checked: db "replaceAllChecked"
name_replace_all_checked_len equ $-name_replace_all_checked
name_to_text: db "toText"
name_to_text_len equ $-name_to_text
name_is_nebo_identifier: db "isNeboIdentifier"
name_is_nebo_identifier_len equ $-name_is_nebo_identifier
name_is_ok: db "isOk"
name_is_ok_len equ $-name_is_ok
name_is_err: db "isErr"
name_is_err_len equ $-name_is_err
name_empty: db "empty"
name_empty_len equ $-name_empty
name_from_byte: db "fromByte"
name_from_byte_len equ $-name_from_byte
name_from_values: db "fromValues"
name_from_values_len equ $-name_from_values
name_at: db "at"
name_at_len equ $-name_at
name_get: db "get"
name_get_len equ $-name_get
name_slice: db "slice"
name_slice_len equ $-name_slice
name_is_some: db "isSome"
name_is_some_len equ $-name_is_some
name_is_none: db "isNone"
name_is_none_len equ $-name_is_none
name_unwrap_or: db "unwrapOr"
name_unwrap_or_len equ $-name_unwrap_or
name_bit_and: db "bitAnd"
name_bit_and_len equ $-name_bit_and
name_bit_or: db "bitOr"
name_bit_or_len equ $-name_bit_or
name_bit_xor: db "bitXor"
name_bit_xor_len equ $-name_bit_xor
name_bit_not: db "bitNot"
name_bit_not_len equ $-name_bit_not
name_shift_left: db "shiftLeft"
name_shift_left_len equ $-name_shift_left
name_shift_right: db "shiftRight"
name_shift_right_len equ $-name_shift_right
name_test_bit: db "testBit"
name_test_bit_len equ $-name_test_bit
name_with_bit: db "withBit"
name_with_bit_len equ $-name_with_bit
name_console: db "console"
name_console_len equ $-name_console
name_scan: db "scan"
name_scan_len equ $-name_scan
name_color: db "color"
name_color_len equ $-name_color
name_red: db "RED"
name_red_len equ $-name_red

section .text
NEBOC_ABI_FUNCTION neboc_text_char_bytes_vertical_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_TOKEN_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_START_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_END_OFFSET],0
 mov rbx,1
.loop:
 cmp rbx,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .finish
 mov rdi,r13
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rcx,NEBOC_AST_CALL_EXPR
 je .call
 jmp .next
.char:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],1
 inc qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_OPERATION_COUNT_OFFSET]
 jmp .next
.call:
 mov rdi,r12
 mov rsi,rbx
 call g04v_validate_call
 test eax,eax
 jnz .done
.next:
 inc rbx
 jmp .loop
.finish:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_OPERATION_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET]
 imul rax,rcx
 mov [r12+neboc_text_char_unicode_e_bytes_VERTICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
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

; request*, call node id
; Uses the frozen PF002 API contract as the one diagnostic/name authority.
g04v_validate_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,144
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdi,[rsp]
 mov ecx,neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,r12
 mov rsi,rbx
 call g04v_token_ptr
 test rax,rax
 jz .internal
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,rdx
 mov r8,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_OFFSET]
 add r8,rdx
 mov [rsp+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET],r8
 mov [rsp+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET],rcx
 mov [rsp+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET],rdx
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],rax
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov qword [rsp+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g04v_expr_type
 mov [rsp+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],rax
 mov qword [rsp+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 ; Bytes.empty() is the sole static call in this profile.
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g04v_is_bytes_type_ref
 test eax,eax
 jz .invoke
 mov qword [rsp+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
 jmp .invoke
.constructor:
 mov qword [rsp+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],NEBOC_API_OPERATION_TYPE_REFERENCE
 mov qword [rsp+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
.invoke:
 lea rdi,[rsp]
 call neboc_text_char_bytes_api_contract
 test eax,eax
 jz .accepted
 cmp qword [rsp+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET],NEBOC_API_DIAG_UNKNOWN
 jne .error
 ; text_char_unicode_e_bytes and Console are peer domains.  Resolve canonical Console/scan names
 ; against the frozen intrinsic table before treating a textual receiver as an
 ; unknown text_char_unicode_e_bytes API.  The intrinsic table remains the authority for receiver,
 ; arity, effect, return type and runtime contract.
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r13
 call g04v_resolve_intrinsic
 test eax,eax
 jnz .delegated
 ; A declared receiver-first function remains owned by the ordinary resolver,
 ; even when its receiver is Text, Char or Bytes. This prevents the bounded
 ; foundation pass from capturing calls such as 2.soma(3).
 mov rdi,r12
 mov rsi,rbx
 call g04v_is_declared_function_name
 test eax,eax
 jnz .ignored
 ; Unknown foundation APIs are text_char_unicode_e_bytes diagnostics only for a proven textual
 ; receiver. Other known scalar receivers and unresolved receivers remain
 ; owned by the ordinary function resolver/diagnostic pipeline.
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_ID_TEXT
 je .error
 cmp rax,NEBOC_TYPE_ID_CHAR
 je .error
 cmp rax,NEBOC_TYPE_ID_BYTES
 je .error
 jmp .ignored
.error:
 ; A method on a binding-owned identifier has no type in this isolated text_char_unicode_e_bytes
 ; request. bindings_constantes_mutabilidade_e_definite_assignment is authoritative for that receiver and already validated it.
 ; Keep text_char_unicode_e_bytes authoritative for proven Text/Char/Bytes receivers and cli_driver type
 ; constructors, but do not manufacture a textual mismatch from type zero.
 cmp qword [rsp+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 jne .publish_error
 cmp qword [rsp+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],0
 je .ignored
.publish_error:
 mov rdi,r12
 mov rsi,[rsp+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET]
 mov rdx,rbx
 call g04v_set_error
 jmp .done
.accepted:
 ; Type references by themselves are not text_char_unicode_e_bytes operations.
 cmp qword [rsp+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],NEBOC_API_OPERATION_TYPE_REFERENCE
 je .ignored
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_BYTES_FROM_BYTE
 je .validate_constructor
 cmp rax,NEBOC_API_METHOD_BYTES_FROM_VALUES
 jne .accepted_method_ready
.validate_constructor:
 mov rdi,r12
 mov rsi,r13
 call g04v_validate_bytes_constructor
 test eax,eax
 jnz .done
.accepted_method_ready:
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_TEXT_EQUALS
 jb .query_argument_ready
 cmp rax,NEBOC_API_METHOD_TEXT_LAST_INDEX_OF
 ja .query_argument_ready
 mov rdi,r12
 mov rsi,r13
 call g04v_validate_text_argument
 test eax,eax
 jnz .done
.query_argument_ready:
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_TEXT_CONCAT
 jb .transform_argument_ready
 cmp rax,NEBOC_API_METHOD_TEXT_PAD_END
 ja .transform_argument_ready
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_text_transform_arguments
 test eax,eax
 jnz .done
.transform_argument_ready:
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_TEXT_SPLIT_CHECKED
 je .validate_checked_arguments
 cmp rax,NEBOC_API_METHOD_TEXT_REPLACE_ALL_CHECKED
 jne .checked_argument_ready
.validate_checked_arguments:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_text_transform_arguments
 test eax,eax
 jnz .done
.checked_argument_ready:
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_TEXT_SLICE_CODEPOINTS
 je .validate_unicode_slice_arguments
 cmp rax,NEBOC_API_METHOD_TEXT_SLICE_GRAPHEMES
 jne .unicode_slice_arguments_ready
.validate_unicode_slice_arguments:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_text_transform_arguments
 test eax,eax
 jnz .done
.unicode_slice_arguments_ready:
 mov rax,[rsp+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_BYTES_AT
 je .validate_access
 cmp rax,NEBOC_API_METHOD_BYTES_GET
 je .validate_access
 cmp rax,NEBOC_API_METHOD_BYTES_SLICE
 je .validate_access
 cmp rax,NEBOC_API_METHOD_INT_BIT_AND
 je .validate_bitwise
 cmp rax,NEBOC_API_METHOD_INT_BIT_OR
 je .validate_bitwise
 cmp rax,NEBOC_API_METHOD_INT_BIT_XOR
 je .validate_bitwise
 cmp rax,NEBOC_API_METHOD_INT_BIT_NOT
 je .validate_bitwise
 cmp rax,NEBOC_API_METHOD_INT_SHIFT_LEFT
 je .validate_bit_access
 cmp rax,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 je .validate_bit_access
 cmp rax,NEBOC_API_METHOD_INT_TEST_BIT
 je .validate_bit_access
 cmp rax,NEBOC_API_METHOD_INT_WITH_BIT
 jne .accepted_ready
.validate_bit_access:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_bit_access
 test eax,eax
 jnz .done
 jmp .accepted_ready
.validate_bitwise:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_bitwise
 test eax,eax
 jnz .done
 jmp .accepted_ready
.validate_access:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rax
 call g04v_validate_bytes_access
 test eax,eax
 jnz .done
.accepted_ready:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],1
 inc qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_OPERATION_COUNT_OFFSET]
 jmp .ignored
.delegated:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],1
 inc qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_OPERATION_COUNT_OFFSET]
.ignored:
 xor eax,eax
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,144
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; vertical request*, method token index, call node id
; Returns 1 only when the canonical v0.1 intrinsic table resolves the exact
; source name and signature.  No Console contract is duplicated here.
g04v_resolve_intrinsic:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,720
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r14
 call g04v_node_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g04v_expr_type
 mov r15,rax
 mov rax,[rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+712],rax

 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_console]
 mov ecx,name_console_len
 call g04v_token_match
 test eax,eax
 jnz .console
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_scan]
 mov ecx,name_scan_len
 call g04v_token_match
 test eax,eax
 jnz .scan
 jmp .no
.console:
 mov ebx,NEBOC_INTRINSIC_NAME_CONSOLE
 jmp .initialize
.scan:
 mov ebx,NEBOC_INTRINSIC_NAME_SCAN
.initialize:
 lea rdi,[rsp]
 lea rsi,[rsp+NEBOC_INTRINSIC_TABLE_SIZE]
 mov edx,NEBOC_INTRINSIC_COUNT
 call neboc_intrinsic_table_init
 test eax,eax
 jnz .no
 lea rdi,[rsp]
 call neboc_intrinsic_table_declare_v0_1
 test eax,eax
 jnz .no
 lea rdi,[rsp]
 call neboc_intrinsic_table_freeze
 test eax,eax
 jnz .no
 lea rdi,[rsp]
 call neboc_intrinsic_table_validate_runtime_contracts
 test eax,eax
 jnz .no

 lea rdi,[rsp+NEBOC_INTRINSIC_TABLE_SIZE+NEBOC_INTRINSIC_COUNT*NEBOC_INTRINSIC_ENTRY_SIZE]
 mov ecx,NEBOC_INTRINSIC_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rsp+NEBOC_INTRINSIC_TABLE_SIZE+NEBOC_INTRINSIC_COUNT*NEBOC_INTRINSIC_ENTRY_SIZE]
 mov [rax+NEBOC_INTRINSIC_REQUEST_NAME_ID_OFFSET],rbx
 mov [rax+NEBOC_INTRINSIC_REQUEST_RECEIVER_TYPE_OFFSET],r15
 mov rcx,[rsp+712]
 mov [rax+NEBOC_INTRINSIC_REQUEST_POSITIONAL_COUNT_OFFSET],rcx
 cmp rbx,NEBOC_INTRINSIC_NAME_CONSOLE
 jne .resolve
 cmp rcx,1
 jne .resolve
 mov rdi,r12
 mov rsi,r14
 call g04v_is_color_behavior_call
 test eax,eax
 jz .request_again
 lea rax,[rsp+NEBOC_INTRINSIC_TABLE_SIZE+NEBOC_INTRINSIC_COUNT*NEBOC_INTRINSIC_ENTRY_SIZE]
 mov qword [rax+NEBOC_INTRINSIC_REQUEST_POSITIONAL_COUNT_OFFSET],0
 mov qword [rax+NEBOC_INTRINSIC_REQUEST_BEHAVIOR_MASK_OFFSET],NEBOC_BEHAVIOR_MASK_COLOR
 jmp .resolve
.request_again:
 lea rax,[rsp+NEBOC_INTRINSIC_TABLE_SIZE+NEBOC_INTRINSIC_COUNT*NEBOC_INTRINSIC_ENTRY_SIZE]
.resolve:
 lea rdi,[rsp]
 mov rsi,rax
 call neboc_intrinsic_resolve
 test eax,eax
 jnz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,720
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; vertical request*, console call node id -> 1 only for RED.color().  The
; intrinsic table still authorizes the behavior mask on Console; this helper
; only classifies the already-frozen source spelling into that mask.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g04v_is_color_behavior_call:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .no
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r14
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .no
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .no
 mov rdi,r14
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .no
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_color]
 mov ecx,name_color_len
 call g04v_token_match
 test eax,eax
 jz .no
 mov rdi,r14
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel name_red]
 mov ecx,name_red_len
 call g04v_token_match
 test eax,eax
 jz .no
 mov eax,1
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

%undef call
g04v_expr_type:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .unknown
 mov rbx,rax
 mov rax,[rbx+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .wrapper
 cmp rax,NEBOC_AST_BINDING_TERMINAL
 je .wrapper
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .wrapper
 cmp rax,NEBOC_AST_EXPRESSION_STMT
 je .wrapper
 cmp rax,NEBOC_AST_BINDING_STMT
 je .wrapper
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unknown
.wrapper:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g04v_expr_type
 jmp .done
.identifier:
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel name_bytes]
 mov ecx,name_bytes_len
 call g04v_token_match
 test eax,eax
 jnz .bytes
 jmp .unknown
.call:
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_byte_length]
 mov ecx,name_byte_length_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_codepoint_count]
 mov ecx,name_codepoint_count_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_grapheme_count]
 mov ecx,name_grapheme_count_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_normalize_nfc]
 mov ecx,name_normalize_nfc_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_normalize_nfd]
 mov ecx,name_normalize_nfd_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_case_fold]
 mov ecx,name_case_fold_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_slice_codepoints]
 mov ecx,name_slice_codepoints_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_slice_graphemes]
 mov ecx,name_slice_graphemes_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_codepoint]
 mov ecx,name_codepoint_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_empty_text]
 mov ecx,name_is_empty_text_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_equals_text]
 mov ecx,name_equals_text_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_equals_ascii_ignore_case]
 mov ecx,name_equals_ascii_ignore_case_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_starts_with_text]
 mov ecx,name_starts_with_text_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_ends_with_text]
 mov ecx,name_ends_with_text_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_contains_text]
 mov ecx,name_contains_text_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_index_of]
 mov ecx,name_index_of_len
 call g04v_token_match
 test eax,eax
 jnz .option_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_last_index_of]
 mov ecx,name_last_index_of_len
 call g04v_token_match
 test eax,eax
 jnz .option_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_ascii]
 mov ecx,name_is_ascii_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_utf8]
 mov ecx,name_is_utf8_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_blank]
 mov ecx,name_is_blank_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_digits]
 mov ecx,name_is_digits_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_alpha_ascii]
 mov ecx,name_is_alpha_ascii_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_alnum_ascii]
 mov ecx,name_is_alnum_ascii_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_concat_text]
 mov ecx,name_concat_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_trim]
 mov ecx,name_trim_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_trim_start]
 mov ecx,name_trim_start_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_trim_end]
 mov ecx,name_trim_end_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_lower_text]
 mov ecx,name_lower_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_upper_text]
 mov ecx,name_upper_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_byte_slice_text]
 mov ecx,name_byte_slice_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_take_bytes]
 mov ecx,name_take_bytes_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_drop_bytes]
 mov ecx,name_drop_bytes_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_normalize_newlines]
 mov ecx,name_normalize_newlines_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_normalize_whitespace]
 mov ecx,name_normalize_whitespace_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_replace_once]
 mov ecx,name_replace_once_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_replace_all]
 mov ecx,name_replace_all_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_split_text]
 mov ecx,name_split_text_len
 call g04v_token_match
 test eax,eax
 jnz .text_split
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_join_text]
 mov ecx,name_join_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_pad_start]
 mov ecx,name_pad_start_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_pad_end]
 mov ecx,name_pad_end_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_parse_int_text]
 mov ecx,name_parse_int_text_len
 call g04v_token_match
 test eax,eax
 jnz .result_int_text_error
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_parse_float_text]
 mov ecx,name_parse_float_text_len
 call g04v_token_match
 test eax,eax
 jnz .result_float_text_error
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_parse_bool_text]
 mov ecx,name_parse_bool_text_len
 call g04v_token_match
 test eax,eax
 jnz .result_bool_text_error
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_split_checked]
 mov ecx,name_split_checked_len
 call g04v_token_match
 test eax,eax
 jnz .result_text_split_text_error
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_replace_all_checked]
 mov ecx,name_replace_all_checked_len
 call g04v_token_match
 test eax,eax
 jnz .result_text_text_error
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_to_text]
 mov ecx,name_to_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_nebo_identifier]
 mov ecx,name_is_nebo_identifier_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_ok]
 mov ecx,name_is_ok_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_err]
 mov ecx,name_is_err_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_empty]
 mov ecx,name_empty_len
 call g04v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_at]
 mov ecx,name_at_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_get]
 mov ecx,name_get_len
 call g04v_token_match
 test eax,eax
 jnz .option_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_slice]
 mov ecx,name_slice_len
 call g04v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_some]
 mov ecx,name_is_some_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_none]
 mov ecx,name_is_none_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_unwrap_or]
 mov ecx,name_unwrap_or_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bit_and]
 mov ecx,name_bit_and_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bit_or]
 mov ecx,name_bit_or_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bit_xor]
 mov ecx,name_bit_xor_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bit_not]
 mov ecx,name_bit_not_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_shift_left]
 mov ecx,name_shift_left_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_shift_right]
 mov ecx,name_shift_right_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_test_bit]
 mov ecx,name_test_bit_len
 call g04v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_with_bit]
 mov ecx,name_with_bit_len
 call g04v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_from_byte]
 mov ecx,name_from_byte_len
 call g04v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_from_values]
 mov ecx,name_from_values_len
 call g04v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_console]
 mov ecx,name_console_len
 call g04v_token_match
 test eax,eax
 jnz .console_type
 jmp .unknown
.constructor:
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_text]
 mov ecx,name_text_len
 call g04v_token_match
 test eax,eax
 jnz .text
 jmp .unknown
.text: mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.char: mov eax,NEBOC_TYPE_ID_CHAR
 jmp .done
.float: mov eax,NEBOC_TYPE_ID_FLOAT
 jmp .done
.bytes: mov eax,NEBOC_TYPE_ID_BYTES
 jmp .done
.text_split: mov eax,NEBOC_TYPE_ID_TEXT_SPLIT
 jmp .done
.option_int: mov eax,NEBOC_TYPE_ID_OPTION_INT
 jmp .done
.result_int_text_error: mov eax,NEBOC_TYPE_ID_RESULT_INT_TEXT_ERROR
 jmp .done
.result_float_text_error: mov eax,NEBOC_TYPE_ID_RESULT_FLOAT_TEXT_ERROR
 jmp .done
.result_bool_text_error: mov eax,NEBOC_TYPE_ID_RESULT_BOOL_TEXT_ERROR
 jmp .done
.result_text_text_error: mov eax,NEBOC_TYPE_ID_RESULT_TEXT_TEXT_ERROR
 jmp .done
.result_text_split_text_error: mov eax,NEBOC_TYPE_ID_RESULT_TEXT_SPLIT_TEXT_ERROR
 jmp .done
.int: mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.bool: mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.console_type: mov eax,NEBOC_TYPE_ID_CONSOLE
 jmp .done
.unknown: xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret


; request*, call-name token index -> 1 when the Program declares a receiver-first
; function with the same exact UTF-8 identifier. FunctionDecl payload0 is the
; parser-frozen function-name token index. Built-in text_char_unicode_e_bytes names still reach the
; API contract first and therefore retain their canonical diagnostics.
g04v_is_declared_function_name:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 test r14,r14
 jz .no
 mov r15,1
.scan:
 cmp r15,[r14+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .no
 mov rdi,r14
 mov rsi,r15
 call g04v_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .next
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 call g04v_token_equal
 test eax,eax
 jnz .yes
.next:
 inc r15
 jmp .scan
.yes:
 mov eax,1
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

; request*, token index A, token index B -> 1 when both identifier spellings
; are byte-identical in the same source buffer.
g04v_token_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g04v_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call g04v_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 cmp qword [r15+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r15+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[r15+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 test rcx,rcx
 jz .no
 mov rsi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_OFFSET]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_OFFSET]
 add rdi,[r15+NEBOC_TOKEN_START_OFFSET]
 cld
 repe cmpsb
 jne .no
 mov eax,1
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

g04v_is_bytes_type_ref:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel name_bytes]
 mov ecx,name_bytes_len
 call g04v_token_match
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, token index -> token*
g04v_token_ptr:
 cmp rsi,[rdi+neboc_text_char_unicode_e_bytes_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_text_char_unicode_e_bytes_VERTICAL_TOKENS_OFFSET]
 ret
.none: xor eax,eax
 ret

; request*, token index, expected*, expected length -> 1/0
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g04v_token_match:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 call g04v_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_OFFSET]
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

%undef call
g04v_set_error:
 push rbx
 mov rbx,rdx
 mov [rdi+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],rsi
 mov [rdi+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_TOKEN_OFFSET],rbx
 mov rsi,rbx
 call g04v_token_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rdi+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 pop rbx
 ret

; request*, call node id. Query arguments are real Text expressions, never
; arbitrary scalar values accepted merely because the arity happened to fit.
g04v_validate_text_argument:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .query_argument_internal
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .query_argument_internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .query_argument_internal
 mov rdi,r12
 mov rsi,rbx
 call g04v_expr_type
 cmp eax,NEBOC_TYPE_ID_TEXT
 je .query_argument_ok
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .query_argument_internal
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 mov esi,NEBOC_API_DIAG_ARGUMENT_MUST_BE_TEXT
 call g04v_set_error
 jmp .query_argument_done
.query_argument_ok:
 xor eax,eax
 jmp .query_argument_done
.query_argument_internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.query_argument_done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; request*, call node id, G055/G057 method id. The source-facing bounded profile
; accepts literal Text arguments and literal non-negative Int counts only. This
; keeps allocation sizing deterministic and rejects malformed calls before
; code generation can allocate a caller-owned workspace.
g04v_validate_text_transform_arguments:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r15
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 ; Zero-argument transforms were already checked by the API contract.
 cmp r14,NEBOC_API_METHOD_TEXT_TRIM
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_TRIM_START
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_TRIM_END
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_LOWER
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_UPPER
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_NORMALIZE_NEWLINES
 je .ok
 cmp r14,NEBOC_API_METHOD_TEXT_NORMALIZE_WHITESPACE
 je .ok
 test rbx,rbx
 jz .internal
 ; byteSlice/take/drop/pad start with a literal Int. Other transforms start
 ; with Text (concat, replace, split, join).
 cmp r14,NEBOC_API_METHOD_TEXT_BYTE_SLICE
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_TAKE_BYTES
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_DROP_BYTES
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_START
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_END
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_SLICE_CODEPOINTS
 je .first_int
 cmp r14,NEBOC_API_METHOD_TEXT_SLICE_GRAPHEMES
 je .first_int
 jmp .first_text
.first_int:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov [rsp],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .int_error_first
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+8],rax
 jmp .second_select
.first_text:
 mov rdi,r12
 mov rsi,rbx
 call g04v_expr_type
 cmp eax,NEBOC_TYPE_ID_TEXT
 jne .text_error_first
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .first_text_literal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .text_error_first
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .text_error_first
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .text_error_first
.first_text_literal:
 mov [rsp+24],rax
 cmp r14,NEBOC_API_METHOD_TEXT_SPLIT
 je .first_text_nonempty
 cmp r14,NEBOC_API_METHOD_TEXT_REPLACE_ONCE
 je .first_text_nonempty
 cmp r14,NEBOC_API_METHOD_TEXT_REPLACE_ALL
 je .first_text_nonempty
 jmp .second_select
.first_text_nonempty:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call g04v_token_ptr
 test rax,rax
 jz .internal
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 je .empty_error_first
.second_select:
 cmp r14,NEBOC_API_METHOD_TEXT_BYTE_SLICE
 je .second_int
 cmp r14,NEBOC_API_METHOD_TEXT_SLICE_CODEPOINTS
 je .second_int
 cmp r14,NEBOC_API_METHOD_TEXT_SLICE_GRAPHEMES
 je .second_int
 cmp r14,NEBOC_API_METHOD_TEXT_REPLACE_ONCE
 je .second_text
 cmp r14,NEBOC_API_METHOD_TEXT_REPLACE_ALL
 je .second_text
 cmp r14,NEBOC_API_METHOD_TEXT_REPLACE_ALL_CHECKED
 je .second_text
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_START
 je .second_text
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_END
 je .second_text
 jmp .ok
.second_int:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .int_error_second
 cmp r14,NEBOC_API_METHOD_TEXT_BYTE_SLICE
 jne .ok
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp [rsp+8],rax
 ja .bounds_error_second
 jmp .ok
.second_text:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04v_expr_type
 cmp eax,NEBOC_TYPE_ID_TEXT
 jne .text_error_second
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .second_text_literal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .text_error_second
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .text_error_second
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .text_error_second
.second_text_literal:
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_START
 je .second_text_nonempty
 cmp r14,NEBOC_API_METHOD_TEXT_PAD_END
 jne .ok
.second_text_nonempty:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call g04v_token_ptr
 test rax,rax
 jz .internal
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 je .empty_error_second
.ok:
 xor eax,eax
 jmp .done
.text_error_first:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_TEXT_ARGUMENT
 mov r15,rbx
 jmp .argument_error
.int_error_first:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_INT_ARGUMENT
 mov r15,rbx
 jmp .argument_error
.text_error_second:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_TEXT_ARGUMENT
 mov r15,rbx
 jmp .argument_error
.int_error_second:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_INT_ARGUMENT
 mov r15,rbx
 jmp .argument_error
.empty_error_first:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_EMPTY_SEPARATOR
 mov r15,rbx
 jmp .argument_error
.empty_error_second:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_EMPTY_SEPARATOR
 mov r15,rbx
 jmp .argument_error
.bounds_error_second:
 mov esi,NEBOC_API_DIAG_TEXT_TRANSFORM_BOUNDS
 mov r15,rbx
.argument_error:
 mov [rsp+24],rsi
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r15
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rsi,[rsp+24]
 mov rdi,r12
 call g04v_set_error
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, call node id. Validates literal-only byte values and executes the
; bounded lowering contract so public semantic acceptance cannot bypass it.
g04v_validate_bytes_constructor:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 lea rdi,[rsp]
 mov ecx,NEBOC_BYTES_LOWER_QWORDS
 xor eax,eax
 rep stosq
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r14
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+NEBOC_BYTES_LOWER_COUNT_OFFSET],rax
 cmp rax,1
 jne .kind_four
 mov qword [rsp+NEBOC_BYTES_LOWER_KIND_OFFSET],NEBOC_BYTES_LOWER_FROM_BYTE
 jmp .scan
.kind_four:
 mov qword [rsp+NEBOC_BYTES_LOWER_KIND_OFFSET],NEBOC_BYTES_LOWER_FROM_VALUES
.scan:
 xor r15d,r15d
.arg_loop:
 cmp r15,[rsp+NEBOC_BYTES_LOWER_COUNT_OFFSET]
 jae .lower
 test rbx,rbx
 jz .internal
 mov rdi,r14
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .literal
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .negative
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .dynamic
 mov esi,NEBOC_DIAG_CONSTRUCTOR_NON_INT
 jmp .arg_error
.negative:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .non_int
 mov esi,NEBOC_DIAG_BYTE_BELOW_ZERO
 jmp .arg_error
.non_int:
 mov esi,NEBOC_DIAG_CONSTRUCTOR_NON_INT
 jmp .arg_error
.dynamic:
 mov esi,NEBOC_DIAG_CONSTRUCTOR_DYNAMIC
 jmp .arg_error
.literal:
 mov rax,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,255
 ja .above
 mov [rsp+NEBOC_BYTES_LOWER_VALUE0_OFFSET+r15*8],rax
 mov rbx,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .arg_loop
.above:
 mov esi,NEBOC_DIAG_BYTE_ABOVE_255
.arg_error:
 mov rdx,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 call g04v_set_error
 jmp .done
.lower:
 lea rdi,[rsp]
 call neboc_bytes_constructor_lower
 test eax,eax
 jnz .internal
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, Bytes expression node id, out { length, packed bytes }.
; The bounded profile admits only empty, fromByte/fromValues and recursively
; bounded slice expressions, so no allocator or source fingerprint is needed.
g04v_extract_static_bytes:
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
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 mov r15,rax
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_empty]
 mov ecx,name_empty_len
 call g04v_token_match
 test eax,eax
 jnz .ok
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_from_byte]
 mov ecx,name_from_byte_len
 call g04v_token_match
 test eax,eax
 jnz .one
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_from_values]
 mov ecx,name_from_values_len
 call g04v_token_match
 test eax,eax
 jnz .four
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_slice]
 mov ecx,name_slice_len
 call g04v_token_match
 test eax,eax
 jnz .slice
 jmp .bad
.one: mov qword [rsp],1
 jmp .constructor
.four: mov qword [rsp],4
.constructor:
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+8],0
 xor r15d,r15d
.value_loop:
 cmp r15,[rsp]
 jae .values_done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
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
 call g04v_extract_static_bytes
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+16],rcx
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
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
.slice_empty:
 xor eax,eax
.slice_write:
 mov [r14],rdx
 mov [r14+8],rax
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, call node id, method id. Validate literal bounds and execute the
; shared F03 lowering contract. get() deliberately accepts out-of-range and
; lowers it to canonical Option<Int> None.
g04v_validate_bytes_access:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,112
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+80]
 call g04v_extract_static_bytes
 test eax,eax
 jnz .internal
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .first_literal
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .range_error
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .dynamic
 mov esi,NEBOC_DIAG_INDEX_WRONG_TYPE
 jmp .arg_error
.dynamic:
 mov esi,NEBOC_DIAG_INDEX_DYNAMIC
 jmp .arg_error
.range_error:
 cmp r14,NEBOC_API_METHOD_BYTES_SLICE
 je .slice_error_code
 mov esi,NEBOC_DIAG_AT_OUT_OF_BOUNDS
 jmp .arg_error
.slice_error_code:
 mov esi,NEBOC_DIAG_SLICE_INVALID_RANGE
.arg_error:
 mov rdx,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 call g04v_set_error
 jmp .done
.first_literal:
 mov rax,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_BYTES_ACCESS_INDEX_OFFSET],rax
 cmp r14,NEBOC_API_METHOD_BYTES_SLICE
 jne .lower
 mov rbx,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .second_literal
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .dynamic
 jmp .slice_error_code
.second_literal:
 mov rax,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_BYTES_ACCESS_END_OFFSET],rax
.lower:
 mov rax,[rsp+80]
 mov [rsp+NEBOC_BYTES_ACCESS_LENGTH_OFFSET],rax
 mov rax,[rsp+88]
 mov [rsp+NEBOC_BYTES_ACCESS_PACKED_OFFSET],rax
 cmp r14,NEBOC_API_METHOD_BYTES_AT
 je .op_at
 cmp r14,NEBOC_API_METHOD_BYTES_GET
 je .op_get
 mov qword [rsp+NEBOC_BYTES_ACCESS_OPERATION_OFFSET],NEBOC_BYTES_ACCESS_SLICE
 jmp .invoke
.op_at: mov qword [rsp+NEBOC_BYTES_ACCESS_OPERATION_OFFSET],NEBOC_BYTES_ACCESS_AT
 jmp .invoke
.op_get: mov qword [rsp+NEBOC_BYTES_ACCESS_OPERATION_OFFSET],NEBOC_BYTES_ACCESS_GET
.invoke:
 lea rdi,[rsp]
 call neboc_bytes_access_lower
 test eax,eax
 jz .ok
 cmp r14,NEBOC_API_METHOD_BYTES_SLICE
 je .slice_error_code
 mov esi,NEBOC_DIAG_AT_OUT_OF_BOUNDS
 jmp .arg_error
.ok:
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,112
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, Int expression node id, out qword. Supports the bounded literal,
; unary-minus and nested cli_driver bitwise surface and executes the shared lowering.
g04v_eval_static_int:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .literal
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .unary
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_bit_and]
 mov ecx,name_bit_and_len
 call g04v_token_match
 test eax,eax
 jnz .op_and
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_bit_or]
 mov ecx,name_bit_or_len
 call g04v_token_match
 test eax,eax
 jnz .op_or
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_bit_xor]
 mov ecx,name_bit_xor_len
 call g04v_token_match
 test eax,eax
 jnz .op_xor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_bit_not]
 mov ecx,name_bit_not_len
 call g04v_token_match
 test eax,eax
 jnz .op_not
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_shift_left]
 mov ecx,name_shift_left_len
 call g04v_token_match
 test eax,eax
 jnz .op_shift_left
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_shift_right]
 mov ecx,name_shift_right_len
 call g04v_token_match
 test eax,eax
 jnz .op_shift_right
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_with_bit]
 mov ecx,name_with_bit_len
 call g04v_token_match
 test eax,eax
 jnz .op_with_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_at]
 mov ecx,name_at_len
 call g04v_token_match
 test eax,eax
 jnz .op_at
 jmp .bad
.op_and: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_AND
 jmp .receiver
.op_or: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_OR
 jmp .receiver
.op_xor: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_XOR
 jmp .receiver
.op_not: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_NOT
 jmp .receiver
.op_shift_left: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_SHIFT_LEFT
 jmp .receiver
.op_shift_right: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_SHIFT_RIGHT
 jmp .receiver
.op_with_bit: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_WITH_BIT
.receiver:
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+48]
 call g04v_eval_static_int
 test eax,eax
 jnz .done
 mov rax,[rsp+48]
 mov [rsp+NEBOC_INT_BITS_RECEIVER_OFFSET],rax
 cmp qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_NOT
 je .lower
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[rsp+56]
 call g04v_eval_static_int
 test eax,eax
 jnz .done
 mov rax,[rsp+56]
 mov [rsp+NEBOC_INT_BITS_ARGUMENT_OFFSET],rax
 cmp qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_WITH_BIT
 jne .lower
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BOOL_LITERAL
 jne .bad
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_INT_BITS_ENABLED_OFFSET],rax
 jmp .lower
.op_at:
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp+48]
 call g04v_extract_static_bytes
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .bad
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 call g04v_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,[rsp+48]
 jae .bad
 shl rcx,3
 mov rax,[rsp+56]
 shr rax,cl
 and eax,255
 mov [r14],rax
 jmp .ok
.lower:
 lea rdi,[rsp]
 call neboc_int_bits_lower
 test eax,eax
 jnz .done
 mov rax,[rsp+NEBOC_INT_BITS_RESULT_OFFSET]
 mov [r14],rax
 jmp .ok
.unary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,r14
 call g04v_eval_static_int
 test eax,eax
 jnz .done
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .ok
 neg qword [r14]
 jmp .ok
.literal:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [r14],rax
.ok: xor eax,eax
 jmp .done
.bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, bitwise call node id, method id.
g04v_validate_bitwise:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 cmp r14,NEBOC_API_METHOD_INT_BIT_NOT
 je .evaluate
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g04v_expr_type
 cmp rax,NEBOC_TYPE_ID_INT
 je .evaluate
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 mov esi,NEBOC_DIAG_BITWISE_WRONG_ARGUMENT
 call g04v_set_error
 jmp .done
.evaluate:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call g04v_eval_static_int
 test eax,eax
 jnz .internal
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, shift/bit-access call node id, method id. Counts and positions are
; intentionally literal-only in the bounded profile and validated in 0..63.
g04v_validate_bit_access:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rsp+48]
 call g04v_eval_static_int
 test eax,eax
 jnz .internal
 mov rax,[rsp+48]
 mov [rsp+NEBOC_INT_BITS_RECEIVER_OFFSET],rax
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .literal
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .range
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 je .dynamic
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .dynamic
 cmp r14,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 jbe .shift_type
 mov esi,NEBOC_DIAG_POSITION_WRONG_TYPE
 jmp .arg_error
.shift_type:
 mov esi,NEBOC_DIAG_SHIFT_WRONG_TYPE
 jmp .arg_error
.dynamic:
 cmp r14,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 jbe .shift_dynamic
 mov esi,NEBOC_DIAG_POSITION_DYNAMIC
 jmp .arg_error
.shift_dynamic:
 mov esi,NEBOC_DIAG_SHIFT_DYNAMIC
 jmp .arg_error
.range:
 cmp r14,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 jbe .shift_range
 mov esi,NEBOC_DIAG_POSITION_OUT_OF_RANGE
 jmp .arg_error
.shift_range:
 mov esi,NEBOC_DIAG_SHIFT_OUT_OF_RANGE
.arg_error:
 mov rdx,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 call g04v_set_error
 jmp .done
.literal:
 mov rax,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,63
 ja .range
 mov [rsp+NEBOC_INT_BITS_ARGUMENT_OFFSET],rax
 cmp r14,NEBOC_API_METHOD_INT_WITH_BIT
 jne .operation
 mov rbx,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,[r12+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET]
 mov rsi,rbx
 call g04v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BOOL_LITERAL
 jne .enabled_type
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+NEBOC_INT_BITS_ENABLED_OFFSET],rcx
 jmp .operation
.enabled_type:
 mov r13,rax
 mov esi,NEBOC_DIAG_BITWISE_WRONG_ARGUMENT
 jmp .arg_error
.operation:
 cmp r14,NEBOC_API_METHOD_INT_SHIFT_LEFT
 je .op_shift_left
 cmp r14,NEBOC_API_METHOD_INT_SHIFT_RIGHT
 je .op_shift_right
 cmp r14,NEBOC_API_METHOD_INT_TEST_BIT
 je .op_test_bit
 mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_WITH_BIT
 jmp .lower
.op_shift_left: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_SHIFT_LEFT
 jmp .lower
.op_shift_right: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_SHIFT_RIGHT
 jmp .lower
.op_test_bit: mov qword [rsp+NEBOC_INT_BITS_OPERATION_OFFSET],NEBOC_INT_BITS_TEST_BIT
.lower:
 lea rdi,[rsp]
 call neboc_int_bits_lower
 test eax,eax
 jnz .internal
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g04v_node_ptr:
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
