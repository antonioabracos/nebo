; OBSERVABILIDADE-EXPLAIN-DEBUG-SIMULACAO-E-EVOLUCAO-F04 bounded retries, idempotency, and reverse compensation.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/workflow/saga.inc"
section .text
NEBOC_ABI_FUNCTION nebo_retry_delay
 ; base,attempt,max_attempts,out
 test rcx,rcx
 jz .invalid
 test edx,edx
 jz .limit
 cmp edx,NEBO_SAGA_MAX_ATTEMPTS
 ja .limit
 cmp esi,edx
 jae .exhausted
 cmp esi,63
 jae .limit
 mov r8,rcx
 mov rax,rdi
 mov ecx,esi
 shl rax,cl
 mov [r8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SAGA_INVALID
 ret
.limit: mov eax,NEBO_SAGA_LIMIT
 ret
.exhausted: mov eax,NEBO_SAGA_EXHAUSTED
 ret

NEBOC_ABI_FUNCTION nebo_idempotency_lookup
 ; entries[key,result],count,key,out
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,NEBO_IDEMPOTENCY_MAX_KEYS
 ja .limit
 xor eax,eax
 xor r8d,r8d
 xor r9d,r9d
.scan:
 cmp rax,rsi
 jae .scan_done
 mov r10,rax
 shl r10,4
 cmp [rdi+r10],rdx
 jne .next
 inc r8
 mov r9,[rdi+r10+8]
.next:
 inc rax
 jmp .scan
.scan_done:
 test r8,r8
 jz .not_found
 cmp r8,1
 jne .duplicate
 mov [rcx],r9
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SAGA_INVALID
 ret
.limit: mov eax,NEBO_SAGA_LIMIT
 ret
.not_found: mov eax,NEBO_SAGA_NOT_FOUND
 ret
.duplicate: mov eax,NEBO_SAGA_DUPLICATE_KEY
 ret

NEBOC_ABI_FUNCTION nebo_saga_compensation_order
 ; completed_count,out,capacity
 test rsi,rsi
 jz .invalid
 cmp rdi,NEBO_SAGA_MAX_STEPS
 ja .limit
 cmp rdx,rdi
 jb .limit
 mov rcx,rdi
 xor eax,eax
.reverse:
 test rcx,rcx
 jz .done
 dec rcx
 mov [rsi+rax*8],rcx
 inc rax
 jmp .reverse
.done: xor eax,eax
 ret
.invalid: mov eax,NEBO_SAGA_INVALID
 ret
.limit: mov eax,NEBO_SAGA_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_saga_terminal_status
 ; compensation_failed boolean
 test edi,edi
 jnz .stuck
 mov eax,NEBO_SAGA_COMPENSATED
 ret
.stuck: mov eax,NEBO_SAGA_STUCK
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
