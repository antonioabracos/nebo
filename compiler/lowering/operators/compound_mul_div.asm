; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO atomic `*=` and `/=` lowering for signed Int targets.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

extern neboc_core_checked_multiply
extern neboc_core_checked_divide

section .text
; compound_multiply(target*, rhs)
NEBOC_ABI_FUNCTION neboc_compound_multiply
 test rdi,rdi
 jz .mul_invalid
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov rdi,[rbx]
 lea rdx,[rsp]
 call neboc_core_checked_multiply
 test eax,eax
 jnz .mul_done
 mov rax,[rsp]
 mov [rbx],rax
 xor eax,eax
.mul_done:
 add rsp,16
 pop rbx
 ret
.mul_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; compound_divide(target*, rhs)
NEBOC_ABI_FUNCTION neboc_compound_divide
 test rdi,rdi
 jz .div_invalid
 push rbx
 sub rsp,16
 mov rbx,rdi
 mov rdi,[rbx]
 lea rdx,[rsp]
 call neboc_core_checked_divide
 test eax,eax
 jnz .div_done
 mov rax,[rsp]
 mov [rbx],rax
 xor eax,eax
.div_done:
 add rsp,16
 pop rbx
 ret
.div_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
