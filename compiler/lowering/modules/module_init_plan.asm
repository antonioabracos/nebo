bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"
section .text
NEBOC_ABI_FUNCTION neboc_module_init_plan
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_INIT_MAX
 ja .limit
 xor ecx,ecx
 xor eax,eax
.loop: cmp rcx,rsi
 jae .put
 add rax,[rdi+rcx*8]
 inc rcx
 jmp .loop
.put: mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
