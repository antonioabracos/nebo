; Nebo Assembly — Linux x86-64 HostServices adapter v0
;
; Purpose:
;   Provide the first approved host adapter strictly behind HostServices v0.
;
; Inputs:
;   RDI always points to the versioned HostServices table.
;
; Outputs:
;   StatusCode in EAX and explicit result payloads.
;
; Status:
;   Process spawn/wait return UNSUPPORTED_TARGET in this capability-limited v0.
;
; Clobbers:
;   Caller-saved registers and Linux syscall clobbers RCX/R11.
;
; Preserved:
;   RBX, RBP, R12, R13, R14, R15 and RSP.
;
; Stack:
;   No red-zone dependency; no executable stack.
;
; Ownership:
;   mmap/memfd/file handles transfer according to each service contract.
;
; Thread safety:
;   Reentrant; no mutable global state.
;
; Errors:
;   Linux errno values are translated to internal StatusCode values.
;
; Tests:
;   scripts/mf006/validate.sh and linux_host_smoke.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/host/contracts/host_services.inc"

extern neboc_host_process_exit

global neboc_linux_host_services

section .data
align 16
neboc_linux_host_services:
    dq NEBOC_HOST_SERVICES_VERSION
    dq NEBOC_HOST_SERVICES_SIZE
    dq NEBOC_HOST_CAP_LINUX_V0
    dq 0
    dq neboc_linux_memory_reserve
    dq neboc_linux_memory_release
    dq neboc_linux_file_open_read
    dq neboc_linux_file_read_all
    dq neboc_linux_file_write_all
    dq neboc_linux_file_close
    dq neboc_linux_path_normalize
    dq neboc_linux_temp_create
    dq neboc_linux_temp_remove
    dq neboc_linux_process_spawn
    dq neboc_linux_process_wait
    dq neboc_linux_monotonic_time
    dq neboc_linux_diagnostic_write
    dq neboc_linux_process_exit

section .text

NEBOC_ABI_FUNCTION neboc_linux_memory_reserve
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    push r12
    mov r12, rdx
    xor edi, edi
    mov edx, 3
    mov r10d, 0x22
    mov r8, -1
    xor r9d, r9d
    mov eax, 9
    syscall
    cmp rax, -4095
    jae .oom
    mov [r12], rax
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.oom:
    mov qword [r12], 0
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OUT_OF_MEMORY
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_memory_release
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov rdi, rsi
    mov rsi, rdx
    mov eax, 11
    syscall
    test rax, rax
    js .io_error
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_file_open_read
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    push r12
    mov r12, rcx
    mov rdi, -100
    xor edx, edx
    xor r10d, r10d
    mov eax, 257
    syscall
    cmp rax, -4095
    jae .io_error
    mov [r12], rax
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    mov qword [r12], -1
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_file_read_all
    test rdx, rdx
    jz .invalid
    test r8, r8
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    xor ebx, ebx
    mov qword [r15], 0
.read_loop:
    cmp rbx, r14
    jae .ok
    xor eax, eax
    mov rdi, r12
    lea rsi, [r13 + rbx]
    mov rdx, r14
    sub rdx, rbx
    syscall
    test rax, rax
    jz .ok
    js .read_error
    add rbx, rax
    jmp .read_loop
.read_error:
    cmp rax, -4
    je .read_loop
    mov [r15], rbx
    mov r11d, NEBOC_STATUS_IO_ERROR
    jmp .finish
.ok:
    mov [r15], rbx
    xor r11d, r11d
.finish:
    mov eax, r11d
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_file_write_all
    test rdx, rdx
    jz .invalid
    test r8, r8
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    xor ebx, ebx
    mov qword [r15], 0
.write_loop:
    cmp rbx, r14
    jae .ok
    mov eax, 1
    mov rdi, r12
    lea rsi, [r13 + rbx]
    mov rdx, r14
    sub rdx, rbx
    syscall
    test rax, rax
    jz .io_error
    js .write_error
    add rbx, rax
    jmp .write_loop
.write_error:
    cmp rax, -4
    je .write_loop
.io_error:
    mov [r15], rbx
    mov r11d, NEBOC_STATUS_IO_ERROR
    jmp .finish
.ok:
    mov [r15], rbx
    xor r11d, r11d
.finish:
    mov eax, r11d
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_file_close
    mov rdi, rsi
    mov eax, 3
    syscall
    test rax, rax
    js .io_error
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR

NEBOC_ABI_FUNCTION neboc_linux_path_normalize
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    mov [rcx + NEBOC_HOST_SLICE_POINTER_OFFSET], rsi
    mov [rcx + NEBOC_HOST_SLICE_LENGTH_OFFSET], rdx
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_temp_create
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    push r12
    mov r12, rcx
    mov rdi, rsi
    mov esi, 1
    mov eax, 319
    syscall
    cmp rax, -4095
    jae .io_error
    mov [r12], rax
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    mov qword [r12], -1
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_temp_remove
    mov rdi, rsi
    mov eax, 3
    syscall
    test rax, rax
    js .io_error
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR

NEBOC_ABI_FUNCTION neboc_linux_process_spawn
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_process_wait
    test rdx, rdx
    jz .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_UNSUPPORTED_TARGET
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_monotonic_time
    test rsi, rsi
    jz .invalid
    push r12
    mov r12, rsi
    sub rsp, 16
    mov edi, 1
    mov rsi, rsp
    mov eax, 228
    syscall
    test rax, rax
    js .io_error
    mov rax, [rsp]
    imul rax, rax, 1000000000
    add rax, [rsp + 8]
    mov [r12], rax
    add rsp, 16
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.io_error:
    add rsp, 16
    pop r12
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_IO_ERROR
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_diagnostic_write
    test rdx, rdx
    jz .invalid
    push rbx
    push r12
    push r13
    mov r12, rdx
    mov r13, rcx
    xor ebx, ebx
.write_loop:
    cmp rbx, r13
    jae .ok
    mov eax, 1
    mov edi, 2
    lea rsi, [r12 + rbx]
    mov rdx, r13
    sub rdx, rbx
    syscall
    test rax, rax
    jz .io_error
    js .write_error
    add rbx, rax
    jmp .write_loop
.write_error:
    cmp rax, -4
    je .write_loop
.io_error:
    mov r11d, NEBOC_STATUS_IO_ERROR
    jmp .finish
.ok:
    xor r11d, r11d
.finish:
    mov eax, r11d
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_linux_process_exit
    mov edi, esi
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
