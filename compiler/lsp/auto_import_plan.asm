bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
section .text
; auto_import_plan(snapshot_revision, requested_revision, symbol, out*)
NEBOC_ABI_FUNCTION neboc_auto_import_plan
 test rcx,rcx
 jz .arg
 cmp rdi,rsi
 jne .source
 test rdx,rdx
 jz .source
 mov [rcx],rdx
 mov [rcx+8],rdi
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
