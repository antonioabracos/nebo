; Integrated native proof for the G156 DocRecord ABI and interface section.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"

global _start
extern neboc_doc_symbol_id
extern neboc_doc_record_new
extern neboc_doc_record_validate
extern neboc_doc_record_set_summary
extern neboc_doc_record_add_parameter
extern neboc_doc_record_set_return
extern neboc_doc_record_add_error
extern neboc_doc_record_add_effect
extern neboc_doc_record_add_capability
extern neboc_doc_record_set_ownership
extern neboc_doc_record_set_complexity
extern neboc_doc_record_add_risk
extern neboc_doc_record_add_example
extern neboc_doc_record_add_law
extern neboc_doc_record_signature_hash
extern neboc_doc_record_rebind
extern neboc_doc_record_merge
extern neboc_doc_serialize
extern neboc_doc_deserialize
extern neboc_doc_project_index_key

%define EXPECTED_SYMBOL 0x2d16ca99b776a23d
%define SENTINEL 0xa5a5a5a5a5a5a5a5

section .text
_start:
    lea rdi, [rel symbol_name]
    mov esi, 8
    lea rdx, [rel scalar]
    call neboc_doc_symbol_id
    test eax, eax
    jnz fail
    mov rax, EXPECTED_SYMBOL
    cmp qword [rel scalar], rax
    jne fail

    lea rdi, [rel request]
    lea rsi, [rel record_a]
    call neboc_doc_record_new
    test eax, eax
    jnz fail
    lea rdi, [rel record_a]
    call neboc_doc_record_validate
    test eax, eax
    jnz fail

    lea rdi, [rel record_a]
    mov rsi, 0x42424242
    lea rdx, [rel record_b]
    call neboc_doc_record_rebind
    test eax, eax
    jnz fail
    cmp qword [rel record_b + NEBOC_DOC_OFF_SYMBOL], 0x42424242
    jne fail
    mov rax, qword [rel record_a + NEBOC_DOC_OFF_SIGNATURE]
    cmp qword [rel record_b + NEBOC_DOC_OFF_SIGNATURE], rax
    jne fail
    mov rax, qword [rel record_a + NEBOC_DOC_OFF_TITLE]
    cmp qword [rel record_b + NEBOC_DOC_OFF_TITLE], rax
    jne fail
    mov rax, NEBOC_DOC_RECORD_MAGIC
    cmp qword [rel record_a + NEBOC_DOC_OFF_MAGIC], rax
    jne fail
    cmp qword [rel record_a + NEBOC_DOC_OFF_INDEX_KEY], 0
    je fail

    lea rdi, [rel record_a]
    lea rsi, [rel scalar]
    call neboc_doc_record_signature_hash
    test eax, eax
    jnz fail
    mov rax, 0x1111222233334444
    cmp qword [rel scalar], rax
    jne fail

%macro SETTER 2
    lea rdi, [rel record_a]
    mov rsi, %2
    call %1
    test eax, eax
    jnz fail
%endmacro
    SETTER neboc_doc_record_set_summary, 0x201
    SETTER neboc_doc_record_add_parameter, 0x301
    SETTER neboc_doc_record_add_parameter, 0x302
    SETTER neboc_doc_record_set_return, 0x401
    SETTER neboc_doc_record_add_error, 0x501
    SETTER neboc_doc_record_add_effect, 0x601
    SETTER neboc_doc_record_add_capability, 0x701
    SETTER neboc_doc_record_set_ownership, 0x801
    SETTER neboc_doc_record_set_complexity, 0x901
    SETTER neboc_doc_record_add_risk, 0xa01
    SETTER neboc_doc_record_add_example, 0xd01
    SETTER neboc_doc_record_add_law, 0xe01
%undef SETTER
    lea rdi, [rel record_a]
    call neboc_doc_record_validate
    test eax, eax
    jnz fail
    cmp byte [rel record_a + NEBOC_DOC_OFF_COUNTS_A], 2
    jne fail

    lea rdi, [rel record_a]
    lea rsi, [rel record_a]
    lea rdx, [rel merged]
    call neboc_doc_record_merge
    test eax, eax
    jnz fail
    mov rax, qword [rel record_a + NEBOC_DOC_OFF_CONTENT_HASH]
    cmp qword [rel merged + NEBOC_DOC_OFF_CONTENT_HASH], rax
    jne fail

    lea rdi, [rel conflict_request]
    lea rsi, [rel record_b]
    call neboc_doc_record_new
    test eax, eax
    jnz fail
    mov rax, SENTINEL
    mov qword [rel conflict_out], rax
    lea rdi, [rel record_a]
    lea rsi, [rel record_b]
    lea rdx, [rel conflict_out]
    call neboc_doc_record_merge
    cmp eax, NEBOC_DOC_STATUS_CONFLICT
    jne fail
    mov rax, SENTINEL
    cmp qword [rel conflict_out], rax
    jne fail

    mov rax, SENTINEL
    mov qword [rel serialized_length], rax
    lea rdi, [rel record_a]
    lea rsi, [rel interface_bytes]
    mov edx, 4192
    lea rcx, [rel serialized_length]
    call neboc_doc_serialize
    test eax, eax
    jnz fail
    cmp qword [rel serialized_length], 4192
    jne fail
    lea rdi, [rel interface_bytes]
    mov esi, 4192
    lea rdx, [rel roundtrip]
    call neboc_doc_deserialize
    test eax, eax
    jnz fail
    lea rsi, [rel record_a]
    lea rdi, [rel roundtrip]
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    repe cmpsq
    jne fail
    lea rdi, [rel roundtrip]
    lea rsi, [rel scalar]
    call neboc_doc_project_index_key
    test eax, eax
    jnz fail
    cmp qword [rel scalar], 0
    je fail

    xor byte [rel interface_bytes + 120], 1
    mov rax, SENTINEL
    mov qword [rel blocked], rax
    lea rdi, [rel interface_bytes]
    mov esi, 4192
    lea rdx, [rel blocked]
    call neboc_doc_deserialize
    test eax, eax
    jz fail
    mov rax, SENTINEL
    cmp qword [rel blocked], rax
    jne fail
    xor byte [rel interface_bytes + 120], 1

    lea rdi, [rel private_request]
    lea rsi, [rel record_b]
    call neboc_doc_record_new
    test eax, eax
    jnz fail
    mov rax, SENTINEL
    mov qword [rel serialized_length], rax
    lea rdi, [rel record_b]
    lea rsi, [rel blocked_interface]
    mov edx, 4192
    lea rcx, [rel serialized_length]
    call neboc_doc_serialize
    test eax, eax
    jz fail
    mov rax, SENTINEL
    cmp qword [rel serialized_length], rax
    jne fail

    xor edi, edi
    jmp exit
fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall

section .rodata
symbol_name: db 'g156_api'
align 8
request:
    dq 0, 0, EXPECTED_SYMBOL, 17, 83, 0x1111222233334444, 1
    dq 0x0000000100000004, 0x101, 0, 0, 0, 0, 0, 0, 0
    dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    times (NEBOC_DOC_RECORD_BYTES / 8 - 32) dq 0
conflict_request:
    dq 0, 0, EXPECTED_SYMBOL, 17, 83, 0x1111222233334444, 1
    dq 0x0000000100000005, 0x999, 0, 0, 0, 0, 0, 0, 0
    dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    times (NEBOC_DOC_RECORD_BYTES / 8 - 32) dq 0
private_request:
    dq 0, 0, EXPECTED_SYMBOL, 17, 83, 0x1111222233334444, 1
    dq 0x0000000200000004, 0x101, 0, 0, 0, 0, 0, 0, 0
    dq 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    times (NEBOC_DOC_RECORD_BYTES / 8 - 32) dq 0

section .bss
align 16
record_a: resb NEBOC_DOC_RECORD_BYTES
record_b: resb NEBOC_DOC_RECORD_BYTES
merged: resb NEBOC_DOC_RECORD_BYTES
roundtrip: resb NEBOC_DOC_RECORD_BYTES
interface_bytes: resb 4192
blocked_interface: resb 4192
blocked: resb NEBOC_DOC_RECORD_BYTES
conflict_out: resb NEBOC_DOC_RECORD_BYTES
scalar: resq 1
serialized_length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
