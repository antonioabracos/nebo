; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F04 deterministic emitter for authenticated Slice plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/semantic/collections/slice_view.inc"
%include "compiler/lowering/collections/slice_view_plan.inc"
%include "compiler/codegen/collections/x86_64/slice_view_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
prefix:
 db 10,'section .text',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
prefix_len equ $-prefix
suffix: db 10,'    ret',10
suffix_len equ $-suffix

section .text

NEBOC_ABI_FUNCTION neboc_slice_codegen_emit_start
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
 mov qword [r12+NEBOC_SLICE_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_SLICE_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_SLICE_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+NEBOC_SLICE_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+NEBOC_SLICE_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,NEBOC_SLICE_PLAN_MAGIC
 cmp [r13+NEBOC_SLICE_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rax,NEBOC_SLICE_LAYOUT_ID
 cmp [r13+NEBOC_SLICE_PLAN_LAYOUT_ID_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_SLICE_PLAN_FOUND_OFFSET],1
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_SLICE_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+NEBOC_SLICE_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,r14
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+NEBOC_SLICE_PLAN_RESULT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_SLICE_CODEGEN_EMITTED_OFFSET],1
 mov rax,[r13+NEBOC_SLICE_PLAN_HASH_OFFSET]
 mov [r12+NEBOC_SLICE_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_SLICE_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_SLICE_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
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

section .note.GNU-stack noalloc noexec nowrite progbits
