; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F05 pointerless bounded monomorphization plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/generics/generic_plan.inc"

section .text

NEBOC_ABI_FUNCTION neboc_generic_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 mov ecx,NEBOC_GEN_PLAN_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_GEN_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_GEN_FLAGS_OFFSET],(NEBOC_GEN_FLAG_PARSED|NEBOC_GEN_FLAG_ANALYZED)
 jne .source
 mov r14,[r12+NEBOC_GEN_RECORDS_OFFSET]
 test r14,r14
 jz .source
 mov r15,[r12+NEBOC_GEN_USE_COUNT_OFFSET]
 test r15,r15
 jz .source
 cmp r15,NEBOC_GEN_MAX_INSTANCES
 ja .source
 mov rax,NEBOC_GEN_PLAN_MAGIC
 mov [r13+NEBOC_GEN_PLAN_MAGIC_OFFSET],rax
 mov rax,[r14+NEBOC_GEN_RECORD_DECLARATION_HASH_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_DECLARATION_HASH_OFFSET],rax
 mov rax,[r14+NEBOC_GEN_RECORD_CONSTRAINT_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_CONSTRAINT_OFFSET],rax
 mov rax,[r14+NEBOC_GEN_RECORD_KIND_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_KIND_OFFSET],rax
 mov [r13+NEBOC_GEN_PLAN_USE_COUNT_OFFSET],r15
 mov rax,[r12+NEBOC_GEN_INSTANCE_COUNT_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_INSTANCE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_GEN_RESULT_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_RESULT_OFFSET],rax
 mov rax,[r12+NEBOC_GEN_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_GEN_PLAN_SEMANTIC_HASH_OFFSET],rax
 xor ebx,ebx
.fold:
 cmp rbx,r15
 jae .folded
 mov rdx,rbx
 shl rdx,6
 mov rax,[r14+rdx+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 mov rcx,[r14+rdx+NEBOC_GEN_RECORD_CANONICAL_INDEX_OFFSET]
 and ecx,63
 rol rax,cl
 xor [r13+NEBOC_GEN_PLAN_INSTANCE_SET_HASH_OFFSET],rax
 mov rax,[r14+rdx+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET]
 ror rax,cl
 xor [r13+NEBOC_GEN_PLAN_SYMBOL_SET_HASH_OFFSET],rax
 inc rbx
 jmp .fold
.folded:
 mov qword [r13+NEBOC_GEN_PLAN_TARGET_OFFSET],NEBOC_GEN_PLAN_TARGET_X86_64_SYSV
 mov qword [r13+NEBOC_GEN_PLAN_FLAGS_OFFSET],NEBOC_GEN_PLAN_FLAG_POINTERLESS_AOT
 mov qword [r13+NEBOC_GEN_PLAN_BUDGET_OFFSET],NEBOC_GEN_MAX_INSTANCES
 mov rdi,r13
 mov ecx,NEBOC_GEN_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+NEBOC_GEN_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r13+NEBOC_GEN_PLAN_DIAGNOSTIC_OFFSET],NEBOC_GEN_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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
