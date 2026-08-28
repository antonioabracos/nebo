; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F07 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/firmware_update.inc"
extern nebo_firmware_update_evaluate
section .data
example_records dq 8,16,24,32
section .bss
example_report resb NEBO_FIRMWARE_UPDATE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_firmware_update_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
