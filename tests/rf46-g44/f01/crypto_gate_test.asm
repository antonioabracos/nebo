bits 64
default rel
%include "runtime/security/crypto_gate.inc"
extern nebo_crypto_algorithm_lookup
section .bss
report resb NEBO_CRYPTO_REPORT_SIZE
section .text
global _start
_start:
    mov edi,1
    mov esi,1
    lea rdx,[report]
    call nebo_crypto_algorithm_lookup
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_CRYPTO_REPORT_ALGORITHM],1
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    mov edi,4402
    mov esi,1
    lea rdx,[report]
    call nebo_crypto_algorithm_lookup
    cmp eax,NEBO_CRYPTO_STATUS_UNAVAILABLE
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    mov edi,9999
    mov esi,1
    lea rdx,[report]
    call nebo_crypto_algorithm_lookup
    cmp eax,NEBO_CRYPTO_STATUS_FORBIDDEN
    jne fail
    mov edi,1
    mov esi,2
    lea rdx,[report]
    call nebo_crypto_algorithm_lookup
    cmp eax,NEBO_CRYPTO_STATUS_UNAVAILABLE
    jne fail
    mov edi,1
    mov esi,1
    xor edx,edx
    call nebo_crypto_algorithm_lookup
    cmp eax,NEBO_CRYPTO_STATUS_INVALID
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
