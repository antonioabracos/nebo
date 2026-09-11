; G147-S08 whole-group performance/conformance closeout.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/registry/performance/operator_performance.inc"
section .text
NEBOC_ABI_FUNCTION nebo_operator_performance_closeout
    ; rdi=array of eight evidence tokens, rsi=count, rdx=report.
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rsi,8
    jne .invalid
    xor r8d,r8d
    xor r9d,r9d
    xor r10d,r10d
.scan:
    mov rax,[rdi+r8*8]
    test rax,rax
    jz .missing
    bts r9,r8
    rol r10,9
    xor r10,rax
.next:
    inc r8
    cmp r8,8
    jb .scan
    mov [rdx+NEBO_OPERATOR_CLOSEOUT_PASSED_OFFSET],r9
    mov qword [rdx+NEBO_OPERATOR_CLOSEOUT_APPLICABLE_OFFSET],0xff
    mov qword [rdx+NEBO_OPERATOR_CLOSEOUT_FAILURES_OFFSET],0
    cmp r9,0xff
    je .closed
    mov qword [rdx+NEBO_OPERATOR_CLOSEOUT_FAILURES_OFFSET],1
.closed:
    mov qword [rdx+NEBO_OPERATOR_CLOSEOUT_REGISTRY_ROWS_OFFSET],0
    mov qword [rdx+NEBO_OPERATOR_CLOSEOUT_OWNERS_OFFSET],8
    mov [rdx+NEBO_OPERATOR_CLOSEOUT_DIGEST_OFFSET],r10
    xor eax,eax
    ret
.missing:
    jmp .next
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_operator_performance_audit
    test rdi,rdi
    jz .invalid
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_PASSED_OFFSET],0xff
    jne .source
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_APPLICABLE_OFFSET],0xff
    jne .source
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_FAILURES_OFFSET],0
    jne .source
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_REGISTRY_ROWS_OFFSET],0
    jne .source
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_OWNERS_OFFSET],8
    jne .source
    cmp qword [rdi+NEBO_OPERATOR_CLOSEOUT_DIGEST_OFFSET],0
    je .source
    xor eax,eax
    ret
.source:
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    ret
.invalid:
    mov eax,NEBOC_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
