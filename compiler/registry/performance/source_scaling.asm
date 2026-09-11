; G147-S05 bounded source/Unicode/template/diagnostic scaling.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION benchmarkOperatorSourceScaling
    ; rdi=bytes, rsi=Unicode scalars, rdx=templates, rcx=diagnostics, r8=report.
    test r8,r8
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,NEBO_OPERATOR_PERF_MAX_INPUT
    ja .limit
    cmp rsi,rdi
    ja .invalid
    cmp rdx,65536
    ja .limit
    cmp rcx,4096
    ja .limit
    mov r9,rsi
    shl r9,2
    lea r10,[rdx*8]
    sub r10,rdx
    add r9,r10
    lea r10,[rcx+rcx*2]
    lea r10,[r10+rcx*8]
    add r9,r10
    add r9,rdi
    mov [r8+NEBO_OPERATOR_SOURCE_BYTES_OFFSET],rdi
    mov [r8+NEBO_OPERATOR_SOURCE_UNICODE_OFFSET],rsi
    mov [r8+NEBO_OPERATOR_SOURCE_TEMPLATES_OFFSET],rdx
    mov [r8+NEBO_OPERATOR_SOURCE_DIAGNOSTICS_OFFSET],rcx
    mov [r8+NEBO_OPERATOR_SOURCE_WORK_OFFSET],r9
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_registry_source_scaling
    test rdx,rdx
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,NEBO_OPERATOR_PERF_MAX_INPUT
    ja .limit
    lea rax,[rdi+rdi*2+61]
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
