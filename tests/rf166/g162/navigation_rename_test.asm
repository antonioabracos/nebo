; HOVER-SIGNATURE-HELP-DEFINITION-REFERENCES-E-RENAME-POR-SYMBOLID integrated bounded native conformance test.
bits 64
default rel
global _start
extern neboc_hover
extern neboc_signature_help
extern neboc_definition
extern neboc_references
extern neboc_semantic_rename
extern neboc_interface_definition
extern neboc_tooling_transaction
%define SENTINEL 0xa5a5a5a5a5a5a5a5
section .text
_start:
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_hover
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 17
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    lea rdi, [rel doc_input]
    mov esi, 3
    lea rdx, [rel result_b]
    call neboc_hover
    test eax, eax
    jnz fail
    cmp qword [rel result_b + 16], 17
    jne fail
    cmp qword [rel result_b + 8], 3
    jne fail
    mov rax, [rel result_a]
    cmp rax, [rel result_b]
    je fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_hover
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_signature_help
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 18
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_signature_help
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_definition
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 19
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_definition
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_references
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 20
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_references
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_semantic_rename
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 21
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_semantic_rename
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_interface_definition
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 22
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_interface_definition
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail
    lea rdi, [rel record_input]
    mov esi, 12
    lea rdx, [rel result_a]
    call neboc_tooling_transaction
    test eax, eax
    jnz fail
    cmp qword [rel result_a + 16], 23
    jne fail
    cmp qword [rel result_a + 8], 12
    jne fail
    mov rax, SENTINEL
    lea rdi, [rel result_b]
    mov ecx, 3
    rep stosq
    lea rdi, [rel record_input]
    xor esi, esi
    lea rdx, [rel result_b]
    call neboc_tooling_transaction
    cmp eax, 2
    jne fail
    mov rax, SENTINEL
    cmp qword [rel result_b], rax
    jne fail

    xor edi, edi
    jmp exit
fail:
    mov edi, 1
exit:
    mov eax, 60
    syscall
section .rodata
doc_input: db 'doc'
record_input: db 'valid-record'
comment_input: db '/*a/*b*/c*/'
section .bss
align 8
result_a: resq 3
result_b: resq 3
