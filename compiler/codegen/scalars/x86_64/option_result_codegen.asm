; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 public Option/Result x86-64 codegen
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/parser/option_result_vertical_parser.inc"
%include "compiler/semantic/types/option_result_vertical.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/lowering/scalars/option_result_native_lowering.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/scalars/x86_64/option_result_codegen.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal
extern neboc_foundation_float_materialize_literal

section .rodata
prologue_a: db '    push rbp',10,'    mov rbp, rsp',10,'    sub rsp, '
prologue_a_len equ $-prologue_a
newline: db 10
newline_len equ $-newline
epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    xor eax, eax',10,'    ret',10
epilogue_len equ $-epilogue
lea_slot: db '    lea rdi, [rbp - '
lea_slot_len equ $-lea_slot
close_bracket: db ']',10
close_bracket_len equ $-close_bracket
mov_esi: db '    mov esi, '
mov_esi_len equ $-mov_esi
mov_rdx: db '    mov rdx, '
mov_rdx_len equ $-mov_rdx
mov_rax: db '    mov rax, '
mov_rax_len equ $-mov_rax
movq_xmm0_rax: db '    movq xmm0, rax',10
movq_xmm0_rax_len equ $-movq_xmm0_rax
call_store_zero: db '    call neboc_runtime_store_zero_payload',10
call_store_zero_len equ $-call_store_zero
call_store_integer: db '    call neboc_runtime_store_integer',10
call_store_integer_len equ $-call_store_integer
call_store_float: db '    call neboc_runtime_store_float',10
call_store_float_len equ $-call_store_float
call_tag_test: db '    call neboc_runtime_tag_test',10
call_tag_test_len equ $-call_tag_test
call_unwrap_integer: db '    call neboc_runtime_unwrap_integer',10
call_unwrap_integer_len equ $-call_unwrap_integer
call_unwrap_float: db '    call neboc_runtime_unwrap_float',10
call_unwrap_float_len equ $-call_unwrap_float
store_byte: db '    mov [rbp - '
store_byte_len equ $-store_byte
store_float: db '    movsd [rbp - '
store_float_len equ $-store_float
store_byte_tail: db '], al',10
store_byte_tail_len equ $-store_byte_tail
store_dword_tail: db '], eax',10
store_dword_tail_len equ $-store_dword_tail
store_qword_tail: db '], rax',10
store_qword_tail_len equ $-store_qword_tail
store_float_tail: db '], xmm0',10
store_float_tail_len equ $-store_float_tail

section .text

g06c_append:
 mov rdi,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 jmp neboc_assembly_writer_append_bytes

g06c_token_ptr:
 mov rax,rsi
 cmp rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_TOKENS_OFFSET]
 ret
.bad: xor eax,eax
 ret

g06c_operation_ptr:
 mov rax,rsi
 cmp rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_OPERATION_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rax,[rdi+NEBOC_CODEGEN_OPERATIONS_OFFSET]
 ret
.bad: xor eax,eax
 ret

g06c_symbol_ptr:
 mov rax,rsi
 cmp rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SYMBOL_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_VSYM_RECORD_SIZE
 add rax,[rdi+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SYMBOLS_OFFSET]
 ret
.bad: xor eax,eax
 ret

; request*, prefix, prefix_len, value, signed flag -> status
g06c_emit_number_line:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,r15
 test rbx,rbx
 jz .unsigned
 call neboc_assembly_writer_append_i64_decimal
 jmp .number_done
.unsigned:
 call neboc_assembly_writer_append_u64_decimal
.number_done:
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g06c_append
 jmp .done
.writer: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, slot -> emit lea rdi
g06c_emit_slot_address:
 push r12
 sub rsp,16
 mov r12,rdi
 mov [rsp],rsi
 mov rdi,r12
 lea rsi,[rel lea_slot]
 mov edx,lea_slot_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel close_bracket]
 mov edx,close_bracket_len
 call g06c_append
 jmp .done
.writer:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,16
 pop r12
 ret

; request*, token index -> RAX bits, EDX status
g06c_materialize_float:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,r13
 call g06c_token_ptr
 test rax,rax
 jz .bad
 mov rbx,rax
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_REQUEST_OFFSET]
 test rdi,rdi
 jz .bad
 mov rcx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SOURCE_OFFSET]
 add rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_REQUEST_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rax
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_BITS_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .bad
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_BITS_OFFSET]
 mov rax,[rax]
 xor edx,edx
 jmp .done
.bad:
 xor eax,eax
 mov edx,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 pop rbx
 ret

; request*, output symbol*, scalar type -> status; value already in RAX/XMM0
g06c_store_scalar:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 cmp r14,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 jne .integer_prefix
 lea rsi,[rel store_float]
 mov edx,store_float_len
 jmp .append_prefix
.integer_prefix:
 lea rsi,[rel store_byte]
 mov edx,store_byte_len
.append_prefix:
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,[r13+NEBOC_VSYM_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 cmp r14,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 je .byte
 cmp r14,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
 je .dword
 cmp r14,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 je .float
 lea rsi,[rel store_qword_tail]
 mov edx,store_qword_tail_len
 jmp .tail
.byte: lea rsi,[rel store_byte_tail]
 mov edx,store_byte_tail_len
 jmp .tail
.dword: lea rsi,[rel store_dword_tail]
 mov edx,store_dword_tail_len
 jmp .tail
.float: lea rsi,[rel store_float_tail]
 mov edx,store_float_tail_len
.tail:
 mov rdi,r12
 call g06c_append
 jmp .done
.writer: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, operation* -> status
g06c_emit_operation:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_RESOLVED_OUTPUT_OFFSET]
 call g06c_symbol_ptr
 test rax,rax
 jz .bad_symbol
 mov r14,rax
 cmp qword [r13+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 jne .observer
 mov rdi,r12
 mov rsi,[r14+NEBOC_VSYM_SLOT_OFFSET]
 call g06c_emit_slot_address
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_esi]
 mov edx,mov_esi_len
 mov rcx,[r13+NEBOC_VOP_TAG_VALUE_OFFSET]
 xor r8d,r8d
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_VOP_RUNTIME_HELPER_OFFSET]
 cmp rax,NEBOC_NATIVE_HELPER_STORE_ZERO_PAYLOAD
 je .call_zero
 cmp rax,NEBOC_NATIVE_HELPER_STORE_INTEGER
 je .construct_integer
 cmp rax,NEBOC_NATIVE_HELPER_STORE_FLOAT
 je .construct_float
 jmp .bad_operation
.construct_integer:
 mov rdi,r12
 lea rsi,[rel mov_rdx]
 mov edx,mov_rdx_len
 mov rcx,[r13+NEBOC_VOP_VALUE_DATA_OFFSET]
 mov r8d,0
 cmp qword [r13+NEBOC_VOP_VALUE_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 jne .emit_integer_payload
 mov r8d,1
.emit_integer_payload:
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_store_integer]
 mov edx,call_store_integer_len
 call g06c_append
 jmp .done
.construct_float:
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_VALUE_TOKEN_OFFSET]
 call g06c_materialize_float
 test edx,edx
 jnz .float_error
 mov [rsp],rax
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 mov rcx,[rsp]
 xor r8d,r8d
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel movq_xmm0_rax]
 mov edx,movq_xmm0_rax_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_store_float]
 mov edx,call_store_float_len
 call g06c_append
 jmp .done
.call_zero:
 mov rdi,r12
 lea rsi,[rel call_store_zero]
 mov edx,call_store_zero_len
 call g06c_append
 jmp .done
.observer:
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_RESOLVED_RECEIVER_OFFSET]
 call g06c_symbol_ptr
 test rax,rax
 jz .bad_symbol
 mov r15,rax
 mov rdi,r12
 mov rsi,[r15+NEBOC_VSYM_SLOT_OFFSET]
 call g06c_emit_slot_address
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_esi]
 mov edx,mov_esi_len
 mov rcx,[r13+NEBOC_VOP_TAG_VALUE_OFFSET]
 cmp qword [r13+NEBOC_VOP_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_TAG_TEST
 je .predicate_tag
 mov rcx,[r13+NEBOC_VOP_SUCCESS_TAG_OFFSET]
.predicate_tag:
 xor r8d,r8d
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_VOP_RUNTIME_HELPER_OFFSET]
 cmp rax,NEBOC_NATIVE_HELPER_TAG_TEST
 je .predicate
 cmp rax,NEBOC_NATIVE_HELPER_UNWRAP_INTEGER
 je .unwrap_integer
 cmp rax,NEBOC_NATIVE_HELPER_UNWRAP_FLOAT
 je .unwrap_float
 jmp .bad_operation
.predicate:
 mov rdi,r12
 lea rsi,[rel call_tag_test]
 mov edx,call_tag_test_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 mov edx,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 call g06c_store_scalar
 jmp .done
.unwrap_integer:
 mov rdi,r12
 lea rsi,[rel mov_rdx]
 mov edx,mov_rdx_len
 mov rcx,[r13+NEBOC_VOP_VALUE_DATA_OFFSET]
 xor r8d,r8d
 cmp qword [r13+NEBOC_VOP_VALUE_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 jne .emit_fallback_integer
 mov r8d,1
.emit_fallback_integer:
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_unwrap_integer]
 mov edx,call_unwrap_integer_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 mov rdx,[r13+NEBOC_VOP_RESULT_TYPE_OFFSET]
 call g06c_store_scalar
 jmp .done
.unwrap_float:
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_VALUE_TOKEN_OFFSET]
 call g06c_materialize_float
 test edx,edx
 jnz .float_error
 mov [rsp],rax
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 mov rcx,[rsp]
 xor r8d,r8d
 call g06c_emit_number_line
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel movq_xmm0_rax]
 mov edx,movq_xmm0_rax_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_unwrap_float]
 mov edx,call_unwrap_float_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 mov edx,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 call g06c_store_scalar
 jmp .done
.float_error:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],NEBOC_CODEGEN_ERROR_FLOAT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_symbol:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.bad_operation:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],NEBOC_CODEGEN_ERROR_OPERATION
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_option_result_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 test rax,rax
 jz .invalid
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_CODEGEN_ERROR_OPERATION_OFFSET],0
 mov qword [r12+NEBOC_CODEGEN_OPERATION_EMITTED_OFFSET],0
 mov rdi,r12
 lea rsi,[rel prologue_a]
 mov edx,prologue_a_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FRAME_SIZE_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g06c_append
 test eax,eax
 jnz .done
 xor r13d,r13d
.loop:
 cmp r13,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_OPERATION_COUNT_OFFSET]
 jae .finish
 mov rdi,r12
 mov rsi,r13
 call g06c_operation_ptr
 test rax,rax
 jz .invalid_operation
 mov r14,rax
 mov [r12+NEBOC_CODEGEN_ERROR_OPERATION_OFFSET],r13
 mov rdi,r12
 mov rsi,r14
 call g06c_emit_operation
 test eax,eax
 jnz .done
 inc qword [r12+NEBOC_CODEGEN_OPERATION_EMITTED_OFFSET]
 inc r13
 jmp .loop
.finish:
 mov rdi,r12
 lea rsi,[rel epilogue]
 mov edx,epilogue_len
 call g06c_append
 test eax,eax
 jnz .done
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_CODEGEN_OPERATION_EMITTED_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FRAME_SIZE_OFFSET]
 imul rax,rcx
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_HASH_OFFSET_codegen_scalars_x86_64],rax
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_operation:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_ERROR_CODE_OFFSET],NEBOC_CODEGEN_ERROR_OPERATION
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

section .note.GNU-stack noalloc noexec nowrite progbits
