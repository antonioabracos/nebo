; POTENCIA-XOR-E-COMPARACAO-TOTAL bounded exact-type power bridges; no implicit Int/Float coercion.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

extern neboc_core_checked_power

%define NEBOC_CORE_FLOAT_POWER_MAX_EXPONENT 1000000

section .rodata align=8
float_one: dq 0x3ff0000000000000

section .text
; Exact Int/Int bridge is the canonical checked implementation.
NEBOC_ABI_FUNCTION neboc_core_power_int_bridge
 jmp neboc_core_checked_power

; Float/Int bridge (base binary64 bits, exponent, out binary64 bits*).
; Negative exponents are supported for finite nonzero Float bases.
NEBOC_ABI_FUNCTION neboc_core_power_float_int
 test rdx,rdx
 jz .invalid
 mov rax,rdi
 shr rax,52
 and eax,0x7ff
 cmp eax,0x7ff
 je .domain
 xor r9d,r9d
 mov r8,rsi
 test r8,r8
 jns .magnitude
 mov r9d,1
 mov rax,0x8000000000000000
 cmp r8,rax
 je .limit
 neg r8
.magnitude:
 cmp r8,NEBOC_CORE_FLOAT_POWER_MAX_EXPONENT
 ja .limit
 test r9d,r9d
 jz .prepare
 mov rax,rdi
 shl rax,1
 test rax,rax
 jz .domain
.prepare:
 movq xmm1,rdi
 movq xmm0,[rel float_one]
.loop:
 test r8,r8
 jz .reciprocal
 test r8b,1
 jz .after_result
 mulsd xmm0,xmm1
.after_result:
 shr r8,1
 jz .reciprocal
 mulsd xmm1,xmm1
 jmp .loop
.reciprocal:
 test r9d,r9d
 jz .finite
 movq xmm2,[rel float_one]
 divsd xmm2,xmm0
 movapd xmm0,xmm2
.finite:
 movq rax,xmm0
 mov rcx,rax
 shr rcx,52
 and ecx,0x7ff
 cmp ecx,0x7ff
 je .limit
 mov [rdx],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.domain:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
