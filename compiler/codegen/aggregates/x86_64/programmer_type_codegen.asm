; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PF005 deterministic bounded aggregate program emitter
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/programmer_type_vertical.inc"
%include "compiler/codegen/aggregates/x86_64/programmer_type_codegen.inc"
extern neboc_assembly_writer_append_bytes
section .rodata
g09c_prefix: db 10,'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    mov rax, '
g09c_prefix_len equ $-g09c_prefix
g09c_suffix: db 10,'    ret',10
g09c_suffix_len equ $-g09c_suffix
g09c_digits: db '0123456789abcdef'
section .data
g09c_value: db '0x0000000000000000'
g09c_value_len equ $-g09c_value
section .text
g09c_append:
 mov rax,[rdi+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_WRITER_OFFSET]
 test rax,rax
 jz .bad
 mov rdi,rax
 jmp neboc_assembly_writer_append_bytes
.bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
g09c_format_hex:
 add rdi,18
 lea rsi,[rel g09c_digits]
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
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_programmer_type_codegen_emit_start
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_VERTICAL_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r13+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],1
 jne .source
 cmp qword [r13+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r13+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FLAGS_OFFSET],neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FLAGS_REQUIRED
 jne .source
 mov rax,[r13+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_OUTPUT_VALUE_OFFSET]
 lea rdi,[rel g09c_value]
 call g09c_format_hex
 mov rdi,r12
 lea rsi,[rel g09c_prefix]
 mov edx,g09c_prefix_len
 call g09c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel g09c_value]
 mov edx,g09c_value_len
 call g09c_append
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel g09c_suffix]
 mov edx,g09c_suffix_len
 call g09c_append
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_HASH_OFFSET]
 mov [r12+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_ERROR_OFFSET],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.source:
 mov qword [r12+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_ERROR_OFFSET],2
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
