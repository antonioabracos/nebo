bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"
section .text
; parse selected symbol ids and reject wildcard/duplicates.
NEBOC_ABI_FUNCTION neboc_selective_parse
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_SELECTIVE_MAX
 ja .limit
 xor ecx,ecx
 xor r8d,r8d
.loop: cmp rcx,rsi
 jae .put
 mov rax,[rdi+rcx*8]
 test rax,rax
 jz .source
 cmp rax,-1
 je .source
 xor r8,rax
 rol r8,7
 inc rcx
 jmp .loop
.put: mov [rdx],r8
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
