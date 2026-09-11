; G147-S03 bounded parser/precedence/binder work accounting.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION benchmarkOperatorParser
    ; rdi=tokens, rsi=nodes, rdx=binders, rcx=depth, r8=report.
    test r8,r8
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,262144
    ja .limit
    cmp rsi,rdi
    ja .invalid
    cmp rdx,rsi
    ja .invalid
    cmp rcx,256
    ja .limit
    mov r9,rdi
    shl r9,1
    lea r10,[rsi+rsi*2]
    add r9,r10
    lea r10,[rdx+rdx*4]
    add r9,r10
    mov r10,rcx
    imul r10,rcx
    add r9,r10
    mov [r8+NEBO_OPERATOR_PARSER_TOKENS_OFFSET],rdi
    mov [r8+NEBO_OPERATOR_PARSER_NODES_OFFSET],rsi
    mov [r8+NEBO_OPERATOR_PARSER_BINDERS_OFFSET],rdx
    mov [r8+NEBO_OPERATOR_PARSER_DEPTH_OFFSET],rcx
    mov [r8+NEBO_OPERATOR_PARSER_WORK_OFFSET],r9
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_registry_parser_budget
    test rdx,rdx
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,262144
    ja .limit
    lea rax,[rdi+rdi*2+31]
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
