bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
; resolve_alias(pairs[alias,module], count, alias, out_module*)
NEBOC_ABI_FUNCTION neboc_import_resolve_alias
 test rdi,rdi
 jz .arg
 test r8,r8
 jz .arg
 cmp rsi,NEBOC_IMPORT_MAX_ITEMS
 ja .limit
 xor ecx,ecx
.loop: cmp rcx,rsi
 jae .source
 mov rax,rcx
 shl rax,4
 cmp rdx,[rdi+rax]
 je .found
 inc rcx
 jmp .loop
.found: mov rax,rcx
 shl rax,4
 mov rax,[rdi+rax+8]
 test rax,rax
 jz .source
 mov [r8],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
