; G142 contextual Registry owner.  Template notation is resolved only after
; a caller has established the corresponding Text/FormatPlan subgrammar.
bits 64
default rel
%define NEBO_TEMPLATE_NOTATION_PLAN_IMPLEMENTATION 1
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/text/template_notation_plan.inc"

section .text
global nebo_template_notation_registry_lookup

; RDI global Registry ID, RSI established template context.
; Success: RAX local notation kind, RDX contextual fixity, RCX flags,
; R8 registry suffix. Failure: all outputs zero.
nebo_template_notation_registry_lookup:
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_077
 cmp rdi,rax
 je .interpolation
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_078
 cmp rdi,rax
 je .percent
 mov rax,NEBOC_OPERATOR_ID_NSR_DOM_079
 cmp rdi,rax
 je .slash
 jmp .bad
.interpolation:
 cmp esi,TEMPLATE_NOTATION_CONTEXT_INTERPOLATED_TEXT
 jne .bad
 mov eax,TEMPLATE_NOTATION_INTERPOLATION
 mov r8d,77
 mov ecx,TEMPLATE_NOTATION_FLAG_DOMAIN_GATED | TEMPLATE_NOTATION_FLAG_BOUNDED | TEMPLATE_NOTATION_FLAG_EXACTLY_ONCE
 jmp .ok
.percent:
 cmp esi,TEMPLATE_NOTATION_CONTEXT_FORMAT_TEXT
 jne .bad
 mov eax,TEMPLATE_NOTATION_PERCENT
 mov r8d,78
 mov ecx,TEMPLATE_NOTATION_FLAG_DOMAIN_GATED | TEMPLATE_NOTATION_FLAG_BOUNDED | TEMPLATE_NOTATION_FLAG_EXACTLY_ONCE
 jmp .ok
.slash:
 cmp esi,TEMPLATE_NOTATION_CONTEXT_SLASH_TEXT
 jne .bad
 mov eax,TEMPLATE_NOTATION_SLASH
 mov r8d,79
 mov ecx,TEMPLATE_NOTATION_FLAG_DOMAIN_GATED | TEMPLATE_NOTATION_FLAG_BOUNDED | TEMPLATE_NOTATION_FLAG_PLAIN_FALLBACK
.ok:
 mov edx,NEBOC_OPERATOR_FIXITY_CONTEXTUAL
 ret
.bad:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
