bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
section .text
; qualify(alias_digest, symbol_digest, out*) -> status
NEBOC_ABI_FUNCTION neboc_import_qualify
 test rdx,rdx
 jz .arg
 test rdi,rdi
 jz .source
 test rsi,rsi
 jz .source
 mov rax,rdi
 rol rax,17
 xor rax,rsi
 test rax,rax
 jnz .put
 mov eax,1
.put: mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
