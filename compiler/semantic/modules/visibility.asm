bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"
section .text
; visibility_check(flags, requested_reexport, out_visible*)
NEBOC_ABI_FUNCTION neboc_visibility_check
 test rdx,rdx
 jz .arg
 test rdi,NEBOC_VIS_PUBLIC|NEBOC_VIS_REEXPORT
 jz .source
 test rsi,rsi
 jz .visible
 test rdi,NEBOC_VIS_REEXPORT
 jz .source
.visible: mov qword [rdx],1
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
