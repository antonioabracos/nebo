; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO canonical prefix/power precedence boundary.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/expression/operator_precedence.inc"

%define NEBOC_CORE_PREFIX_PLUS 1
%define NEBOC_CORE_PREFIX_NEGATE 2
%define NEBOC_CORE_POWER 3

section .text
; core_prefix_power_binding(kind) -> EDX=left BP, ECX=right BP,
; R8D=associativity. Prefix is right-binding; power is right-associative and
; binds tighter, so -2 ^ 2 lowers as -(2 ^ 2).
NEBOC_ABI_FUNCTION neboc_core_prefix_power_binding
 cmp edi,NEBOC_CORE_PREFIX_PLUS
 je .prefix
 cmp edi,NEBOC_CORE_PREFIX_NEGATE
 je .prefix
 cmp edi,NEBOC_CORE_POWER
 je .power
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.prefix:
 mov edx,NEBOC_OPERATOR_BP_PREFIX
 mov ecx,NEBOC_OPERATOR_BP_PREFIX
 mov r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 xor eax,eax
 ret
.power:
 mov edx,NEBOC_OPERATOR_BP_POWER
 mov ecx,NEBOC_OPERATOR_BP_POWER
 mov r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 xor eax,eax
 ret

NEBOC_ABI_FUNCTION neboc_core_prefix_power_validate
 mov eax,NEBOC_OPERATOR_BP_POWER
 cmp eax,NEBOC_OPERATOR_BP_PREFIX
 jbe .invalid
 mov eax,NEBOC_OPERATOR_BP_PREFIX
 cmp eax,NEBOC_OPERATOR_BP_MULTIPLICATIVE
 jbe .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
