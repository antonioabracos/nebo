bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=milli-Celsius. Exact affine conversion to milli-Fahrenheit.
; rax=value, edx=status (PRECISION when the target scale cannot represent it).
global nebo_temperature_c_to_f_exact
nebo_temperature_c_to_f_exact:
    mov rax, rdi
    imul rax, 9
    jo .overflow
    cqo
    mov ecx, 5
    idiv rcx
    test rdx, rdx
    jnz .precision
    add rax, 32000
    jo .overflow
    xor edx, edx
    ret
.precision:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_PRECISION
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=milli-Fahrenheit. Exact affine conversion to milli-Celsius.
global nebo_temperature_f_to_c_exact
nebo_temperature_f_to_c_exact:
    mov rax, rdi
    sub rax, 32000
    jo .f_overflow
    imul rax, 5
    jo .f_overflow
    cqo
    mov ecx, 9
    idiv rcx
    test rdx, rdx
    jnz .f_precision
    xor edx, edx
    ret
.f_precision:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_PRECISION
    ret
.f_overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; edi='C' or 'F', esi=context after U+00B0. eax=unit, edx=status.
global nebo_temperature_suffix_classify
nebo_temperature_suffix_classify:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_SYNTAX
    test esi, NEBO_QCTX_HAS_COMPLETE_OPERAND
    jz .done
    test esi, NEBO_QCTX_DOMAIN_ENABLED
    jz .domain_error
    cmp edi, 'C'
    je .celsius
    cmp edi, 'F'
    jne .done
    mov eax, NEBO_UNIT_MILLI_FAHRENHEIT
    xor edx, edx
    ret
.celsius:
    mov eax, NEBO_UNIT_MILLI_CELSIUS
    xor edx, edx
.done:
    ret
.domain_error:
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
