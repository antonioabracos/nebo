; Canonical semantic metadata records for Nebo compiled interfaces.
;
; Record V1 (64 bytes):
;   +00 SymbolId                    qword
;   +08 declared effect mask         qword
;   +16 declared capability mask     qword
;   +24 ownership contract           dword (1..4)
;   +28 presence flags               dword (doc=1, dependency=2)
;   +32 semantic documentation digest qword
;   +40 dependency ModuleId          qword
;   +48 dependency API fingerprint   qword
;   +56 dependency ABI fingerprint   qword
;
; Capability bits are explicit metadata; dependency identity never adds bits.
; rdi=input, rsi=count, rdx=output, rcx=capacity. Exact in-place is allowed,
; partial overlap is rejected, and output is ordered strictly by SymbolId.
; Validation completes before the first output write.

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define METADATA_RECORD_BYTES 64
%define METADATA_MAX_RECORDS  1024
%define METADATA_EFFECT_MASK   0xff
%define METADATA_CAP_MASK      0xffff
%define METADATA_FLAG_DOC      1
%define METADATA_FLAG_DEP      2
%define METADATA_FLAG_MASK     3

%define METADATA_DIAG_ARGUMENT    1
%define METADATA_DIAG_COUNT       2
%define METADATA_DIAG_CAPACITY    3
%define METADATA_DIAG_OVERLAP     4
%define METADATA_DIAG_SYMBOL      5
%define METADATA_DIAG_EFFECT      6
%define METADATA_DIAG_CAPABILITY  7
%define METADATA_DIAG_OWNERSHIP   8
%define METADATA_DIAG_FLAGS       9
%define METADATA_DIAG_DOC         10
%define METADATA_DIAG_DEPENDENCY  11
%define METADATA_DIAG_DUPLICATE   12

section .text

NEBOC_ABI_FUNCTION neboc_interface_metadata_canonicalize
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, METADATA_RECORD_BYTES

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    cmp r13, METADATA_MAX_RECORDS
    ja .count
    test r13, r13
    jz .success
    test r12, r12
    jz .argument
    test r14, r14
    jz .argument
    test r12, 7
    jnz .argument
    test r14, 7
    jnz .argument
    cmp r15, r13
    jb .capacity

    mov rbx, r13
    shl rbx, 6
    lea rax, [r12 + rbx]
    cmp rax, r12
    jb .argument
    lea rcx, [r14 + rbx]
    cmp rcx, r14
    jb .argument
    cmp r12, r14
    je .validate
    cmp r12, rcx
    jae .validate
    cmp r14, rax
    jb .overlap

.validate:
    xor ebp, ebp
.validate_loop:
    cmp rbp, r13
    jae .copy
    mov r10, rbp
    shl r10, 6
    add r10, r12
    cmp qword [r10], 0
    je .symbol

    mov rax, qword [r10 + 8]
    mov rcx, rax
    and rcx, ~METADATA_EFFECT_MASK
    jnz .effect
    mov rax, qword [r10 + 16]
    mov rcx, rax
    and rcx, ~METADATA_CAP_MASK
    jnz .capability
    mov eax, dword [r10 + 24]
    test eax, eax
    jz .ownership
    cmp eax, 4
    ja .ownership
    mov edx, dword [r10 + 28]
    mov eax, edx
    and eax, ~METADATA_FLAG_MASK
    jnz .flags

    test edx, METADATA_FLAG_DOC
    jz .doc_absent
    cmp qword [r10 + 32], 0
    je .doc
    jmp .dependency_check
.doc_absent:
    cmp qword [r10 + 32], 0
    jne .doc

.dependency_check:
    test edx, METADATA_FLAG_DEP
    jz .dependency_absent
    cmp qword [r10 + 40], 0
    je .dependency
    cmp qword [r10 + 48], 0
    je .dependency
    cmp qword [r10 + 56], 0
    je .dependency
    jmp .duplicates
.dependency_absent:
    cmp qword [r10 + 40], 0
    jne .dependency
    cmp qword [r10 + 48], 0
    jne .dependency
    cmp qword [r10 + 56], 0
    jne .dependency

.duplicates:
    xor r9d, r9d
.duplicate_loop:
    cmp r9, rbp
    jae .record_valid
    mov rax, r9
    shl rax, 6
    mov rcx, qword [r12 + rax]
    cmp rcx, qword [r10]
    je .duplicate
    inc r9
    jmp .duplicate_loop
.record_valid:
    inc rbp
    jmp .validate_loop

.copy:
    cmp r12, r14
    je .sort
    mov rdi, r14
    mov rsi, r12
    mov rcx, rbx
    shr rcx, 3
    rep movsq

.sort:
    mov ebp, 1
.sort_outer:
    cmp rbp, r13
    jae .success
    mov r10, rbp
    shl r10, 6
    add r10, r14
    mov rax, qword [r10]
    mov qword [rsp], rax
    mov rax, qword [r10 + 8]
    mov qword [rsp + 8], rax
    mov rax, qword [r10 + 16]
    mov qword [rsp + 16], rax
    mov rax, qword [r10 + 24]
    mov qword [rsp + 24], rax
    mov rax, qword [r10 + 32]
    mov qword [rsp + 32], rax
    mov rax, qword [r10 + 40]
    mov qword [rsp + 40], rax
    mov rax, qword [r10 + 48]
    mov qword [rsp + 48], rax
    mov rax, qword [r10 + 56]
    mov qword [rsp + 56], rax
    mov r11, rbp
.sort_inner:
    test r11, r11
    jz .insert
    mov r9, r11
    dec r9
    shl r9, 6
    add r9, r14
    mov rax, qword [rsp]
    cmp qword [r9], rax
    jbe .insert
    lea r10, [r9 + METADATA_RECORD_BYTES]
    mov rax, qword [r9]
    mov qword [r10], rax
    mov rax, qword [r9 + 8]
    mov qword [r10 + 8], rax
    mov rax, qword [r9 + 16]
    mov qword [r10 + 16], rax
    mov rax, qword [r9 + 24]
    mov qword [r10 + 24], rax
    mov rax, qword [r9 + 32]
    mov qword [r10 + 32], rax
    mov rax, qword [r9 + 40]
    mov qword [r10 + 40], rax
    mov rax, qword [r9 + 48]
    mov qword [r10 + 48], rax
    mov rax, qword [r9 + 56]
    mov qword [r10 + 56], rax
    dec r11
    jmp .sort_inner
.insert:
    mov r10, r11
    shl r10, 6
    add r10, r14
    mov rax, qword [rsp]
    mov qword [r10], rax
    mov rax, qword [rsp + 8]
    mov qword [r10 + 8], rax
    mov rax, qword [rsp + 16]
    mov qword [r10 + 16], rax
    mov rax, qword [rsp + 24]
    mov qword [r10 + 24], rax
    mov rax, qword [rsp + 32]
    mov qword [r10 + 32], rax
    mov rax, qword [rsp + 40]
    mov qword [r10 + 40], rax
    mov rax, qword [rsp + 48]
    mov qword [r10 + 48], rax
    mov rax, qword [rsp + 56]
    mov qword [r10 + 56], rax
    inc rbp
    jmp .sort_outer

.success:
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, METADATA_DIAG_ARGUMENT
    jmp .return
.count:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, METADATA_DIAG_COUNT
    jmp .return
.capacity:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, METADATA_DIAG_CAPACITY
    jmp .return
.overlap:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, METADATA_DIAG_OVERLAP
    jmp .return
.symbol:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_SYMBOL
    jmp .return
.effect:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_EFFECT
    jmp .return
.capability:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_CAPABILITY
    jmp .return
.ownership:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_OWNERSHIP
    jmp .return
.flags:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_FLAGS
    jmp .return
.doc:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_DOC
    jmp .return
.dependency:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_DEPENDENCY
    jmp .return
.duplicate:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, METADATA_DIAG_DUPLICATE

.return:
    add rsp, METADATA_RECORD_BYTES
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
