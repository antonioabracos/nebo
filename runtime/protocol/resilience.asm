; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F06: explicit bounded resilience, idempotency and local telemetry.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/resilience.inc"
section .text

; rdi=policy, rsi=max attempts, rdx=method flags
NEBOC_ABI_FUNCTION nebo_rpc_policy_retry
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .limit
    cmp rsi,NEBO_MAX_RETRIES
    ja .limit
    cmp rsi,1
    jbe .commit
    test rdx,NEBO_RPC_METHOD_IDEMPOTENT
    jz .denied
.commit:
    mov [rdi+NEBO_POLICY_MAX_ATTEMPTS],rsi
    mov qword [rdi+NEBO_POLICY_LAST_ATTEMPTS],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.denied:
    mov eax,NEBO_RETRY_DENIED
    ret

; rdi=policy, rsi=total logical timeout (>0)
NEBOC_ABI_FUNCTION nebo_rpc_policy_timeout
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .limit
    mov [rdi+NEBO_POLICY_TIMEOUT],rsi
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=policy, rsi=failure threshold, rdx=cooldown ticks
NEBOC_ABI_FUNCTION nebo_rpc_policy_circuit_breaker
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .limit
    cmp rsi,64
    ja .limit
    test rdx,rdx
    jz .limit
    mov [rdi+NEBO_POLICY_FAILURE_THRESHOLD],rsi
    mov [rdi+NEBO_POLICY_COOLDOWN],rdx
    mov qword [rdi+NEBO_POLICY_CIRCUIT_STATE],NEBO_CIRCUIT_CLOSED_STATE
    mov qword [rdi+NEBO_POLICY_FAILURES],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=policy, rsi=max in flight
NEBOC_ABI_FUNCTION nebo_rpc_policy_bulkhead
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .limit
    cmp rsi,256
    ja .limit
    mov [rdi+NEBO_POLICY_BULKHEAD],rsi
    mov qword [rdi+NEBO_POLICY_IN_FLIGHT],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=request, rsi=nonzero key, rdx=method flags
NEBOC_ABI_FUNCTION nebo_request_idempotency_key
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,NEBO_RPC_METHOD_IDEMPOTENT
    jz .denied
    mov [rdi+NEBO_REQUEST_KEY],rsi
    mov [rdi+NEBO_REQUEST_METHOD_FLAGS],rdx
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.denied:
    mov eax,NEBO_RETRY_DENIED
    ret

; Extra bounded constructor: rdi=store, rsi=key storage, rdx=capacity.
NEBOC_ABI_FUNCTION nebo_dedup_init
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .limit
    cmp rdx,NEBO_MAX_DEDUP
    ja .limit
    mov [rdi+NEBO_DEDUP_KEYS],rsi
    mov [rdi+NEBO_DEDUP_CAPACITY],rdx
    mov qword [rdi+NEBO_DEDUP_COUNT],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret

; rdi=store, rsi=key. First observation appends; duplicates are explicit.
NEBOC_ABI_FUNCTION nebo_server_deduplicate
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov r8,[rdi+NEBO_DEDUP_COUNT]
    mov r9,[rdi+NEBO_DEDUP_KEYS]
    xor ecx,ecx
.scan:
    cmp rcx,r8
    jae .append
    cmp rsi,[r9+rcx*8]
    je .duplicate
    inc rcx
    jmp .scan
.append:
    cmp r8,[rdi+NEBO_DEDUP_CAPACITY]
    jae .limit
    mov [r9+r8*8],rsi
    inc r8
    mov [rdi+NEBO_DEDUP_COUNT],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.duplicate:
    mov eax,NEBO_DUPLICATE_REQUEST
    ret

; Extra failure-injection state transition:
; rdi=policy, rsi=method flags, rdx=attempt result, rcx=elapsed ticks.
NEBOC_ABI_FUNCTION nebo_rpc_policy_attempt
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_POLICY_CIRCUIT_STATE],NEBO_CIRCUIT_OPEN_STATE
    je .circuit
    mov rax,[rdi+NEBO_POLICY_BULKHEAD]
    test rax,rax
    jz .invalid
    cmp [rdi+NEBO_POLICY_IN_FLIGHT],rax
    jae .bulkhead
    inc qword [rdi+NEBO_POLICY_IN_FLIGHT]
    inc qword [rdi+NEBO_POLICY_CALLS]
    add [rdi+NEBO_POLICY_LATENCY],rcx
    mov rax,[rdi+NEBO_POLICY_TIMEOUT]
    test rax,rax
    jz .invalid_inflight
    cmp rcx,rax
    jbe .status
    mov edx,NEBO_DEADLINE
.status:
    mov [rdi+NEBO_POLICY_LAST_STATUS],rdx
    inc qword [rdi+NEBO_POLICY_LAST_ATTEMPTS]
    dec qword [rdi+NEBO_POLICY_IN_FLIGHT]
    test rdx,rdx
    jz .success
    inc qword [rdi+NEBO_POLICY_ERRORS]
    inc qword [rdi+NEBO_POLICY_FAILURES]
    mov rax,[rdi+NEBO_POLICY_FAILURE_THRESHOLD]
    test rax,rax
    jz .no_circuit
    cmp [rdi+NEBO_POLICY_FAILURES],rax
    jb .no_circuit
    mov qword [rdi+NEBO_POLICY_CIRCUIT_STATE],NEBO_CIRCUIT_OPEN_STATE
    mov eax,NEBO_CIRCUIT_OPEN
    ret
.no_circuit:
    mov rax,[rdi+NEBO_POLICY_MAX_ATTEMPTS]
    cmp qword [rdi+NEBO_POLICY_LAST_ATTEMPTS],rax
    jae .return_status
    test rsi,NEBO_RPC_METHOD_IDEMPOTENT
    jz .return_status
    inc qword [rdi+NEBO_POLICY_RETRIES]
    mov eax,NEBO_NEED_MORE
    ret
.return_status:
    mov eax,edx
    ret
.success:
    mov qword [rdi+NEBO_POLICY_FAILURES],0
    mov qword [rdi+NEBO_POLICY_LAST_ATTEMPTS],1
    xor eax,eax
    ret
.invalid_inflight:
    dec qword [rdi+NEBO_POLICY_IN_FLIGHT]
.invalid:
    mov eax,NEBO_INVALID
    ret
.circuit:
    mov eax,NEBO_CIRCUIT_OPEN
    ret
.bulkhead:
    mov eax,NEBO_BULKHEAD_FULL
    ret

; rdi=policy, rsi=metrics output
NEBOC_ABI_FUNCTION nebo_rpc_metrics
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi+NEBO_POLICY_CALLS]
    mov [rsi+NEBO_METRICS_CALLS],rax
    mov rax,[rdi+NEBO_POLICY_ERRORS]
    mov [rsi+NEBO_METRICS_ERRORS],rax
    mov rax,[rdi+NEBO_POLICY_RETRIES]
    mov [rsi+NEBO_METRICS_RETRIES],rax
    mov rax,[rdi+NEBO_POLICY_IN_FLIGHT]
    mov [rsi+NEBO_METRICS_IN_FLIGHT],rax
    mov rax,[rdi+NEBO_POLICY_DUPLICATES]
    mov [rsi+NEBO_METRICS_DUPLICATES],rax
    mov rax,[rdi+NEBO_POLICY_LATENCY]
    mov [rsi+NEBO_METRICS_LATENCY],rax
    mov rax,[rdi+NEBO_POLICY_CIRCUIT_STATE]
    mov [rsi+NEBO_METRICS_CIRCUIT],rax
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=policy, rsi=redacted trace output
NEBOC_ABI_FUNCTION nebo_rpc_trace
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi+NEBO_POLICY_LAST_REQUEST]
    mov [rsi+NEBO_TRACE_REQUEST_ID],rax
    mov rax,[rdi+NEBO_POLICY_LAST_STATUS]
    mov [rsi+NEBO_TRACE_STATUS],rax
    mov rax,[rdi+NEBO_POLICY_LAST_ATTEMPTS]
    mov [rsi+NEBO_TRACE_ATTEMPTS],rax
    mov qword [rsi+NEBO_TRACE_REDACTED],1
    mov qword [rsi+NEBO_TRACE_PROVENANCE],NEBO_RPC_ENDPOINT_MEMORY
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
