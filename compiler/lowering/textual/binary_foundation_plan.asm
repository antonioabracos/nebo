; RF204-G001 authenticated lowering from binary semantic facts to native plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binary_foundation_parser.inc"
%include "compiler/lowering/textual/binary_foundation_plan.inc"

section .text

bf_plan_hash:
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

NEBOC_ABI_FUNCTION neboc_binary_foundation_lower
 test rdi,rdi
 jz .argument_direct
 test rsi,rsi
 jz .argument_direct
 test rdi,7
 jnz .argument_direct
 test rsi,7
 jnz .argument_direct
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_BF_FOUND_OFFSET],1
 jne .argument
 cmp qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],0
 jne .source
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_BF_OPERATION_MASK_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_RESULT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 imul rax,rcx
 cmp rax,[r12+NEBOC_BF_SEMANTIC_HASH_OFFSET]
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_BF_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_BF_PLAN_MAGIC
 mov [r13+NEBOC_BF_PLAN_MAGIC_OFFSET],rax
 mov qword [r13+NEBOC_BF_PLAN_VERSION_OFFSET],NEBOC_BF_PLAN_VERSION
 mov rax,[r12+NEBOC_BF_OPERATION_MASK_OFFSET]
 mov [r13+NEBOC_BF_PLAN_OPERATION_MASK_OFFSET],rax
 mov rax,[r12+NEBOC_BF_RESULT_OFFSET]
 mov [r13+NEBOC_BF_PLAN_RESULT_OFFSET],rax
 mov rax,[r12+NEBOC_BF_SEQUENCE0_LENGTH_OFFSET]
 mov [r13+NEBOC_BF_PLAN_SEQUENCE0_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_BF_SEQUENCE0_PACKED_OFFSET]
 mov [r13+NEBOC_BF_PLAN_SEQUENCE0_PACKED_OFFSET],rax
 mov rax,[r12+NEBOC_BF_SEQUENCE1_LENGTH_OFFSET]
 mov [r13+NEBOC_BF_PLAN_SEQUENCE1_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_BF_SEQUENCE1_PACKED_OFFSET]
 mov [r13+NEBOC_BF_PLAN_SEQUENCE1_PACKED_OFFSET],rax
 mov rdi,r13
 mov ecx,NEBOC_BF_PLAN_HASHED_BYTES
 call bf_plan_hash
 mov [r13+NEBOC_BF_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_BF_DIAGNOSTIC_OFFSET],NEBOC_BF_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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
