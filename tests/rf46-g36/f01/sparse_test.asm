bits 64
default rel
%include "runtime/sparse/sparse.inc"
extern nebo_csr_validate
extern nebo_csr_spmv_i64
section .data
rowptr dd 0,2,3
cols dd 0,2,1
vals dq 1,2,3
x dq 4,5,6
desc dq rowptr,cols,vals
     dd 2,3,3,0
bad_cols dd 0,0,1
section .bss
y resq 2
section .text
global _start
_start:
    lea rdi,[rowptr]
    lea rsi,[cols]
    mov edx,2
    mov ecx,3
    mov r8d,3
    call nebo_csr_validate
    test eax,eax
    jnz fail
    lea rdi,[desc]
    lea rsi,[x]
    lea rdx,[y]
    call nebo_csr_spmv_i64
    test eax,eax
    jnz fail
    cmp qword [y],16
    jne fail
    cmp qword [y+8],15
    jne fail
    lea rdi,[rowptr]
    lea rsi,[bad_cols]
    mov edx,2
    mov ecx,3
    mov r8d,3
    call nebo_csr_validate
    cmp eax,NEBO_SPARSE_INVALID
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
