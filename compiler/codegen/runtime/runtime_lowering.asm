; MF034 runtime-call lowering for Console route contracts
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/runtime/runtime_lowering.inc"
extern neboc_abi_adapter_validate
extern neboc_assembly_writer_validate
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
section .rodata
rt_default: db '    call nebo_runtime_thunk_1',10
rt_default_len equ $-rt_default
rt_named_a: db '    lea rdi, [rel nebo_text_'
rt_named_a_len equ $-rt_named_a
rt_named_b: db ']',10,'    call nebo_runtime_thunk_2',10
rt_named_b_len equ $-rt_named_b
rt_scan_b: db ']',10,'    call nebo_runtime_thunk_3',10
rt_scan_b_len equ $-rt_scan_b
section .text
NEBOC_ABI_FUNCTION neboc_runtime_lowering_init
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 test r12,r12
 jz .invalid
 cmp qword [rbx+NEBOC_RUNTIME_LOWERING_STATE_OFFSET],NEBOC_RUNTIME_LOWERING_STATE_EMPTY
 jne .invalid
 mov rdi,r12
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .adapter
 mov r13,[r12+NEBOC_ABI_ADAPTER_WRITER_OFFSET]
 mov rdi,r13
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .adapter
 cmp qword [r13+NEBOC_ASSEMBLY_WRITER_STATE_OFFSET],NEBOC_ASSEMBLY_WRITER_STATE_READY
 jne .adapter
 mov [rbx+NEBOC_RUNTIME_LOWERING_ABI_ADAPTER_OFFSET],r12
 mov [rbx+NEBOC_RUNTIME_LOWERING_WRITER_OFFSET],r13
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_STATE_OFFSET],NEBOC_RUNTIME_LOWERING_STATE_READY
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_NONE
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_FLAGS_OFFSET],NEBOC_RUNTIME_LOWERING_REQUIRED_FLAGS
 xor eax,eax
 jmp .done
.adapter:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_ADAPTER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_runtime_lowering_emit_default_console
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 cmp qword [rbx+NEBOC_RUNTIME_LOWERING_STATE_OFFSET],NEBOC_RUNTIME_LOWERING_STATE_READY
 jne .invalid
 mov r12,[rbx+NEBOC_RUNTIME_LOWERING_ABI_ADAPTER_OFFSET]
 mov r13,[rbx+NEBOC_RUNTIME_LOWERING_WRITER_OFFSET]
 test r12,r12
 jz .adapter
 test r13,r13
 jz .adapter
 mov rdi,r12
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .adapter
 cmp qword [r12+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .adapter
 mov r14,[r12+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 test r14,r14
 jz .adapter
 mov rax,[r12+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rax,[r14+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jae .budget
 mov r15,[r13+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov rdi,r13
 lea rsi,[rel rt_default]
 mov edx,rt_default_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 inc qword [r12+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 inc qword [rbx+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET]
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_NONE
 xor eax,eax
 jmp .done
.writer:
 mov r14d,eax
 mov [r13+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],r15
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_WRITER_LIMIT
 mov eax,r14d
 jmp .done
.budget:
 mov qword [r12+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_CALL_BUDGET
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.adapter:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_ADAPTER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; emit_named_console(lowering*, text_id)
NEBOC_ABI_FUNCTION neboc_runtime_lowering_emit_named_console
 mov edx,2
 jmp runtime_emit_text_contract
; emit_anonymous_scan(lowering*, text_id)
NEBOC_ABI_FUNCTION neboc_runtime_lowering_emit_anonymous_scan
 mov edx,3
 ; fallthrough
runtime_emit_text_contract:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid_return
 test r12,r12
 jz .invalid
 cmp qword [rbx+NEBOC_RUNTIME_LOWERING_STATE_OFFSET],NEBOC_RUNTIME_LOWERING_STATE_READY
 jne .invalid
 mov r14,[rbx+NEBOC_RUNTIME_LOWERING_ABI_ADAPTER_OFFSET]
 mov r15,[rbx+NEBOC_RUNTIME_LOWERING_WRITER_OFFSET]
 test r14,r14
 jz .adapter
 test r15,r15
 jz .adapter
 mov rdi,r14
 call neboc_abi_adapter_validate
 test eax,eax
 jnz .adapter
 cmp qword [r14+NEBOC_ABI_ADAPTER_STATE_OFFSET],NEBOC_ABI_ADAPTER_STATE_FUNCTION
 jne .adapter
 mov rax,[r14+NEBOC_ABI_ADAPTER_CURRENT_SIGNATURE_OFFSET]
 test rax,rax
 jz .adapter
 mov rcx,[r14+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 cmp rcx,[rax+NEBOC_ABI_SIGNATURE_RUNTIME_CALL_COUNT_OFFSET]
 jae .budget
 mov rax,[r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rdi,r15
 lea rsi,[rel rt_named_a]
 mov edx,rt_named_a_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 mov rdi,r15
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .restore
 mov rdi,r15
 cmp r13,2
 jne .scan
 lea rsi,[rel rt_named_b]
 mov edx,rt_named_b_len
 jmp .append_tail
.scan:
 lea rsi,[rel rt_scan_b]
 mov edx,rt_scan_b_len
.append_tail:
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .restore
 inc qword [r14+NEBOC_ABI_ADAPTER_CURRENT_FUNCTION_CALLS_OFFSET]
 inc qword [rbx+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET]
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_NONE
 xor eax,eax
 jmp .done
.restore:
 mov r13d,eax
 mov rax,[rsp]
 mov [r15+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [rbx+NEBOC_RUNTIME_LOWERING_CALL_COUNT_OFFSET],rax
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_WRITER_LIMIT
 mov eax,r13d
 jmp .done
.budget:
 mov qword [r14+NEBOC_ABI_ADAPTER_LAST_ERROR_OFFSET],NEBOC_ABI_ERROR_CALL_INVALID
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_CALL_BUDGET
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.adapter:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_ADAPTER_NOT_READY
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_RUNTIME_LOWERING_LAST_ERROR_OFFSET],NEBOC_RUNTIME_LOWERING_ERROR_BAD_ARGUMENT
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
section .note.GNU-stack noalloc noexec nowrite progbits
