bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
section .text
NEBOC_ABI_FUNCTION neboc_module_init_effects
 test rdx,rdx
 jz .arg
 mov rax,rdi
 not rsi
 test rax,rsi
 jnz .source
 mov [rdx],rdi
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
