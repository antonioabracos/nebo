; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF005 Float native representation/runtime vertical slice
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/scalars/float/foundation_float_runtime.inc"

section .rodata align=8
foundation_float_runtime_layout:
 dq NEBOC_FLOAT_RUNTIME_CONTRACT_VERSION
 dq NEBOC_FLOAT_RUNTIME_TARGET_X86_64_SYSTEMV_ELF_LINUX
 dq NEBOC_FLOAT_RUNTIME_FORMAT_IEEE754_BINARY64
 dq 64
 dq 8
 dq 8
 dq NEBOC_FLOAT_RUNTIME_REGISTER_CLASS_XMM
 dq NEBOC_FLOAT_RUNTIME_REGISTER_CLASS_XMM
 dq NEBOC_FLOAT_RUNTIME_REQUIRED_FLAGS
 dq NEBOC_FLOAT_RUNTIME_ABI_VERSION
 dq NEBOC_FLOAT_RUNTIME_STATE_FROZEN
 dq 0

section .text

; foundation_float_runtime_layout_get(out_descriptor**)
NEBOC_ABI_FUNCTION neboc_foundation_float_runtime_layout_get
 test rdi,rdi
 jz float_runtime_layout_invalid
 lea rax,[rel foundation_float_runtime_layout]
 mov [rdi],rax
 xor eax,eax
 ret
float_runtime_layout_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; foundation_float_runtime_classify(bits, out_class*, out_flags*)
NEBOC_ABI_FUNCTION neboc_foundation_float_runtime_classify
 test rsi,rsi
 jz float_runtime_classify_invalid
 test rdx,rdx
 jz float_runtime_classify_invalid
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_NORMAL
 mov qword [rdx],0
 xor r8d,r8d
 bt rdi,63
 jnc float_runtime_classify_sign_done
 or r8,NEBOC_FLOAT_RUNTIME_VALUE_FLAG_NEGATIVE
float_runtime_classify_sign_done:
 mov rax,rdi
 shr rax,52
 and eax,0x7ff
 mov rcx,rdi
 mov r9,0x000fffffffffffff
 and rcx,r9
 test rax,rax
 jz float_runtime_classify_zero_or_subnormal
 cmp rax,0x7ff
 je float_runtime_classify_inf_or_nan
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_NORMAL
 jmp float_runtime_classify_store

float_runtime_classify_zero_or_subnormal:
 test rcx,rcx
 jz float_runtime_classify_zero
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_SUBNORMAL
 jmp float_runtime_classify_store
float_runtime_classify_zero:
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_ZERO
 jmp float_runtime_classify_store

float_runtime_classify_inf_or_nan:
 test rcx,rcx
 jz float_runtime_classify_infinity
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_NAN
 bt rcx,51
 jc float_runtime_classify_quiet_nan
 or r8,NEBOC_FLOAT_RUNTIME_VALUE_FLAG_SIGNALING_NAN
 jmp float_runtime_classify_store
float_runtime_classify_quiet_nan:
 or r8,NEBOC_FLOAT_RUNTIME_VALUE_FLAG_QUIET_NAN
 jmp float_runtime_classify_store
float_runtime_classify_infinity:
 mov qword [rsi],NEBOC_FLOAT_RUNTIME_CLASS_INFINITY

float_runtime_classify_store:
 mov [rdx],r8
 xor eax,eax
 ret
float_runtime_classify_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; System V AMD64 scalar operations: lhs in XMM0, rhs in XMM1, result in XMM0.
align 16
global neboc_foundation_float_runtime_identity
neboc_foundation_float_runtime_identity:
 cld
 ret

align 16
global neboc_foundation_float_runtime_add
neboc_foundation_float_runtime_add:
 addsd xmm0,xmm1
 cld
 ret

align 16
global neboc_foundation_float_runtime_sub
neboc_foundation_float_runtime_sub:
 subsd xmm0,xmm1
 cld
 ret

align 16
global neboc_foundation_float_runtime_mul
neboc_foundation_float_runtime_mul:
 mulsd xmm0,xmm1
 cld
 ret

align 16
global neboc_foundation_float_runtime_div
neboc_foundation_float_runtime_div:
 divsd xmm0,xmm1
 cld
 ret

align 16
global neboc_foundation_float_runtime_neg
neboc_foundation_float_runtime_neg:
 movq rax,xmm0
 btc rax,63
 movq xmm0,rax
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
