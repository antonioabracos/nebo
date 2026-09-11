; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F05 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/embedded/dma_timer_watchdog.inc"
extern nebo_dma_timer_watchdog_evaluate
section .data
records dq 6,12,18,24
invalid_record dq 1020481
section .bss
report resb NEBO_DMA_TIMER_WATCHDOG_REPORT_SIZE
max_records resq NEBO_DMA_TIMER_WATCHDOG_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_DMA_TIMER_WATCHDOG_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_DMA_TIMER_WATCHDOG_REPORT_SUM],60
    jne fail
    mov rax,0xe1b197462eaf9ee0
    cmp [report+NEBO_DMA_TIMER_WATCHDOG_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_DMA_TIMER_WATCHDOG_REPORT_MIN],6
    jne fail
    cmp qword [report+NEBO_DMA_TIMER_WATCHDOG_REPORT_MAX],24
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
    cmp eax,NEBO_DMA_TIMER_WATCHDOG_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
    cmp eax,NEBO_DMA_TIMER_WATCHDOG_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
    cmp eax,NEBO_DMA_TIMER_WATCHDOG_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_DMA_TIMER_WATCHDOG_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
    cmp eax,NEBO_DMA_TIMER_WATCHDOG_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_DMA_TIMER_WATCHDOG_MAX_RECORDS
    lea rdx,[report]
    call nebo_dma_timer_watchdog_evaluate
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
