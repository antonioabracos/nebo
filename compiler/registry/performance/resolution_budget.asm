; G147-S04 collision-safe bounded operator query cache.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION nebo_operator_query_cache_init
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov r8,rdi
    xor eax,eax
    mov rcx,NEBO_OPERATOR_CACHE_SIZE/8
    rep stosq
    mov [r8+NEBO_OPERATOR_CACHE_GENERATION_OFFSET],rsi
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_query_cache_lookup
    ; rdi=cache, rsi=key, rdx=fingerprint, rcx=value output.
    test rdi,rdi
    jz .invalid
    test rcx,rcx
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp qword [rdi+NEBO_OPERATOR_CACHE_GENERATION_OFFSET],0
    je .invalid
    mov r8,rsi
    xor r8,rdx
    and r8,NEBO_OPERATOR_CACHE_SLOTS-1
    bt [rdi+NEBO_OPERATOR_CACHE_VALID_OFFSET],r8
    jnc .miss
    cmp [rdi+NEBO_OPERATOR_CACHE_KEYS_OFFSET+r8*8],rsi
    jne .miss
    cmp [rdi+NEBO_OPERATOR_CACHE_FINGERPRINTS_OFFSET+r8*8],rdx
    jne .miss
    mov rax,[rdi+NEBO_OPERATOR_CACHE_VALUES_OFFSET+r8*8]
    mov [rcx],rax
    inc qword [rdi+NEBO_OPERATOR_CACHE_HITS_OFFSET]
    xor eax,eax
    ret
.miss:
    inc qword [rdi+NEBO_OPERATOR_CACHE_MISSES_OFFSET]
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_query_cache_store
    ; rdi=cache, rsi=key, rdx=fingerprint, rcx=value.
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp qword [rdi+NEBO_OPERATOR_CACHE_GENERATION_OFFSET],0
    je .invalid
    mov r8,rsi
    xor r8,rdx
    and r8,NEBO_OPERATOR_CACHE_SLOTS-1
    bt [rdi+NEBO_OPERATOR_CACHE_VALID_OFFSET],r8
    jnc .publish
    cmp [rdi+NEBO_OPERATOR_CACHE_KEYS_OFFSET+r8*8],rsi
    jne .evict
    cmp [rdi+NEBO_OPERATOR_CACHE_FINGERPRINTS_OFFSET+r8*8],rdx
    je .publish
.evict:
    inc qword [rdi+NEBO_OPERATOR_CACHE_EVICTIONS_OFFSET]
.publish:
    mov [rdi+NEBO_OPERATOR_CACHE_KEYS_OFFSET+r8*8],rsi
    mov [rdi+NEBO_OPERATOR_CACHE_VALUES_OFFSET+r8*8],rcx
    mov [rdi+NEBO_OPERATOR_CACHE_FINGERPRINTS_OFFSET+r8*8],rdx
    bts qword [rdi+NEBO_OPERATOR_CACHE_VALID_OFFSET],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_query_cache_invalidate
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov [rdi+NEBO_OPERATOR_CACHE_GENERATION_OFFSET],rsi
    mov qword [rdi+NEBO_OPERATOR_CACHE_VALID_OFFSET],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_query_cache_stats
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rcx,NEBO_OPERATOR_CACHE_STATS_SIZE/8
.copy:
    mov rax,[rdi]
    mov [rsi],rax
    add rdi,8
    add rsi,8
    loop .copy
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_registry_resolution_budget
    test rdx,rdx
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,65536
    ja .limit
    lea rax,[rdi+rdi*2+47]
    cmp rax,rsi
    ja .limit
    mov [rdx],rax
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
