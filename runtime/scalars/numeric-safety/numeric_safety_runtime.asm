; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF004 isolated numeric-safety runtime prototype
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/scalars/numeric-safety/numeric_safety_runtime.inc"

section .rodata align=8
numeric_safety_runtime_layout:
 dq NEBOC_RUNTIME_CONTRACT_VERSION
 dq NEBOC_RUNTIME_TARGET_X86_64_SYSTEMV_ELF_LINUX
 dq 64
 dq 8
 dq 8
 dq NEBOC_RUNTIME_ABI_CLASS_INTEGER
 dq NEBOC_RUNTIME_REGISTER_RDI
 dq 64
 dq 8
 dq 8
 dq NEBOC_RUNTIME_ABI_CLASS_SSE
 dq NEBOC_RUNTIME_REGISTER_XMM0
 dq NEBOC_RUNTIME_REGISTER_XMM0
 dq 8
 dq 1
 dq 1
 dq NEBOC_RUNTIME_ABI_CLASS_INTEGER
 dq NEBOC_RUNTIME_REGISTER_RAX
 dq NEBOC_RUNTIME_FEATURE_SSE2
 dq NEBOC_RUNTIME_METADATA_NONE
 dq NEBOC_RUNTIME_REQUIRED_FLAGS
 dq 0

section .text

NEBOC_ABI_FUNCTION neboc_numeric_safety_runtime_layout_get
 test rdi,rdi
 jz .invalid
 lea rax,[rel numeric_safety_runtime_layout]
 mov [rdi],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; signed i64 in RDI -> IEEE binary64 in XMM0.
; The helper pins MXCSR rounding-control to round-to-nearest/ties-to-even for the
; conversion and restores the complete caller MXCSR afterwards. No ambient
; floating-point mode can change the language result.
align 16
global neboc_numeric_safety_runtime_int_to_float
neboc_numeric_safety_runtime_int_to_float:
 sub rsp,16
 stmxcsr [rsp]
 mov eax,[rsp]
 and eax,0xffff9fff
 mov [rsp+4],eax
 ldmxcsr [rsp+4]
 cvtsi2sd xmm0,rdi
 ldmxcsr [rsp]
 add rsp,16
 cld
 ret

; All classifiers inspect binary64 bits only. They return canonical Bool 0/1 in
; RAX and cannot raise an IEEE floating-point exception.
align 16
global neboc_numeric_safety_runtime_is_finite
neboc_numeric_safety_runtime_is_finite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 setne al
 movzx eax,al
 cld
 ret

align 16
global neboc_numeric_safety_runtime_is_nan
neboc_numeric_safety_runtime_is_nan:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setnz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
global neboc_numeric_safety_runtime_is_infinite
neboc_numeric_safety_runtime_is_infinite:
 movq rdx,xmm0
 mov rcx,rdx
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 jne .false
 shl rdx,12
 setz al
 movzx eax,al
 cld
 ret
.false:
 xor eax,eax
 cld
 ret

align 16
global neboc_numeric_safety_runtime_is_negative_zero
neboc_numeric_safety_runtime_is_negative_zero:
 movq rdx,xmm0
 mov rax,0x8000000000000000
 cmp rdx,rax
 sete al
 movzx eax,al
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
