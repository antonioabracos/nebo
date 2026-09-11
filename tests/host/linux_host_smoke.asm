; Native smoke for the capability-limited Linux HostServices adapter.

bits 64
default rel

%include "compiler/host/contracts/host_services.inc"
%include "compiler/support/status/status_codes.inc"

extern neboc_linux_host_services
extern neboc_host_validate
extern neboc_host_memory_reserve
extern neboc_host_memory_release
extern neboc_host_temp_create
extern neboc_host_temp_remove
extern neboc_host_monotonic_time
extern neboc_host_process_exit

global _start

section .text
_start:
    sub rsp, 48
    lea rdi, [rel neboc_linux_host_services]
    mov esi, NEBOC_HOST_CAP_LINUX_V0
    call neboc_host_validate
    test eax, eax
    jnz .fail_1

    lea rdi, [rel neboc_linux_host_services]
    mov esi, 4096
    lea rdx, [rsp]
    call neboc_host_memory_reserve
    test eax, eax
    jnz .fail_2
    mov rax, 0x4e45424f484f5354
    mov r10, [rsp]
    mov [r10], rax
    cmp [r10], rax
    jne .fail_3
    lea rdi, [rel neboc_linux_host_services]
    mov rsi, [rsp]
    mov edx, 4096
    call neboc_host_memory_release
    test eax, eax
    jnz .fail_4

    lea rdi, [rel neboc_linux_host_services]
    lea rsi, [rel temp_name]
    mov edx, temp_name_length
    lea rcx, [rsp + 8]
    call neboc_host_temp_create
    test eax, eax
    jnz .fail_5
    lea rdi, [rel neboc_linux_host_services]
    mov rsi, [rsp + 8]
    call neboc_host_temp_remove
    test eax, eax
    jnz .fail_6

    lea rdi, [rel neboc_linux_host_services]
    lea rsi, [rsp + 16]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_7
    lea rdi, [rel neboc_linux_host_services]
    lea rsi, [rsp + 24]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_8
    mov rax, [rsp + 16]
    cmp [rsp + 24], rax
    jb .fail_9

    xor edi, edi
    jmp .exit
.fail_1: mov edi, 1
    jmp .exit
.fail_2: mov edi, 2
    jmp .exit
.fail_3: mov edi, 3
    jmp .exit
.fail_4: mov edi, 4
    jmp .exit
.fail_5: mov edi, 5
    jmp .exit
.fail_6: mov edi, 6
    jmp .exit
.fail_7: mov edi, 7
    jmp .exit
.fail_8: mov edi, 8
    jmp .exit
.fail_9: mov edi, 9
.exit:
    add rsp, 48
    jmp neboc_host_process_exit

section .rodata
temp_name: db "nebo-mf006", 0
temp_name_length equ $ - temp_name - 1

section .note.GNU-stack noalloc noexec nowrite progbits
