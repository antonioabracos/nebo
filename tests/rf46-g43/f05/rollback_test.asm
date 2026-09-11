; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F05 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/simulation/rollback.inc"
extern nebo_rollback_evaluate
section .data
records dq 33,66,99,132
invalid_record dq 1131073
descending dq 2,1
section .bss
report resb NEBO_ROLLBACK_REPORT_SIZE
max_records resq NEBO_ROLLBACK_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_rollback_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_ROLLBACK_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_ROLLBACK_REPORT_SUM],330
    jne fail
    mov rax,0xd5c4296faf7af02c
    cmp [report+NEBO_ROLLBACK_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_ROLLBACK_REPORT_MIN],33
    jne fail
    cmp qword [report+NEBO_ROLLBACK_REPORT_MAX],132
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_rollback_evaluate
    cmp eax,NEBO_ROLLBACK_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_rollback_evaluate
    cmp eax,NEBO_ROLLBACK_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_rollback_evaluate
    cmp eax,NEBO_ROLLBACK_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_ROLLBACK_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_rollback_evaluate
    cmp eax,NEBO_ROLLBACK_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_ROLLBACK_MAX_RECORDS
    lea rdx,[report]
    call nebo_rollback_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_rollback_evaluate
    cmp eax,NEBO_ROLLBACK_STATUS_ORDER
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
