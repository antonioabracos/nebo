; SEGURANCA-UNICODE-DA-FONTE stable Unicode security diagnostic records.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_security_diagnostic(action, cp, start, end, replacement, out*)
NEBOC_ABI_FUNCTION neboc_unicode_security_diagnostic
 test r9,r9
 jz .invalid
 cmp rdx,rcx
 ja .source
 cmp rdi,NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 je .confusable
 cmp rdi,NEBOC_UNICODE_SECURITY_REJECT_BIDI
 je .bidi
 cmp rdi,NEBOC_UNICODE_SECURITY_REJECT_INVISIBLE
 je .invisible
 cmp rdi,NEBOC_UNICODE_SECURITY_REJECT_COMBINING
 je .combining
 cmp rdi,NEBOC_UNICODE_SECURITY_REJECT_MALFORMED_UTF8
 jne .source
 mov r10d,NEBOC_UNICODE_DIAG_MALFORMED_UTF8
 mov r11d,NEBOC_UNICODE_NAME_MALFORMED_UTF8
 jmp .store
.confusable:
 mov r10d,NEBOC_UNICODE_DIAG_CONFUSABLE
 mov r11d,NEBOC_UNICODE_NAME_CONFUSABLE_OPERATOR
 jmp .store
.bidi:
 mov r10d,NEBOC_UNICODE_DIAG_BIDI_CONTROL
 mov r11d,NEBOC_UNICODE_NAME_BIDI_CONTROL
 jmp .store
.invisible:
 mov r10d,NEBOC_UNICODE_DIAG_INVISIBLE
 mov r11d,NEBOC_UNICODE_NAME_INVISIBLE_SEPARATOR
 jmp .store
.combining:
 mov r10d,NEBOC_UNICODE_DIAG_COMBINING
 mov r11d,NEBOC_UNICODE_NAME_COMBINING_MARK
.store:
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_CODE_OFFSET],r10
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_CODEPOINT_OFFSET],rsi
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_START_OFFSET],rdx
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_END_OFFSET],rcx
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_REPLACEMENT_OFFSET],r8
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_NAME_ID_OFFSET],r11
 mov [r9+NEBOC_UNICODE_SECURITY_DIAG_ACTION_OFFSET],rdi
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
