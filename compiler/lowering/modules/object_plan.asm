; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F06 canonical static-object and bounded cache metadata plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/modules/object_plan.inc"

section .text

; object_plan_build(module_plan*, unit_records*, object_plan*)
NEBOC_ABI_FUNCTION neboc_object_plan_build
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,rdi
 or rax,rsi
 or rax,rdx
 test rax,7
 jnz .invalid
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r14
 mov ecx,NEBOC_OBJECT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_MODULE_PLAN_MAGIC
 cmp [r12+NEBOC_MODULE_PLAN_MAGIC_OFFSET],rax
 jne .source
 cmp qword [r12+NEBOC_MODULE_PLAN_UNIT_COUNT_OFFSET],3
 jne .source
 cmp qword [r12+NEBOC_MODULE_PLAN_FLAGS_OFFSET],NEBOC_MODULE_PLAN_FLAG_POINTERLESS
 jne .source
 mov rsi,r12
 mov ecx,NEBOC_MODULE_PLAN_HASHED_BYTES
 call object_hash
 cmp rax,[r12+NEBOC_MODULE_PLAN_HASH_OFFSET]
 jne .source
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_OBJECT_MAGIC
 mov [r14+NEBOC_OBJECT_MAGIC_OFFSET],rax
 mov rax,NEBOC_OBJECT_ABI_HASH
 mov [r14+NEBOC_OBJECT_ABI_HASH_OFFSET],rax
 mov qword [r14+NEBOC_OBJECT_MODULE_COUNT_OFFSET],3
 mov qword [r14+NEBOC_OBJECT_CACHE_MAX_OFFSET],NEBOC_OBJECT_CACHE_MAX
 mov qword [r14+NEBOC_OBJECT_FLAGS_OFFSET],NEBOC_OBJECT_FLAG_CANONICAL_STATIC

 ; Materialize records by semantic canonical index, never argv order.
 xor ebx,ebx
.rank_loop:
 cmp ebx,3
 jae .collision_check
 xor ebp,ebp
.find_rank:
 cmp ebp,3
 jae .source
 mov rdx,rbp
 shl rdx,7
 cmp [r13+rdx+NEBOC_MODULE_RECORD_CANONICAL_INDEX_OFFSET],rbx
 je .rank_found
 inc rbp
 jmp .find_rank
.rank_found:
 mov r15,[r13+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 test r15,r15
 jz .source
 mov [r14+rbx*8+NEBOC_OBJECT_MODULE0_OFFSET],r15
 mov rax,[r13+rdx+NEBOC_MODULE_RECORD_SOURCE_HASH_OFFSET]
 test rax,rax
 jz .source
 mov [r14+rbx*8+NEBOC_OBJECT_SOURCE0_OFFSET],rax
 xor r15,[r13+rdx+NEBOC_MODULE_RECORD_EXPORT_HASH_OFFSET]
 rol r15,23
 mov rax,NEBOC_OBJECT_ABI_HASH
 xor r15,rax
 test r15,r15
 jnz .symbol_ok
 mov r15,1
.symbol_ok:
 mov [r14+rbx*8+NEBOC_OBJECT_SYMBOL0_OFFSET],r15
 inc rbx
 jmp .rank_loop

.collision_check:
 mov rax,[r14+NEBOC_OBJECT_MODULE0_OFFSET]
 cmp rax,[r14+NEBOC_OBJECT_MODULE1_OFFSET]
 je .collision
 cmp rax,[r14+NEBOC_OBJECT_MODULE2_OFFSET]
 je .collision
 mov rax,[r14+NEBOC_OBJECT_MODULE1_OFFSET]
 cmp rax,[r14+NEBOC_OBJECT_MODULE2_OFFSET]
 je .collision
 mov rax,[r14+NEBOC_OBJECT_SYMBOL0_OFFSET]
 cmp rax,[r14+NEBOC_OBJECT_SYMBOL1_OFFSET]
 je .collision
 cmp rax,[r14+NEBOC_OBJECT_SYMBOL2_OFFSET]
 je .collision
 mov rax,[r14+NEBOC_OBJECT_SYMBOL1_OFFSET]
 cmp rax,[r14+NEBOC_OBJECT_SYMBOL2_OFFSET]
 je .collision

 mov rsi,r12
 mov ecx,NEBOC_MODULE_PLAN_SIZE
 call object_hash
 mov r15,rax
 lea rsi,[r14+NEBOC_OBJECT_MODULE0_OFFSET]
 mov ecx,72
 call object_hash
 xor r15,rax
 test r15,r15
 jnz .bundle_ok
 mov r15,1
.bundle_ok:
 mov [r14+NEBOC_OBJECT_BUNDLE_KEY_OFFSET],r15
 mov rsi,r14
 mov ecx,NEBOC_OBJECT_PLAN_HASHED_BYTES
 call object_hash
 mov [r14+NEBOC_OBJECT_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.collision:
 mov eax,NEBOC_OBJECT_DIAG_DUPLICATE_SYMBOL
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 cld
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; cache_seal(object_plan*, cache_record*)
NEBOC_ABI_FUNCTION neboc_object_cache_seal
 test rdi,rdi
 jz .seal_invalid
 test rsi,rsi
 jz .seal_invalid
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .seal_invalid
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 mov ecx,NEBOC_CACHE_QWORDS
 xor eax,eax
 rep stosq
 call object_authenticate
 test eax,eax
 jnz .seal_done
 mov rax,[rbx+NEBOC_OBJECT_ABI_HASH_OFFSET]
 mov [r12+NEBOC_CACHE_ABI_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_OBJECT_BUNDLE_KEY_OFFSET]
 mov [r12+NEBOC_CACHE_BUNDLE_KEY_OFFSET],rax
 mov qword [r12+NEBOC_CACHE_OBJECT_COUNT_OFFSET],NEBOC_CACHE_OBJECT_COUNT
 mov [r12+NEBOC_CACHE_OBJECT0_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_OBJECT_SOURCE0_OFFSET]
 mov [r12+NEBOC_CACHE_OBJECT1_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_OBJECT_SOURCE1_OFFSET]
 mov [r12+NEBOC_CACHE_OBJECT2_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_OBJECT_SOURCE2_OFFSET]
 mov [r12+NEBOC_CACHE_OBJECT3_HASH_OFFSET],rax
 mov qword [r12+NEBOC_CACHE_FLAGS_OFFSET],NEBOC_CACHE_FLAG_COMPLETE
 mov rsi,r12
 mov ecx,NEBOC_CACHE_HASHED_BYTES
 call object_hash
 mov [r12+NEBOC_CACHE_HASH_OFFSET],rax
 xor eax,eax
.seal_done:
 pop r12
 pop rbx
 ret
.seal_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; cache_validate(object_plan*, cache_record*)
NEBOC_ABI_FUNCTION neboc_object_cache_validate
 test rdi,rdi
 jz .cache_invalid
 test rsi,rsi
 jz .cache_invalid
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .cache_invalid
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 mov qword [r12+NEBOC_CACHE_DIAGNOSTIC_OFFSET],0
 call object_authenticate
 test eax,eax
 jnz .cache_partial
 mov rax,[rbx+NEBOC_OBJECT_ABI_HASH_OFFSET]
 cmp [r12+NEBOC_CACHE_ABI_HASH_OFFSET],rax
 jne .cache_abi
 mov rax,[rbx+NEBOC_OBJECT_BUNDLE_KEY_OFFSET]
 cmp [r12+NEBOC_CACHE_BUNDLE_KEY_OFFSET],rax
 jne .cache_stale
 cmp qword [r12+NEBOC_CACHE_OBJECT_COUNT_OFFSET],NEBOC_CACHE_OBJECT_COUNT
 jne .cache_stale
 cmp qword [r12+NEBOC_CACHE_FLAGS_OFFSET],NEBOC_CACHE_FLAG_COMPLETE
 jne .cache_stale
 mov rsi,r12
 mov ecx,NEBOC_CACHE_HASHED_BYTES
 call object_hash
 cmp rax,[r12+NEBOC_CACHE_HASH_OFFSET]
 jne .cache_stale
 xor eax,eax
 jmp .cache_done
.cache_abi:
 mov eax,NEBOC_OBJECT_DIAG_ABI_MISMATCH
 jmp .cache_failure
.cache_stale:
 mov eax,NEBOC_OBJECT_DIAG_STALE_CACHE
 jmp .cache_failure
.cache_partial:
 mov eax,NEBOC_OBJECT_DIAG_PARTIAL_ARTIFACT
.cache_failure:
 mov [r12+NEBOC_CACHE_DIAGNOSTIC_OFFSET],rax
.cache_done:
 pop r12
 pop rbx
 ret
.cache_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; RBX points at an object plan. Returns zero only for an authenticated plan.
object_authenticate:
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_OBJECT_MAGIC
 cmp [rbx+NEBOC_OBJECT_MAGIC_OFFSET],rax
 jne .bad
 cmp qword [rbx+NEBOC_OBJECT_MODULE_COUNT_OFFSET],3
 jne .bad
 cmp qword [rbx+NEBOC_OBJECT_FLAGS_OFFSET],NEBOC_OBJECT_FLAG_CANONICAL_STATIC
 jne .bad
 mov rsi,rbx
 mov ecx,NEBOC_OBJECT_PLAN_HASHED_BYTES
 call object_hash
 cmp rax,[rbx+NEBOC_OBJECT_HASH_OFFSET]
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

object_hash:
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
