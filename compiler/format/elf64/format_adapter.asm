; Nebo Assembly — MF034 ELF64 textual Format Adapter v0
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_context.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/format/elf64/format_adapter.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"

extern neboc_target_context_validate
extern neboc_arch_backend_validate
extern neboc_assembly_writer_validate
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal

section .rodata
fmt_global_start: db 'global _start',10
fmt_global_start_len equ $-fmt_global_start
fmt_extern_start: db 'extern nebo_runtime_start',10
fmt_extern_start_len equ $-fmt_extern_start
fmt_text_start: db 10,'section .text',10,'_start:',10,'    lea rdi, [rel nebo_fn_'
fmt_text_start_len equ $-fmt_text_start
fmt_start_tail: db ']',10,'    call nebo_runtime_start',10,'    ud2',10
fmt_start_tail_len equ $-fmt_start_tail

section .text

NEBOC_ABI_FUNCTION neboc_format_adapter_init
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
 cmp qword [rbx+NEBOC_FORMAT_ADAPTER_STATE_OFFSET],NEBOC_FORMAT_ADAPTER_STATE_EMPTY
 jne .state
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne .target
 cmp qword [r12+NEBOC_TARGET_CONTEXT_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 jne .target
 mov rdi,r13
 call neboc_arch_backend_validate
 test eax,eax
 jnz .backend
 cmp r12,[r13+NEBOC_ARCH_BACKEND_TARGET_CONTEXT_OFFSET]
 jne .backend
 cmp r14,[r13+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 jne .backend
 mov rdi,r14
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .writer
 cmp qword [r14+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .writer
 mov [rbx+NEBOC_FORMAT_ADAPTER_TARGET_OFFSET],r12
 mov [rbx+NEBOC_FORMAT_ADAPTER_BACKEND_OFFSET],r13
 mov [rbx+NEBOC_FORMAT_ADAPTER_WRITER_OFFSET],r14
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_STATE_OFFSET],NEBOC_FORMAT_ADAPTER_STATE_READY
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_MACHINE_OFFSET],NEBOC_FORMAT_MACHINE_X86_64
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_ENTRY_FUNCTION_ID_OFFSET],0
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_SECTION_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_SYMBOL_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_RUNTIME_ABI_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_NONE
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_FLAGS_OFFSET],NEBOC_FORMAT_ADAPTER_REQUIRED_FLAGS
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_RESERVED0_OFFSET],0
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_RESERVED1_OFFSET],0
 xor eax,eax
 jmp .done
.target:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_TARGET_MISMATCH
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jmp .done
.backend:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BACKEND_MISMATCH
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_WRITER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.state:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_format_adapter_validate
 push rbx
 push r12
 push r13
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rax,[rbx+NEBOC_FORMAT_ADAPTER_STATE_OFFSET]
 cmp rax,NEBOC_FORMAT_ADAPTER_STATE_READY
 je .state_ok
 cmp rax,NEBOC_FORMAT_ADAPTER_STATE_PRELUDE_EMITTED
 jne .state
.state_ok:
 cmp qword [rbx+NEBOC_FORMAT_ADAPTER_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 jne .invalid
 cmp qword [rbx+NEBOC_FORMAT_ADAPTER_MACHINE_OFFSET],NEBOC_FORMAT_MACHINE_X86_64
 jne .invalid
 cmp qword [rbx+NEBOC_FORMAT_ADAPTER_FLAGS_OFFSET],NEBOC_FORMAT_ADAPTER_REQUIRED_FLAGS
 jne .invalid
 mov r12,[rbx+NEBOC_FORMAT_ADAPTER_TARGET_OFFSET]
 mov r13,[rbx+NEBOC_FORMAT_ADAPTER_BACKEND_OFFSET]
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 mov rdi,r12
 call neboc_target_context_validate
 test eax,eax
 jnz .invalid
 mov rdi,r13
 call neboc_arch_backend_validate
 test eax,eax
 jnz .invalid
 mov rax,[rbx+NEBOC_FORMAT_ADAPTER_WRITER_OFFSET]
 cmp rax,[r13+NEBOC_ARCH_BACKEND_WRITER_OFFSET]
 jne .invalid
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_NONE
 xor eax,eax
 jmp .done
.state:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

; format_adapter_emit_entry_prelude(adapter*, entry_function_id)
NEBOC_ABI_FUNCTION neboc_format_adapter_emit_entry_prelude
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 cmp qword [rbx+NEBOC_FORMAT_ADAPTER_STATE_OFFSET],NEBOC_FORMAT_ADAPTER_STATE_READY
 jne .state
 mov r13,[rbx+NEBOC_FORMAT_ADAPTER_WRITER_OFFSET]
 mov rdi,r13
 lea rsi,[rel fmt_global_start]
 mov edx,fmt_global_start_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r13
 lea rsi,[rel fmt_extern_start]
 mov edx,fmt_extern_start_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r13
 lea rsi,[rel fmt_text_start]
 mov edx,fmt_text_start_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r13
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r13
 lea rsi,[rel fmt_start_tail]
 mov edx,fmt_start_tail_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov [rbx+NEBOC_FORMAT_ADAPTER_ENTRY_FUNCTION_ID_OFFSET],r12
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_SECTION_COUNT_OFFSET],1
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_SYMBOL_COUNT_OFFSET],3
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_STATE_OFFSET],NEBOC_FORMAT_ADAPTER_STATE_PRELUDE_EMITTED
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_NONE
 xor eax,eax
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_WRITER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.state:
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_STATE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 test rbx,rbx
 jz .invalid_return
 mov qword [rbx+NEBOC_FORMAT_ADAPTER_LAST_ERROR_OFFSET],NEBOC_FORMAT_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
