; SEGURANCA-UNICODE-DA-FONTE explicit fullwidth/operator-confusable rejection.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_confusable_policy(codepoint, out_policy*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_unicode_confusable_policy
 test rsi,rsi
 jz .invalid
 cmp rdi,0x10ffff
 ja .source
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 cmp rdi,0xff01
 jb .named
 cmp rdi,0xff5e
 ja .named
 mov r8d,NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 mov r9,rdi
 sub r9,0xfee0
 mov r10d,NEBOC_UNICODE_DIAG_CONFUSABLE
 jmp .store
.named:
 cmp rdi,0x2010
 je .minus
 cmp rdi,0x2011
 je .minus
 cmp rdi,0x2215
 je .slash
 cmp rdi,0x2044
 jne .store
.slash:
 mov r9d,'/'
 jmp .reject
.minus:
 mov r9d,'-'
.reject:
 mov r8d,NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 mov r10d,NEBOC_UNICODE_DIAG_CONFUSABLE
.store:
 mov [rsi+NEBOC_UNICODE_POLICY_ACTION_OFFSET],r8
 mov [rsi+NEBOC_UNICODE_POLICY_CODEPOINT_OFFSET],rdi
 mov [rsi+NEBOC_UNICODE_POLICY_REPLACEMENT_OFFSET],r9
 mov [rsi+NEBOC_UNICODE_POLICY_DIAGNOSTIC_OFFSET],r10
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
