; MF010 Linux adapter smoke for default CompilationSession ownership/cleanup.

bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/support/limits/compilation_limits.inc"
%include "compiler/session/compilation_session.inc"

%define TEST_OWNER 0x4c494e5558534553

extern neboc_linux_host_services
extern neboc_compilation_session_init
extern neboc_compilation_session_validate
extern neboc_compilation_session_check_limit
extern neboc_compilation_session_fail
extern neboc_compilation_session_destroy
extern neboc_host_process_exit

global _start

section .bss align=16
linux_session: resb NEBOC_COMPILATION_SESSION_SIZE

section .text
_start:
    lea rdi, [rel linux_session]
    xor eax, eax
    mov ecx, NEBOC_COMPILATION_SESSION_QWORDS
    rep stosq
    lea rdi, [rel linux_session]
    lea rsi, [rel neboc_linux_host_services]
    mov rdx, TEST_OWNER
    call neboc_compilation_session_init
    test eax, eax
    jnz .exit
    lea rdi, [rel linux_session]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_validate
    test eax, eax
    jnz .fail_1
    lea rdi, [rel linux_session]
    mov esi, NEBOC_RESOURCE_SOURCE_BYTES
    mov edx, 1
    mov rcx, TEST_OWNER
    call neboc_compilation_session_check_limit
    test eax, eax
    jnz .fail_2
    lea rdi, [rel linux_session]
    mov esi, NEBOC_STATUS_INVALID_SOURCE
    mov rdx, TEST_OWNER
    call neboc_compilation_session_fail
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne .fail_3
    cmp qword [rel linux_session + NEBOC_SESSION_RESOURCES_ACTIVE_OFFSET], 0
    jne .fail_4
    lea rdi, [rel linux_session]
    mov rsi, TEST_OWNER
    call neboc_compilation_session_destroy
    test eax, eax
    jnz .fail_5
    xor eax, eax
.exit:
    mov edi, eax
    jmp neboc_host_process_exit
.fail_1: mov eax, 1
    jmp .exit
.fail_2: mov eax, 2
    jmp .exit
.fail_3: mov eax, 3
    jmp .exit
.fail_4: mov eax, 4
    jmp .exit
.fail_5: mov eax, 5
    jmp .exit

section .note.GNU-stack noalloc noexec nowrite progbits
