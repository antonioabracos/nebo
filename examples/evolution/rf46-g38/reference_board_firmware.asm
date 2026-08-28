; Simulator-only reference firmware payload. It has no OS, libc or ambient service.
bits 64
default rel
section .data
firmware_boot_count dq 1
section .bss
firmware_last_status resq 1
section .text
global _nebo_firmware_main
_nebo_firmware_main:
    mov rax,[firmware_boot_count]
    mov [firmware_last_status],rax
    xor eax,eax
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
