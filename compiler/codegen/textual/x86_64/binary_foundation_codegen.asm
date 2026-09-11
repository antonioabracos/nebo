; RF204-G001 deterministic x86-64 emitter for authenticated binary plans.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binary_foundation_parser.inc"
%include "compiler/lowering/textual/binary_foundation_plan.inc"
%include "compiler/codegen/textual/x86_64/binary_foundation_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal

section .rodata
bf_prefix:
 db 10,'section .rodata',10
 db 'align 8',10
 db 'global nebo_binary_foundation_plan',10
 db 'nebo_binary_foundation_plan:',10
 db '    dq '
bf_prefix_len equ $-bf_prefix
bf_mid:
 db 10,'    dq '
bf_mid_len equ $-bf_mid
bf_text:
 db 10,'section .text',10
 db '; RF204-G001 result is lowered from token-authenticated binary operations.',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, '
bf_text_len equ $-bf_text
bf_constant_time_text:
 db 10,'section .text',10
 db '; constantTimeEquals folds neither an early-success nor an early-failure branch.',10
 db 'global nebo_fn_1',10
 db 'nebo_fn_1:',10
 db '    mov rax, [rel nebo_binary_foundation_plan + 8]',10
 db '    xor rax, [rel nebo_binary_foundation_plan + 16]',10
 db '    mov rcx, [rel nebo_binary_foundation_plan + 24]',10
 db '    xor rcx, [rel nebo_binary_foundation_plan + 32]',10
 db '    or rax, rcx',10
 db '    test rax, rax',10
 db '    sete al',10
 db '    movzx rax, al',10
 db '    ret',10
bf_constant_time_text_len equ $-bf_constant_time_text
bf_suffix:
 db 10,'    ret',10
bf_suffix_len equ $-bf_suffix

section .text

bf_codegen_hash:
 mov rax,1469598103934665603
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

NEBOC_ABI_FUNCTION neboc_binary_foundation_codegen_emit
 test rdi,rdi
 jz .argument_direct
 test rdi,7
 jnz .argument_direct
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov qword [r12+NEBOC_BF_CODEGEN_EMITTED_OFFSET],0
 mov qword [r12+NEBOC_BF_CODEGEN_DIAGNOSTIC_OFFSET],0
 mov r13,[r12+NEBOC_BF_CODEGEN_PLAN_OFFSET]
 mov rbx,[r12+NEBOC_BF_CODEGEN_WRITER_OFFSET]
 test r13,r13
 jz .argument
 test rbx,rbx
 jz .argument
 mov rax,NEBOC_BF_PLAN_MAGIC
 cmp [r13+NEBOC_BF_PLAN_MAGIC_OFFSET],rax
 jne .source
 cmp qword [r13+NEBOC_BF_PLAN_VERSION_OFFSET],NEBOC_BF_PLAN_VERSION
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_BF_PLAN_HASHED_BYTES
 call bf_codegen_hash
 cmp rax,[r13+NEBOC_BF_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,rbx
 lea rsi,[rel bf_prefix]
 mov edx,bf_prefix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_OPERATION_MASK_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel bf_mid]
 mov edx,bf_mid_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_SEQUENCE0_PACKED_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel bf_mid]
 mov edx,bf_mid_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_SEQUENCE1_PACKED_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel bf_mid]
 mov edx,bf_mid_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_SEQUENCE0_LENGTH_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel bf_mid]
 mov edx,bf_mid_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_SEQUENCE1_LENGTH_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 test qword [r13+NEBOC_BF_PLAN_OPERATION_MASK_OFFSET],(1 << (NEBOC_BF_OP_CONSTANT_TIME_EQUALS-1))
 jz .constant_result
 mov rdi,rbx
 lea rsi,[rel bf_constant_time_text]
 mov edx,bf_constant_time_text_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 jmp .emitted
.constant_result:
 mov rdi,rbx
 lea rsi,[rel bf_text]
 mov edx,bf_text_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 mov rdi,rbx
 mov rsi,[r13+NEBOC_BF_PLAN_RESULT_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel bf_suffix]
 mov edx,bf_suffix_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
.emitted:
 mov qword [r12+NEBOC_BF_CODEGEN_EMITTED_OFFSET],1
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_BF_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+NEBOC_BF_CODEGEN_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.argument_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
