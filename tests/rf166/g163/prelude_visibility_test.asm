; RF166-G163 native manifest transport and failure-atomicity conformance.
bits 64
default rel

%include "compiler/semantic/prelude/prelude.inc"

global _start
extern neboc_prelude_manifest
extern neboc_prelude_inject
extern neboc_prelude_surface
extern neboc_prelude_console_scan
extern neboc_no_prelude
extern neboc_stdlib_registry
extern neboc_prelude_migration

%define SENTINEL 0xa5a5a5a5a5a5a5a5

%macro RESET_RESULT 0
    mov rax, SENTINEL
    lea rdi, [rel result]
    mov ecx, 3
    rep stosq
%endmacro

%macro TEST_OWNER 3
    RESET_RESULT
    lea rdi, [rel edition_one]
    mov esi, edition_one_len
    lea rdx, [rel result]
    call %1
    test eax, eax
    jnz fail
    mov rax, %3
    cmp qword [rel result], rax
    jne fail
    cmp qword [rel result + 8], edition_one_len
    jne fail
    cmp qword [rel result + 16], %2
    jne fail

    ; A distinct manifest must produce a distinct authenticated digest.
    RESET_RESULT
    lea rdi, [rel edition_two]
    mov esi, edition_two_len
    lea rdx, [rel result]
    call %1
    test eax, eax
    jnz fail
    mov rax, %3
    cmp qword [rel result], rax
    je fail
    cmp qword [rel result + 8], edition_two_len
    jne fail
    cmp qword [rel result + 16], %2
    jne fail

    ; Rejected input must leave the result structure byte-for-byte untouched.
    RESET_RESULT
    lea rdi, [rel edition_one]
    xor esi, esi
    lea rdx, [rel result]
    call %1
    cmp eax, NEBOC_PRELUDE_STATUS_LENGTH
    jne fail
    call assert_sentinel
    test eax, eax
    jnz fail

    RESET_RESULT
    lea rdi, [rel invalid_manifest]
    mov esi, invalid_manifest_len
    lea rdx, [rel result]
    call %1
    cmp eax, NEBOC_PRELUDE_STATUS_ENCODING
    jne fail
    call assert_sentinel
    test eax, eax
    jnz fail
%endmacro

section .text
_start:
    TEST_OWNER neboc_prelude_manifest, NEBOC_PRELUDE_TAG_MANIFEST, 0x9b6c51a21935cfd1
    TEST_OWNER neboc_prelude_inject, NEBOC_PRELUDE_TAG_INJECTION, 0x9b6c51a21935cfd2
    TEST_OWNER neboc_prelude_surface, NEBOC_PRELUDE_TAG_SURFACE, 0x9b6c51a21935cfd3
    TEST_OWNER neboc_prelude_console_scan, NEBOC_PRELUDE_TAG_CONSOLE_SCAN, 0x9b6c51a21935cfd4
    TEST_OWNER neboc_no_prelude, NEBOC_PRELUDE_TAG_DISABLED, 0x9b6c51a21935cfd5
    TEST_OWNER neboc_stdlib_registry, NEBOC_PRELUDE_TAG_STDLIB, 0x9b6c51a21935cfd6
    TEST_OWNER neboc_prelude_migration, NEBOC_PRELUDE_TAG_MIGRATION, 0x9b6c51a21935cfd7

    xor edi, edi
    jmp exit

assert_sentinel:
    mov rax, SENTINEL
    cmp qword [rel result], rax
    jne .bad
    cmp qword [rel result + 8], rax
    jne .bad
    cmp qword [rel result + 16], rax
    jne .bad
    xor eax, eax
    ret
.bad:
    mov eax, 1
    ret

fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall

section .rodata
edition_one: db 'edition-one'
edition_one_len: equ $ - edition_one
edition_two: db 'edition-two'
edition_two_len: equ $ - edition_two
invalid_manifest: db 'a', 0xff, 'b'
invalid_manifest_len: equ $ - invalid_manifest

section .bss
align 8
result: resq 3
