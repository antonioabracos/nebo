; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F02 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/embedded/mmio_trace.inc"
extern nebo_mmio_trace_evaluate
section .data
records dq 3,6,9,12
invalid_record dq 1008193
section .bss
report resb NEBO_MMIO_TRACE_REPORT_SIZE
max_records resq NEBO_MMIO_TRACE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_MMIO_TRACE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_MMIO_TRACE_REPORT_SUM],30
    jne fail
    mov rax,0x289d03353db42abb
    cmp [report+NEBO_MMIO_TRACE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_MMIO_TRACE_REPORT_MIN],3
    jne fail
    cmp qword [report+NEBO_MMIO_TRACE_REPORT_MAX],12
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    cmp eax,NEBO_MMIO_TRACE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    cmp eax,NEBO_MMIO_TRACE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    cmp eax,NEBO_MMIO_TRACE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_MMIO_TRACE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    cmp eax,NEBO_MMIO_TRACE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_MMIO_TRACE_MAX_RECORDS
    lea rdx,[report]
    call nebo_mmio_trace_evaluate
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
