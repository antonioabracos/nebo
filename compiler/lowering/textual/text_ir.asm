bits 64
default rel
%include "compiler/parser/text_contract.inc"
%include "compiler/lowering/textual/text_ir.inc"
%include "runtime/textual/text_core.inc"
global neboc_text_lower
global neboc_text_plan
section .text
align 16
neboc_text_lower:
 cmp edi,NEBO_AST_TEXT_LITERAL
 jne .error
 mov eax,NEBO_LIR_TEXT_DESCRIPTOR
 ret
.error:
 mov eax,NEBO_LIR_ERROR
 ret

; edi=AST kind, rsi=decoded byte length, rdx=effect flags, rcx=out TextPlan.
; Pointerless plan fields are committed only after limits and effect policy.
align 16
neboc_text_plan:
 test rcx,rcx
 jz .plan_error
 cmp edi,NEBO_AST_TEXT_LITERAL_EXPR
 jne .plan_error
 cmp rsi,MAX_TEXT_BYTES
 ja .plan_error
 cmp rdx,NEBO_TEXT_PLAN_EFFECT_NONE
 jne .plan_error
 mov qword [rcx+NEBO_TEXT_PLAN_KIND_OFFSET],NEBO_HIR_TEXT_PLAN
 mov qword [rcx+NEBO_TEXT_PLAN_REPRESENTATION_OFFSET],NEBO_LIR_TEXT_DESCRIPTOR
 mov [rcx+NEBO_TEXT_PLAN_BYTE_LENGTH_OFFSET],rsi
 mov qword [rcx+NEBO_TEXT_PLAN_ENCODING_OFFSET],NEBO_TEXT_ENCODING_UTF8
 mov [rcx+NEBO_TEXT_PLAN_EFFECTS_OFFSET],rdx
 mov qword [rcx+NEBO_TEXT_PLAN_RUNTIME_CONTRACT_OFFSET],NEBO_TEXT_ABI_VERSION
 mov eax,NEBO_HIR_TEXT_PLAN
 ret
.plan_error:
 mov eax,NEBO_LIR_ERROR
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
