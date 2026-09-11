; RESOLVER-TYPECHECKER-E-SEMANTICA-F01 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/portable/wasm_module.inc"
extern nebo_wasm_module_evaluate
extern nebo_wasm_validate
section .data
records dq 9,18,27,36
invalid_record dq 1032769
descending dq 2,1
valid_wasm db 0x00,0x61,0x73,0x6d,1,0,0,0, 1,1,0, 5,4,1,1,1,16, 10,1,0
valid_wasm_size equ $-valid_wasm
bad_magic db 1,0x61,0x73,0x6d,1,0,0,0
bad_order db 0,0x61,0x73,0x6d,1,0,0,0, 5,1,0, 1,1,0
bad_order_size equ $-bad_order
truncated_wasm db 0,0x61,0x73,0x6d,1,0,0,0, 1,2,0
truncated_wasm_size equ $-truncated_wasm
overlong_leb db 0,0x61,0x73,0x6d,1,0,0,0, 1,0x80,0
overlong_leb_size equ $-overlong_leb
unsupported_section db 0,0x61,0x73,0x6d,1,0,0,0, 12,0
unsupported_section_size equ $-unsupported_section
section .bss
report resb NEBO_WASM_MODULE_REPORT_SIZE
max_records resq NEBO_WASM_MODULE_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[valid_wasm]
    mov esi,valid_wasm_size
    lea rdx,[report]
    call nebo_wasm_validate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_WASM_VALIDATE_SECTION_COUNT],3
    jne fail
    cmp qword [report+NEBO_WASM_VALIDATE_MODULE_BYTES],valid_wasm_size
    jne fail
    cmp qword [report+NEBO_WASM_VALIDATE_LAST_SECTION],10
    jne fail
    cmp qword [report+NEBO_WASM_VALIDATE_PAYLOAD_BYTES],6
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[bad_magic]
    mov esi,8
    lea rdx,[report]
    call nebo_wasm_validate
    cmp eax,NEBO_WASM_MODULE_STATUS_MALFORMED
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    lea rdi,[bad_order]
    mov esi,bad_order_size
    lea rdx,[report]
    call nebo_wasm_validate
    cmp eax,NEBO_WASM_MODULE_STATUS_ORDER
    jne fail
    lea rdi,[truncated_wasm]
    mov esi,truncated_wasm_size
    lea rdx,[report]
    call nebo_wasm_validate
    cmp eax,NEBO_WASM_MODULE_STATUS_MALFORMED
    jne fail
    lea rdi,[overlong_leb]
    mov esi,overlong_leb_size
    lea rdx,[report]
    call nebo_wasm_validate
    cmp eax,NEBO_WASM_MODULE_STATUS_NONCANONICAL
    jne fail
    lea rdi,[unsupported_section]
    mov esi,unsupported_section_size
    lea rdx,[report]
    call nebo_wasm_validate
    cmp eax,NEBO_WASM_MODULE_STATUS_UNSUPPORTED
    jne fail
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_WASM_MODULE_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_WASM_MODULE_REPORT_SUM],90
    jne fail
    mov rax,0x93c73c10f6de4ab8
    cmp [report+NEBO_WASM_MODULE_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_WASM_MODULE_REPORT_MIN],9
    jne fail
    cmp qword [report+NEBO_WASM_MODULE_REPORT_MAX],36
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    cmp eax,NEBO_WASM_MODULE_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    cmp eax,NEBO_WASM_MODULE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    cmp eax,NEBO_WASM_MODULE_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_WASM_MODULE_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    cmp eax,NEBO_WASM_MODULE_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_WASM_MODULE_MAX_RECORDS
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    test eax,eax
    jnz fail
    mov rax,0x8877665544332211
    mov [report],rax
    lea rdi,[descending]
    mov esi,2
    lea rdx,[report]
    call nebo_wasm_module_evaluate
    cmp eax,NEBO_WASM_MODULE_STATUS_ORDER
    jne fail
    mov rax,0x8877665544332211
    cmp [report],rax
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
