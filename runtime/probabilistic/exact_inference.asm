; PLUGINS-FFI-E-EXTENSIBILIDADE-F03 bounded exact enumeration over finite integer-weight states.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/exact_inference.inc"
section .text
; rdi=positive u64 state weights, rsi=count, rdx=query index, rcx=report.
NEBOC_ABI_FUNCTION nebo_prob_exact_enumerate_u64
    test rdi,rdi
    jz .invalid
    test rcx,rcx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_INFER_MAX_STATES
    ja .limit
    cmp rdx,rsi
    jae .invalid
    xor r8d,r8d
    xor r9d,r9d
.sum:
    mov rax,[rdi+r9*8]
    test rax,rax
    jz .invalid
    add r8,rax
    jc .limit
    mov rax,NEBO_INFER_MAX_EXACT_F64_SUM
    cmp r8,rax
    ja .limit
    inc r9
    cmp r9,rsi
    jb .sum
    mov r10,[rdi+rdx*8]
    mov [rcx+NEBO_INFER_REPORT_TOTAL_WEIGHT],r8
    mov [rcx+NEBO_INFER_REPORT_QUERY_WEIGHT],r10
    mov [rcx+NEBO_INFER_REPORT_STATE_COUNT],rsi
    cvtsi2sd xmm0,r10
    cvtsi2sd xmm1,r8
    divsd xmm0,xmm1
    movsd [rcx+NEBO_INFER_REPORT_MARGINAL],xmm0
    xor eax,eax
    ret
.invalid: mov eax,NEBO_INFER_INVALID
    ret
.limit: mov eax,NEBO_INFER_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
