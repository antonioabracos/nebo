; Operator resolution admits identity only. Explicit language constructors are
; a separate semantic surface and are never searched as overload conversions.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; conversion_policy(source_type, target_type, mode, out_kind*)
; EDX carries a typed operator diagnostic on INVALID_SOURCE.
NEBOC_ABI_FUNCTION neboc_operator_conversion_policy
 test rcx,rcx
 jz .invalid_argument
 test rdi,rdi
 jz .invalid_argument
 test rsi,rsi
 jz .invalid_argument
 cmp rdx,NEBOC_OPERATOR_CONVERSION_MODE_EXPLICIT
 ja .invalid_argument
 cmp rdi,rsi
 jne .different
 mov qword [rcx],NEBOC_OPERATOR_CONVERSION_IDENTITY
 xor eax,eax
 xor edx,edx
 ret
.different:
 cmp rdx,NEBOC_OPERATOR_CONVERSION_MODE_IMPLICIT
 jne .explicit_outside_resolution
 mov edx,NEBOC_OPERATOR_DIAG_IMPLICIT_CONVERSION_FORBIDDEN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.explicit_outside_resolution:
 mov edx,NEBOC_OPERATOR_DIAG_NO_EXACT_CANDIDATE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid_argument:
 xor edx,edx
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_operator_types_exact
 xor eax,eax
 test rdi,rdi
 jz .types_done
 cmp rdi,rsi
 sete al
.types_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
