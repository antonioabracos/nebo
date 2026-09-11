bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_adapter_registry_validate
extern nebo_adapter_lookup
global _start
section .text
_start:
    lea rdi, [rel registry]
    lea rsi, [rel receipt]
    call nebo_adapter_registry_validate
    test eax, eax
    jnz fail
    cmp qword [rel receipt + NEBO_REGISTRY_RECEIPT_COUNT_OFFSET], 2
    jne fail
    lea rdi, [rel entries]
    mov esi, 2
    mov edx, nebo_render_model_TYPE_TEXT
    lea rcx, [rel found]
    call nebo_adapter_lookup
    test eax, eax
    jnz fail
    lea rax, [rel entries + NEBO_ADAPTER_SIZE]
    cmp [rel found], rax
    jne fail
    lea rdi, [rel private_registry]
    lea rsi, [rel untouched]
    call nebo_adapter_registry_validate
    cmp eax, NEBO_RENDER_PRIVACY
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
adapter_scalar:
    ret
adapter_text:
    ret
section .data
entries:
    dq NEBO_TYPE_INT, adapter_scalar, 0x1001, NEBO_ADAPTER_SAFE
    dq nebo_render_model_TYPE_TEXT, adapter_text, 0x1002, NEBO_ADAPTER_SAFE
private_entry:
    dq nebo_render_model_TYPE_BYTES, adapter_text, 0x1003, NEBO_ADAPTER_SENSITIVE
registry: dq entries, 2
private_registry: dq private_entry, 1
untouched: times NEBO_REGISTRY_RECEIPT_SIZE db 0xaa
section .bss
receipt: resb NEBO_REGISTRY_RECEIPT_SIZE
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
