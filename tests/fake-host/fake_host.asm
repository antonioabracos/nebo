; Nebo Assembly — deterministic FakeHost for HostServices v0
;
; Purpose:
;   Provide programmable memory, file, process, clock, diagnostic and temp
;   behavior without OS calls.
;
; Inputs:
;   HostServices v0 arguments and mutable fake context.
;
; Outputs:
;   StatusCode plus deterministic result payloads and trace counters.
;
; Status:
;   Programmed failures map to OOM, IO_ERROR or LIMIT_EXCEEDED.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   No red-zone dependency; no executable stack.
;
; Ownership:
;   Fake buffers remain owned by FakeHost.
;
; Thread safety:
;   One mutable fake context per test process.
;
; Errors:
;   No syscall, shell, process or filesystem side effect exists.
;
; Tests:
;   All eight MF006 primary HostServices tests.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/host/contracts/host_services.inc"
%include "tests/fake-host/fake_host.inc"

global nebo_fake_host_services
global nebo_fake_host_context
global nebo_fake_host_reset

section .data
align 16
nebo_fake_host_services:
    dq NEBOC_HOST_SERVICES_VERSION
    dq NEBOC_HOST_SERVICES_SIZE
    dq NEBOC_HOST_CAP_ALL
    dq nebo_fake_host_context
    dq nebo_fake_memory_reserve
    dq nebo_fake_memory_release
    dq nebo_fake_file_open_read
    dq nebo_fake_file_read_all
    dq nebo_fake_file_write_all
    dq nebo_fake_file_close
    dq nebo_fake_path_normalize
    dq nebo_fake_temp_create
    dq nebo_fake_temp_remove
    dq nebo_fake_process_spawn
    dq nebo_fake_process_wait
    dq nebo_fake_monotonic_time
    dq nebo_fake_diagnostic_write
    dq nebo_fake_process_exit

section .rodata
fake_file_data: db "NEBOHOST"
fake_file_data_length equ $ - fake_file_data

section .bss align=16
nebo_fake_host_context: resb NEBOC_FAKE_CONTEXT_SIZE
%if (NEBOC_FAKE_CONTEXT_SIZE % 16) != 0
    resb 16 - (NEBOC_FAKE_CONTEXT_SIZE % 16)
%endif
fake_memory: resb 4096

section .text

NEBOC_ABI_FUNCTION nebo_fake_host_reset
    lea rdi, [rel nebo_fake_host_context]
    xor eax, eax
    mov ecx, NEBOC_FAKE_CONTEXT_SIZE / 8
    rep stosq
    lea rax, [rel fake_file_data]
    mov [rel nebo_fake_host_context + NEBOC_FAKE_FILE_DATA_POINTER_OFFSET], rax
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_FILE_DATA_LENGTH_OFFSET], fake_file_data_length
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PARTIAL_CHUNK_OFFSET], 2
    lea rax, [rel fake_memory]
    mov [rel nebo_fake_host_context + NEBOC_FAKE_MEMORY_POINTER_OFFSET], rax
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_MEMORY_CAPACITY_OFFSET], 4096
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_NEXT_TEMP_HANDLE_OFFSET], 1
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_CLOCK_NOW_OFFSET], 1000
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_CLOCK_STEP_OFFSET], 10
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PROCESS_STDOUT_LENGTH_OFFSET], 4
    mov qword [rel nebo_fake_host_context + NEBOC_FAKE_PROCESS_STDERR_LENGTH_OFFSET], 2
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK

NEBOC_ABI_FUNCTION nebo_fake_memory_reserve
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rdx, rdx
    jz .invalid
    test qword [r9 + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_MEMORY_RESERVE
    jnz .oom
    test rsi, rsi
    jz .invalid
    cmp rsi, [r9 + NEBOC_FAKE_MEMORY_CAPACITY_OFFSET]
    ja .oom
    cmp qword [r9 + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 0
    jne .oom
    mov rax, [r9 + NEBOC_FAKE_MEMORY_POINTER_OFFSET]
    mov [rdx], rax
    mov qword [r9 + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 1
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.oom:
    mov qword [rdx], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OUT_OF_MEMORY
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_memory_release
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    cmp rsi, [r9 + NEBOC_FAKE_MEMORY_POINTER_OFFSET]
    jne .invalid
    mov qword [r9 + NEBOC_FAKE_MEMORY_ACTIVE_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_file_open_read
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rcx, rcx
    jz .invalid
    test qword [r9 + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_FILE_OPEN
    jnz .io_error
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov qword [r9 + NEBOC_FAKE_FILE_CURSOR_OFFSET], 0
    mov qword [r9 + NEBOC_FAKE_FILE_OPEN_OFFSET], 1
    mov qword [rcx], 1
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    mov qword [rcx], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_file_read_all
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rdx, rdx
    jz .invalid
    test r8, r8
    jz .invalid
    mov qword [r8], 0
    cmp rsi, 1
    jne .io_error
    cmp qword [r9 + NEBOC_FAKE_FILE_OPEN_OFFSET], 1
    jne .io_error
    mov r10, [r9 + NEBOC_FAKE_FILE_DATA_LENGTH_OFFSET]
    sub r10, [r9 + NEBOC_FAKE_FILE_CURSOR_OFFSET]
    jz .ok
    test rcx, rcx
    jz .limit
    mov r11, [r9 + NEBOC_FAKE_PARTIAL_CHUNK_OFFSET]
    test r11, r11
    jnz .chunk_nonzero
    mov r11, r10
.chunk_nonzero:
    cmp r11, r10
    cmova r11, r10
    cmp r11, rcx
    cmova r11, rcx
    mov rsi, [r9 + NEBOC_FAKE_FILE_DATA_POINTER_OFFSET]
    add rsi, [r9 + NEBOC_FAKE_FILE_CURSOR_OFFSET]
    mov rdi, rdx
    mov rcx, r11
    rep movsb
    add [r9 + NEBOC_FAKE_FILE_CURSOR_OFFSET], r11
    inc qword [r9 + NEBOC_FAKE_READ_CALLS_OFFSET]
    mov [r8], r11
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.io_error:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_file_write_all
    test r8, r8
    jz .invalid
    mov [r8], rcx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_file_close
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    cmp rsi, 1
    jne .invalid
    mov qword [r9 + NEBOC_FAKE_FILE_OPEN_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_path_normalize
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    mov [rcx + NEBOC_HOST_SLICE_POINTER_OFFSET], rsi
    mov [rcx + NEBOC_HOST_SLICE_LENGTH_OFFSET], rdx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_temp_create
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rcx, rcx
    jz .invalid
    mov rax, [r9 + NEBOC_FAKE_NEXT_TEMP_HANDLE_OFFSET]
    mov [rcx], rax
    inc qword [r9 + NEBOC_FAKE_NEXT_TEMP_HANDLE_OFFSET]
    inc qword [r9 + NEBOC_FAKE_TEMP_ACTIVE_OFFSET]
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_temp_remove
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rsi, rsi
    jz .invalid
    cmp qword [r9 + NEBOC_FAKE_TEMP_ACTIVE_OFFSET], 0
    je .invalid
    dec qword [r9 + NEBOC_FAKE_TEMP_ACTIVE_OFFSET]
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_process_spawn
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rdx, rdx
    jz .invalid_no_output
    test rsi, rsi
    jz .invalid
    test qword [r9 + NEBOC_FAKE_FAIL_MASK_OFFSET], NEBOC_FAKE_FAIL_PROCESS_SPAWN
    jnz .io_error
    mov rax, [rsi + NEBOC_PROCESS_REQUEST_ARGC_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, NEBOC_PROCESS_REQUEST_MAX_ARGS
    ja .limit
    mov r10, [rsi + NEBOC_PROCESS_REQUEST_ARGV_OFFSET]
    test r10, r10
    jz .invalid
    mov rcx, rax
.validate_args:
    cmp qword [r10 + NEBOC_HOST_ARG_POINTER_OFFSET], 0
    je .invalid
    add r10, NEBOC_HOST_ARG_SIZE
    loop .validate_args
    mov [r9 + NEBOC_FAKE_PROCESS_REQUEST_OFFSET], rsi
    mov rax, [rsi + NEBOC_PROCESS_REQUEST_ARGV_OFFSET]
    mov [r9 + NEBOC_FAKE_LAST_ARGV_POINTER_OFFSET], rax
    mov rax, [rsi + NEBOC_PROCESS_REQUEST_ARGC_OFFSET]
    mov [r9 + NEBOC_FAKE_LAST_ARGC_OFFSET], rax
    mov qword [r9 + NEBOC_FAKE_PROCESS_SPAWNED_OFFSET], 1
    mov qword [r9 + NEBOC_FAKE_PROCESS_WAITED_OFFSET], 0
    mov qword [rdx], 1
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    mov qword [rdx], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.limit:
    mov qword [rdx], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid:
    mov qword [rdx], 0
.invalid_no_output:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_process_wait
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp rsi, 1
    jne .invalid
    cmp qword [r9 + NEBOC_FAKE_PROCESS_SPAWNED_OFFSET], 1
    jne .invalid
    mov r10, [r9 + NEBOC_FAKE_PROCESS_REQUEST_OFFSET]
    mov rax, [r9 + NEBOC_FAKE_PROCESS_STDOUT_LENGTH_OFFSET]
    mov [rdx + NEBOC_PROCESS_RESULT_STDOUT_LENGTH_OFFSET], rax
    mov r11, [r9 + NEBOC_FAKE_PROCESS_STDERR_LENGTH_OFFSET]
    mov [rdx + NEBOC_PROCESS_RESULT_STDERR_LENGTH_OFFSET], r11
    mov rcx, [r9 + NEBOC_FAKE_PROCESS_EXIT_CODE_OFFSET]
    mov [rdx + NEBOC_PROCESS_RESULT_EXIT_CODE_OFFSET], rcx
    mov qword [rdx + NEBOC_PROCESS_RESULT_TERM_SIGNAL_OFFSET], 0
    add rax, r11
    cmp rax, [r10 + NEBOC_PROCESS_REQUEST_MAX_OUTPUT_OFFSET]
    ja .limit
    mov rax, [r9 + NEBOC_FAKE_PROCESS_STDOUT_LENGTH_OFFSET]
    cmp rax, [r10 + NEBOC_PROCESS_REQUEST_STDOUT_CAPACITY_OFFSET]
    ja .limit
    mov rax, [r9 + NEBOC_FAKE_PROCESS_STDERR_LENGTH_OFFSET]
    cmp rax, [r10 + NEBOC_PROCESS_REQUEST_STDERR_CAPACITY_OFFSET]
    ja .limit
    mov qword [r9 + NEBOC_FAKE_PROCESS_WAITED_OFFSET], 1
    mov qword [r9 + NEBOC_FAKE_PROCESS_SPAWNED_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.limit:
    mov qword [r9 + NEBOC_FAKE_PROCESS_WAITED_OFFSET], 1
    mov qword [r9 + NEBOC_FAKE_PROCESS_SPAWNED_OFFSET], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_monotonic_time
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    test rsi, rsi
    jz .invalid
    mov rax, [r9 + NEBOC_FAKE_CLOCK_NOW_OFFSET]
    mov [rsi], rax
    add rax, [r9 + NEBOC_FAKE_CLOCK_STEP_OFFSET]
    mov [r9 + NEBOC_FAKE_CLOCK_NOW_OFFSET], rax
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION nebo_fake_diagnostic_write
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    inc qword [r9 + NEBOC_FAKE_DIAGNOSTIC_COUNT_OFFSET]
    mov [r9 + NEBOC_FAKE_LAST_DIAGNOSTIC_OFFSET], rsi
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK

NEBOC_ABI_FUNCTION nebo_fake_process_exit
    mov r9, [rdi + NEBOC_HOST_SERVICES_CONTEXT_OFFSET]
    mov [r9 + NEBOC_FAKE_EXIT_STATUS_OFFSET], rsi
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK

section .note.GNU-stack noalloc noexec nowrite progbits
