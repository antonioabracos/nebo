; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 pointerless authenticated Array/Range lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/lowering/collections/array_range_plan.inc"

section .text

NEBOC_ABI_FUNCTION neboc_array_range_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_AR_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_AR_DIAGNOSTIC_OFFSET],0
 jne .source
 call semantic_hash
 cmp rax,[r12+NEBOC_AR_SEMANTIC_HASH_OFFSET]
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_AR_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_AR_PLAN_MAGIC
 mov [r13+NEBOC_AR_PLAN_MAGIC_OFFSET],rax
 mov rax,NEBOC_ARRAY_RANGE_LAYOUT_ID
 mov [r13+NEBOC_AR_PLAN_LAYOUT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_AR_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_AR_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_CONSTRUCT_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_ARRAY_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_ARRAY_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_RANGE_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_RANGE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_ACCESS_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_RESULT_TYPE_OFFSET]
 mov [r13+NEBOC_AR_PLAN_RESULT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_AR_RESULT_VALUE_OFFSET]
 mov [r13+NEBOC_AR_PLAN_RESULT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_AR_LAYOUT_SIZE_OFFSET]
 mov [r13+NEBOC_AR_PLAN_LAYOUT_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_AR_LAYOUT_ALIGN_OFFSET]
 mov [r13+NEBOC_AR_PLAN_LAYOUT_ALIGN_OFFSET],rax
 mov rax,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_LOOP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_ITERATION_COUNT_OFFSET]
 mov [r13+NEBOC_AR_PLAN_ITERATION_COUNT_OFFSET],rax
 mov rdi,r13
 mov ecx,NEBOC_AR_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+NEBOC_AR_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
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

semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rdx,NEBOC_ARRAY_RANGE_LAYOUT_ID
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_FOUND_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RESULT_TYPE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RESULT_VALUE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LAYOUT_SIZE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LAYOUT_ALIGN_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ARRAY_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RANGE_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ITERATION_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 xor r9d,r9d
.loop_hash:
 cmp r9,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .done
 mov r10,r9
 imul r10,NEBOC_FOR_RECORD_SIZE
 add r10,[r12+NEBOC_AR_LOOPS_OFFSET]
 xor r11d,r11d
.record_hash:
 cmp r11,NEBOC_FOR_RECORD_QWORDS
 jae .next_loop_hash
 mov rdx,[r10+r11*8]
 xor rax,rdx
 imul rax,r8
 inc r11
 jmp .record_hash
.next_loop_hash:
 inc r9
 jmp .loop_hash
.done:
 ret

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
