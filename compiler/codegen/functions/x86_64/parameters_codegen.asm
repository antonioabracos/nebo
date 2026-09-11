; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F02 deterministic scalar projection emitter.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/parameters_parser.inc"
%include "compiler/lowering/functions/parameters_plan.inc"
%include "compiler/codegen/functions/x86_64/parameters_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
seguranca_numerica_conversoes_e_overflow_prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
seguranca_numerica_conversoes_e_overflow_prefix_len equ $-seguranca_numerica_conversoes_e_overflow_prefix
parameters_codegen_suffix: db 10,'    ret',10
suffix_len equ $-parameters_codegen_suffix
callable_prefix: db 10,'section .text',10,'extern nebo_runtime_callable_init',10,'extern nebo_runtime_callable_invoke',10,'extern nebo_runtime_callable_capture',10,'extern nebo_runtime_callable_drop',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    push rbp',10,'    mov rbp, rsp',10,'    sub rsp, 80',10,'    mov rdi, rsp',10,'    mov esi, '
callable_prefix_len equ $-callable_prefix
callable_capture_value: db 10,'    mov rdx, '
callable_capture_value_len equ $-callable_capture_value
callable_capture_borrow: db 10,'    lea rdx, [rel nebo_callable_capture_cell]'
callable_capture_borrow_len equ $-callable_capture_borrow
callable_argument_type: db 10,'    mov ecx, '
callable_argument_type_len equ $-callable_argument_type
callable_argument: db 10,'    call nebo_runtime_callable_init',10,'    mov rdi, rsp',10,'    mov rsi, '
callable_argument_len equ $-callable_argument
callable_invoke: db 10,'    lea rdx, [rel nebo_callable_selected]',10,'    call nebo_runtime_callable_invoke',10,'    mov [rsp+64], rax',10,'    mov rdi, rsp',10,'    call nebo_runtime_callable_drop',10,'    mov rax, [rsp+64]',10,'    leave',10,'    ret',10,'nebo_callable_selected:',10
callable_invoke_len equ $-callable_invoke
callable_body_value: db '    mov rax, rdi',10,'    ret',10
callable_body_value_len equ $-callable_body_value
callable_body_capture: db '    mov rdi, rsi',10,'    jmp nebo_runtime_callable_capture',10
callable_body_capture_len equ $-callable_body_capture
callable_body_sum: db '    push rbx',10,'    mov rbx, rdi',10,'    mov rdi, rsi',10,'    call nebo_runtime_callable_capture',10,'    add rax, rbx',10,'    jo nebo_runtime_trap_overflow',10,'    pop rbx',10,'    ret',10
callable_body_sum_len equ $-callable_body_sum
callable_cell: db 'section .rodata align=8',10,'nebo_callable_capture_cell: dq '
callable_cell_len equ $-callable_cell
callable_end: db 10
callable_end_len equ $-callable_end

%macro PARAM_APPEND 1
 mov rdi,r14
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
%endmacro
%macro PARAM_VALUE 1
 mov rdi,r14
 mov rsi,[r13+%1]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
%endmacro

section .text

seguranca_numerica_conversoes_e_overflow_codegen_hash:
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

NEBOC_ABI_FUNCTION neboc_parameters_codegen_emit_start
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
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_functions_x86_64_native_vertical]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC
 cmp [r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rax,NEBOC_ABI_PROFILE_ID
 cmp [r13+NEBOC_PLAN_PROFILE_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_PLAN_FOUND_OFFSET],1
 jne .source
 mov rdi,r13
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASHED_BYTES
 call seguranca_numerica_conversoes_e_overflow_codegen_hash
 cmp rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASH_OFFSET]
 jne .source
 cmp qword [r13+NEBOC_PLAN_CALLABLE_COUNT_OFFSET],0
 jne .callable
 mov rdi,r14
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_prefix]
 mov edx,seguranca_numerica_conversoes_e_overflow_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+NEBOC_PLAN_OUTPUT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel parameters_codegen_suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.emitted:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASH_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.callable:
 PARAM_APPEND callable_prefix
 PARAM_VALUE NEBOC_PLAN_CAPTURE_MODE_OFFSET
 cmp qword [r13+NEBOC_PLAN_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_BORROW
 je .borrow
 PARAM_APPEND callable_capture_value
 PARAM_VALUE NEBOC_PLAN_CALLABLE_CAPTURE_VALUE_OFFSET
 jmp .typed_argument
.borrow:
 PARAM_APPEND callable_capture_borrow
.typed_argument:
 PARAM_APPEND callable_argument_type
 PARAM_VALUE NEBOC_PLAN_CALLABLE_ARGUMENT_TYPE_OFFSET
 PARAM_APPEND callable_argument
 PARAM_VALUE NEBOC_PLAN_CALLABLE_ARGUMENT_VALUE_OFFSET
 PARAM_APPEND callable_invoke
 cmp qword [r13+NEBOC_PLAN_CALLABLE_BODY_OFFSET],NEBOC_CALLABLE_BODY_VALUE
 je .body_value
 cmp qword [r13+NEBOC_PLAN_CALLABLE_BODY_OFFSET],NEBOC_CALLABLE_BODY_CAPTURE
 je .body_capture
 cmp qword [r13+NEBOC_PLAN_CALLABLE_BODY_OFFSET],NEBOC_CALLABLE_BODY_SUM
 jne .source
 PARAM_APPEND callable_body_sum
 jmp .capture_cell
.body_value:
 PARAM_APPEND callable_body_value
 jmp .capture_cell
.body_capture:
 PARAM_APPEND callable_body_capture
.capture_cell:
 PARAM_APPEND callable_cell
 PARAM_VALUE NEBOC_PLAN_CALLABLE_CAPTURE_VALUE_OFFSET
 PARAM_APPEND callable_end
 jmp .emitted
.source:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
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

section .note.GNU-stack noalloc noexec nowrite progbits
