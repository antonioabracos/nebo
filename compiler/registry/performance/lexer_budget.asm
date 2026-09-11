; G147-S02 bounded lexer/trie/DFA/Unicode work accounting.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION benchmarkOperatorLexer
    ; rdi=source bytes, rsi=ASCII operators, rdx=Unicode operators, rcx=report.
    test rcx,rcx
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,NEBO_OPERATOR_PERF_MAX_INPUT
    ja .limit
    mov r8,rsi
    add r8,rdx
    jc .limit
    cmp r8,rdi
    ja .invalid
    mov r9,rsi
    shl r9,1
    lea r10,[rdx+rdx*4]
    add r9,r10
    add r9,rdi
    mov [rcx+NEBO_OPERATOR_LEXER_BYTES_OFFSET],rdi
    mov [rcx+NEBO_OPERATOR_LEXER_ASCII_OFFSET],rsi
    mov [rcx+NEBO_OPERATOR_LEXER_UNICODE_OFFSET],rdx
    mov [rcx+NEBO_OPERATOR_LEXER_TOKENS_OFFSET],r8
    mov [rcx+NEBO_OPERATOR_LEXER_WORK_OFFSET],r9
    mov qword [rcx+NEBO_OPERATOR_LEXER_DFA_STATES_OFFSET],3
    xor eax,eax
    ret
.limit:
    mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_registry_lexer_budget
    ; rdi=input bytes, rsi=max work units, rdx=work output. Atomic on failure.
    test rdx,rdx
    jz .invalid
    test rdi,rdi
    jz .invalid
    cmp rdi,1048576
    ja .limit
    lea rax,[rdi+rdi*2+17]
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
