bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"
section .text
NEBOC_ABI_FUNCTION neboc_module_init_diagnostic
 test rsi,rsi
 jz .arg
 cmp rdi,1
 jb .source
 cmp rdi,6
 ja .source
 mov eax,NEBOC_INIT_DIAG_BASE
 add eax,edi
 mov [rsi],eax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
