; Nebo Assembly — SourceFile and safe read-all v0
;
; Purpose:
;   Read one source through HostServices, preserve bytes, validate strict UTF-8,
;   enforce UTF-8-without-BOM and retain only a stable logical path.
;
; Inputs:
;   RDI = SourceFile*, RSI = SourceLoadRequest*.
;
; Outputs:
;   SourceFile fields and StatusCode in EAX.
;
; Status:
;   OK, INVALID_ARGUMENT, IO_ERROR, INVALID_SOURCE or LIMIT_EXCEEDED.
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
;   Logical path/content are Arena-owned. The physical path is never retained.
;
; Thread safety:
;   Mutation requires the request owner token and current Arena generation.
;
; Errors:
;   Failure stores a minimal diagnostic code and byte offset without absolutes.
;
; Tests:
;   NEBO-SOURCE-GOLDEN-001, NEBO-SOURCE-NEG-002,
;   NEBO-SOURCE-NEG-003 and NEBO-SOURCE-NEG-007.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/limits/compilation_limits.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/utf8/utf8.inc"
%include "compiler/source/file/source_file.inc"

extern neboc_arena_validate
extern neboc_arena_allocate
extern neboc_host_file_open_read
extern neboc_host_file_read_all
extern neboc_host_file_close
extern neboc_hash_fnv1a32
extern neboc_utf8_validate

section .text

; logical_path_validate(bytes*, length)
NEBOC_ABI_FUNCTION neboc_source_logical_path_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, NEBOC_SOURCE_LOGICAL_PATH_MAX_BYTES
    ja .invalid
    mov al, [rdi]
    cmp al, '/'
    je .invalid
    cmp al, 92
    je .invalid
    cmp byte [rdi + rsi - 1], '/'
    je .invalid
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .ok
    mov al, [rdi + rcx]
    test al, al
    jz .invalid
    cmp al, 92
    je .invalid
    inc rcx
    jmp .loop
.ok:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_file_validate(source*, owner)
NEBOC_ABI_FUNCTION neboc_source_file_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [rdi + NEBOC_SOURCE_FILE_OWNER_OFFSET], rsi
    jne .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_LOGICAL_PATH_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_LOGICAL_LENGTH_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_CONTENT_OFFSET], 0
    je .invalid
    mov rax, [rdi + NEBOC_SOURCE_FILE_CONTENT_LENGTH_OFFSET]
    cmp rax, [rdi + NEBOC_SOURCE_FILE_LIMIT_OFFSET]
    ja .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_STATUS_OFFSET], NEBOC_STATUS_OK
    jne .invalid
    cmp qword [rdi + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_NONE
    jne .invalid
    mov r8, [rdi + NEBOC_SOURCE_FILE_ARENA_OFFSET]
    test r8, r8
    jz .invalid
    cmp qword [r8 + NEBOC_ARENA_ACTIVE_OFFSET], 1
    jne .invalid
    cmp [r8 + NEBOC_ARENA_OWNER_OFFSET], rsi
    jne .invalid
    mov rax, [r8 + NEBOC_ARENA_GENERATION_OFFSET]
    cmp [rdi + NEBOC_SOURCE_FILE_ARENA_GENERATION_OFFSET], rax
    jne .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_file_reset(source*, owner)
NEBOC_ABI_FUNCTION neboc_source_file_reset
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_SOURCE_FILE_OWNER_OFFSET], rsi
    jne .invalid
    mov r8, [rdi + NEBOC_SOURCE_FILE_GENERATION_OFFSET]
    inc r8
    jnz .generation_ready
    mov r8d, 1
.generation_ready:
    xor eax, eax
    mov ecx, NEBOC_SOURCE_FILE_QWORDS
    cld
    rep stosq
    mov [rdi - NEBOC_SOURCE_FILE_SIZE + NEBOC_SOURCE_FILE_GENERATION_OFFSET], r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_file_load(source*, request*)
NEBOC_ABI_FUNCTION neboc_source_file_load
    test rdi, rdi
    jz .invalid_fast
    test rsi, rsi
    jz .invalid_fast
    cmp qword [rdi + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0
    jne .invalid_fast

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48

    mov rbx, rdi
    mov r12, rsi
    mov r13, [r12 + NEBOC_SOURCE_REQUEST_OWNER_OFFSET]
    xor r14d, r14d
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_NONE
    mov qword [rsp], -1
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0

    test r13, r13
    jz .invalid_request
    cmp qword [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET], 0
    je .invalid_request
    cmp qword [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET], 0
    je .invalid_request
    cmp qword [r12 + NEBOC_SOURCE_REQUEST_PHYSICAL_PATH_OFFSET], 0
    je .invalid_request
    cmp qword [r12 + NEBOC_SOURCE_REQUEST_PHYSICAL_LENGTH_OFFSET], 0
    je .invalid_request
    cmp qword [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_PATH_OFFSET], 0
    je .invalid_request
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    test rax, rax
    jz .invalid_request
    cmp rax, NEBOC_LIMIT_DEFAULT_SOURCE_BYTES
    ja .invalid_request

    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET]
    mov rsi, r13
    call neboc_arena_validate
    test eax, eax
    jne .status_no_diagnostic

    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_PATH_OFFSET]
    mov rsi, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET]
    call neboc_source_logical_path_validate
    test eax, eax
    jne .invalid_logical_path

    ; Copy stable logical path plus NUL into the Arena.
    mov rsi, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET]
    inc rsi
    jc .limit_failure
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET]
    mov edx, 1
    mov rcx, r13
    lea r8, [rsp + 16]
    call neboc_arena_allocate
    test eax, eax
    jne .status_no_diagnostic
    mov rdi, [rsp + 16]
    mov rsi, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_PATH_OFFSET]
    mov rcx, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET]
    cld
    rep movsb
    mov byte [rdi], 0

    ; Initialize failure-visible stable fields; physical path is omitted.
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov [rbx + NEBOC_SOURCE_FILE_HOST_OFFSET], rax
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET]
    mov [rbx + NEBOC_SOURCE_FILE_ARENA_OFFSET], rax
    mov [rbx + NEBOC_SOURCE_FILE_OWNER_OFFSET], r13
    mov rax, [rsp + 16]
    mov [rbx + NEBOC_SOURCE_FILE_LOGICAL_PATH_OFFSET], rax
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LOGICAL_LENGTH_OFFSET]
    mov [rbx + NEBOC_SOURCE_FILE_LOGICAL_LENGTH_OFFSET], rax
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    mov [rbx + NEBOC_SOURCE_FILE_LIMIT_OFFSET], rax
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET]
    mov rax, [rax + NEBOC_ARENA_GENERATION_OFFSET]
    mov [rbx + NEBOC_SOURCE_FILE_ARENA_GENERATION_OFFSET], rax
    mov qword [rbx + NEBOC_SOURCE_FILE_STATUS_OFFSET], NEBOC_STATUS_OK
    mov qword [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_NONE
    mov qword [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], 0
    mov qword [rbx + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0

    ; Allocate limit+1 bytes so an exact-limit source can be distinguished
    ; from an oversized source without file-size or stat dependencies.
    mov rsi, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    inc rsi
    jc .limit_failure
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_ARENA_OFFSET]
    mov edx, 1
    mov rcx, r13
    lea r8, [rsp + 8]
    call neboc_arena_allocate
    test eax, eax
    jne .status_no_diagnostic

    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov rsi, [r12 + NEBOC_SOURCE_REQUEST_PHYSICAL_PATH_OFFSET]
    mov rdx, [r12 + NEBOC_SOURCE_REQUEST_PHYSICAL_LENGTH_OFFSET]
    lea rcx, [rsp]
    call neboc_host_file_open_read
    test eax, eax
    jne .open_failure

.read_next:
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    inc rax
    sub rax, [rsp + 24]
    jz .oversize
    mov qword [rsp + 32], 0
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov rsi, [rsp]
    mov rdx, [rsp + 8]
    add rdx, [rsp + 24]
    mov rcx, rax
    lea r8, [rsp + 32]
    call neboc_host_file_read_all
    test eax, eax
    jne .read_failure_close
    mov rax, [rsp + 32]
    test rax, rax
    jz .read_complete
    add [rsp + 24], rax
    jc .read_failure_close
    mov rax, [rsp + 24]
    cmp rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    ja .oversize_close
    jmp .read_next

.read_complete:
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov rsi, [rsp]
    call neboc_host_file_close
    test eax, eax
    jne .read_failure
    mov qword [rsp], -1

    ; UTF-8 BOM is forbidden by CORE-002.
    cmp qword [rsp + 24], NEBOC_UTF8_BOM_SIZE
    jb .validate_utf8
    mov rax, [rsp + 8]
    cmp byte [rax], NEBOC_UTF8_BOM_BYTE_0
    jne .validate_utf8
    cmp byte [rax + 1], NEBOC_UTF8_BOM_BYTE_1
    jne .validate_utf8
    cmp byte [rax + 2], NEBOC_UTF8_BOM_BYTE_2
    jne .validate_utf8
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_BOM_FORBIDDEN
    mov qword [rsp + 40], 0
    jmp .record_failure

.validate_utf8:
    mov rdi, [rsp + 8]
    mov rsi, [rsp + 24]
    lea rdx, [rsp + 40]
    call neboc_utf8_validate
    test eax, eax
    jne .invalid_utf8

    mov rdi, [rsp + 8]
    mov rsi, [rsp + 24]
    lea rdx, [rsp + 40]
    call neboc_hash_fnv1a32
    test eax, eax
    jne .status_no_diagnostic

    mov rax, [rsp + 8]
    mov [rbx + NEBOC_SOURCE_FILE_CONTENT_OFFSET], rax
    mov rax, [rsp + 24]
    mov [rbx + NEBOC_SOURCE_FILE_CONTENT_LENGTH_OFFSET], rax
    mov rax, [rsp + 40]
    mov [rbx + NEBOC_SOURCE_FILE_CONTENT_HASH_OFFSET], rax
    mov qword [rbx + NEBOC_SOURCE_FILE_STATUS_OFFSET], NEBOC_STATUS_OK
    mov qword [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], NEBOC_SOURCE_DIAGNOSTIC_NONE
    mov qword [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], 0
    mov qword [rbx + NEBOC_SOURCE_FILE_FLAGS_OFFSET], NEBOC_SOURCE_FILE_FLAG_NONE
    mov qword [rbx + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 1
    mov rax, [rbx + NEBOC_SOURCE_FILE_GENERATION_OFFSET]
    inc rax
    jnz .store_generation
    mov eax, 1
.store_generation:
    mov [rbx + NEBOC_SOURCE_FILE_GENERATION_OFFSET], rax
    xor eax, eax
    jmp .finish

.invalid_utf8:
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_INVALID_UTF8
    jmp .record_failure
.open_failure:
    mov r14d, NEBOC_STATUS_IO_ERROR
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_OPEN_FAILED
    mov qword [rsp + 40], 0
    jmp .record_failure
.read_failure_close:
    mov r14d, NEBOC_STATUS_IO_ERROR
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_READ_FAILED
    jmp .close_then_record
.oversize_close:
    mov r14d, NEBOC_STATUS_LIMIT_EXCEEDED
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_LIMIT_EXCEEDED
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    mov [rsp + 40], rax
.close_then_record:
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov rsi, [rsp]
    call neboc_host_file_close
    mov qword [rsp], -1
    jmp .record_failure
.oversize:
    mov r14d, NEBOC_STATUS_LIMIT_EXCEEDED
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_LIMIT_EXCEEDED
    mov rax, [r12 + NEBOC_SOURCE_REQUEST_LIMIT_OFFSET]
    mov [rsp + 40], rax
    jmp .close_then_record
.read_failure:
    mov r14d, NEBOC_STATUS_IO_ERROR
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_READ_FAILED
    mov qword [rsp + 40], 0
    jmp .record_failure
.limit_failure:
    mov r14d, NEBOC_STATUS_LIMIT_EXCEEDED
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_LIMIT_EXCEEDED
    mov qword [rsp + 40], 0
    jmp .record_failure
.invalid_logical_path:
    mov r14d, NEBOC_STATUS_INVALID_ARGUMENT
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_INVALID_LOGICAL_PATH
    mov qword [rsp + 40], 0
    jmp .record_failure_minimal
.invalid_request:
    mov r14d, NEBOC_STATUS_INVALID_ARGUMENT
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_NONE
    mov qword [rsp + 40], 0
    jmp .record_failure_minimal
.status_no_diagnostic:
    mov r14d, eax
    mov r15d, NEBOC_SOURCE_DIAGNOSTIC_NONE
    mov qword [rsp + 40], 0
.record_failure:
    mov [rbx + NEBOC_SOURCE_FILE_STATUS_OFFSET], r14
    mov [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], r15
    mov rax, [rsp + 40]
    mov [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], rax
    mov qword [rbx + NEBOC_SOURCE_FILE_CONTENT_OFFSET], 0
    mov qword [rbx + NEBOC_SOURCE_FILE_CONTENT_LENGTH_OFFSET], 0
    mov qword [rbx + NEBOC_SOURCE_FILE_CONTENT_HASH_OFFSET], 0
    mov qword [rbx + NEBOC_SOURCE_FILE_ACTIVE_OFFSET], 0
    mov eax, r14d
    jmp .finish
.record_failure_minimal:
    mov [rbx + NEBOC_SOURCE_FILE_STATUS_OFFSET], r14
    mov [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET], r15
    mov rax, [rsp + 40]
    mov [rbx + NEBOC_SOURCE_FILE_DIAGNOSTIC_OFFSET_OFFSET], rax
    mov eax, r14d
.finish:
    cmp qword [rsp], -1
    je .restore
    mov r14d, eax
    mov rdi, [r12 + NEBOC_SOURCE_REQUEST_HOST_OFFSET]
    mov rsi, [rsp]
    call neboc_host_file_close
    mov eax, r14d
.restore:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid_fast:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
