; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-F02 deterministic native ownership emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"
%include "compiler/lowering/memory/move_copy_clone_plan.inc"
%include "compiler/codegen/memory/x86_64/move_copy_clone_codegen.inc"

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

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_move_copy_clone_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_HASH_OFFSET],0
 mov r13,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_PLAN_OFFSET]
 mov r14,[r12+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_memory_x86_64_native_vertical]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r13,7
 jnz .invalid
 test r14,7
 jnz .invalid
 mov rax,neboc_text_char_unicode_e_bytes_PLAN_MAGIC
 cmp [r13+neboc_text_char_unicode_e_bytes_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rdi,r13
 mov ecx,neboc_text_char_unicode_e_bytes_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r13+neboc_text_char_unicode_e_bytes_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,r14
 lea rsi,[rel prefix]
 mov edx,prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,r14
 mov rsi,[r13+neboc_text_char_unicode_e_bytes_PLAN_RESULT_VALUE_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r14
 lea rsi,[rel suffix]
 mov edx,suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_EMITTED_START
 mov rax,[r13+neboc_text_char_unicode_e_bytes_PLAN_HASH_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_CODEGEN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_DIAG_CLONE_UNAVAILABLE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
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
.done: ret

section .note.GNU-stack noalloc noexec nowrite progbits
