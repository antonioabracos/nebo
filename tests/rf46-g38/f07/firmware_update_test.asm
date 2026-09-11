; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F07 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/embedded/firmware_update.inc"
extern nebo_firmware_update_evaluate
section .data
records dq 8,16,24,32
invalid_record dq 1028673
descending dq 2,1
section .bss
report resb NEBO_FIRMWARE_UPDATE_REPORT_SIZE
max_records resq NEBO_FIRMWARE_UPDATE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_FIRMWARE_UPDATE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_FIRMWARE_UPDATE_REPORT_SUM],80
    jne fail
    mov rax,0x6f6b6766fe7227c2
    cmp [report+NEBO_FIRMWARE_UPDATE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_FIRMWARE_UPDATE_REPORT_MIN],8
    jne fail
    cmp qword [report+NEBO_FIRMWARE_UPDATE_REPORT_MAX],32
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    cmp eax,NEBO_FIRMWARE_UPDATE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    cmp eax,NEBO_FIRMWARE_UPDATE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    cmp eax,NEBO_FIRMWARE_UPDATE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_FIRMWARE_UPDATE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    cmp eax,NEBO_FIRMWARE_UPDATE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_FIRMWARE_UPDATE_MAX_RECORDS
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_firmware_update_evaluate
    cmp eax,NEBO_FIRMWARE_UPDATE_STATUS_ORDER
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
