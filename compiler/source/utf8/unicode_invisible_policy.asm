; SEGURANCA-UNICODE-DA-FONTE invisible separator and combining-mark policy.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_invisible_policy(codepoint, out_policy*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_unicode_invisible_policy
 test rsi,rsi
 jz .invalid
 xor r8d,r8d
 xor r10d,r10d
 cmp rdi,0x0300
 jb .invisible_ranges
 cmp rdi,0x036f
 jbe .combining
.invisible_ranges:
 cmp rdi,0x200b
 jb .word_joiner
 cmp rdi,0x200f
 jbe .invisible
.word_joiner:
 cmp rdi,0x2060
 je .invisible
 cmp rdi,0xfeff
 jne .store
.invisible:
 mov r8d,NEBOC_UNICODE_SECURITY_REJECT_INVISIBLE
 mov r10d,NEBOC_UNICODE_DIAG_INVISIBLE
 jmp .store
.combining:
 mov r8d,NEBOC_UNICODE_SECURITY_REJECT_COMBINING
 mov r10d,NEBOC_UNICODE_DIAG_COMBINING
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
