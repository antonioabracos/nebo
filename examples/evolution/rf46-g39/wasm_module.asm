; RESOLVER-TYPECHECKER-E-SEMANTICA-F01 bounded native composition example.
bits 64
default rel
%include "runtime/portable/wasm_module.inc"
extern nebo_wasm_validate
section .data
example_module db 0x00,0x61,0x73,0x6d,1,0,0,0, 1,1,0
example_module_size equ $-example_module
section .bss
example_report resb NEBO_WASM_MODULE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_module]
    mov esi,example_module_size
    lea rdx,[example_report]
    call nebo_wasm_validate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
