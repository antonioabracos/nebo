bits 64
default rel
%include "runtime/numeric/units/units.inc"
extern nebo_dimension_combine_i8
extern nebo_dimension_equal_i8
extern nebo_quantity_convert_i64
extern nebo_unit_affine_guard
section .data
length db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
time db 0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0
velocity db 1,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0
overflow_dim db 127,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
section .bss
dim_out resb 16
rat_out resq 2
section .text
global _start
_start:
    lea rdi,[dim_out]
    lea rsi,[length]
    lea rdx,[time]
    mov ecx,NEBO_UNIT_COMBINE_DIV
    call nebo_dimension_combine_i8
    test eax,eax
    jnz fail
    lea rdi,[dim_out]
    lea rsi,[velocity]
    call nebo_dimension_equal_i8
    test eax,eax
    jnz fail
    mov byte [dim_out],42
    lea rdi,[dim_out]
    lea rsi,[overflow_dim]
    lea rdx,[length]
    mov ecx,NEBO_UNIT_COMBINE_MUL
    call nebo_dimension_combine_i8
    cmp eax,NEBO_UNIT_OVERFLOW
    jne fail
    cmp byte [dim_out],42
    jne fail
    lea rdi,[rat_out]
    mov esi,100
    mov edx,1
    mov ecx,1
    mov r8d,100
    call nebo_quantity_convert_i64
    test eax,eax
    jnz fail
    cmp qword [rat_out],1
    jne fail
    cmp qword [rat_out+8],1
    jne fail
    mov edi,NEBO_UNIT_AFFINE_ABSOLUTE
    mov esi,1
    call nebo_unit_affine_guard
    cmp eax,NEBO_UNIT_AFFINE_MISUSE
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
