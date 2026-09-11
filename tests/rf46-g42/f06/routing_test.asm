; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F06 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/routing.inc"
extern nebo_routing_evaluate
section .data
records dq 27,54,81,108
invalid_record dq 1106497
descending dq 2,1
section .bss
report resb NEBO_ROUTING_REPORT_SIZE
max_records resq NEBO_ROUTING_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_routing_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_ROUTING_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_ROUTING_REPORT_SUM],270
    jne fail
    mov rax,0x6c772aa7d1d7bde7
    cmp [report+NEBO_ROUTING_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_ROUTING_REPORT_MIN],27
    jne fail
    cmp qword [report+NEBO_ROUTING_REPORT_MAX],108
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_routing_evaluate
    cmp eax,NEBO_ROUTING_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_routing_evaluate
    cmp eax,NEBO_ROUTING_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_routing_evaluate
    cmp eax,NEBO_ROUTING_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_ROUTING_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_routing_evaluate
    cmp eax,NEBO_ROUTING_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_ROUTING_MAX_RECORDS
    lea rdx,[report]
    call nebo_routing_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_routing_evaluate
    cmp eax,NEBO_ROUTING_STATUS_ORDER
    jne fail
    mov rax,0x8877665544332211
    cmp [report],rax
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
