; RF204-G001 token-driven recognizer for the binary foundation extension.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/binary_foundation_parser.inc"

section .rodata
n_from_values: db 'fromValues'
n_from_values_len equ $-n_from_values
n_from_byte: db 'fromByte'
n_from_byte_len equ $-n_from_byte
n_empty: db 'empty'
n_empty_len equ $-n_empty
n_with_capacity: db 'withCapacity'
n_with_capacity_len equ $-n_with_capacity
n_zeroed: db 'zeroed'
n_zeroed_len equ $-n_zeroed
n_from_hex: db 'fromHex'
n_from_hex_len equ $-n_from_hex
n_from_text: db 'fromText'
n_from_text_len equ $-n_from_text
n_is_empty: db 'isEmpty'
n_is_empty_len equ $-n_is_empty
n_find: db 'find'
n_find_len equ $-n_find
n_starts_with: db 'startsWith'
n_starts_with_len equ $-n_starts_with
n_ends_with: db 'endsWith'
n_ends_with_len equ $-n_ends_with
n_reserve: db 'reserve'
n_reserve_len equ $-n_reserve
n_extend: db 'extend'
n_extend_len equ $-n_extend
n_from_bytes: db 'fromBytes'
n_from_bytes_len equ $-n_from_bytes
n_from_buffer: db 'fromBuffer'
n_from_buffer_len equ $-n_from_buffer
n_subslice: db 'subslice'
n_subslice_len equ $-n_subslice
n_copy_to: db 'copyTo'
n_copy_to_len equ $-n_copy_to
n_to_bytes: db 'toBytes'
n_to_bytes_len equ $-n_to_bytes
n_read_u16_le: db 'readU16LE'
n_read_u16_le_len equ $-n_read_u16_le
n_read_u32_be: db 'readU32BE'
n_read_u32_be_len equ $-n_read_u32_be
n_write_u64_le: db 'writeU64LE'
n_write_u64_le_len equ $-n_write_u64_le
n_byte_swap: db 'byteSwap'
n_byte_swap_len equ $-n_byte_swap
n_align_up: db 'alignUp'
n_align_up_len equ $-n_align_up
n_is_aligned: db 'isAligned'
n_is_aligned_len equ $-n_is_aligned
n_equals: db 'equals'
n_equals_len equ $-n_equals
n_compare_lexicographic: db 'compareLexicographic'
n_compare_lexicographic_len equ $-n_compare_lexicographic
n_xor_with: db 'xorWith'
n_xor_with_len equ $-n_xor_with
n_crc32: db 'crc32'
n_crc32_len equ $-n_crc32
n_adler32: db 'adler32'
n_adler32_len equ $-n_adler32
n_constant_time_equals: db 'constantTimeEquals'
n_constant_time_equals_len equ $-n_constant_time_equals
n_receiver_bytes: db 'Bytes'
n_receiver_bytes_len equ $-n_receiver_bytes
n_receiver_text: db 'Text'
n_receiver_text_len equ $-n_receiver_text
n_receiver_buffer: db 'Buffer'
n_receiver_buffer_len equ $-n_receiver_buffer
n_receiver_slice: db 'Slice'
n_receiver_slice_len equ $-n_receiver_slice
n_receiver_memory: db 'memory'
n_receiver_memory_len equ $-n_receiver_memory

section .text

; RAX token ordinal, R12 request -> token pointer or zero.
bf_token_ptr:
 cmp rax,[r12+NEBOC_BF_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_BF_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; Exact shared spellings such as equals/startsWith/endsWith belong to G054
; when the syntactic receiver is a Text literal or exact Text("...") value.
; The early G001 token owner must decline both bounded public receiver forms.
bf_has_text_receiver:
 push rbx
 cmp rax,2
 jb .no
 mov rbx,rax
 dec rax
 call bf_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 mov rax,rbx
 sub rax,2
 call bf_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 je .yes
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .no
 cmp rbx,5
 jb .no
 mov rax,rbx
 sub rax,3
 call bf_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .no
 mov rax,rbx
 sub rax,4
 call bf_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .no
 mov rax,rbx
 sub rax,5
 lea rsi,[rel n_receiver_text]
 mov edx,n_receiver_text_len
 call bf_token_match
 test eax,eax
 jz .no
.yes:
 mov eax,1
 pop rbx
 ret
.no:
 xor eax,eax
 pop rbx
 ret

; RAX token ordinal, RSI spelling, EDX length -> EAX boolean.
bf_token_match:
 push rbx
 push r13
 push r14
 push r15
 mov r13,rax
 mov r14,rsi
 mov r15d,edx
 call bf_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r15
 jne .no
 mov r8,[r12+NEBOC_BF_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; R13 method token, RSI receiver spelling, EDX length -> EAX boolean.
bf_static_receiver_match:
 cmp r13,2
 jb .no
 lea rax,[r13-2]
 jmp bf_token_match
.no:
 xor eax,eax
 ret

; R13 method token, EDI minimum and ESI maximum argument count.  Nested calls
; are skipped structurally so commas inside Bytes.fromValues do not affect an
; enclosing call.  EAX is a status and a failure publishes a stable arity
; diagnostic at the owned method token.
bf_validate_call_arity:
 push rbx
 push r13
 push r14
 push r15
 mov r14d,edi
 mov r15d,esi
 lea rbx,[r13+2]
 mov rax,rbx
 call bf_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .empty
 mov edx,1
 xor ecx,ecx
.scan:
 mov rax,rbx
 call bf_token_ptr
 test rax,rax
 jz .syntax
 mov r8,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r8,NEBOC_TOKEN_LPAREN
 jne .close
 inc rcx
 jmp .next
.close:
 cmp r8,NEBOC_TOKEN_RPAREN
 jne .comma
 test rcx,rcx
 jz .counted
 dec rcx
 jmp .next
.comma:
 cmp r8,NEBOC_TOKEN_COMMA
 jne .next
 test rcx,rcx
 jnz .next
 inc rdx
.next:
 inc rbx
 jmp .scan
.empty:
 xor edx,edx
.counted:
 cmp edx,r14d
 jb .arity
 cmp edx,r15d
 ja .arity
 xor eax,eax
 jmp .done
.arity:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_ARITY
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.syntax:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_SYNTAX
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; R13 is fromValues/fromByte token. Record at most two bounded sequences.
bf_collect_sequence:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,16
 mov r14,r13
 inc r14
 mov rax,r14
 call bf_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .syntax
 inc r14
 xor ebx,ebx                    ; packed little-endian bytes
 xor r15d,r15d                  ; byte count
.value:
 mov rax,r14
 call bf_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .type
 mov rcx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rcx,255
 ja .type
 cmp r15,8
 jae .length
 mov [rsp],rcx
 mov ecx,r15d
 shl ecx,3
 mov rax,[rsp]
 shl rax,cl
 or rbx,rax
 inc r15
 inc r14
 mov rax,r14
 call bf_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .store
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne .syntax
 inc r14
 jmp .value
.store:
 mov rax,[r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET]
 cmp rax,2
 jae .ok
 test rax,rax
 jnz .second
 mov [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],r15
 mov [r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET],rbx
 jmp .count
.second:
 mov [r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET],r15
 mov [r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET],rbx
.count:
 inc qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET]
.ok:
 xor eax,eax
 jmp .done
.type:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_TYPE
 jmp .invalid
.length:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_LENGTH
 jmp .invalid
.syntax:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_SYNTAX
.invalid:
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r14
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Mark operation EDX at token R13.
bf_mark_operation:
 mov eax,1
 mov ecx,edx
 dec ecx
 shl rax,cl
 or [r12+NEBOC_BF_OPERATION_MASK_OFFSET],rax
 mov [r12+NEBOC_BF_LAST_OPERATION_OFFSET],rdx
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov qword [r12+NEBOC_BF_FOUND_OFFSET],1
 ret

NEBOC_ABI_FUNCTION neboc_binary_foundation_parse
 test rdi,rdi
 jz .argument_direct
 test rdi,7
 jnz .argument_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov qword [r12+NEBOC_BF_FOUND_OFFSET],0
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_BF_OPERATION_MASK_OFFSET],0
 mov qword [r12+NEBOC_BF_LAST_OPERATION_OFFSET],0
 mov qword [r12+NEBOC_BF_INTEGER_COUNT_OFFSET],0
 mov qword [r12+NEBOC_BF_TEXT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET],0
 mov qword [r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET],0
 mov qword [r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET],0
 mov qword [r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET],0
 mov qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],0
 mov r15,[r12+NEBOC_BF_TOKEN_COUNT_OFFSET]
 test r15,r15
 jz .ok
 xor r13d,r13d
 xor ebx,ebx                    ; brace depth
 xor r14d,r14d                  ; parenthesis depth
.scan:
 cmp r13,r15
 jae .finish
 mov rax,r13
 call bf_token_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_LBRACE
 jne .close_brace
 inc rbx
 jmp .facts
.close_brace:
 cmp rcx,NEBOC_TOKEN_RBRACE
 jne .open_paren
 test rbx,rbx
 jz .syntax
 dec rbx
 jmp .facts
.open_paren:
 cmp rcx,NEBOC_TOKEN_LPAREN
 jne .close_paren
 inc r14
 jmp .facts
.close_paren:
 cmp rcx,NEBOC_TOKEN_RPAREN
 jne .facts
 test r14,r14
 jz .syntax
 dec r14
.facts:
 ; G123: claim the public infix XOR only after a bounded Bytes left operand
 ; has been authenticated. Semantic analysis still requires the right operand
 ; and equal lengths before any result is published.
 cmp rcx,NEBOC_TOKEN_XOR
 jne .integer_fact
 cmp qword [r12+NEBOC_BF_SEQUENCE_COUNT_OFFSET],0
 je .names
 mov edx,NEBOC_BF_OP_INFIX_XOR
 call bf_mark_operation
 jmp .next
.integer_fact:
 cmp rcx,NEBOC_TOKEN_INTEGER
 jne .text
 mov rdx,[r12+NEBOC_BF_INTEGER_COUNT_OFFSET]
 cmp rdx,NEBOC_BF_MAX_INTEGERS
 jae .capacity
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r12+NEBOC_BF_INTEGER_VALUES_OFFSET+rdx*8],rax
 inc qword [r12+NEBOC_BF_INTEGER_COUNT_OFFSET]
 jmp .names
.text:
 cmp rcx,NEBOC_TOKEN_TEXT
 jne .names
 mov rdx,[r12+NEBOC_BF_TEXT_COUNT_OFFSET]
 cmp rdx,4
 jae .text_counted
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r12+NEBOC_BF_TEXT0_PAYLOAD_OFFSET+rdx*8],rax
.text_counted:
 inc qword [r12+NEBOC_BF_TEXT_COUNT_OFFSET]
.names:
 ; Public operations are method-call identifiers only.  A same-spelled local,
 ; comment, text literal, declaration name or longer identifier cannot claim
 ; this owner.
 test r13,r13
 jz .next
 mov rax,r13
 dec rax
 call bf_token_ptr
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 mov rax,r13
 inc rax
 call bf_token_ptr
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .next
 mov rax,r13
 lea rsi,[rel n_from_values]
 mov edx,n_from_values_len
 call bf_token_match
 test eax,eax
 jz .from_byte
 lea rsi,[rel n_receiver_bytes]
 mov edx,n_receiver_bytes_len
 call bf_static_receiver_match
 test eax,eax
 jz .from_byte
 mov edi,1
 mov esi,8
 call bf_validate_call_arity
 test eax,eax
 jnz .next
 call bf_collect_sequence
 test eax,eax
 jnz .done
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BYTES
 jmp .next
.from_byte:
 mov rax,r13
 lea rsi,[rel n_from_byte]
 mov edx,n_from_byte_len
 call bf_token_match
 test eax,eax
 jz .empty
 lea rsi,[rel n_receiver_bytes]
 mov edx,n_receiver_bytes_len
 call bf_static_receiver_match
 test eax,eax
 jz .empty
 mov edi,1
 mov esi,1
 call bf_validate_call_arity
 test eax,eax
 jnz .next
 call bf_collect_sequence
 test eax,eax
 jnz .done
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BYTES
 jmp .next
.empty:
 mov rax,r13
 lea rsi,[rel n_empty]
 mov edx,n_empty_len
 call bf_token_match
 test eax,eax
 jz .with_capacity
 lea rsi,[rel n_receiver_bytes]
 mov edx,n_receiver_bytes_len
 call bf_static_receiver_match
 test eax,eax
 jz .with_capacity
 xor edi,edi
 xor esi,esi
 call bf_validate_call_arity
 test eax,eax
 jnz .next
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BYTES
 jmp .next
.with_capacity:
 mov rax,r13
 lea rsi,[rel n_with_capacity]
 mov edx,n_with_capacity_len
 call bf_token_match
 test eax,eax
 jz .zeroed
 lea rsi,[rel n_receiver_buffer]
 mov edx,n_receiver_buffer_len
 call bf_static_receiver_match
 test eax,eax
 jz .zeroed
 mov edi,1
 mov esi,1
 call bf_validate_call_arity
 test eax,eax
 jnz .next
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BUFFER
 jmp .next
.zeroed:
 mov rax,r13
 lea rsi,[rel n_zeroed]
 mov edx,n_zeroed_len
 call bf_token_match
 test eax,eax
 jz .op_from_hex
 lea rsi,[rel n_receiver_buffer]
 mov edx,n_receiver_buffer_len
 call bf_static_receiver_match
 test eax,eax
 jz .op_from_hex
 mov edi,1
 mov esi,1
 call bf_validate_call_arity
 test eax,eax
 jnz .next
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BUFFER
 jmp .next
%macro BF_OPERATION 6
.%1:
 mov rax,r13
 lea rsi,[rel %2]
 mov edx,%3
 call bf_token_match
 test eax,eax
 jz .%5
%if %4 = NEBOC_BF_OP_IS_EMPTY || %4 = NEBOC_BF_OP_STARTS_WITH || %4 = NEBOC_BF_OP_ENDS_WITH || %4 = NEBOC_BF_OP_EQUALS
 mov rax,r13
 call bf_has_text_receiver
 test eax,eax
 jnz .next
%endif
%if %4 = NEBOC_BF_OP_FROM_HEX || %4 = NEBOC_BF_OP_FROM_TEXT
 lea rsi,[rel n_receiver_bytes]
 mov edx,n_receiver_bytes_len
 call bf_static_receiver_match
 test eax,eax
 jz .%5
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_BYTES
%elif %4 = NEBOC_BF_OP_SLICE_FROM_BYTES || %4 = NEBOC_BF_OP_SLICE_FROM_BUFFER
 lea rsi,[rel n_receiver_slice]
 mov edx,n_receiver_slice_len
 call bf_static_receiver_match
 test eax,eax
 jz .%5
 or qword [r12+NEBOC_BF_TYPE_MASK_OFFSET],NEBOC_BF_TYPE_SLICE
%elif %4 = NEBOC_BF_OP_ALIGN_UP || %4 = NEBOC_BF_OP_IS_ALIGNED
 lea rsi,[rel n_receiver_memory]
 mov edx,n_receiver_memory_len
 call bf_static_receiver_match
 test eax,eax
 jz .%5
%endif
 mov edx,%4
 call bf_mark_operation
 mov edi,%6
 mov esi,%6
 call bf_validate_call_arity
 test eax,eax
 jnz .done
 jmp .next
%endmacro
BF_OPERATION op_from_hex, n_from_hex, n_from_hex_len, NEBOC_BF_OP_FROM_HEX, op_from_text, 1
BF_OPERATION op_from_text, n_from_text, n_from_text_len, NEBOC_BF_OP_FROM_TEXT, op_is_empty, 2
BF_OPERATION op_is_empty, n_is_empty, n_is_empty_len, NEBOC_BF_OP_IS_EMPTY, op_find, 0
BF_OPERATION op_find, n_find, n_find_len, NEBOC_BF_OP_FIND, op_starts_with, 1
BF_OPERATION op_starts_with, n_starts_with, n_starts_with_len, NEBOC_BF_OP_STARTS_WITH, op_ends_with, 1
BF_OPERATION op_ends_with, n_ends_with, n_ends_with_len, NEBOC_BF_OP_ENDS_WITH, op_reserve, 1
BF_OPERATION op_reserve, n_reserve, n_reserve_len, NEBOC_BF_OP_RESERVE, op_extend, 1
BF_OPERATION op_extend, n_extend, n_extend_len, NEBOC_BF_OP_EXTEND, op_from_bytes, 1
BF_OPERATION op_from_bytes, n_from_bytes, n_from_bytes_len, NEBOC_BF_OP_SLICE_FROM_BYTES, op_from_buffer, 1
BF_OPERATION op_from_buffer, n_from_buffer, n_from_buffer_len, NEBOC_BF_OP_SLICE_FROM_BUFFER, op_subslice, 1
BF_OPERATION op_subslice, n_subslice, n_subslice_len, NEBOC_BF_OP_SUBSLICE, op_copy_to, 2
BF_OPERATION op_copy_to, n_copy_to, n_copy_to_len, NEBOC_BF_OP_COPY_TO, op_to_bytes, 1
BF_OPERATION op_to_bytes, n_to_bytes, n_to_bytes_len, NEBOC_BF_OP_TO_BYTES, op_read_u16, 0
BF_OPERATION op_read_u16, n_read_u16_le, n_read_u16_le_len, NEBOC_BF_OP_READ_U16_LE, op_read_u32, 1
BF_OPERATION op_read_u32, n_read_u32_be, n_read_u32_be_len, NEBOC_BF_OP_READ_U32_BE, op_write_u64, 1
BF_OPERATION op_write_u64, n_write_u64_le, n_write_u64_le_len, NEBOC_BF_OP_WRITE_U64_LE, op_byte_swap, 2
BF_OPERATION op_byte_swap, n_byte_swap, n_byte_swap_len, NEBOC_BF_OP_BYTE_SWAP, op_align_up, 0
BF_OPERATION op_align_up, n_align_up, n_align_up_len, NEBOC_BF_OP_ALIGN_UP, op_is_aligned, 2
BF_OPERATION op_is_aligned, n_is_aligned, n_is_aligned_len, NEBOC_BF_OP_IS_ALIGNED, op_equals, 2
BF_OPERATION op_equals, n_equals, n_equals_len, NEBOC_BF_OP_EQUALS, op_compare, 1
BF_OPERATION op_compare, n_compare_lexicographic, n_compare_lexicographic_len, NEBOC_BF_OP_COMPARE_LEXICOGRAPHIC, op_xor, 1
BF_OPERATION op_xor, n_xor_with, n_xor_with_len, NEBOC_BF_OP_XOR_WITH, op_crc32, 1
BF_OPERATION op_crc32, n_crc32, n_crc32_len, NEBOC_BF_OP_CRC32, op_adler32, 0
BF_OPERATION op_adler32, n_adler32, n_adler32_len, NEBOC_BF_OP_ADLER32, op_constant, 0
.op_constant:
 mov rax,r13
 lea rsi,[rel n_constant_time_equals]
 mov edx,n_constant_time_equals_len
 call bf_token_match
 test eax,eax
 jz .next
 mov edx,NEBOC_BF_OP_CONSTANT_TIME_EQUALS
 call bf_mark_operation
 mov edi,1
 mov esi,1
 call bf_validate_call_arity
 test eax,eax
 jnz .done
.next:
 inc r13
 jmp .scan
.finish:
 test rbx,rbx
 jnz .syntax
 test r14,r14
 jnz .syntax
.ok:
 xor eax,eax
 jmp .done
.syntax:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_SYNTAX
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.capacity:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_CAPACITY
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.internal:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_INTERNAL
 mov [r12+NEBOC_BF_ERROR_TOKEN_OFFSET],r13
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.argument_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
