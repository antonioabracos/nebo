; SEGURANCA-UNICODE-DA-FONTE bidirectional source-display control policy.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_bidi_policy(codepoint, out_policy*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_unicode_bidi_policy
 test rsi,rsi
 jz .invalid
 xor r8d,r8d
 xor r10d,r10d
 cmp rdi,0x202a
 jb .isolates
 cmp rdi,0x202e
 jbe .reject
.isolates:
 cmp rdi,0x2066
 jb .store
 cmp rdi,0x2069
 ja .store
.reject:
 mov r8d,NEBOC_UNICODE_SECURITY_REJECT_BIDI
 mov r10d,NEBOC_UNICODE_DIAG_BIDI_CONTROL
.store:
 mov [rsi+NEBOC_UNICODE_POLICY_ACTION_OFFSET],r8
 mov [rsi+NEBOC_UNICODE_POLICY_CODEPOINT_OFFSET],rdi
 mov qword [rsi+NEBOC_UNICODE_POLICY_REPLACEMENT_OFFSET],0
 mov [rsi+NEBOC_UNICODE_POLICY_DIAGNOSTIC_OFFSET],r10
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
