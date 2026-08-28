; TEXT-CHAR-UNICODE-E-BYTES-PF004 native representation/runtime prototype — 32 scenarios
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/semantic/types/text_char_bytes_semantic.inc"
%include "compiler/lowering/textual/text_char_bytes_ir_contract.inc"
%include "compiler/lowering/textual/text_char_bytes_native_lowering.inc"
%include "runtime/textual/text-char-bytes/text_char_bytes_runtime.inc"
extern neboc_text_char_bytes_native_lower
extern neboc_runtime_char_literal
extern neboc_runtime_text_byte_length
extern neboc_runtime_text_codepoint_count
extern neboc_runtime_char_codepoint
extern neboc_runtime_bytes_empty
extern neboc_runtime_bytes_byte_length
extern neboc_runtime_empty_bytes_descriptor

section .rodata align=8
text_ascii_data: db 'N','e','b','o'
align 8
text_ascii_desc: dq text_ascii_data,4,0
text_utf8_data: db 'O','l',0xc3,0xa1,' ',0xf0,0x9f,0x98,0x80
align 8
text_utf8_desc: dq text_utf8_data,9,0
text_empty_data: db 0
align 8
text_empty_desc: dq text_empty_data,0,0

section .bss align=16
sem: resb neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_semantic_types
ir: resb neboc_text_char_unicode_e_bytes_IR_REQUEST_SIZE
native: resb neboc_text_char_unicode_e_bytes_NATIVE_REQUEST_SIZE
native2: resb neboc_text_char_unicode_e_bytes_NATIVE_REQUEST_SIZE

section .text
clear_requests:
 lea rdi,[rel sem]
 mov ecx,(neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_semantic_types+neboc_text_char_unicode_e_bytes_IR_REQUEST_SIZE+neboc_text_char_unicode_e_bytes_NATIVE_REQUEST_SIZE*2)/8
 xor eax,eax
 rep stosq
 ret
; edi=operation
prepare_valid:
 push rbx
 mov ebx,edi
 call clear_requests
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],rbx
 mov [rel ir+neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET],rbx
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_SEM_ERROR_NONE
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_IR_ERROR_NONE
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_OFFSET],0
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_RUNTIME_METADATA_OFFSET],0
 mov rax,0x1111111111111111
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rax,0x2222222222222222
 mov [rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET],rax
 cmp ebx,NEBOC_SEM_OPERATION_CHAR_LITERAL
 je .char_literal
 cmp ebx,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 je .text_byte
 cmp ebx,NEBOC_SEM_OPERATION_TEXT_CODEPOINT_COUNT
 je .text_count
 cmp ebx,NEBOC_SEM_OPERATION_CHAR_CODEPOINT
 je .char_cp
 cmp ebx,NEBOC_SEM_OPERATION_BYTES_EMPTY
 je .bytes_empty
 cmp ebx,NEBOC_SEM_OPERATION_BYTES_BYTE_LENGTH
 je .bytes_len
 jmp .done
.char_literal:
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_IMMEDIATE_U32
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_IMMEDIATE_U32
 jmp .done
.text_byte:
 mov eax,NEBOC_SEM_LIR_TEXT_DESCRIPTOR_BYTE_LENGTH
 jmp .text_common
.text_count:
 mov eax,NEBOC_SEM_LIR_UTF8_CODEPOINT_COUNT
.text_common:
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],rax
 mov [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],rax
 jmp .done
.char_cp:
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ZERO_EXTEND_U32_TO_I64
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ZERO_EXTEND_U32_TO_I64
 jmp .done
.bytes_empty:
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_STATIC_EMPTY_BYTES_DESCRIPTOR
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_STATIC_EMPTY_BYTES_DESCRIPTOR
 jmp .done
.bytes_len:
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_BYTES_DESCRIPTOR_LENGTH
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_BYTES_DESCRIPTOR_LENGTH
.done:
 pop rbx
 ret
lower:
 lea rax,[rel sem]
 mov [rel native+neboc_text_char_unicode_e_bytes_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_text_char_unicode_e_bytes_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_TARGET_ID_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native]
 jmp neboc_text_char_bytes_native_lower
fail:
 mov edi,r15d
 mov eax,60
 syscall
ud2
%macro CASE 1
 mov r15d,%1
%endmacro
%macro REQUIRE_Z 0
 jne fail
%endmacro
%macro REQUIRE_NZ 0
 je fail
%endmacro

global _start
_start:
 cld
 CASE 1
 xor edi,edi
 call neboc_text_char_bytes_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 2
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 lea rax,[rel sem]
 mov [rel native+neboc_text_char_unicode_e_bytes_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native+neboc_text_char_unicode_e_bytes_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_TARGET_ID_OFFSET],99
 lea rdi,[rel native]
 call neboc_text_char_bytes_native_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 3
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQUIRE_Z
 CASE 4
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_ERROR_CODE_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 REQUIRE_Z
 CASE 5
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 6
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_RUNTIME_METADATA_OFFSET],1
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 7
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET],0
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 CASE 8
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel ir+neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET],NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z

 CASE 9
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_IMMEDIATE_U32
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RESULT_SIZE_OFFSET],4
 REQUIRE_Z
 CASE 10
 mov edi,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_TEXT_BYTE_LENGTH
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_OPERAND_SIZE_OFFSET],24
 REQUIRE_Z
 CASE 11
 mov edi,NEBOC_SEM_OPERATION_TEXT_CODEPOINT_COUNT
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_UTF8_COUNT_LOOP
 REQUIRE_Z
 CASE 12
 mov edi,NEBOC_SEM_OPERATION_CHAR_CODEPOINT
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_ZERO_EXTEND_U32_TO_I64
 REQUIRE_Z
 CASE 13
 mov edi,NEBOC_SEM_OPERATION_BYTES_EMPTY
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+NEBOC_NATIVE_DESCRIPTOR_FLAGS_OFFSET],NEBOC_NATIVE_BYTES_FLAGS_STATIC_IMMUTABLE_EMPTY
 REQUIRE_Z
 CASE 14
 mov edi,NEBOC_SEM_OPERATION_BYTES_BYTE_LENGTH
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_OPERAND_REPR_OFFSET],NEBOC_NATIVE_REPR_BYTES_DESCRIPTOR_PTR
 REQUIRE_Z
 CASE 15
 mov edi,99
 call prepare_valid
 call lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 REQUIRE_Z
 CASE 16
 mov edi,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 call prepare_valid
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z

 CASE 17
 mov edi,'A'
 call neboc_runtime_char_literal
 cmp eax,'A'
 REQUIRE_Z
 CASE 18
 mov edi,0x1f600
 call neboc_runtime_char_literal
 cmp eax,0x1f600
 REQUIRE_Z
 CASE 19
 mov edi,0x10ffff
 call neboc_runtime_char_codepoint
 cmp eax,0x10ffff
 REQUIRE_Z
 CASE 20
 lea rdi,[rel text_empty_desc]
 call neboc_runtime_text_byte_length
 test rax,rax
 REQUIRE_Z
 CASE 21
 lea rdi,[rel text_utf8_desc]
 call neboc_runtime_text_byte_length
 cmp rax,9
 REQUIRE_Z
 CASE 22
 lea rdi,[rel text_ascii_desc]
 call neboc_runtime_text_codepoint_count
 cmp rax,4
 REQUIRE_Z
 CASE 23
 lea rdi,[rel text_utf8_desc]
 call neboc_runtime_text_codepoint_count
 cmp rax,5
 REQUIRE_Z
 CASE 24
 lea rdi,[rel text_empty_desc]
 call neboc_runtime_text_codepoint_count
 test rax,rax
 REQUIRE_Z
 CASE 25
 call neboc_runtime_bytes_empty
 test rax,rax
 REQUIRE_NZ
 lea rcx,[rel neboc_runtime_empty_bytes_descriptor]
 cmp rax,rcx
 REQUIRE_Z
 mov rbx,rax
 CASE 26
 cmp qword [rbx+NEBO_RUNTIME_BYTES_DESCRIPTOR_LENGTH_OFFSET],0
 REQUIRE_Z
 CASE 27
 cmp dword [rbx+NEBO_RUNTIME_BYTES_DESCRIPTOR_FLAGS_OFFSET],NEBO_RUNTIME_BYTES_FLAGS_EMPTY
 REQUIRE_Z
 cmp word [rbx+NEBO_RUNTIME_BYTES_DESCRIPTOR_ELEMENT_WIDTH_OFFSET],1
 REQUIRE_Z
 cmp word [rbx+NEBO_RUNTIME_BYTES_DESCRIPTOR_LIFETIME_OFFSET],1
 REQUIRE_Z
 CASE 28
 mov rdi,rbx
 call neboc_runtime_bytes_byte_length
 test rax,rax
 REQUIRE_Z
 CASE 29
 mov edi,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 mov rbx,[rel native+neboc_text_char_unicode_e_bytes_NATIVE_HASH_OFFSET]
 mov rax,0xaaaaaaaaaaaaaaaa
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rax,0xbbbbbbbbbbbbbbbb
 mov [rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET],rax
 lea rax,[rel sem]
 mov [rel native2+neboc_text_char_unicode_e_bytes_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rel ir]
 mov [rel native2+neboc_text_char_unicode_e_bytes_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rel native2+neboc_text_char_unicode_e_bytes_NATIVE_TARGET_ID_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rel native2]
 call neboc_text_char_bytes_native_lower
 test eax,eax
 REQUIRE_Z
 cmp rbx,[rel native2+neboc_text_char_unicode_e_bytes_NATIVE_HASH_OFFSET]
 REQUIRE_Z
 CASE 30
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_OPERAND_ABI_CLASS_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_ABI_INTEGER
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RESULT_ABI_CLASS_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_ABI_INTEGER
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_REGISTER_RDI
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RETURN_REGISTER_OFFSET],neboc_text_char_unicode_e_bytes_NATIVE_REGISTER_RAX
 REQUIRE_Z
 CASE 31
 mov edi,NEBOC_SEM_OPERATION_BYTES_EMPTY
 call prepare_valid
 call lower
 test eax,eax
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RESULT_SIZE_OFFSET],24
 REQUIRE_Z
 cmp qword [rel native+neboc_text_char_unicode_e_bytes_NATIVE_RESULT_ALIGNMENT_OFFSET],8
 REQUIRE_Z
 CASE 32
 mov edi,NEBOC_SEM_OPERATION_CHAR_LITERAL
 call prepare_valid
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 call lower
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 REQUIRE_Z
 xor edi,edi
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
