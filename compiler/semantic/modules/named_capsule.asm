bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
NEBOC_ABI_FUNCTION neboc_named_capsule
 test rsi,rsi
 jz .arg
 test rcx,rcx
 jz .arg
 test rdi,rdi
 jz .source
 test rdx,rdx
 jz .source
 cmp rdx,NEBOC_IMPORT_MAX_ITEMS
 ja .limit
 mov rax,rdi
 xor r8d,r8d
.loop: cmp r8,rdx
 jae .put
 mov r9,[rsi+r8*8]
 test r9,r9
 jz .source
 xor rax,r9
 rol rax,11
 inc r8
 jmp .loop
.put: mov [rcx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
