; RESOLVER-TYPECHECKER-E-SEMANTICA-F02 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/wasm_interface.inc"
extern nebo_wasm_interface_evaluate
section .data
records dq 10,20,30,40
invalid_record dq 1036865
section .bss
report resb NEBO_WASM_INTERFACE_REPORT_SIZE
max_records resq NEBO_WASM_INTERFACE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_WASM_INTERFACE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_WASM_INTERFACE_REPORT_SUM],100
    jne fail
    mov rax,0x8292e810ed285e37
    cmp [report+NEBO_WASM_INTERFACE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_WASM_INTERFACE_REPORT_MIN],10
    jne fail
    cmp qword [report+NEBO_WASM_INTERFACE_REPORT_MAX],40
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    cmp eax,NEBO_WASM_INTERFACE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    cmp eax,NEBO_WASM_INTERFACE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    cmp eax,NEBO_WASM_INTERFACE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_WASM_INTERFACE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    cmp eax,NEBO_WASM_INTERFACE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_WASM_INTERFACE_MAX_RECORDS
    lea rdx,[report]
    call nebo_wasm_interface_evaluate
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
