bits 64
default rel

section .text
extern nebo_runtime_abi_version
extern nebo_runtime_contract_3
global nebo_runtime_thunk_3
nebo_runtime_thunk_3:
    cmp qword [rel nebo_runtime_abi_version], 0
    jne .nebo_runtime_version_mismatch_3
    jmp nebo_runtime_contract_3
.nebo_runtime_version_mismatch_3:
    mov eax, 7
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
