; POTENCIA-XOR-E-COMPARACAO-TOTAL checked Int power by exponentiation by squaring.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text
; checked_power(base, nonnegative_exponent, out*)
; Output remains byte-for-byte unchanged on domain or overflow failure.
NEBOC_ABI_FUNCTION neboc_core_checked_power
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 js .domain
 mov r8,1
 mov r9,rdi
 mov rcx,rsi
.loop:
 test rcx,rcx
 jz .success
 test cl,1
 jz .after_result
 imul r8,r9
 jo .overflow
.after_result:
 shr rcx,1
 jz .success
 imul r9,r9
 jo .overflow
 jmp .loop
.success:
 mov [rdx],r8
 xor eax,eax
 ret
.overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.domain:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
