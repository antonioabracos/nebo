; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F06 pointerless authenticated nominal-type plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/nominal_types.inc"
%include "compiler/lowering/aggregates/nominal_plan.inc"

section .text

nominal_plan_hash:
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

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_nominal_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .invalid_direct
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 mov ecx,NEBOC_NOM_PLAN_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_NOM_FOUND_OFFSET],1
 jne .source
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_ANALYZED
 jz .source
 mov rax,NEBOC_NOM_PLAN_MAGIC
 mov [r13+NEBOC_NOM_PLAN_MAGIC_OFFSET],rax
 mov qword [r13+NEBOC_NOM_PLAN_VERSION_OFFSET],NEBOC_NOM_PLAN_VERSION_A0
 mov rax,[r12+NEBOC_NOM_KIND_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_KIND_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_TYPE_KEY_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_TYPE_KEY_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_UNDERLYING_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_VARIANT_COUNT_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_VARIANT_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_ACTIVE_TAG_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_ACTIVE_TAG_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_PAYLOAD_TYPE_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_PAYLOAD_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_PAYLOAD_VALUE_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_PAYLOAD_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_RESULT_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_RESULT_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_SIZE_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_ALIGN_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_ALIGN_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_PAYLOAD_OFFSET_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_PAYLOAD_OFFSET_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_DROP_COUNT_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_NOM_FLAGS_OFFSET]
 mov [r13+NEBOC_NOM_PLAN_FLAGS_OFFSET],rax
 mov rdi,r13
 mov ecx,NEBOC_NOM_PLAN_HASHED_BYTES
 call nominal_plan_hash
 mov [r13+NEBOC_NOM_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov qword [r12+NEBOC_NOM_DIAGNOSTIC_OFFSET],NEBOC_NOM_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
