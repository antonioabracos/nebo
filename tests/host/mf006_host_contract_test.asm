; MF006 executable HostServices/FakeHost conformance suite.

bits 64
default rel

%include "compiler/host/contracts/host_services.inc"
%include "compiler/support/status/status_codes.inc"
%include "tests/fake-host/fake_host.inc"

extern nebo_fake_host_services
extern nebo_fake_host_context
extern nebo_fake_host_reset
extern neboc_host_validate
extern neboc_host_memory_reserve
extern neboc_host_file_open_read
extern neboc_host_read_complete
extern neboc_host_open_read_with_diagnostic
extern neboc_host_temp_create
extern neboc_host_temp_remove
extern neboc_host_process_spawn
extern neboc_host_process_wait
extern neboc_host_monotonic_time
extern neboc_host_process_exit

global _start

section .text

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .usage
    mov rsi, [rsp + 16]
    mov al, [rsi]
    sub al, '0'
    cmp al, 1
    jb .usage
    cmp al, 8
    ja .usage
    movzx eax, al
    lea rdx, [rel scenario_table]
    mov rax, [rdx + rax * 8 - 8]
    call rax
    mov edi, eax
    jmp neboc_host_process_exit
.usage:
    mov edi, 99
    jmp neboc_host_process_exit

scenario_1:
    sub rsp, 8
    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    mov esi, NEBOC_HOST_CAP_ALL
    call neboc_host_validate
    add rsp, 8
    ret

scenario_2:
    sub rsp, 40
    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel fixture_path]
    mov edx, fixture_path_length
    lea rcx, [rsp]
    call neboc_host_file_open_read
    test eax, eax
    jnz .fail_1
    lea rdi, [rel nebo_fake_host_services]
    mov rsi, [rsp]
    lea rdx, [rsp + 16]
    mov ecx, 16
    lea r8, [rsp + 8]
    call neboc_host_read_complete
    test eax, eax
    jnz .fail_2
    cmp qword [rsp + 8], 8
    jne .fail_3
    mov rax, 0x54534f484f42454e
    cmp [rsp + 16], rax
    jne .fail_4
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_READ_CALLS_OFFSET], 4
    jne .fail_5
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 21
    jmp .done
.fail_2:
    mov eax, 22
    jmp .done
.fail_3:
    mov eax, 23
    jmp .done
.fail_4:
    mov eax, 24
    jmp .done
.fail_5:
    mov eax, 25
.done:
    add rsp, 40
    ret

scenario_3:
    sub rsp, 8
    call nebo_fake_host_reset
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_FILE_OPEN
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel missing_path]
    mov edx, missing_path_length
    lea rcx, [rsp]
    call neboc_host_open_read_with_diagnostic
    cmp eax, NEBOC_STATUS_IO_ERROR
    jne .fail_1
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_DIAGNOSTIC_COUNT_OFFSET], 1
    jne .fail_2
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_LAST_DIAGNOSTIC_OFFSET], NEBOC_STATUS_IO_ERROR
    jne .fail_3
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 31
    jmp .done
.fail_2:
    mov eax, 32
    jmp .done
.fail_3:
    mov eax, 33
.done:
    add rsp, 8
    ret

scenario_4:
    sub rsp, 8
    call nebo_fake_host_reset
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_MEMORY_RESERVE
    lea rdi, [rel nebo_fake_host_services]
    mov esi, 64
    lea rdx, [rsp]
    call neboc_host_memory_reserve
    cmp eax, NEBOC_STATUS_OUT_OF_MEMORY
    jne .fail
    cmp qword [rsp], 0
    jne .fail
    xor eax, eax
    jmp .done
.fail:
    mov eax, 41
.done:
    add rsp, 8
    ret

scenario_5:
    sub rsp, 8
    call nebo_fake_host_reset
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_PROCESS_SPAWN
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel security_request]
    lea rdx, [rsp]
    call neboc_host_process_spawn
    cmp eax, NEBOC_STATUS_IO_ERROR
    jne .fail_1

    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel security_request]
    lea rdx, [rsp]
    call neboc_host_process_spawn
    test eax, eax
    jnz .fail_2
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_LAST_ARGC_OFFSET], 2
    jne .fail_3
    lea rax, [rel security_argv]
    cmp [rel nebo_fake_host_context + NEBOC_FAKE_LAST_ARGV_POINTER_OFFSET], rax
    jne .fail_4
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_TEMP_ACTIVE_OFFSET], 0
    jne .fail_5
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 51
    jmp .done
.fail_2:
    mov eax, 52
    jmp .done
.fail_3:
    mov eax, 53
    jmp .done
.fail_4:
    mov eax, 54
    jmp .done
.fail_5:
    mov eax, 55
.done:
    add rsp, 8
    ret

scenario_6:
    sub rsp, 40
    call nebo_fake_host_reset
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PROCESS_STDOUT_LENGTH_OFFSET], 40
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PROCESS_STDERR_LENGTH_OFFSET], 40
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel limited_request]
    lea rdx, [rsp]
    call neboc_host_process_spawn
    test eax, eax
    jnz .fail_1
    lea rdi, [rel nebo_fake_host_services]
    mov rsi, [rsp]
    lea rdx, [rsp + 8]
    call neboc_host_process_wait
    cmp eax, NEBOC_STATUS_LIMIT_EXCEEDED
    jne .fail_2
    cmp qword [rsp + 8 + NEBOC_PROCESS_RESULT_STDOUT_LENGTH_OFFSET], 40
    jne .fail_3
    cmp qword [rsp + 8 + NEBOC_PROCESS_RESULT_STDERR_LENGTH_OFFSET], 40
    jne .fail_4
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 61
    jmp .done
.fail_2:
    mov eax, 62
    jmp .done
.fail_3:
    mov eax, 63
    jmp .done
.fail_4:
    mov eax, 64
.done:
    add rsp, 40
    ret

scenario_7:
    sub rsp, 24
    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel temp_prefix]
    mov edx, temp_prefix_length
    lea rcx, [rsp]
    call neboc_host_temp_create
    test eax, eax
    jnz .fail_1
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rel temp_prefix]
    mov edx, temp_prefix_length
    lea rcx, [rsp + 8]
    call neboc_host_temp_create
    test eax, eax
    jnz .fail_2
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_TEMP_ACTIVE_OFFSET], 2
    jne .fail_3
    lea rdi, [rel nebo_fake_host_services]
    mov rsi, [rsp]
    call neboc_host_temp_remove
    test eax, eax
    jnz .fail_4
    lea rdi, [rel nebo_fake_host_services]
    mov rsi, [rsp + 8]
    call neboc_host_temp_remove
    test eax, eax
    jnz .fail_5
    cmp qword [rel nebo_fake_host_context + NEBOC_FAKE_TEMP_ACTIVE_OFFSET], 0
    jne .fail_6
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 71
    jmp .done
.fail_2:
    mov eax, 72
    jmp .done
.fail_3:
    mov eax, 73
    jmp .done
.fail_4:
    mov eax, 74
    jmp .done
.fail_5:
    mov eax, 75
    jmp .done
.fail_6:
    mov eax, 76
.done:
    add rsp, 24
    ret

scenario_8:
    sub rsp, 40
    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rsp]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_1
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rsp + 8]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_2
    cmp qword [rsp], 1000
    jne .fail_3
    cmp qword [rsp + 8], 1010
    jne .fail_4
    call nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rsp + 16]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_5
    lea rdi, [rel nebo_fake_host_services]
    lea rsi, [rsp + 24]
    call neboc_host_monotonic_time
    test eax, eax
    jnz .fail_6
    mov rax, [rsp]
    cmp [rsp + 16], rax
    jne .fail_7
    mov rax, [rsp + 8]
    cmp [rsp + 24], rax
    jne .fail_8
    xor eax, eax
    jmp .done
.fail_1:
    mov eax, 81
    jmp .done
.fail_2:
    mov eax, 82
    jmp .done
.fail_3:
    mov eax, 83
    jmp .done
.fail_4:
    mov eax, 84
    jmp .done
.fail_5:
    mov eax, 85
    jmp .done
.fail_6:
    mov eax, 86
    jmp .done
.fail_7:
    mov eax, 87
    jmp .done
.fail_8:
    mov eax, 88
.done:
    add rsp, 40
    ret

section .rodata
align 8
scenario_table:
    dq scenario_1, scenario_2, scenario_3, scenario_4
    dq scenario_5, scenario_6, scenario_7, scenario_8

fixture_path: db "fixture.no", 0
fixture_path_length equ $ - fixture_path - 1
missing_path: db "missing.no", 0
missing_path_length equ $ - missing_path - 1
temp_prefix: db "nebo-mf006", 0
temp_prefix_length equ $ - temp_prefix - 1

security_arg0: db "/usr/bin/printf", 0
security_arg0_length equ $ - security_arg0 - 1
security_arg1: db "safe;touch SHOULD_NOT_EXIST", 0
security_arg1_length equ $ - security_arg1 - 1
align 8
security_argv:
    dq security_arg0, security_arg0_length
    dq security_arg1, security_arg1_length
security_request:
    dq security_argv
    dq 2
    dq 0
    dq 0
    dq process_stdout
    dq 128
    dq process_stderr
    dq 128
    dq 256
limited_request:
    dq security_argv
    dq 2
    dq 0
    dq 0
    dq process_stdout
    dq 64
    dq process_stderr
    dq 64
    dq 64

section .bss align=16
process_stdout: resb 128
process_stderr: resb 128

section .note.GNU-stack noalloc noexec nowrite progbits
