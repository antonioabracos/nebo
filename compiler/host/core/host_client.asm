; Nebo Assembly — OS-independent HostServices client
;
; Purpose:
;   Validate and dispatch versioned HostServices calls without OS imports.
;
; Inputs:
;   Per-function arguments follow NEBOC_INTERNAL_ABI_v0.
;
; Outputs:
;   StatusCode in EAX and explicit result payloads.
;
; Status:
;   INVALID_ARGUMENT for malformed tables; UNSUPPORTED_TARGET for absent slots.
;
; Clobbers:
;   Caller-saved registers and flags.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   16-byte aligned before every internal CALL; no red-zone dependency.
;
; Ownership:
;   All objects remain owned by the caller or selected adapter.
;
; Thread safety:
;   Reentrant when the selected HostServices context is reentrant.
;
; Errors:
;   No syscall, dynamic loader or shell fallback exists in this module.
;
; Tests:
;   NEBO-HOST-CONTRACT-001 through NEBO-HOST-DETERMINISM-008.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/host/contracts/host_services.inc"

section .text

NEBOC_ABI_FUNCTION neboc_host_validate
    test rdi, rdi
    jz .invalid
    cmp qword [rdi + NEBOC_HOST_SERVICES_VERSION_OFFSET], NEBOC_HOST_SERVICES_VERSION
    jne .invalid
    cmp qword [rdi + NEBOC_HOST_SERVICES_SIZE_OFFSET], NEBOC_HOST_SERVICES_SIZE
    jb .invalid
    mov rax, [rdi + NEBOC_HOST_SERVICES_CAPABILITIES_OFFSET]
    and rax, rsi
    cmp rax, rsi
    jne .unsupported
    mov ecx, NEBOC_HOST_SERVICES_MEMORY_RESERVE_OFFSET
.check_slots:
    cmp ecx, NEBOC_HOST_SERVICES_SIZE
    jae .ok
    cmp qword [rdi + rcx], 0
    je .unsupported
    add ecx, 8
    jmp .check_slots
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.unsupported:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET

%macro NEBOC_HOST_DISPATCH 2
NEBOC_ABI_FUNCTION %1
    test rdi, rdi
    jz %%invalid
    cmp qword [rdi + NEBOC_HOST_SERVICES_VERSION_OFFSET], NEBOC_HOST_SERVICES_VERSION
    jne %%invalid
    cmp qword [rdi + NEBOC_HOST_SERVICES_SIZE_OFFSET], NEBOC_HOST_SERVICES_SIZE
    jb %%invalid
    mov rax, [rdi + %2]
    test rax, rax
    jz %%unsupported
    sub rsp, 8
    call rax
    add rsp, 8
    cld
    ret
%%invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%%unsupported:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
%endmacro

NEBOC_HOST_DISPATCH neboc_host_memory_reserve, NEBOC_HOST_SERVICES_MEMORY_RESERVE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_memory_release, NEBOC_HOST_SERVICES_MEMORY_RELEASE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_file_open_read, NEBOC_HOST_SERVICES_FILE_OPEN_READ_OFFSET
NEBOC_HOST_DISPATCH neboc_host_file_read_all, NEBOC_HOST_SERVICES_FILE_READ_ALL_OFFSET
NEBOC_HOST_DISPATCH neboc_host_file_write_all, NEBOC_HOST_SERVICES_FILE_WRITE_ALL_OFFSET
NEBOC_HOST_DISPATCH neboc_host_file_close, NEBOC_HOST_SERVICES_FILE_CLOSE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_path_normalize, NEBOC_HOST_SERVICES_PATH_NORMALIZE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_temp_create, NEBOC_HOST_SERVICES_TEMP_CREATE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_temp_remove, NEBOC_HOST_SERVICES_TEMP_REMOVE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_process_spawn, NEBOC_HOST_SERVICES_PROCESS_SPAWN_OFFSET
NEBOC_HOST_DISPATCH neboc_host_process_wait, NEBOC_HOST_SERVICES_PROCESS_WAIT_OFFSET
NEBOC_HOST_DISPATCH neboc_host_monotonic_time, NEBOC_HOST_SERVICES_MONOTONIC_TIME_OFFSET
NEBOC_HOST_DISPATCH neboc_host_diagnostic_write, NEBOC_HOST_SERVICES_DIAGNOSTIC_WRITE_OFFSET
NEBOC_HOST_DISPATCH neboc_host_service_process_exit, NEBOC_HOST_SERVICES_PROCESS_EXIT_OFFSET

; Reads until EOF through repeated bounded HostServices reads.
NEBOC_ABI_FUNCTION neboc_host_read_complete
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    xor r15d, r15d
    mov [rsp + 8], r8

.read_next:
    cmp r15, r14
    je .limit
    mov qword [rsp], 0
    mov rdi, rbx
    mov rsi, r12
    lea rdx, [r13 + r15]
    mov rcx, r14
    sub rcx, r15
    lea r8, [rsp]
    call neboc_host_file_read_all
    test eax, eax
    jne .finish_status
    mov rax, [rsp]
    test rax, rax
    jz .success
    mov rdx, r14
    sub rdx, r15
    cmp rax, rdx
    ja .internal_error
    add r15, rax
    jmp .read_next

.success:
    xor r11d, r11d
    jmp .finish
.limit:
    mov r11d, NEBOC_STATUS_LIMIT_EXCEEDED
    jmp .finish
.internal_error:
    mov r11d, NEBOC_STATUS_INTERNAL_ERROR
    jmp .finish
.finish_status:
    mov r11d, eax
.finish:
    mov r10, [rsp + 8]
    test r10, r10
    jz .restore
    mov [r10], r15
.restore:
    mov eax, r11d
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

; Converts an open failure into status + diagnostic through the same table.
NEBOC_ABI_FUNCTION neboc_host_open_read_with_diagnostic
    push rbx
    push r12
    push r13
    mov rbx, rdi
    call neboc_host_file_open_read
    test eax, eax
    jz .done
    mov r12d, eax
    mov rdi, rbx
    mov esi, r12d
    lea rdx, [rel .open_failed]
    mov ecx, .open_failed_length
    call neboc_host_diagnostic_write
    mov eax, r12d
.done:
    pop r13
    pop r12
    pop rbx
    cld
    ret

section .rodata
.open_failed: db "host file open failed"
.open_failed_length equ $ - .open_failed

section .note.GNU-stack noalloc noexec nowrite progbits
