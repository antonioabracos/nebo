bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
NEBOC_ABI_FUNCTION neboc_anonymous_capsule
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_IMPORT_MAX_ITEMS
 ja .limit
 xor ecx,ecx
 xor r8d,r8d
.outer: cmp rcx,rsi
 jae .put
 cmp qword [rdi+rcx*8],0
 je .source
 mov r9,rcx
 inc r9
.inner: cmp r9,rsi
 jae .next
 mov rax,[rdi+rcx*8]
 cmp rax,[rdi+r9*8]
 je .source
 inc r9
 jmp .inner
.next: bts r8,rcx
 inc rcx
 jmp .outer
.put: mov [rdx],r8
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
