bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .rodata
percent_suffix:       db "%"
per_mille_suffix:     db 0xe2, 0x80, 0xb0
basis_points_suffix:  db 0xe2, 0x80, 0xb1
angle_suffix:         db 0xc2, 0xb0
celsius_suffix:       db 0xc2, 0xb0, "C"
fahrenheit_suffix:    db 0xc2, 0xb0, "F"

section .text

; edi=unit. rax=UTF-8 suffix, edx=byte length, ecx=status.
global nebo_quantity_format_suffix
nebo_quantity_format_suffix:
    xor eax, eax
    xor edx, edx
    mov ecx, NEBO_QUANTITY_ERR_UNIT
    cmp edi, NEBO_UNIT_PERCENT
    je .percent
    cmp edi, NEBO_UNIT_PER_MILLE
    je .per_mille
    cmp edi, NEBO_UNIT_BASIS_POINTS
    je .basis_points
    cmp edi, NEBO_UNIT_MILLIDEGREE
    je .angle
    cmp edi, NEBO_UNIT_MILLI_CELSIUS
    je .celsius
    cmp edi, NEBO_UNIT_MILLI_FAHRENHEIT
    je .fahrenheit
    ret
.percent:
    lea rax, [percent_suffix]
    mov edx, 1
    jmp .ok
.per_mille:
    lea rax, [per_mille_suffix]
    mov edx, 3
    jmp .ok
.basis_points:
    lea rax, [basis_points_suffix]
    mov edx, 3
    jmp .ok
.angle:
    lea rax, [angle_suffix]
    mov edx, 2
    jmp .ok
.celsius:
    lea rax, [celsius_suffix]
    mov edx, 3
    jmp .ok
.fahrenheit:
    lea rax, [fahrenheit_suffix]
    mov edx, 3
.ok:
    xor ecx, ecx
    ret

; Stable serialization uses the numeric unit tag, never a localized spelling.
global nebo_quantity_serialization_tag
nebo_quantity_serialization_tag:
    cmp edi, NEBO_UNIT_PERCENT
    jb .bad
    cmp edi, NEBO_UNIT_MILLI_FAHRENHEIT
    ja .bad
    mov eax, edi
    xor edx, edx
    ret
.bad:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_UNIT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
