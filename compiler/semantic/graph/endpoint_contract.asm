default rel
section .text
global nebo_endpoint_contract_validate
; descriptor: node id,port id,schema id,capability mask.
nebo_endpoint_contract_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi], 0
    jle .invalid
    cmp qword [rdi+8], 0
    jle .invalid
    cmp qword [rdi+16], 0
    jle .invalid
    cmp qword [rdi+24], 0
    jle .capability
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.capability: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
