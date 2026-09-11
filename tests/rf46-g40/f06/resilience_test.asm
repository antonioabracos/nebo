bits 64
default rel
%include "runtime/protocol/resilience.inc"
extern nebo_rpc_policy_retry
extern nebo_rpc_policy_timeout
extern nebo_rpc_policy_circuit_breaker
extern nebo_rpc_policy_bulkhead
extern nebo_request_idempotency_key
extern nebo_dedup_init
extern nebo_server_deduplicate
extern nebo_rpc_policy_attempt
extern nebo_rpc_metrics
extern nebo_rpc_trace
section .bss
policy resb nebo_ast_hir_lir_planner_e_otimizacao_POLICY_SIZE
request resb nebo_ast_hir_lir_planner_e_otimizacao_REQUEST_SIZE
store resb NEBO_DEDUP_SIZE
keys resq 4
metrics resb NEBO_METRICS_SIZE
trace resb nebo_ast_hir_lir_planner_e_otimizacao_TRACE_SIZE
section .text
global _start
_start:
    ; Automatic retries on non-idempotent methods are forbidden and atomic.
    mov qword [policy+NEBO_POLICY_MAX_ATTEMPTS],0x7777
    lea rdi,[policy]
    mov esi,3
    xor edx,edx
    call nebo_rpc_policy_retry
    cmp eax,NEBO_RETRY_DENIED
    jne fail
    cmp qword [policy+NEBO_POLICY_MAX_ATTEMPTS],0x7777
    jne fail
    lea rdi,[policy]
    mov esi,3
    mov edx,NEBO_RPC_METHOD_IDEMPOTENT
    call nebo_rpc_policy_retry
    test eax,eax
    jnz fail
    lea rdi,[policy]
    mov esi,100
    call nebo_rpc_policy_timeout
    test eax,eax
    jnz fail
    lea rdi,[policy]
    mov esi,2
    mov edx,50
    call nebo_rpc_policy_circuit_breaker
    test eax,eax
    jnz fail
    lea rdi,[policy]
    mov esi,1
    call nebo_rpc_policy_bulkhead
    test eax,eax
    jnz fail
    lea rdi,[request]
    mov rsi,0xabc
    mov edx,NEBO_RPC_METHOD_IDEMPOTENT
    call nebo_request_idempotency_key
    test eax,eax
    jnz fail
    lea rdi,[store]
    lea rsi,[keys]
    mov edx,4
    call nebo_dedup_init
    test eax,eax
    jnz fail
    lea rdi,[store]
    mov rsi,0xabc
    call nebo_server_deduplicate
    test eax,eax
    jnz fail
    lea rdi,[store]
    mov rsi,0xabc
    call nebo_server_deduplicate
    cmp eax,NEBO_DUPLICATE_REQUEST
    jne fail
    ; First injected failure requests one explicit retry.
    lea rdi,[policy]
    mov esi,NEBO_RPC_METHOD_IDEMPOTENT
    mov edx,NEBO_UNAVAILABLE
    mov ecx,10
    call nebo_rpc_policy_attempt
    cmp eax,NEBO_NEED_MORE
    jne fail
    ; Second failure opens the circuit; later calls remain rejected.
    lea rdi,[policy]
    mov esi,NEBO_RPC_METHOD_IDEMPOTENT
    mov edx,NEBO_UNAVAILABLE
    mov ecx,20
    call nebo_rpc_policy_attempt
    cmp eax,NEBO_CIRCUIT_OPEN
    jne fail
    lea rdi,[policy]
    mov esi,NEBO_RPC_METHOD_IDEMPOTENT
    xor edx,edx
    mov ecx,1
    call nebo_rpc_policy_attempt
    cmp eax,NEBO_CIRCUIT_OPEN
    jne fail
    lea rdi,[policy]
    lea rsi,[metrics]
    call nebo_rpc_metrics
    test eax,eax
    jnz fail
    cmp qword [metrics+NEBO_METRICS_CALLS],2
    jne fail
    cmp qword [metrics+NEBO_METRICS_ERRORS],2
    jne fail
    cmp qword [metrics+NEBO_METRICS_RETRIES],1
    jne fail
    cmp qword [metrics+NEBO_METRICS_IN_FLIGHT],0
    jne fail
    cmp qword [metrics+NEBO_METRICS_CIRCUIT],NEBO_CIRCUIT_OPEN_STATE
    jne fail
    mov qword [policy+NEBO_POLICY_LAST_REQUEST],0x1234
    lea rdi,[policy]
    lea rsi,[trace]
    call nebo_rpc_trace
    test eax,eax
    jnz fail
    cmp qword [trace+NEBO_TRACE_REQUEST_ID],0x1234
    jne fail
    cmp qword [trace+NEBO_TRACE_REDACTED],1
    jne fail
    ; Dedup capacity is hard and failure-atomic.
    lea rdi,[store]
    mov rsi,1
    call nebo_server_deduplicate
    test eax,eax
    jnz fail
    lea rdi,[store]
    mov rsi,2
    call nebo_server_deduplicate
    test eax,eax
    jnz fail
    lea rdi,[store]
    mov rsi,3
    call nebo_server_deduplicate
    test eax,eax
    jnz fail
    lea rdi,[store]
    mov rsi,4
    call nebo_server_deduplicate
    cmp eax,NEBO_LIMIT
    jne fail
    cmp qword [store+NEBO_DEDUP_COUNT],4
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
