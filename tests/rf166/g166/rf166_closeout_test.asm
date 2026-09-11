; RF166-G166 integrated bounded native conformance test.
bits 64
default rel
global _start
extern neboc_rf166_reconciliation_closeout
extern neboc_rf166_multipackage_imports_e2e
extern neboc_rf166_public_module_examples
extern neboc_rf166_public_semantic_doc_examples
extern neboc_rf166_prelude_reachability_e2e
extern neboc_rf166_lsp_tooling_e2e
extern neboc_rf166_comment_tooling_e2e
extern neboc_rf166_offline_sdk_integration
extern neboc_rf166_independent_audit_probe
%define SENTINEL 0xa5a5a5a5a5a5a5a5
section .text
_start:
    lea rdi, [rel record_9]
    mov esi, record_9_end - record_9
    lea rdx, [rel result]
    call neboc_rf166_reconciliation_closeout
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 9
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_9]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_reconciliation_closeout
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_10]
    mov esi, record_10_end - record_10
    lea rdx, [rel result]
    call neboc_rf166_multipackage_imports_e2e
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 10
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_10]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_multipackage_imports_e2e
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_11]
    mov esi, record_11_end - record_11
    lea rdx, [rel result]
    call neboc_rf166_public_module_examples
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 11
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_11]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_public_module_examples
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_12]
    mov esi, record_12_end - record_12
    lea rdx, [rel result]
    call neboc_rf166_public_semantic_doc_examples
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 12
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_12]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_public_semantic_doc_examples
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_13]
    mov esi, record_13_end - record_13
    lea rdx, [rel result]
    call neboc_rf166_prelude_reachability_e2e
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 13
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_13]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_prelude_reachability_e2e
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_14]
    mov esi, record_14_end - record_14
    lea rdx, [rel result]
    call neboc_rf166_lsp_tooling_e2e
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 14
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_14]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_lsp_tooling_e2e
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_15]
    mov esi, record_15_end - record_15
    lea rdx, [rel result]
    call neboc_rf166_comment_tooling_e2e
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 15
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_15]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_comment_tooling_e2e
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_16]
    mov esi, record_16_end - record_16
    lea rdx, [rel result]
    call neboc_rf166_offline_sdk_integration
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 16
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_16]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_offline_sdk_integration
    cmp eax, 2
    jne .fail
    mov rax, SENTINEL
    cmp qword [rel rejected], rax
    jne .fail
    lea rdi, [rel record_17]
    mov esi, record_17_end - record_17
    lea rdx, [rel result]
    call neboc_rf166_independent_audit_probe
    test eax, eax
    jnz .fail
    cmp qword [rel result + 16], 17
    jne .fail
    mov rax, SENTINEL
    lea rdi, [rel rejected]
    mov ecx, 4
    rep stosq
    lea rdi, [rel record_17]
    xor esi, esi
    lea rdx, [rel rejected]
    call neboc_rf166_independent_audit_probe
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
record_9:
    dd 0x34434652
    db 1, 9
    dw 0
    dd record_9_end - record_9_payload
    dd 1
record_9_payload: db 'case-09-bounded'
record_9_end:
record_10:
    dd 0x34434652
    db 1, 10
    dw 0
    dd record_10_end - record_10_payload
    dd 1
record_10_payload: db 'case-10-bounded'
record_10_end:
record_11:
    dd 0x34434652
    db 1, 11
    dw 0
    dd record_11_end - record_11_payload
    dd 1
record_11_payload: db 'case-11-bounded'
record_11_end:
record_12:
    dd 0x34434652
    db 1, 12
    dw 0
    dd record_12_end - record_12_payload
    dd 1
record_12_payload: db 'case-12-bounded'
record_12_end:
record_13:
    dd 0x34434652
    db 1, 13
    dw 0
    dd record_13_end - record_13_payload
    dd 1
record_13_payload: db 'case-13-bounded'
record_13_end:
record_14:
    dd 0x34434652
    db 1, 14
    dw 0
    dd record_14_end - record_14_payload
    dd 1
record_14_payload: db 'case-14-bounded'
record_14_end:
record_15:
    dd 0x34434652
    db 1, 15
    dw 0
    dd record_15_end - record_15_payload
    dd 1
record_15_payload: db 'case-15-bounded'
record_15_end:
record_16:
    dd 0x34434652
    db 1, 16
    dw 0
    dd record_16_end - record_16_payload
    dd 1
record_16_payload: db 'case-16-bounded'
record_16_end:
record_17:
    dd 0x34434652
    db 1, 17
    dw 0
    dd record_17_end - record_17_payload
    dd 1
record_17_payload: db 'case-17-bounded'
record_17_end:

section .bss
align 8
result: resq 4
rejected: resq 4
