bits 64
default rel

%include "compiler/tokens/operator_registry.inc"
%include "compiler/tokens/token_kind.inc"

section .rodata

percent_lexeme:      db "%"
degree_lexeme:       db 0xc2, 0xb0
per_mille_lexeme:    db 0xe2, 0x80, 0xb0
basis_points_lexeme: db 0xe2, 0x80, 0xb1
celsius_lexeme:      db 0xc2, 0xb0, "C"
fahrenheit_lexeme:   db 0xc2, 0xb0, "F"

; The G129 live semantic slice. Each row uses the program-wide Registry ABI;
; lexeme_start holds the exact UTF-8 spelling and lexeme_count its byte length.
align 8
g129_typed_quantity_registry:
    dq NEBOC_OPERATOR_ID_NSR_CORE_042
    dq NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_CONTEXTUAL
    dq 120
    dq NEBOC_OPERATOR_ASSOC_LEFT
    dq percent_lexeme
    dq 1
    dq NEBOC_OPERATOR_DOMAIN_CORE
    dq NEBOC_OPERATOR_FLAG_CONTEXTUAL

    dq NEBOC_OPERATOR_ID_NSR_DOM_019
    dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_POSTFIX
    dq 170
    dq NEBOC_OPERATOR_ASSOC_NONE
    dq degree_lexeme
    dq 2
    dq NEBOC_OPERATOR_DOMAIN_ANGLE
    dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED

    dq NEBOC_OPERATOR_ID_NSR_DOM_020
    dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_POSTFIX
    dq 170
    dq NEBOC_OPERATOR_ASSOC_NONE
    dq per_mille_lexeme
    dq 3
    dq NEBOC_OPERATOR_DOMAIN_QUANTITY_RATIO
    dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED

    dq NEBOC_OPERATOR_ID_NSR_DOM_021
    dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_POSTFIX
    dq 170
    dq NEBOC_OPERATOR_ASSOC_NONE
    dq basis_points_lexeme
    dq 3
    dq NEBOC_OPERATOR_DOMAIN_QUANTITY_RATIO
    dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED

    dq NEBOC_OPERATOR_ID_NSR_DOM_022
    dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_POSTFIX
    dq 170
    dq NEBOC_OPERATOR_ASSOC_NONE
    dq celsius_lexeme
    dq 3
    dq NEBOC_OPERATOR_DOMAIN_TEMPERATURE
    dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED

    dq NEBOC_OPERATOR_ID_NSR_DOM_023
    dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
    dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    dq NEBOC_OPERATOR_FIXITY_POSTFIX
    dq 170
    dq NEBOC_OPERATOR_ASSOC_NONE
    dq fahrenheit_lexeme
    dq 3
    dq NEBOC_OPERATOR_DOMAIN_TEMPERATURE
    dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED
g129_typed_quantity_registry_end:

section .text

; edi=zero-based row. rax=immutable OperatorRegistryEntry or zero.
global neboc_typed_quantity_registry_at
neboc_typed_quantity_registry_at:
    cmp edi, 6
    jae .not_found
    imul eax, edi, NEBOC_OPERATOR_ENTRY_SIZE
    lea rdx, [g129_typed_quantity_registry]
    add rax, rdx
    ret
.not_found:
    xor eax, eax
    ret

; rax=number of live G129 semantic rows.
global neboc_typed_quantity_registry_count
neboc_typed_quantity_registry_count:
    mov eax, (g129_typed_quantity_registry_end - g129_typed_quantity_registry) / NEBOC_OPERATOR_ENTRY_SIZE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
