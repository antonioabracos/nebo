; Bounded exact substitution for generic operator result TypeIds.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; substitute_type(declared_type, substitutions, count, out_type*) -> status,
; EDX diagnostic. Concrete types are identity. Generic parameters require one
; unique non-zero concrete binding; output is unchanged on every failure.
NEBOC_ABI_FUNCTION neboc_operator_substitute_type
 test rcx,rcx
 jz .invalid_argument
 test rdi,rdi
 jz .invalid_argument
 mov r8,rdi
 mov rax,NEBOC_OPERATOR_TYPE_PARAMETER_FLAG
 test r8,rax
 jnz .generic
 mov [rcx],r8
 xor eax,eax
 xor edx,edx
 ret
.generic:
 mov rax,NEBOC_OPERATOR_TYPE_PARAMETER_ID_MASK
 and r8,rax
 jz .invalid_argument
 test rsi,rsi
 jz .missing
 test rdx,rdx
 jz .missing
 cmp rdx,NEBOC_OPERATOR_MAX_SUBSTITUTIONS
 ja .limit
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.scan:
 cmp r9,rdx
 jae .scan_done
 mov rax,r9
 imul rax,NEBOC_OPERATOR_SUBSTITUTION_SIZE
 add rax,rsi
 cmp [rax+NEBOC_OPERATOR_SUBSTITUTION_PARAMETER_OFFSET],r8
 jne .next
 mov rax,[rax+NEBOC_OPERATOR_SUBSTITUTION_TYPE_OFFSET]
 test rax,rax
 jz .conflict
 mov r10,rax
 inc r11d
.next:
 inc r9
 jmp .scan
.scan_done:
 test r11d,r11d
 jz .missing
 cmp r11d,1
 jne .conflict
 mov [rcx],r10
 xor eax,eax
 xor edx,edx
 ret
.missing:
 mov edx,NEBOC_OPERATOR_DIAG_SUBSTITUTION_MISSING
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.conflict:
 mov edx,NEBOC_OPERATOR_DIAG_SUBSTITUTION_CONFLICT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov edx,NEBOC_OPERATOR_DIAG_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_argument:
 xor edx,edx
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
