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

; rdi=canonical value, esi=unit, edx=locale, rcx=FormatPlan*. A plan is
; committed only after every field validates, preserving failure atomicity.
global nebo_quantity_format_plan
nebo_quantity_format_plan:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdi
    mov r13d, esi
    test rbx, rbx
    jz .plan_syntax
    cmp edx, NEBO_QUANTITY_LOCALE_FR
    ja .plan_domain
    sub rsp, 16
    mov [rsp], rdx
    mov edi, r13d
    call nebo_quantity_format_suffix
    mov r8, [rsp]
    add rsp, 16
    test ecx, ecx
    jnz .plan_unit
    mov [rbx + NEBO_QUANTITY_FORMAT_VALUE_OFFSET], r12
    mov [rbx + NEBO_QUANTITY_FORMAT_UNIT_OFFSET], r13
    mov [rbx + NEBO_QUANTITY_FORMAT_SUFFIX_OFFSET], rax
    mov [rbx + NEBO_QUANTITY_FORMAT_SUFFIX_LENGTH_OFFSET], rdx
    mov [rbx + NEBO_QUANTITY_FORMAT_LOCALE_OFFSET], r8
    xor eax, eax
    jmp .plan_done
.plan_syntax:
    mov eax, NEBO_QUANTITY_ERR_SYNTAX
    jmp .plan_done
.plan_domain:
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    jmp .plan_done
.plan_unit:
    mov eax, NEBO_QUANTITY_ERR_UNIT
.plan_done:
    pop r13
    pop r12
    pop rbx
    ret

; Console labels deliberately reuse the FormatPlan suffix authority.
global nebo_quantity_console_label
nebo_quantity_console_label:
    jmp nebo_quantity_format_suffix

section .note.GNU-stack noalloc noexec nowrite progbits
