bits 64
default rel
%include "compiler/lowering/textual/text_ir.inc"
%include "compiler/codegen/textual/x86_64/text_codegen.inc"
%include "runtime/textual/text_core.inc"
global neboc_text_codegen
global neboc_text_codegen_plan
section .text
align 16
neboc_text_codegen:
 cmp edi,NEBO_LIR_TEXT_DESCRIPTOR
 jne .error
 mov eax,NEBO_CODEGEN_STATIC_DESCRIPTOR
 ret
.error:
 mov eax,NEBO_CODEGEN_ERROR
 ret

; rdi=pointerless TextPlan.  Code generation authenticates the representation,
; encoding and ABI version before selecting the static descriptor contract.
align 16
neboc_text_codegen_plan:
 test rdi,rdi
 jz .plan_error
 cmp qword [rdi+NEBO_TEXT_PLAN_KIND_OFFSET],NEBO_HIR_TEXT_PLAN
 jne .plan_error
 cmp qword [rdi+NEBO_TEXT_PLAN_REPRESENTATION_OFFSET],NEBO_LIR_TEXT_DESCRIPTOR
 jne .plan_error
 cmp qword [rdi+NEBO_TEXT_PLAN_ENCODING_OFFSET],NEBO_TEXT_ENCODING_UTF8
 jne .plan_error
 cmp qword [rdi+NEBO_TEXT_PLAN_RUNTIME_CONTRACT_OFFSET],NEBO_TEXT_ABI_VERSION
 jne .plan_error
 mov eax,NEBO_CODEGEN_STATIC_DESCRIPTOR
 mov edx,NEBO_CODEGEN_TEXT_RUNTIME_CONTRACT
 ret
.plan_error:
 mov eax,NEBO_CODEGEN_ERROR
 xor edx,edx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
