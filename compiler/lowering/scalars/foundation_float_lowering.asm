; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF005 deterministic Float literal materialization
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"

section .text

; foundation_float_materialize_literal(request*)
; Strict positive [0-9]+.[0-9]+ -> IEEE 754 binary64.
; The conversion is deterministic and source-bounded, with no integer accumulator.
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

 pxor xmm0,xmm0                    ; accumulated value
 mov r11,10
 cvtsi2sd xmm3,r11                 ; 10.0
 xor r15d,r15d                     ; source index
 xor r9d,r9d                       ; integer digits
 xor r10d,r10d                     ; fraction digits

.integer_loop:
 cmp r15,r14
 jae .invalid_shape
 movzx r11d,byte [r13+r15]
 cmp r11b,'.'
 je .dot
 cmp r11b,'0'
 jb .invalid_shape
 cmp r11b,'9'
 ja .invalid_shape
 sub r11d,'0'
 mulsd xmm0,xmm3
 cvtsi2sd xmm1,r11
 addsd xmm0,xmm1
 inc r9
 inc r15
 jmp .integer_loop

.dot:
 test r9,r9
 jz .invalid_shape
 inc r15
 cmp r15,r14
 jae .invalid_shape
 mov r11,1
 cvtsi2sd xmm4,r11
 divsd xmm4,xmm3                   ; decimal place = 0.1

.fraction_loop:
 cmp r15,r14
 jae .materialize
 movzx r11d,byte [r13+r15]
 cmp r11b,'0'
 jb .invalid_shape
 cmp r11b,'9'
 ja .invalid_shape
 sub r11d,'0'
 cvtsi2sd xmm1,r11
 mulsd xmm1,xmm4
 addsd xmm0,xmm1
 divsd xmm4,xmm3
 inc r10
 inc r15
 jmp .fraction_loop

.materialize:
 test r10,r10
 jz .invalid_shape
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_INTEGER_DIGITS_OFFSET],r9
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_FRACTION_DIGITS_OFFSET],r10
 movq [r12],xmm0
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

section .note.GNU-stack noalloc noexec nowrite progbits
