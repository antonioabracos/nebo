bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
NEBOC_ABI_FUNCTION neboc_import_format
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test r8,r8
 jz .arg
 cmp rsi,NEBOC_IMPORT_MAX_BYTES
 ja .limit
 cmp rcx,rsi
 jb .limit
 xor r9d,r9d
.loop: cmp r9,rsi
 jae .put
 mov al,[rdi+r9]
 cmp al,'*'
 je .source
 mov [rdx+r9],al
 inc r9
 jmp .loop
.put: mov [r8],rsi
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
