; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF005 deterministic Float literal materialization
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"

section .text

; foundation_float_materialize_literal(request*)
; Strict positive [0-9]+.[0-9]+ -> IEEE 754 binary64.
; Exact integer-ratio rounding is deterministic and preserves the source bound.
NEBOC_ABI_FUNCTION neboc_foundation_float_materialize_literal
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .bad_no_record
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_NONE
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],0
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],0
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_FLAGS_OFFSET],0
 mov r13,[rbx+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET]
 mov r14,[rbx+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET]
 mov r12,[rbx+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET]
 test r12,r12
 jz .bad
 mov qword [r12],0
 test r13,r13
 jz .bad
 test r14,r14
 jz .invalid_shape
 cmp r14,NEBOC_FLOAT_LOWERING_MAX_TOTAL_DIGITS+1
 ja .source_limit

 mov rdi,r13
 mov rsi,r14
 call neboc_decimal_binary64_exact
 test eax,eax
 jz .materialize
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_limit
 jmp .invalid_shape
.materialize:
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],rcx
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],r8
 mov [r12],rdx
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_FLAGS_OFFSET],NEBOC_FLOAT_LOWERING_REQUIRED_FLAGS
 xor eax,eax
 jmp .done

.source_limit:
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_SOURCE_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_shape:
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_INVALID_SHAPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FLOAT_LOWERING_REQUEST_ERROR_CODE_OFFSET],NEBOC_FLOAT_LOWERING_ERROR_BAD_REQUEST
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_no_record:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

%include "compiler/lowering/scalars/decimal_binary64.inc"

section .note.GNU-stack noalloc noexec nowrite progbits
