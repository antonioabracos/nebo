; G147-S01 reproducible cold/warm/incremental operator benchmark policy.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"

section .text
NEBOC_ABI_FUNCTION nebo_operator_benchmark_configure
    ; rdi=config, rsi=state. Validate before publishing any state byte.
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rdi,rsi
    je .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_CORPUS_OFFSET],0
    je .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_COMPILER_OFFSET],0
    je .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_OPTIONS_OFFSET],0
    je .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_TARGET_OFFSET],NEBO_OPERATOR_TARGET_X86_64
    jne .unsupported
    mov rax,[rdi+NEBO_OPERATOR_BENCH_REPETITIONS_OFFSET]
    cmp rax,3
    jb .invalid
    cmp rax,31
    ja .limit
    mov rax,[rdi+NEBO_OPERATOR_BENCH_MAX_INPUT_OFFSET]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_OPERATOR_PERF_MAX_INPUT
    ja .limit
    cmp qword [rdi+NEBO_OPERATOR_BENCH_MAX_WORK_OFFSET],0
    je .invalid
    mov rcx,7
.copy:
    mov rax,[rdi]
    mov [rsi],rax
    add rdi,8
    add rsi,8
    loop .copy
    mov qword [rsi],1
    xor eax,eax
    ret
.unsupported:
    mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION benchmarkOperatorCompiler
    ; rdi=state, rsi=mode, rdx=input units, rcx=result.
    test rdi,rdi
    jz .invalid
    test rcx,rcx
    jz .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_ACTIVE_OFFSET],1
    jne .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,[rdi+NEBO_OPERATOR_BENCH_MAX_INPUT_OFFSET]
    ja .limit
    cmp rsi,NEBO_OPERATOR_PERF_MODE_COLD
    je .cold
    cmp rsi,NEBO_OPERATOR_PERF_MODE_WARM
    je .warm
    cmp rsi,NEBO_OPERATOR_PERF_MODE_INCREMENTAL
    je .incremental
    jmp .invalid
.cold:
    mov r8,7
    mov r9,101
    jmp .measure
.warm:
    mov r8,3
    mov r9,43
    jmp .measure
.incremental:
    mov r8,4
    mov r9,59
.measure:
    mov r10,rdx
    mov rax,r10
    mul r8
    test rdx,rdx
    jnz .limit
    add rax,r9
    jc .limit
    mov r9,rax
    mov r11,[rdi+NEBO_OPERATOR_BENCH_MAX_WORK_OFFSET]
    mov r8,NEBO_OPERATOR_PERF_PASS
    cmp r9,r11
    jbe .classed
    mov r8,NEBO_OPERATOR_PERF_REGRESSION
.classed:
    mov [rcx+NEBO_OPERATOR_RESULT_MODE_OFFSET],rsi
    mov [rcx+NEBO_OPERATOR_RESULT_INPUT_OFFSET],r10
    mov [rcx+NEBO_OPERATOR_RESULT_WORK_OFFSET],r9
    mov [rcx+NEBO_OPERATOR_RESULT_LIMIT_OFFSET],r11
    mov [rcx+NEBO_OPERATOR_RESULT_CLASS_OFFSET],r8
    mov rax,[rdi+NEBO_OPERATOR_BENCH_CORPUS_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_BENCH_COMPILER_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_BENCH_OPTIONS_OFFSET]
    xor rax,[rdi+NEBO_OPERATOR_BENCH_TARGET_OFFSET]
    xor rax,rsi
    xor rax,[rcx+NEBO_OPERATOR_RESULT_INPUT_OFFSET]
    xor rax,r9
    mov [rcx+NEBO_OPERATOR_RESULT_DIGEST_OFFSET],rax
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_benchmark_compare
    ; rdi=current, rsi=baseline, rdx=noise tolerance, rcx=class out.
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rcx,rcx
    jz .invalid
    mov r8,[rdi+NEBO_OPERATOR_RESULT_WORK_OFFSET]
    mov r9,[rsi+NEBO_OPERATOR_RESULT_WORK_OFFSET]
    mov rax,r9
    add rax,rdx
    jc .invalid
    cmp r8,rax
    ja .regression
    mov rax,r8
    add rax,rdx
    jc .invalid
    cmp rax,r9
    jb .improvement
    mov qword [rcx],NEBO_OPERATOR_PERF_INCONCLUSIVE
    xor eax,eax
    ret
.regression:
    mov qword [rcx],NEBO_OPERATOR_PERF_REGRESSION
    xor eax,eax
    ret
.improvement:
    mov qword [rcx],NEBO_OPERATOR_PERF_IMPROVEMENT
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_benchmark_manifest
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp qword [rdi+NEBO_OPERATOR_BENCH_ACTIVE_OFFSET],1
    jne .invalid
    mov rcx,6
.manifest_copy:
    mov rax,[rdi]
    mov [rsi],rax
    add rdi,8
    add rsi,8
    loop .manifest_copy
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_benchmark_close
    test rdi,rdi
    jz .invalid
    xor eax,eax
    mov rcx,NEBO_OPERATOR_BENCH_SIZE/8
    rep stosq
    xor eax,eax
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
