; RF166-G165 integrated bounded native conformance test.
bits 64
default rel
global _start
extern neboc_rf166_module_import_conformance
extern neboc_rf166_interface_fuzz_conformance
extern neboc_rf166_semantic_doc_conformance
extern neboc_rf166_lsp_parity_conformance
extern neboc_rf166_comment_fuzz_conformance
extern neboc_rf166_edition_migration_conformance
extern neboc_rf166_deterministic_incremental_conformance
%define SENTINEL 0xa5a5a5a5a5a5a5a5
section .text
_start:
    lea rdi, [rel record_1]
    mov esi, record_1_end - record_1
    lea rdx, [rel result]
    call neboc_rf166_module_import_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 1
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_1]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_module_import_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_2]
    mov esi, record_2_end - record_2
    lea rdx, [rel result]
    call neboc_rf166_interface_fuzz_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 2
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_2]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_interface_fuzz_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_3]
    mov esi, record_3_end - record_3
    lea rdx, [rel result]
    call neboc_rf166_semantic_doc_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 3
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_3]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_semantic_doc_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_4]
    mov esi, record_4_end - record_4
    lea rdx, [rel result]
    call neboc_rf166_lsp_parity_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 4
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_4]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_lsp_parity_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_5]
    mov esi, record_5_end - record_5
    lea rdx, [rel result]
    call neboc_rf166_comment_fuzz_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 5
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_5]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_comment_fuzz_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_6]
    mov esi, record_6_end - record_6
    lea rdx, [rel result]
    call neboc_rf166_edition_migration_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 6
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_6]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_edition_migration_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_7]
    mov esi, record_7_end - record_7
    lea rdx, [rel result]
    call neboc_rf166_deterministic_incremental_conformance
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 7
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_7]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_deterministic_incremental_conformance
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail

    xor edi, edi
    jmp .exit
.fail:
    mov edi, 1
.exit:
    mov eax, 60
    syscall
section .rodata
record_1:
    dd 0x34434652
    db 1, 1
    dw 0
    dd record_1_end - record_1_payload
    dd 1
record_1_payload: db 'case-01-bounded'
record_1_end:
record_2:
    dd 0x34434652
    db 1, 2
    dw 0
    dd record_2_end - record_2_payload
    dd 1
record_2_payload: db 'case-02-bounded'
record_2_end:
record_3:
    dd 0x34434652
    db 1, 3
    dw 0
    dd record_3_end - record_3_payload
    dd 1
record_3_payload: db 'case-03-bounded'
record_3_end:
record_4:
    dd 0x34434652
    db 1, 4
    dw 0
    dd record_4_end - record_4_payload
    dd 1
record_4_payload: db 'case-04-bounded'
record_4_end:
record_5:
    dd 0x34434652
    db 1, 5
    dw 0
    dd record_5_end - record_5_payload
    dd 1
record_5_payload: db 'case-05-bounded'
record_5_end:
record_6:
    dd 0x34434652
    db 1, 6
    dw 0
    dd record_6_end - record_6_payload
    dd 1
record_6_payload: db 'case-06-bounded'
record_6_end:
record_7:
    dd 0x34434652
    db 1, 7
    dw 0
    dd record_7_end - record_7_payload
    dd 1
record_7_payload: db 'case-07-bounded'
record_7_end:

section .bss
align 8
result: resq 4
rejected: resq 4
