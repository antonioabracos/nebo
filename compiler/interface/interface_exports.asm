; Canonical public export records for Nebo compiled interfaces.
;
; Record V1 (64 bytes):
;   +00 SymbolId                 qword
;   +08 canonical name digest    qword
;   +16 kind                     dword (1..6)
;   +20 visibility               dword (1=public, 2=reexport)
;   +24 public type digest       qword
;   +32 generic contract digest  qword
;   +40 target layout digest     qword
;   +48 constant value digest    qword
;   +56 presence flags           qword (generic=1, layout=2, constant=4)
;
; rdi=input records, rsi=count, rdx=output records, rcx=output capacity.
; Exact in-place canonicalization is supported; partial overlap is rejected.
; Every record and duplicate constraint is checked before output publication.
; On success records are ordered strictly by SymbolId.
;
; eax=NEBOC_STATUS_*, edx=stable rejection reason (zero on success).

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define EXPORT_RECORD_BYTES 64
%define EXPORT_MAX_RECORDS  1024
%define EXPORT_KIND_CONSTANT 3
%define EXPORT_KIND_NAMESPACE 5
%define EXPORT_FLAG_GENERIC  1
%define EXPORT_FLAG_LAYOUT   2
%define EXPORT_FLAG_CONSTANT 4
%define EXPORT_FLAG_MASK     7

%define EXPORT_DIAG_ARGUMENT       1
%define EXPORT_DIAG_COUNT_LIMIT    2
%define EXPORT_DIAG_CAPACITY       3
%define EXPORT_DIAG_OVERLAP        4
%define EXPORT_DIAG_SYMBOL_ID      5
%define EXPORT_DIAG_NAME           6
%define EXPORT_DIAG_KIND           7
%define EXPORT_DIAG_VISIBILITY     8
%define EXPORT_DIAG_TYPE           9
%define EXPORT_DIAG_FLAGS          10
%define EXPORT_DIAG_GENERIC        11
%define EXPORT_DIAG_LAYOUT         12
%define EXPORT_DIAG_CONSTANT       13
%define EXPORT_DIAG_DUPLICATE      14

section .text

NEBOC_ABI_FUNCTION neboc_interface_exports_canonicalize
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, EXPORT_RECORD_BYTES

    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    cmp r13, EXPORT_MAX_RECORDS
    ja .count_limit
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
    je .symbol_id
    cmp qword [r10 + 8], 0
    je .name
    mov eax, dword [r10 + 16]
    test eax, eax
    jz .kind
    cmp eax, 6
    ja .kind
    mov ecx, dword [r10 + 20]
    test ecx, ecx
    jz .visibility
    cmp ecx, 2
    ja .visibility
    cmp eax, EXPORT_KIND_NAMESPACE
    je .type_valid
    cmp qword [r10 + 24], 0
    je .type
.type_valid:
    mov rdx, qword [r10 + 56]
    mov rcx, rdx
    and rcx, ~EXPORT_FLAG_MASK
    jnz .flags

    test edx, EXPORT_FLAG_GENERIC
    jz .generic_absent
    cmp qword [r10 + 32], 0
    je .generic
    jmp .layout_check
.generic_absent:
    cmp qword [r10 + 32], 0
    jne .generic

.layout_check:
    test edx, EXPORT_FLAG_LAYOUT
    jz .layout_absent
    cmp qword [r10 + 40], 0
    je .layout
    jmp .constant_check
.layout_absent:
    cmp qword [r10 + 40], 0
    jne .layout

.constant_check:
    test edx, EXPORT_FLAG_CONSTANT
    jz .constant_absent
    cmp dword [r10 + 16], EXPORT_KIND_CONSTANT
    jne .constant
    cmp qword [r10 + 48], 0
    je .constant
    jmp .duplicates
.constant_absent:
    cmp qword [r10 + 48], 0
    jne .constant
    cmp dword [r10 + 16], EXPORT_KIND_CONSTANT
    je .constant

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
    lea r10, [r9 + EXPORT_RECORD_BYTES]
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
    mov edx, EXPORT_DIAG_ARGUMENT
    jmp .return
.count_limit:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, EXPORT_DIAG_COUNT_LIMIT
    jmp .return
.capacity:
    mov eax, NEBOC_STATUS_LIMIT_EXCEEDED
    mov edx, EXPORT_DIAG_CAPACITY
    jmp .return
.overlap:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
    mov edx, EXPORT_DIAG_OVERLAP
    jmp .return
.symbol_id:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_SYMBOL_ID
    jmp .return
.name:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_NAME
    jmp .return
.kind:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_KIND
    jmp .return
.visibility:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_VISIBILITY
    jmp .return
.type:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_TYPE
    jmp .return
.flags:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_FLAGS
    jmp .return
.generic:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_GENERIC
    jmp .return
.layout:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_LAYOUT
    jmp .return
.constant:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_CONSTANT
    jmp .return
.duplicate:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    mov edx, EXPORT_DIAG_DUPLICATE

.return:
    add rsp, EXPORT_RECORD_BYTES
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
