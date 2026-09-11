bits 64
default rel
%include "compiler/parser/console_arguments.inc"
%include "compiler/semantic/console_calls.inc"
extern neboc_console_factory_validate
global _start
section .text
_start:
    lea rdi, [rel bounded]
    lea rsi, [rel proof]
    call neboc_console_factory_validate
    test eax, eax
    jnz fail
    cmp qword [rel proof + NEBOC_FACTORY_PROOF_INVOCATIONS_OFFSET], 4
    jne fail
    lea rdi, [rel unbounded]
    lea rsi, [rel untouched]
    call neboc_console_factory_validate
    cmp eax, NEBOC_OPTION_FACTORY_UNBOUNDED
    jne fail
    lea rdi, [rel excessive]
    lea rsi, [rel untouched]
    call neboc_console_factory_validate
    cmp eax, NEBOC_OPTION_FACTORY_UNBOUNDED
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
factory: xor eax, eax
    ret
section .data
bounded: dq factory, 4, 1024, 4
unbounded: dq factory, 0, 1024, 4
excessive: dq factory, 4, NEBOC_MAX_OPTION_BUILD_STEPS + 1, 4
untouched: times NEBOC_FACTORY_PROOF_SIZE db 0xaa
section .bss
proof: resb NEBOC_FACTORY_PROOF_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
