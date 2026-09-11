; RESOLVER-TYPECHECKER-E-SEMANTICA-F06 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/portability.inc"
extern nebo_portability_evaluate
section .data
records dq 14,28,42,56
invalid_record dq 1053249
section .bss
report resb NEBO_PORTABILITY_REPORT_SIZE
max_records resq NEBO_PORTABILITY_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_portability_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_PORTABILITY_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_PORTABILITY_REPORT_SUM],140
    jne fail
    mov rax,0xc8aab8111515ac5b
    cmp [report+NEBO_PORTABILITY_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_PORTABILITY_REPORT_MIN],14
    jne fail
    cmp qword [report+NEBO_PORTABILITY_REPORT_MAX],56
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_portability_evaluate
    cmp eax,NEBO_PORTABILITY_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_portability_evaluate
    cmp eax,NEBO_PORTABILITY_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_portability_evaluate
    cmp eax,NEBO_PORTABILITY_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_PORTABILITY_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_portability_evaluate
    cmp eax,NEBO_PORTABILITY_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_PORTABILITY_MAX_RECORDS
    lea rdx,[report]
    call nebo_portability_evaluate
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
