bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=value, rsi=absolute uncertainty, edx=unit.
; rax=value, rdx=uncertainty, ecx=unit, r8d=status.
global nebo_uncertain_measurement_create
nebo_uncertain_measurement_create:
    test rsi, rsi
    js .domain
    cmp edx, NEBO_UNIT_NONE
    jb .unit
    cmp edx, NEBO_UNIT_MILLI_FAHRENHEIT
    ja .unit
    mov ecx, edx
    mov rax, rdi
    mov rdx, rsi
    xor r8d, r8d
    ret
.unit:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov r8d, NEBO_QUANTITY_ERR_UNIT
    ret
.domain:
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov r8d, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
