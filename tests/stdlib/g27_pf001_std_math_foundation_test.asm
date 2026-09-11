; BIBLIOTECA-PADRAO-POR-DOMINIOS-PF001 native bounded std.math tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/std_math_foundation.inc"

extern neboc_std_math_init
extern neboc_std_math_evaluate
extern neboc_host_process_exit

section .bss align=16
record: resb neboc_biblioteca_padrao_por_dominios_RECORD_SIZE
saved_hash: resq 1

section .text
global _start
_start:
    mov r15d, 10
    lea rdi, [rel record]
    mov ecx, neboc_biblioteca_padrao_por_dominios_RECORD_QWORDS
    xor eax, eax
    rep stosq

    xor edi, edi
    call neboc_std_math_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel record + 1]
    call neboc_std_math_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; abs(-27) = 27.
    mov r15d, 20
    lea rdi, [rel record]
    mov esi, NEBOC_OP_ABS
    mov rdx, -27
    xor ecx, ecx
    xor r8d, r8d
    mov r9d, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    call neboc_std_math_init
    test eax, eax
    jnz fail
    mov rax, [rel record + neboc_biblioteca_padrao_por_dominios_STATE_HASH_OFFSET]
    mov [rel saved_hash], rax
    lea rdi, [rel record]
    call neboc_std_math_evaluate
    test eax, eax
    jnz fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_RESULT_OFFSET], 27
    jne fail

    ; Reinitialize a fresh record for clamp(120, 0, 100) = 100.
    mov r15d, 30
    lea rdi, [rel record]
    mov ecx, neboc_biblioteca_padrao_por_dominios_RECORD_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel record]
    mov esi, NEBOC_OP_CLAMP
    mov edx, 120
    xor ecx, ecx
    mov r8d, 100
    mov r9d, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    call neboc_std_math_init
    test eax, eax
    jnz fail
    lea rdi, [rel record]
    call neboc_std_math_evaluate
    test eax, eax
    jnz fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_RESULT_OFFSET], 100
    jne fail

    ; Invalid clamp domain is rejected without initialization.
    mov r15d, 40
    lea rdi, [rel record]
    mov ecx, neboc_biblioteca_padrao_por_dominios_RECORD_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel record]
    mov esi, NEBOC_OP_CLAMP
    xor edx, edx
    mov ecx, 10
    mov r8, -10
    mov r9d, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    call neboc_std_math_init
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_MAGIC_OFFSET], 0
    jne fail

    ; min/max use signed Int ordering.
    mov r15d, 50
    lea rdi, [rel record]
    mov esi, NEBOC_OP_MIN
    mov rdx, -9
    mov ecx, 4
    xor r8d, r8d
    mov r9d, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    call neboc_std_math_init
    test eax, eax
    jnz fail
    lea rdi, [rel record]
    call neboc_std_math_evaluate
    test eax, eax
    jnz fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_RESULT_OFFSET], -9
    jne fail

    ; Immutable request tampering is denied.
    mov r15d, 60
    inc qword [rel record + neboc_biblioteca_padrao_por_dominios_VALUE_OFFSET]
    lea rdi, [rel record]
    call neboc_std_math_evaluate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_DIAGNOSTIC_OFFSET], neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
    jne fail

    ; abs(Int.min) is a stable runtime-domain failure.
    mov r15d, 70
    lea rdi, [rel record]
    mov ecx, neboc_biblioteca_padrao_por_dominios_RECORD_QWORDS
    xor eax, eax
    rep stosq
    lea rdi, [rel record]
    mov esi, NEBOC_OP_ABS
    mov rdx, 0x8000000000000000
    xor ecx, ecx
    xor r8d, r8d
    mov r9d, neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
    call neboc_std_math_init
    test eax, eax
    jnz fail
    lea rdi, [rel record]
    call neboc_std_math_evaluate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_biblioteca_padrao_por_dominios_DIAGNOSTIC_OFFSET], neboc_biblioteca_padrao_por_dominios_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, r15d
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
