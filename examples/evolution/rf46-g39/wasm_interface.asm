; RESOLVER-TYPECHECKER-E-SEMANTICA-F02 bounded native composition example.
bits 64
default rel
%include "runtime/portable/wasm_interface.inc"
extern nebo_wasm_interface_evaluate
section .data
example_records dq 10,20,30,40
section .bss
example_report resb NEBO_WASM_INTERFACE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_wasm_interface_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
