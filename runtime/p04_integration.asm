bits 64
default rel

%include "runtime/p04_integration.inc"

extern nebo_stream_contract_validate
extern nebo_large_data_contract_validate
extern nebo_animation_contract_validate
extern nebo_protocol_contract_validate
extern nebo_live_contract_validate

section .text
global nebo_p04_contract_validate
nebo_p04_contract_validate:
    sub rsp, 24
    mov [rsp], rdi
    mov [rsp + 8], rsi
    mov [rsp + 16], rdx
    call nebo_live_contract_validate
    test eax, eax
    jne .invalid
    mov rdi, 1024
    mov rsi, 128
    mov rdx, 8
    call nebo_stream_contract_validate
    test eax, eax
    jne .invalid
    mov rdi, 100000
    mov rsi, 67108864
    mov rdx, 1024
    call nebo_large_data_contract_validate
    test eax, eax
    jne .invalid
    mov rdi, 120
    mov rsi, 4096
    mov rdx, 1
    call nebo_animation_contract_validate
    test eax, eax
    jne .invalid
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_protocol_contract_validate
    test eax, eax
    jne .invalid
    xor eax, eax
    add rsp, 24
    ret
.invalid:
    mov eax, -1
    add rsp, 24
    ret
