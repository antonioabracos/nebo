; MF007 Linux x86-64 memory region smoke test.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/memory_region.inc"
%include "compiler/support/memory/arena.inc"

extern neboc_linux_host_services
extern neboc_memory_region_init
extern neboc_memory_region_destroy
extern neboc_arena_init
extern neboc_arena_allocate
extern neboc_arena_destroy
extern neboc_host_process_exit

global _start

%define LINUX_MEMORY_OWNER 0x4c4d3037

section .text

_start:
    sub rsp, 8
    lea rdi, [rel linux_region]
    lea rsi, [rel neboc_linux_host_services]
    mov edx, 4096
    mov ecx, 4096
    mov r8d, LINUX_MEMORY_OWNER
    call neboc_memory_region_init
    test eax, eax
    jnz .fail_init

    lea rdi, [rel linux_arena]
    lea rsi, [rel linux_region]
    mov edx, 4096
    mov ecx, LINUX_MEMORY_OWNER
    call neboc_arena_init
    test eax, eax
    jnz .fail_arena

    lea rdi, [rel linux_arena]
    mov esi, 32
    mov edx, 32
    mov ecx, LINUX_MEMORY_OWNER
    lea r8, [rel linux_pointer]
    call neboc_arena_allocate
    test eax, eax
    jnz .fail_allocate
    mov rax, [rel linux_pointer]
    test rax, 31
    jnz .fail_alignment
    mov qword [rax], 0x4e45424f
    cmp qword [rax], 0x4e45424f
    jne .fail_memory

    lea rdi, [rel linux_arena]
    mov esi, LINUX_MEMORY_OWNER
    call neboc_arena_destroy
    test eax, eax
    jnz .fail_destroy_arena

    lea rdi, [rel linux_region]
    mov esi, LINUX_MEMORY_OWNER
    call neboc_memory_region_destroy
    test eax, eax
    jnz .fail_destroy_region

    xor edi, edi
    jmp .exit
.fail_init: mov edi, 1
    jmp .exit
.fail_arena: mov edi, 2
    jmp .exit
.fail_allocate: mov edi, 3
    jmp .exit
.fail_alignment: mov edi, 4
    jmp .exit
.fail_memory: mov edi, 5
    jmp .exit
.fail_destroy_arena: mov edi, 6
    jmp .exit
.fail_destroy_region: mov edi, 7
.exit:
    add rsp, 8
    jmp neboc_host_process_exit

section .bss align=16
linux_region: resb NEBOC_MEMORY_REGION_SIZE
linux_arena: resb NEBOC_ARENA_SIZE
linux_pointer: resq 1

section .note.GNU-stack noalloc noexec nowrite progbits
