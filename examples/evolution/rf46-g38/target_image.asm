; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F01 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/target_image.inc"
extern nebo_target_image_evaluate
section .data
example_records dq 2,4,6,8
section .bss
example_report resb NEBO_TARGET_IMAGE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_target_image_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
