; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F02 deterministic emitter for authenticated Option plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"
%include "compiler/codegen/scalars/x86_64/option_layout_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
prefix_len equ $-prefix
value_prefix: db '    mov rax, '
value_prefix_len equ $-value_prefix
suffix: db 10,'    ret',10
suffix_len equ $-suffix

effect_prefix: db '    mov rdi, '
effect_prefix_len equ $-effect_prefix
effect_int: db 10,'    sub rsp, 8',10,'    call nebo_runtime_console_publish_int',10,'    add rsp, 8',10
effect_int_len equ $-effect_int
effect_bool: db 10,'    sub rsp, 8',10,'    call nebo_runtime_console_publish_bool',10,'    add rsp, 8',10
effect_bool_len equ $-effect_bool
section .text

NEBOC_ABI_FUNCTION neboc_option_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+NEBOC_OPTION_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_OPTION_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_OPTION_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+NEBOC_OPTION_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+NEBOC_OPTION_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,NEBOC_OPTION_PLAN_MAGIC
 cmp [r13+NEBOC_OPTION_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rax,NEBOC_OPTION_LAYOUT_ID
 cmp [r13+NEBOC_OPTION_PLAN_LAYOUT_ID_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_OPTION_PLAN_FOUND_OFFSET],1
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_OPTION_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+NEBOC_OPTION_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,r14
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 cmp qword [r13+NEBOC_OPTION_PLAN_EFFECT_COUNT_OFFSET],32
 ja .source
 xor ebx,ebx
 lea r15,[r13+NEBOC_OPTION_PLAN_EFFECTS_OFFSET]
.effects:
 cmp rbx,[r13+NEBOC_OPTION_PLAN_EFFECT_COUNT_OFFSET]
 jae .result_value
 mov rdi,r14
 lea rsi,[rel effect_prefix]
 mov edx,effect_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r15+8]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 lea rsi,[rel effect_int]
 mov edx,effect_int_len
 cmp qword [r15],NEBOC_OPTION_TYPE_INT
 je .effect_typed
 lea rsi,[rel effect_bool]
 mov edx,effect_bool_len
 cmp qword [r15],NEBOC_OPTION_TYPE_BOOL
 jne .source
.effect_typed:
 mov rdi,r14
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 add r15,32
 inc rbx
 jmp .effects
.result_value:
 mov rdi,r14
 lea rsi,[rel value_prefix]
 mov edx,value_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+NEBOC_OPTION_PLAN_RESULT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_OPTION_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_OPTION_PLAN_HASH_OFFSET]
 mov [r12+NEBOC_OPTION_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_OPTION_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_OPTION_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_OPTION_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_OPTION_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_result_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+NEBOC_RESULT_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+NEBOC_RESULT_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+NEBOC_RESULT_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,NEBOC_RESULT_PLAN_MAGIC
 cmp [r13+NEBOC_RESULT_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rax,NEBOC_RESULT_LAYOUT_ID
 cmp [r13+NEBOC_RESULT_PLAN_LAYOUT_ID_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_RESULT_PLAN_FOUND_OFFSET],1
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_RESULT_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+NEBOC_RESULT_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,r14
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 cmp qword [r13+NEBOC_RESULT_PLAN_EFFECT_COUNT_OFFSET],32
 ja .source
 cmp qword [r13+NEBOC_RESULT_PLAN_TEXT_USED_OFFSET],4096
 ja .source
 xor ebx,ebx
 lea r15,[r13+NEBOC_RESULT_PLAN_EFFECTS_OFFSET]
.effects:
 cmp rbx,[r13+NEBOC_RESULT_PLAN_EFFECT_COUNT_OFFSET]
 jae .result_value
 cmp qword [r15],NEBOC_RESULT_TYPE_TEXT
 jne .scalar_effect
 mov rdx,[r15+8]
 mov eax,edx
 shr rdx,32
 add rax,rdx
 cmp rax,[r13+NEBOC_RESULT_PLAN_TEXT_USED_OFFSET]
 ja .source
 mov eax,[r15+8]
 lea rsi,[r13+rax+NEBOC_RESULT_PLAN_TEXT_BYTES_OFFSET]
 mov rdi,r14
 mov r8,rbx
 call result_emit_text
 test eax,eax
 jnz .writer
 jmp .next_effect
.scalar_effect:
 mov rdi,r14
 lea rsi,[rel effect_prefix]
 mov edx,effect_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r15+8]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 lea rsi,[rel effect_int]
 mov edx,effect_int_len
 cmp qword [r15],NEBOC_RESULT_TYPE_INT
 je .effect_typed
 lea rsi,[rel effect_bool]
 mov edx,effect_bool_len
 cmp qword [r15],NEBOC_RESULT_TYPE_BOOL
 jne .source
.effect_typed:
 mov rdi,r14
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.next_effect:
 add r15,32
 inc rbx
 jmp .effects
.result_value:
 mov rdi,r14
 lea rsi,[rel value_prefix]
 mov edx,value_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+NEBOC_RESULT_PLAN_OUTPUT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_RESULT_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_RESULT_PLAN_HASH_OFFSET]
 mov [r12+NEBOC_RESULT_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_RESULT_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_RESULT_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret


; Emit one lexer-derived typed Text constant and publish it through the same
; descriptor ABI as the general function backend. No host pointer is emitted.
; rdi=writer,rsi=bytes,rdx=length,r8=ordered effect id.
result_emit_text:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,r8
 xor ebx,ebx
%macro MESSAGE_BYTES 1
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
%endmacro
%macro MESSAGE_NUMBER 1
 mov rdi,r12
 mov rsi,%1
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
%endmacro
 MESSAGE_BYTES message_rodata
 MESSAGE_NUMBER r15
 MESSAGE_BYTES message_data
 test r14,r14
 jz .empty
.loop:
 movzx esi,byte [r13+rbx]
 mov rdi,r12
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 inc rbx
 cmp rbx,r14
 jae .descriptor
 MESSAGE_BYTES message_comma
 jmp .loop
.empty:
 MESSAGE_NUMBER 0
.descriptor:
 MESSAGE_BYTES message_descriptor
 MESSAGE_NUMBER r15
 MESSAGE_BYTES message_pointer
 MESSAGE_NUMBER r15
 MESSAGE_BYTES message_length
 MESSAGE_NUMBER r14
 MESSAGE_BYTES message_attributes
 MESSAGE_NUMBER r15
 MESSAGE_BYTES message_call
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
%unmacro MESSAGE_BYTES 1
%unmacro MESSAGE_NUMBER 1

section .rodata
message_rodata: db 10,'section .rodata',10,'nebo_result_text_'
message_rodata_len equ $-message_rodata
message_data: db '_bytes: db '
message_data_len equ $-message_data
message_comma: db ','
message_comma_len equ $-message_comma
message_descriptor: db 10,'align 8',10,'nebo_result_text_'
message_descriptor_len equ $-message_descriptor
message_pointer: db '_desc: dq nebo_result_text_'
message_pointer_len equ $-message_pointer
message_length: db '_bytes, '
message_length_len equ $-message_length
message_attributes: db 10,'    dd 0',10,'    dw 1',10,'    dw 1',10,'section .text',10,'    lea rdi, [rel nebo_result_text_'
message_attributes_len equ $-message_attributes
message_call: db '_desc]',10,'    sub rsp, 8',10,'    call nebo_runtime_console_publish_text',10,'    add rsp, 8',10
message_call_len equ $-message_call

section .note.GNU-stack noalloc noexec nowrite progbits
