; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F06 deterministic x86-64 emitter for authenticated A0 plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/nominal_types.inc"
%include "compiler/lowering/aggregates/nominal_plan.inc"
%include "compiler/codegen/aggregates/x86_64/nominal_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal

section .rodata
nominal_prefix:
 db 10,'section .text',10
 db 'global nebo_nominal_value',10
 db 'nebo_nominal_value:',10
 db '    mov rax, rdi',10
 db '    ret',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
nominal_prefix_len equ $-nominal_prefix
nominal_suffix: db 10,'    ret',10
nominal_suffix_len equ $-nominal_suffix

section .text

nominal_codegen_hash:
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

NEBOC_ABI_FUNCTION neboc_nominal_codegen_emit_start
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov qword [r12+NEBOC_NOM_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_NOM_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov r13,[r12+NEBOC_NOM_CODEGEN_PLAN_OFFSET]
 mov rbx,[r12+NEBOC_NOM_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .invalid
 test rbx,rbx
 jz .invalid
 mov rax,NEBOC_NOM_PLAN_MAGIC
 cmp [r13+NEBOC_NOM_PLAN_MAGIC_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_NOM_PLAN_VERSION_OFFSET],NEBOC_NOM_PLAN_VERSION_A0
 jne .source
 test qword [r13+NEBOC_NOM_PLAN_FLAGS_OFFSET],NEBOC_NOM_FLAG_ANALYZED
 jz .source
 mov rdi,r13
 mov ecx,NEBOC_NOM_PLAN_HASHED_BYTES
 call nominal_codegen_hash
 cmp rax,[r13+NEBOC_NOM_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,rbx
 lea rsi,[rel nominal_prefix]
 mov edx,nominal_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_NOM_PLAN_RESULT_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel nominal_suffix]
 mov edx,nominal_suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov qword [r12+NEBOC_NOM_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_NOM_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_NOM_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_NOM_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_NOM_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
