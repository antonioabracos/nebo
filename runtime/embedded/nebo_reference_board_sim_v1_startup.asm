; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F01 deterministic startup and vector contract for the simulator-only board.
bits 64
default rel
extern _nebo_firmware_main
extern __stack_top
extern __data_load
extern __data_start
extern __data_end
extern __bss_start
extern __bss_end

section .vectors align=16
global _nebo_vector_table
_nebo_vector_table:
    dq _nebo_board_reset
    times 15 dq _nebo_board_fault

section .text.startup
global _nebo_board_reset
_nebo_board_reset:
    cli
    cld
    mov rsp,__stack_top
    and rsp,-16
    lea rsi,[__data_load]
    lea rdi,[__data_start]
    lea rcx,[__data_end]
    sub rcx,rdi
    rep movsb
    lea rdi,[__bss_start]
    lea rcx,[__bss_end]
    sub rcx,rdi
    xor eax,eax
    rep stosb
    call _nebo_firmware_main
_nebo_board_halt:
    cli
    hlt
    jmp _nebo_board_halt

global _nebo_board_fault
_nebo_board_fault:
    cli
    hlt
    jmp _nebo_board_fault

section .note.GNU-stack noalloc noexec nowrite progbits
