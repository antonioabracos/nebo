; SEGURANCA-UNICODE-DA-FONTE NFC identity and explicit no-NFKC policy.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_normalization_identity(codepoint, out_policy*) -> StatusCode
; No replacement code point is ever produced.
NEBOC_ABI_FUNCTION neboc_unicode_normalization_identity
 test rsi,rsi
 jz .invalid
 cmp rdi,0x10ffff
 ja .source
 cmp rdi,0xd800
 jb .valid_scalar
 cmp rdi,0xdfff
 jbe .source
.valid_scalar:
 xor eax,eax
 cmp rdi,0xff01
 jb .store
 cmp rdi,0xff5e
 ja .store
 mov eax,NEBOC_UNICODE_NORMALIZATION_REJECT_NFKC_CONFUSABLE
.store:
 mov [rsi+NEBOC_UNICODE_NORMALIZATION_CODEPOINT_OFFSET],rdi
 mov [rsi+NEBOC_UNICODE_NORMALIZATION_ACTION_OFFSET],rax
 mov qword [rsi+NEBOC_UNICODE_NORMALIZATION_FLAGS_OFFSET],NEBOC_UNICODE_SCAN_FLAG_NFC_IDENTITY|NEBOC_UNICODE_SCAN_FLAG_NO_NFKC
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
