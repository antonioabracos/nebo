; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO atomic `%=` and power-only `^=` lowering.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

extern neboc_core_checked_remainder
extern neboc_core_checked_power

section .text
NEBOC_ABI_FUNCTION neboc_compound_remainder
 test rdi,rdi
 jz .rem_invalid
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov rdi,[rbx]
 lea rdx,[rsp]
 call neboc_core_checked_remainder
 test eax,eax
 jnz .rem_done
 mov rax,[rsp]
 mov [rbx],rax
 xor eax,eax
.rem_done:
 add rsp,16
 pop rbx
 ret
.rem_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compound_power
 test rdi,rdi
 jz .power_invalid
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov rdi,[rbx]
 lea rdx,[rsp]
 call neboc_core_checked_power
 test eax,eax
 jnz .power_done
 mov rax,[rsp]
 mov [rbx],rax
 xor eax,eax
.power_done:
 add rsp,16
 pop rbx
 ret
.power_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
