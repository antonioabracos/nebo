; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 authenticated pointerless static-module plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/modules/module_plan.inc"

section .text

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_lower
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,rdi
 or rax,rsi
 test rax,NEBOC_MODULE_ALIGNMENT-1
 jnz .invalid
 mov r8,rdi
 add r8,NEBOC_MODULE_REQUEST_SIZE
 jc .invalid
 mov r9,rsi
 add r9,NEBOC_MODULE_PLAN_SIZE
 jc .invalid
 cmp r8,rsi
 jbe .ranges_ok
 cmp r9,rdi
 ja .invalid
.ranges_ok:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 mov ecx,NEBOC_MODULE_PLAN_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [rbx+NEBOC_MODULE_FOUND_OFFSET],1
 jne .source
 cmp qword [rbx+NEBOC_MODULE_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [rbx+NEBOC_MODULE_UNIT_COUNT_OFFSET],NEBOC_MODULE_MAX_UNITS
 jne .source
 mov rax,NEBOC_MODULE_FLAG_PARSED|NEBOC_MODULE_FLAG_ANALYZED
 cmp [rbx+NEBOC_MODULE_FLAGS_OFFSET],rax
 jne .source
 cmp qword [rbx+NEBOC_MODULE_ROOT_INDEX_OFFSET],NEBOC_MODULE_MAX_UNITS
 jae .source
 cmp qword [rbx+NEBOC_MODULE_START_REF_COUNT_OFFSET],1
 jb .source
 cmp qword [rbx+NEBOC_MODULE_START_REF_COUNT_OFFSET],NEBOC_MODULE_MAX_START_REFS
 ja .source
 cmp qword [rbx+NEBOC_MODULE_GRAPH_HASH_OFFSET],0
 je .source
 cmp qword [rbx+NEBOC_MODULE_SEMANTIC_HASH_OFFSET],0
 je .source

 mov rax,NEBOC_MODULE_PLAN_MAGIC
 mov [r12+NEBOC_MODULE_PLAN_MAGIC_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_UNIT_COUNT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_UNIT_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_ROOT_INDEX_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_ROOT_INDEX_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_RESULT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_RESULT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_EDGE_COUNT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_EDGE_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_PUBLIC_COUNT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_PUBLIC_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_PRIVATE_COUNT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_PRIVATE_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_START_REF_COUNT_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_START_REF_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_GRAPH_HASH_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_GRAPH_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_MODULE_SEMANTIC_HASH_OFFSET]
 mov [r12+NEBOC_MODULE_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov qword [r12+NEBOC_MODULE_PLAN_FLAGS_OFFSET],NEBOC_MODULE_PLAN_FLAG_POINTERLESS
 mov qword [r12+NEBOC_MODULE_PLAN_TARGET_OFFSET],NEBOC_MODULE_PLAN_TARGET_X86_64_SYSV_ELF
 mov rsi,r12
 mov ecx,NEBOC_MODULE_PLAN_HASHED_BYTES
 call mod_plan_hash
 mov [r12+NEBOC_MODULE_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r12
 pop rbx
 cld
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
mod_plan_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rsi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
