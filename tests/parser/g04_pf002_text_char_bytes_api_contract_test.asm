; TEXT-CHAR-UNICODE-E-BYTES-PF002 Text/Char/Bytes API and diagnostics contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
extern neboc_text_char_bytes_api_contract
extern neboc_host_process_exit

%macro CASE 11
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11
%endmacro
section .rodata
s_byte_length: db "byteLength"
s_codepoint_count: db "codepointCount"
s_codepoint: db "codepoint"
s_empty: db "empty"
s_len: db "len"
s_length: db "length"
s_scalar_unicode: db "scalarUnicode"
s_grapheme_count: db "graphemeCount"
s_decode_utf8: db "decodeUtf8"
s_text: db "Text"
s_char: db "Char"
s_bytes: db "Bytes"
s_string: db "String"
s_rune: db "Rune"
s_byte_string: db "ByteString"
s_unknown: db "mystery"
s_brackets: db "[]"
align 8
; operation,receiver_type,receiver_form,subject,len,args,status,method,result,flags,diag
cases:
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_byte_length,10,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_TEXT_BYTE_LENGTH,NEBOC_TYPE_ID_INT,NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_codepoint_count,14,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_TEXT_CODEPOINT_COUNT,NEBOC_TYPE_ID_INT,NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR,NEBOC_RECEIVER_INSTANCE,s_codepoint,9,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_CHAR_CODEPOINT,NEBOC_TYPE_ID_INT,NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_RECEIVER_TYPE,s_empty,5,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_BYTES_EMPTY,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_API_FLAG_STATIC|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_RECEIVER_INSTANCE,s_byte_length,10,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_BYTES_BYTE_LENGTH,NEBOC_TYPE_ID_INT,NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_text,4,0,NEBOC_STATUS_OK,0,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_API_FLAG_TYPE_REFERENCE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_char,4,0,NEBOC_STATUS_OK,0,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR,NEBOC_API_FLAG_TYPE_REFERENCE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_bytes,5,0,NEBOC_STATUS_OK,0,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_API_FLAG_TYPE_REFERENCE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY,0
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_byte_length,10,1,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ARGUMENTS_NOT_ALLOWED
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR,NEBOC_RECEIVER_INSTANCE,s_byte_length,10,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_RECEIVER_MUST_BE_TEXT
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_codepoint,9,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_RECEIVER_MUST_BE_CHAR
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_TYPE,s_codepoint_count,14,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_INSTANCE_RECEIVER_REQUIRED
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_RECEIVER_INSTANCE,s_empty,5,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_TYPE_RECEIVER_REQUIRED
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_empty,5,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_RECEIVER_MUST_BE_BYTES
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_len,3,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_length,6,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR,NEBOC_RECEIVER_INSTANCE,s_scalar_unicode,13,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_string,6,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_rune,4,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE NEBOC_API_OPERATION_TYPE_REFERENCE,0,0,s_byte_string,10,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_grapheme_count,13,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_DEFERRED_API
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES,NEBOC_RECEIVER_INSTANCE,s_decode_utf8,10,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_text_char_unicode_e_bytes_API_DIAG_DEFERRED_API
 CASE neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT,NEBOC_RECEIVER_INSTANCE,s_unknown,7,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_UNKNOWN
 CASE NEBOC_API_OPERATION_BYTES_LITERAL,0,0,s_brackets,2,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_BYTES_LITERAL_UNAVAILABLE
case_count equ ($-cases)/(11*8)

section .bss align=16
request: resb neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE
first_hash: resq 1
section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],rax
 mov rax,[r14+16]
 mov [rel request+NEBOC_API_RECEIVER_FORM_OFFSET],rax
 mov rax,[r14+24]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r14+32]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET],rax
 mov rax,[r14+40]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],rax
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_SOURCE_ID_OFFSET],404
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET],900
 lea rdi,[rel request]
 call neboc_text_char_bytes_api_contract
 cmp rax,[r14+48]
 jne .fail
 mov rax,[rel request+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,[r14+56]
 jne .fail
 mov rax,[rel request+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET]
 cmp rax,[r14+64]
 jne .fail
 mov rax,[rel request+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET]
 cmp rax,[r14+72]
 jne .fail
 mov rax,[rel request+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+80]
 jne .fail
 cmp qword [r14+48],NEBOC_STATUS_OK
 je .success_span
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_API_ERROR_START_OFFSET],900
 jne .fail
 mov rax,900
 add rax,[r14+32]
 cmp [rel request+neboc_text_char_unicode_e_bytes_API_ERROR_END_OFFSET],rax
 jne .fail
 jmp .next
.success_span:
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_API_ERROR_START_OFFSET],0
 jne .fail
 cmp qword [rel request+neboc_text_char_unicode_e_bytes_API_ERROR_END_OFFSET],0
 jne .fail
.next:
 add r14,88
 inc r13d
 dec r15d
 jnz .loop
 ; Deterministic API hash.
 lea rdi,[rel request]
 mov ecx,neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov qword [rel request+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 lea rax,[rel s_byte_length]
 mov [rel request+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET],10
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_SOURCE_ID_OFFSET],404
 mov qword [rel request+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET],9
 lea rdi,[rel request]
 call neboc_text_char_bytes_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel request+neboc_text_char_unicode_e_bytes_API_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_text_char_bytes_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+neboc_text_char_unicode_e_bytes_API_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_text_char_bytes_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
