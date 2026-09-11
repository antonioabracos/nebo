bits 64
default rel
%include "compiler/semantic/numeric/numeric_contract.inc"

section .bss
align 8
contract resb NEBO_NUMERIC_CONTRACT_SIZE

section .text
global _start
_start:
    lea rdi,[contract]
    call nebo_numeric_contract_init
    test eax,eax
    jnz .fail1
    lea rdi,[contract]
    call nebo_numeric_contract_validate
    test eax,eax
    jnz .fail2
    cmp qword [contract+NEBO_NUMERIC_CONTRACT_MAX_VECTOR],64
    jne .fail3
    cmp qword [contract+NEBO_NUMERIC_CONTRACT_MAX_ELEMENTS],4096
    jne .fail4
    cmp qword [contract+NEBO_NUMERIC_CONTRACT_MAX_RANK],6
    jne .fail5
    cmp qword [contract+NEBO_NUMERIC_CONTRACT_MAX_WORKERS],8
    jne .fail6
    cmp qword [contract+NEBO_NUMERIC_CONTRACT_MAX_WORKSPACE],65536
    jne .fail7
    xor edi,edi
    call nebo_numeric_contract_validate
    cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
    jne .fail8
    inc qword [contract+NEBO_NUMERIC_CONTRACT_VERSION]
    lea rdi,[contract]
    call nebo_numeric_contract_validate
    cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
    jne .fail9
    lea rdi,[contract+1]
    call nebo_numeric_contract_validate
    cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
    jne .fail10
    xor edi,edi
    jmp .exit
%assign i 1
%rep 10
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
