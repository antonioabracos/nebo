; Nebo Assembly — MF032 x86-64 Architecture Backend v0
;
; This backend emits deterministic NASM Intel text for the single approved
; x86_64-systemv-elf-linux target. It consumes the frozen TargetContext,
; DataLayout and (when attached) the target-independent Function Lowering Plan.
; ABI lowering, runtime calls, object format packaging and linking remain MF033+.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"

extern neboc_target_context_validate
extern neboc_assembly_writer_validate
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_finalize
extern neboc_function_lowering_table_get_plan
extern neboc_function_lowering_table_get_operation

section .rodata
asm_header: db 'bits 64',10,'default rel',10
asm_header_length equ $-asm_header
asm_text_section: db 10,'section .text',10
asm_text_section_length equ $-asm_text_section
asm_rodata_section: db 10,'section .rodata',10
asm_rodata_section_length equ $-asm_rodata_section
asm_global_function: db 'global nebo_fn_'
asm_global_function_length equ $-asm_global_function
asm_function_label: db 'nebo_fn_'
asm_function_label_length equ $-asm_function_label
asm_int_align: db 'align 8',10
asm_int_align_length equ $-asm_int_align
asm_int_label: db 'nebo_int_'
asm_int_label_length equ $-asm_int_label
asm_int_value: db ': dq '
asm_int_value_length equ $-asm_int_value
asm_text_label: db 'nebo_text_'
asm_text_label_length equ $-asm_text_label
asm_text_value: db ': db '
asm_text_value_length equ $-asm_text_value
asm_text_length_suffix: db '_len equ '
asm_text_length_suffix_length equ $-asm_text_length_suffix
asm_comma_space: db ', '
asm_comma_space_length equ $-asm_comma_space
asm_colon_newline: db ':',10
asm_colon_newline_length equ $-asm_colon_newline
asm_newline: db 10
asm_newline_length equ $-asm_newline
asm_zero: db '0'
asm_zero_length equ $-asm_zero
asm_lowering_comment: db '    ; lowering-op '
asm_lowering_comment_length equ $-asm_lowering_comment
asm_gnu_stack: db 10,'section .note.GNU-stack noalloc noexec nowrite progbits',10
asm_gnu_stack_length equ $-asm_gnu_stack

section .text

; arch_backend_init(backend*, target_context*, lowering_table_or_null*, writer*)
NEBOC_ABI_FUNCTION neboc_arch_backend_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid_return
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_EMPTY
 jne .invalid
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 jne .target
 mov r15,[r12+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET]
 test r15,r15
 jz .target
 mov rdi,r14
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .writer
 cmp qword [r14+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .writer
 mov eax,NEBOC_ARCH_BACKEND_BASE_FLAGS
 test r13,r13
 jz .store
 cmp qword [r13+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 jne .lowering
 cmp qword [r13+NEBOC_LOWERING_TABLE_HASH_OFFSET],0
 je .lowering
 mov rdx,[r13+NEBOC_LOWERING_TABLE_FLAGS_OFFSET]
 and rdx,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 cmp rdx,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 jne .lowering
 or eax,NEBOC_ARCH_BACKEND_FLAG_LOWERING_ATTACHED
.store:
 mov [rbx+NEBOC_ARCH_BACKEND_TARGET_CONTEXT_OFFSET],r12
 mov [rbx+NEBOC_ARCH_BACKEND_DATA_LAYOUT_OFFSET],r15
 mov [rbx+NEBOC_ARCH_BACKEND_LOWERING_TABLE_OFFSET],r13
 mov [rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET],r14
 mov qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_READY
 mov qword [rbx+NEBOC_ARCH_BACKEND_MODULE_ID_OFFSET],0
 mov qword [rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET],0
 mov qword [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],NEBOC_ARCH_BACKEND_SECTION_NONE
 mov qword [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_ARCH_BACKEND_UNRESOLVED_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 mov qword [rbx+NEBOC_ARCH_BACKEND_OUTPUT_HASH_OFFSET],0
 mov [rbx+NEBOC_ARCH_BACKEND_FLAGS_OFFSET],rax
 xor eax,eax
 jmp .done
.target:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.lowering:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_LOWERING_NOT_FROZEN
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_validate(backend*)
NEBOC_ABI_FUNCTION neboc_arch_backend_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rax,[rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET]
 cmp rax,NEBOC_ARCH_BACKEND_STATE_READY
 je .state_ok
 cmp rax,NEBOC_ARCH_BACKEND_STATE_MODULE
 je .state_ok
 cmp rax,NEBOC_ARCH_BACKEND_STATE_FROZEN
 je .state_ok
 jmp .state
.state_ok:
 mov r12,[rbx+NEBOC_ARCH_BACKEND_TARGET_CONTEXT_OFFSET]
 mov r13,[rbx+NEBOC_ARCH_BACKEND_DATA_LAYOUT_OFFSET]
 mov r14,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 cmp r13,[r12+NEBOC_TARGET_CONTEXT_DATA_LAYOUT_PTR_OFFSET]
 jne .target
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 mov rdi,r14
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .writer
 mov r15,[rbx+NEBOC_ARCH_BACKEND_LOWERING_TABLE_OFFSET]
 test r15,r15
 jz .flags
 cmp qword [r15+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 jne .lowering
 cmp qword [r15+NEBOC_LOWERING_TABLE_HASH_OFFSET],0
 je .lowering
.flags:
 mov rax,[rbx+NEBOC_ARCH_BACKEND_FLAGS_OFFSET]
 mov rdx,NEBOC_ARCH_BACKEND_BASE_FLAGS
 test r15,r15
 jz .flags_compare
 or rdx,NEBOC_ARCH_BACKEND_FLAG_LOWERING_ATTACHED
.flags_compare:
 cmp rax,rdx
 jne .invalid
 mov rax,[rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET]
 cmp rax,NEBOC_ARCH_BACKEND_STATE_FROZEN
 jne .not_frozen
 cmp qword [r14+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_SEALED
 jne .writer
 mov rax,[r14+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 test rax,rax
 jz .writer
 cmp rax,[rbx+NEBOC_ARCH_BACKEND_OUTPUT_HASH_OFFSET]
 jne .writer
 jmp .ok
.not_frozen:
 cmp qword [r14+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .writer
.ok:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.target:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.writer:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.lowering:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_LOWERING_NOT_FROZEN
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_begin_module(backend*, module_id, unresolved_node_count)
NEBOC_ABI_FUNCTION neboc_arch_backend_begin_module
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_READY
 jne .state
 test r12,r12
 jz .label
 mov [rbx+NEBOC_ARCH_BACKEND_UNRESOLVED_COUNT_OFFSET],r13
 test r13,r13
 jnz .unresolved
 mov rdi,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 lea rsi,[rel asm_header]
 mov edx,asm_header_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov [rbx+NEBOC_ARCH_BACKEND_MODULE_ID_OFFSET],r12
 mov qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.unresolved:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_UNRESOLVED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.label:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer_state
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .done
.writer_state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_begin_function(backend*, function_id)
NEBOC_ABI_FUNCTION neboc_arch_backend_begin_function
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .state
 test r12,r12
 jz .label
 mov r15,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 mov r13,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov r14,[rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET]
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rdi,rbx
 mov esi,NEBOC_ARCH_BACKEND_SECTION_TEXT
 call backend_switch_section
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_global_function]
 mov edx,asm_global_function_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_newline]
 mov edx,asm_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_function_label]
 mov edx,asm_function_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_colon_newline]
 mov edx,asm_colon_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET],r12
 inc qword [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 inc qword [r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET]
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],r13
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],r14
 mov rax,[rsp]
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET],rax
 jmp .writer
.label:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer_state
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .done
.writer_state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_emit_int_literal(backend*, literal_id, signed_value)
NEBOC_ABI_FUNCTION neboc_arch_backend_emit_int_literal
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .state
 test r12,r12
 jz .label
 mov r15,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 mov r14,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET]
 mov [rsp+16],rax
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET]
 mov [rsp+24],rax
 mov rdi,rbx
 mov esi,NEBOC_ARCH_BACKEND_SECTION_RODATA
 call backend_switch_section
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_int_align]
 mov edx,asm_int_align_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_int_label]
 mov edx,asm_int_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_int_value]
 mov edx,asm_int_value_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r13
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_newline]
 mov edx,asm_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 inc qword [rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET]
 inc qword [r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET]
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],r14
 mov rax,[rsp]
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET],rax
 mov rax,[rsp+24]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET],rax
 jmp .writer
.label:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer_state
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .done
.writer_state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_emit_text_bytes(backend*, string_id, source_bytes*, byte_length)
NEBOC_ABI_FUNCTION neboc_arch_backend_emit_text_bytes
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .state
 test r12,r12
 jz .label
 cmp r14,NEBOC_ASSEMBLY_WRITER_MAX_TEXT_BYTES
 ja .unsafe
 test r14,r14
 jz .source_ok
 test r13,r13
 jz .unsafe
.source_ok:
 mov r15,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 mov [rsp+16],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET]
 mov [rsp+24],rax
 mov rdi,rbx
 mov esi,NEBOC_ARCH_BACKEND_SECTION_RODATA
 call backend_switch_section
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_text_label]
 mov edx,asm_text_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_text_value]
 mov edx,asm_text_value_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 test r14,r14
 jnz .byte_loop_start
 mov rdi,r15
 lea rsi,[rel asm_zero]
 mov edx,asm_zero_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 jmp .bytes_done
.byte_loop_start:
 mov qword [rsp+32],0
.byte_loop:
 mov r10,[rsp+32]
 test r10,r10
 jz .byte_value
 mov rdi,r15
 lea rsi,[rel asm_comma_space]
 mov edx,asm_comma_space_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
.byte_value:
 mov r10,[rsp+32]
 movzx esi,byte [r13+r10]
 mov rdi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 inc qword [rsp+32]
 mov r10,[rsp+32]
 cmp r10,r14
 jb .byte_loop
.bytes_done:
 mov rdi,r15
 lea rsi,[rel asm_newline]
 mov edx,asm_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_text_label]
 mov edx,asm_text_label_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_text_length_suffix]
 mov edx,asm_text_length_suffix_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r14
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_newline]
 mov edx,asm_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 inc qword [rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET]
 inc qword [r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET]
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],rax
 mov rax,[rsp+16]
 mov [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+24]
 mov [rbx+NEBOC_ARCH_BACKEND_CONSTANT_COUNT_OFFSET],rax
 jmp .writer
.unsafe:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_UNSAFE_TEXT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.label:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer_state
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .done
.writer_state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_emit_plan(backend*, plan_id)
; MF032 emits deterministic function identity and trusted logical-operation
; annotations. Physical ABI lowering and executable instructions remain MF033.
NEBOC_ABI_FUNCTION neboc_arch_backend_emit_plan
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .state
 test r12,r12
 jz .label
 mov r13,[rbx+NEBOC_ARCH_BACKEND_LOWERING_TABLE_OFFSET]
 test r13,r13
 jz .lowering
 mov r15,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET]
 mov [rsp+8],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET]
 mov [rsp+16],rax
 mov rax,[rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET]
 mov [rsp+24],rax
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET]
 mov [rsp+32],rax
 mov qword [rsp+40],0
 mov [rsp+48],r12
 mov qword [rsp+56],0
 mov rdi,r13
 mov rsi,r12
 lea rdx,[rsp+56]
 call neboc_function_lowering_table_get_plan
 test eax,eax
 jnz .lowering
 mov r14,[rsp+56]
 cmp qword [r14+NEBOC_FUNCTION_PLAN_STATE_OFFSET],NEBOC_FUNCTION_PLAN_STATE_FROZEN
 jne .lowering
 cmp qword [r14+NEBOC_FUNCTION_PLAN_HASH_OFFSET],0
 je .lowering
 mov rax,[r14+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET]
 and rax,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 cmp rax,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 jne .lowering
 mov rsi,[r14+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET]
 mov rdi,rbx
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .restore
 mov r12,[r14+NEBOC_FUNCTION_PLAN_FIRST_OPERATION_ID_OFFSET]
 mov r14,[r14+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET]
 test r12,r12
 jz .unsupported
 test r14,r14
 jz .unsupported
.plan_loop:
 mov qword [rsp+56],0
 mov rdi,r13
 mov rsi,r12
 lea rdx,[rsp+56]
 call neboc_function_lowering_table_get_operation
 test eax,eax
 jnz .unsupported
 mov rax,[rsp+56]
 mov rcx,[rax+NEBOC_LOWERING_OPERATION_PLAN_ID_OFFSET]
 cmp rcx,[rsp+48]
 jne .unsupported
 mov rcx,[rax+NEBOC_LOWERING_OPERATION_KIND_OFFSET]
 cmp rcx,NEBOC_LOWERING_OPERATION_LOAD_CONSOLE
 jb .unsupported
 cmp rcx,NEBOC_LOWERING_OPERATION_RETURN
 ja .unsupported
 cmp qword [rax+NEBOC_LOWERING_OPERATION_HASH_OFFSET],0
 je .unsupported
 mov rdi,r15
 lea rsi,[rel asm_lowering_comment]
 mov edx,asm_lowering_comment_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rax,[rsp+56]
 mov rsi,[rax+NEBOC_LOWERING_OPERATION_KIND_OFFSET]
 mov rdi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 lea rsi,[rel asm_newline]
 mov edx,asm_newline_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc r12
 dec r14
 jnz .plan_loop
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_UNSUPPORTED_LOWERING_OPERATION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .restore_status
.lowering:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_LOWERING_NOT_FROZEN
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.label:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_INVALID_LABEL_ID
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.restore:
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .restore_writer
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .restore_status
.restore_writer:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
.restore_status:
 mov rdx,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rdx
 mov rdx,[rsp+8]
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],rdx
 mov rdx,[rsp+16]
 mov [rbx+NEBOC_ARCH_BACKEND_CURRENT_FUNCTION_ID_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rbx+NEBOC_ARCH_BACKEND_SYMBOL_COUNT_OFFSET],rdx
 mov rdx,[rsp+32]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LABEL_COUNT_OFFSET],rdx
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; arch_backend_end_module(backend*)
NEBOC_ABI_FUNCTION neboc_arch_backend_end_module
 push rbx
 push r12
 push r13
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 call neboc_arch_backend_validate
 test eax,eax
 jnz .done
 cmp qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_MODULE
 jne .state
 cmp qword [rbx+NEBOC_ARCH_BACKEND_UNRESOLVED_COUNT_OFFSET],0
 jne .unresolved
 mov r12,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 mov r13,[r12+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov rdi,r12
 lea rsi,[rel asm_gnu_stack]
 mov edx,asm_gnu_stack_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r12
 call neboc_assembly_writer_finalize
 test eax,eax
 jnz .writer_finalize
 mov rax,[r12+NEBOC_ASSEMBLY_WRITER_HASH_OFFSET]
 mov [rbx+NEBOC_ARCH_BACKEND_OUTPUT_HASH_OFFSET],rax
 mov qword [rbx+NEBOC_ARCH_BACKEND_STATE_OFFSET],NEBOC_ARCH_BACKEND_STATE_FROZEN
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.unresolved:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_UNRESOLVED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_BAD_MODULE_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 mov [r12+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],r13
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .writer_state
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_LIMIT
 jmp .done
.writer_state:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.writer_finalize:
 mov qword [rbx+NEBOC_ARCH_BACKEND_LAST_ERROR_OFFSET],NEBOC_CODEGEN_ERROR_WRITER_NOT_READY
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

; backend_switch_section(backend*, section_id)
; Local helper; callers snapshot state before invoking it.
backend_switch_section:
 push rbx
 mov rbx,rdi
 cmp rsi,[rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET]
 je .ok
 cmp esi,NEBOC_ARCH_BACKEND_SECTION_TEXT
 je .text
 cmp esi,NEBOC_ARCH_BACKEND_SECTION_RODATA
 je .rodata
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.text:
 mov rdi,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 lea rsi,[rel asm_text_section]
 mov edx,asm_text_section_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov qword [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],NEBOC_ARCH_BACKEND_SECTION_TEXT
 jmp .ok
.rodata:
 mov rdi,[rbx+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 lea rsi,[rel asm_rodata_section]
 mov edx,asm_rodata_section_length
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 mov qword [rbx+NEBOC_ARCH_BACKEND_CURRENT_SECTION_OFFSET],NEBOC_ARCH_BACKEND_SECTION_RODATA
.ok:
 xor eax,eax
.done:
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
