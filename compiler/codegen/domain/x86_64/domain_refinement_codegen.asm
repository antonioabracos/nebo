; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF005 deterministic PositiveInt program emitter
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/domain/domain_refinement_native_contract.inc"
%include "compiler/semantic/types/domain_refinement_vertical.inc"
%include "compiler/codegen/domain/x86_64/domain_refinement_codegen.inc"
extern neboc_assembly_writer_append_bytes

section .rodata
tipos_semanticos_refinamentos_unidades_e_opaque_types_prefix: db 10,'section .text',10,'global nebo_positive_int_try',10,'nebo_positive_int_try:',10,'    test rdi, rdi',10,'    jle .err',10,'    xor eax, eax',10,'    mov rdx, rdi',10,'    ret',10,'.err:',10,'    mov eax, 1',10,'    mov edx, 1',10,'    ret',10,'global nebo_positive_int_is_ok',10,'nebo_positive_int_is_ok:',10,'    test rdi, rdi',10,'    sete al',10,'    movzx eax, al',10,'    ret',10,'global nebo_positive_int_is_err',10,'nebo_positive_int_is_err:',10,'    test rdi, rdi',10,'    setne al',10,'    movzx eax, al',10,'    ret',10,'global nebo_positive_int_unwrap_or',10,'nebo_positive_int_unwrap_or:',10,'    test rdi, rdi',10,'    cmovz rdx, rsi',10,'    mov rax, rdx',10,'    ret',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    mov rdi, '
tipos_semanticos_refinamentos_unidades_e_opaque_types_prefix_len equ $-tipos_semanticos_refinamentos_unidades_e_opaque_types_prefix
after_receiver: db 10,'    call nebo_positive_int_try',10
after_receiver_len equ $-after_receiver
unwrap_prefix: db '    mov rdi, rax',10,'    mov rsi, rdx',10,'    mov rdx, '
unwrap_prefix_len equ $-unwrap_prefix
unwrap_suffix: db 10,'    call nebo_positive_int_unwrap_or',10,'    ret',10
unwrap_suffix_len equ $-unwrap_suffix
is_ok_suffix: db '    mov rdi, rax',10,'    call nebo_positive_int_is_ok',10,'    ret',10
is_ok_suffix_len equ $-is_ok_suffix
is_err_suffix: db '    mov rdi, rax',10,'    call nebo_positive_int_is_err',10,'    ret',10
is_err_suffix_len equ $-is_err_suffix
tipos_semanticos_refinamentos_unidades_e_opaque_types_hex_digits: db '0123456789abcdef'

section .data
receiver_hex: db '0x0000000000000000'
receiver_hex_len equ $-receiver_hex
fallback_hex: db '0x0000000000000000'
fallback_hex_len equ $-fallback_hex

section .text
g08c_append:
 mov rax,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_WRITER_OFFSET]
 test rax,rax
 jz .bad
 mov rdi,rax
 jmp neboc_assembly_writer_append_bytes
.bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

g08c_format_hex:
 add rdi,18
 lea rsi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_hex_digits]
 mov ecx,16
.loop:
 mov rdx,rax
 and edx,15
 mov dl,[rsi+rdx]
 dec rdi
 mov [rdi],dl
 shr rax,4
 dec ecx
 jnz .loop
 ret

NEBOC_ABI_FUNCTION neboc_domain_refinement_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_VERTICAL_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r13+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],1
 jne .source
 cmp qword [r13+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r13+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_REQUIRED
 jne .source
 mov rax,[r13+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 lea rdi,[rel receiver_hex]
 call g08c_format_hex
 mov rax,[r13+NEBOC_VERTICAL_FALLBACK_VALUE_OFFSET]
 lea rdi,[rel fallback_hex]
 call g08c_format_hex
 mov rdi,r12
 lea rsi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_prefix]
 mov edx,tipos_semanticos_refinamentos_unidades_e_opaque_types_prefix_len
 call g08c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel receiver_hex]
 mov edx,receiver_hex_len
 call g08c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel after_receiver]
 mov edx,after_receiver_len
 call g08c_append
 test eax,eax
 jnz .writer
 mov rax,[r13+NEBOC_VERTICAL_OPERATION_OFFSET]
 cmp rax,NEBOC_NATIVE_OP_UNWRAP_OR
 je .unwrap
 cmp rax,NEBOC_NATIVE_OP_IS_OK
 je .is_ok
 cmp rax,NEBOC_NATIVE_OP_IS_ERR
 je .is_err
 jmp .source
.unwrap:
 mov rdi,r12
 lea rsi,[rel unwrap_prefix]
 mov edx,unwrap_prefix_len
 call g08c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel fallback_hex]
 mov edx,fallback_hex_len
 call g08c_append
 test eax,eax
 jnz .writer
 lea r14,[rel unwrap_suffix]
 mov r15d,unwrap_suffix_len
 jmp .finish
.is_ok:
 lea r14,[rel is_ok_suffix]
 mov r15d,is_ok_suffix_len
 jmp .finish
.is_err:
 lea r14,[rel is_err_suffix]
 mov r15d,is_err_suffix_len
.finish:
 mov rdi,r12
 mov rsi,r14
 mov rdx,r15
 call g08c_append
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_HASH_OFFSET]
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_ERROR_OFFSET],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.source:
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_ERROR_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
