bits 64
default rel

%include "compiler/tokens/operator_registry.inc"

section .rodata
sqrt_lexeme:        db 0xe2,0x88,0x9a
cube_root_lexeme:   db 0xe2,0x88,0x9b
fourth_root_lexeme: db 0xe2,0x88,0x9c
factorial_lexeme:   db "!"
infinity_lexeme:    db 0xe2,0x88,0x9e
pi_lexeme:          db 0xcf,0x80
tau_lexeme:         db 0xcf,0x84
floor_lexeme:       db 0xe2,0x8c,0x8a,"x",0xe2,0x8c,0x8b
ceil_lexeme:        db 0xe2,0x8c,0x88,"x",0xe2,0x8c,0x89

%macro MATH_ROW 6
 dq %1
 dq NEBOC_OPERATOR_CLASS_DOMAIN_GATED
 dq NEBOC_OPERATOR_STATE_APPROVED_TARGET
 dq NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
 dq %2
 dq %3
 dq %4
 dq %5
 dq %6
 dq NEBOC_OPERATOR_DOMAIN_TYPED_MATH
 dq NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED
%endmacro

; A bounded compiled view of the nine G130 Registry rows.  The canonical TSV
; remains preserve-only; this table records only the explicitly authorized
; APPROVED_TARGET implementation state.
align 8
g130_typed_math_registry:
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_001,NEBOC_OPERATOR_FIXITY_PREFIX,150,NEBOC_OPERATOR_ASSOC_RIGHT,sqrt_lexeme,3
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_002,NEBOC_OPERATOR_FIXITY_PREFIX,150,NEBOC_OPERATOR_ASSOC_RIGHT,cube_root_lexeme,3
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_003,NEBOC_OPERATOR_FIXITY_PREFIX,150,NEBOC_OPERATOR_ASSOC_RIGHT,fourth_root_lexeme,3
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_004,NEBOC_OPERATOR_FIXITY_POSTFIX,170,NEBOC_OPERATOR_ASSOC_LEFT,factorial_lexeme,1
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_005,NEBOC_OPERATOR_FIXITY_ATOMIC,0,NEBOC_OPERATOR_ASSOC_NONE,infinity_lexeme,3
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_006,NEBOC_OPERATOR_FIXITY_ATOMIC,0,NEBOC_OPERATOR_ASSOC_NONE,pi_lexeme,2
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_007,NEBOC_OPERATOR_FIXITY_ATOMIC,0,NEBOC_OPERATOR_ASSOC_NONE,tau_lexeme,2
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_016,NEBOC_OPERATOR_FIXITY_DELIMITED,0,NEBOC_OPERATOR_ASSOC_NONE,floor_lexeme,7
 MATH_ROW NEBOC_OPERATOR_ID_NSR_DOM_017,NEBOC_OPERATOR_FIXITY_DELIMITED,0,NEBOC_OPERATOR_ASSOC_NONE,ceil_lexeme,7
g130_typed_math_registry_end:

section .text

global neboc_typed_math_registry_at
neboc_typed_math_registry_at:
 cmp edi,9
 jae .missing
 imul eax,edi,NEBOC_OPERATOR_ENTRY_SIZE
 lea rdx,[g130_typed_math_registry]
 add rax,rdx
 ret
.missing:
 xor eax,eax
 ret

global neboc_typed_math_registry_count
neboc_typed_math_registry_count:
 mov eax,(g130_typed_math_registry_end-g130_typed_math_registry)/NEBOC_OPERATOR_ENTRY_SIZE
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
