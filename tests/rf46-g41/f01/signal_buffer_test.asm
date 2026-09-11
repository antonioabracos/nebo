; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F01 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/robotics/signal_buffer.inc"
extern nebo_signal_buffer_evaluate
section .data
records dq 15,30,45,60
invalid_record dq 1057345
descending dq 2,1
section .bss
report resb NEBO_SIGNAL_BUFFER_REPORT_SIZE
max_records resq NEBO_SIGNAL_BUFFER_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_SIGNAL_BUFFER_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_SIGNAL_BUFFER_REPORT_SUM],150
    jne fail
    mov rax,0x3c4585aa98be56a4
    cmp [report+NEBO_SIGNAL_BUFFER_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_SIGNAL_BUFFER_REPORT_MIN],15
    jne fail
    cmp qword [report+NEBO_SIGNAL_BUFFER_REPORT_MAX],60
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    cmp eax,NEBO_SIGNAL_BUFFER_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    cmp eax,NEBO_SIGNAL_BUFFER_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    cmp eax,NEBO_SIGNAL_BUFFER_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_SIGNAL_BUFFER_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    cmp eax,NEBO_SIGNAL_BUFFER_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_SIGNAL_BUFFER_MAX_RECORDS
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_signal_buffer_evaluate
    cmp eax,NEBO_SIGNAL_BUFFER_STATUS_ORDER
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
