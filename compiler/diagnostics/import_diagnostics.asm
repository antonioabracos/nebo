bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
section .text
NEBOC_ABI_FUNCTION neboc_import_diagnostic
 test rsi,rsi
 jz .arg
 cmp rdi,1
 jb .source
 cmp rdi,5
 ja .source
 mov eax,16615100
 add eax,edi
 mov [rsi],eax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
