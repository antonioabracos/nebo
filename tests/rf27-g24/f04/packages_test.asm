bits 64
default rel
%include "compiler/packages/packages.inc"

section .bss
align 16
ledger resb NEBO_PACKAGES_LEDGER_SIZE

section .text
global _start
_start:
    lea rdi,[ledger]
    call nebo_packages_init
    test eax,eax
    jnz .fail1
    lea rdi,[ledger]
    call nebo_packages_validate
    test eax,eax
    jnz .fail2
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_MAX_NODES],64
    jne .fail3
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_MAX_EDGES],256
    jne .fail4
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_MAX_PATH],4096
    jne .fail5
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_MAX_BYTES],16777216
    jne .fail6
    lea rdi,[ledger]
    mov esi,3
    mov edx,2
    mov ecx,0x272404
    call nebo_packages_reserve
    test eax,eax
    jnz .fail7
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_NODES],3
    jne .fail8
    cmp qword [ledger+NEBO_PACKAGES_LEDGER_EDGES],2
    jne .fail9
    mov rbx,[ledger+NEBO_PACKAGES_LEDGER_NODES]
    lea rdi,[ledger]
    mov esi,62
    xor edx,edx
    mov ecx,1
    call nebo_packages_reserve
    cmp eax,NEBO_PACKAGES_ERROR_LIMIT
    jne .fail10
    cmp rbx,[ledger+NEBO_PACKAGES_LEDGER_NODES]
    jne .fail10
    lea rdi,[ledger]
    xor esi,esi
    xor edx,edx
    mov ecx,1
    call nebo_packages_reserve
    cmp eax,NEBO_PACKAGES_ERROR_GRAPH
    jne .fail11
    inc qword [ledger+NEBO_PACKAGES_LEDGER_FLAGS]
    lea rdi,[ledger]
    call nebo_packages_validate
    cmp eax,NEBO_PACKAGES_ERROR_CONTRACT
    jne .fail12
    xor edi,edi
    jmp .exit
%assign i 1
%rep 12
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
