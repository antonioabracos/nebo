bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_MEASUREMENT_FIELD_VALUE        0x01
%define NEBO_MEASUREMENT_FIELD_UNCERTAINTY  0x02
%define NEBO_MEASUREMENT_FIELD_UNIT         0x04

section .rodata
plus_minus_utf8: db 0xc2, 0xb1

section .text

; edi=unit, rsi=uncertainty. eax=stable field mask, edx=status.
global nebo_measurement_metadata_plan
nebo_measurement_metadata_plan:
    test rsi, rsi
    js .domain
    cmp edi, NEBO_UNIT_MILLI_FAHRENHEIT
    ja .unit
    mov eax, NEBO_MEASUREMENT_FIELD_VALUE | NEBO_MEASUREMENT_FIELD_UNCERTAINTY
    test edi, edi
    jz .ok
    or eax, NEBO_MEASUREMENT_FIELD_UNIT
.ok:
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.unit:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_UNIT
    ret

; rax=UTF-8 U+00B1, edx=length. Locale affects numbers, never this marker.
global nebo_measurement_uncertainty_separator
nebo_measurement_uncertainty_separator:
    lea rax, [plus_minus_utf8]
    mov edx, 2
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
