bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/interface/interface_v1.inc"
section .text
; validate/read a complete bounded NI v1 header before publication.
NEBOC_ABI_FUNCTION neboc_interface_v1
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 cmp rsi,NEBOC_NI_HEADER_SIZE
 jb .source
 mov rax,NEBOC_NI_MAGIC
 cmp [rdi],rax
 jne .source
 cmp word [rdi+8],NEBOC_NI_VERSION
 jne .source
 cmp word [rdi+10],NEBOC_NI_HEADER_SIZE
 jne .source
 mov eax,[rdi+48]
 cmp rax,NEBOC_NI_MAX_SECTIONS
 ja .limit
 mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
