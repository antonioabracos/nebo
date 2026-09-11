; G147-S06 deterministic, replayable operator fuzz corpus state.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION nebo_operator_fuzz_init
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,NEBO_OPERATOR_PERF_MAX_CASES
    ja .limit
    mov r8,rdi
    xor eax,eax
    mov rcx,NEBO_OPERATOR_FUZZ_SIZE/8
    rep stosq
    mov [r8+NEBO_OPERATOR_FUZZ_SEED_OFFSET],rsi
    mov [r8+NEBO_OPERATOR_FUZZ_STATE_OFFSET],rsi
    mov [r8+NEBO_OPERATOR_FUZZ_LIMIT_OFFSET],rdx
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_fuzz_next
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi+NEBO_OPERATOR_FUZZ_GENERATED_OFFSET]
    cmp rax,[rdi+NEBO_OPERATOR_FUZZ_LIMIT_OFFSET]
    jae .limit
    mov rax,[rdi+NEBO_OPERATOR_FUZZ_STATE_OFFSET]
    mov rdx,6364136223846793005
    mul rdx
    mov rcx,1442695040888963407
    add rax,rcx
    mov [rdi+NEBO_OPERATOR_FUZZ_STATE_OFFSET],rax
    inc qword [rdi+NEBO_OPERATOR_FUZZ_GENERATED_OFFSET]
    rol qword [rdi+NEBO_OPERATOR_FUZZ_DIGEST_OFFSET],7
    xor [rdi+NEBO_OPERATOR_FUZZ_DIGEST_OFFSET],rax
    mov [rsi],rax
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_fuzz_record
    test rdi,rdi
    jz .invalid
    cmp rsi,1
    ja .invalid
    test rsi,rsi
    jnz .rejected
    inc qword [rdi+NEBO_OPERATOR_FUZZ_ACCEPTED_OFFSET]
    xor eax,eax
    ret
.rejected:
    inc qword [rdi+NEBO_OPERATOR_FUZZ_REJECTED_OFFSET]
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_fuzz_replay_token
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi+NEBO_OPERATOR_FUZZ_SEED_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_FUZZ_DIGEST_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_FUZZ_GENERATED_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_FUZZ_ACCEPTED_OFFSET]
    rol rax,13
    xor rax,[rdi+NEBO_OPERATOR_FUZZ_REJECTED_OFFSET]
    mov [rsi],rax
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_fuzz_minimize
    test rdx,rdx
    jz .invalid
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,rdi
    ja .invalid
    mov [rdx],rsi
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
