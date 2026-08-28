; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F05 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/dma_timer_watchdog.inc"
extern nebo_dma_timer_watchdog_evaluate
section .data
example_records dq 6,12,18,24
section .bss
example_report resb NEBO_DMA_TIMER_WATCHDOG_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_dma_timer_watchdog_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
