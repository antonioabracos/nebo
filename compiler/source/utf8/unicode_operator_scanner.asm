; SEGURANCA-UNICODE-DA-FONTE strict one-code-point UTF-8 scanner.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

section .text
; unicode_operator_scan(bytes, available_length, out_scan*) -> StatusCode
; Rejects overlong forms, surrogates, truncation and values above U+10FFFF.
NEBOC_ABI_FUNCTION neboc_unicode_operator_scan
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rsi,rsi
 jz .source
 movzx eax,byte [rdi]
 cmp eax,0x80
 jb .ascii
 cmp eax,0xc2
 jb .source
 cmp eax,0xdf
 jbe .two
 cmp eax,0xef
 jbe .three
 cmp eax,0xf4
 jbe .four
 jmp .source
.ascii:
 mov r8d,eax
 mov r9d,1
 jmp .classify
.two:
 cmp rsi,2
 jb .source
 movzx ecx,byte [rdi+1]
 mov r10d,ecx
 and r10d,0xc0
 cmp r10d,0x80
 jne .source
 and eax,0x1f
 shl eax,6
 and ecx,0x3f
 or eax,ecx
 mov r8d,eax
 mov r9d,2
 jmp .classify
.three:
 cmp rsi,3
 jb .source
 mov r11d,eax
 movzx ecx,byte [rdi+1]
 movzx r10d,byte [rdi+2]
 mov eax,ecx
 and eax,0xc0
 cmp eax,0x80
 jne .source
 mov eax,r10d
 and eax,0xc0
 cmp eax,0x80
 jne .source
 cmp r11d,0xe0
 jne .three_not_e0
 cmp ecx,0xa0
 jb .source
.three_not_e0:
 cmp r11d,0xed
 jne .three_decode
 cmp ecx,0xa0
 jae .source
.three_decode:
 and r11d,0x0f
 shl r11d,12
 and ecx,0x3f
 shl ecx,6
 or r11d,ecx
 and r10d,0x3f
 or r11d,r10d
 mov r8d,r11d
 mov r9d,3
 jmp .classify
.four:
 cmp rsi,4
 jb .source
 mov r11d,eax
 movzx ecx,byte [rdi+1]
 movzx r10d,byte [rdi+2]
 movzx eax,byte [rdi+3]
 mov esi,ecx
 and esi,0xc0
 cmp esi,0x80
 jne .source
 mov esi,r10d
 and esi,0xc0
 cmp esi,0x80
 jne .source
 mov esi,eax
 and esi,0xc0
 cmp esi,0x80
 jne .source
 cmp r11d,0xf0
 jne .four_not_f0
 cmp ecx,0x90
 jb .source
.four_not_f0:
 cmp r11d,0xf4
 jne .four_decode
 cmp ecx,0x8f
 ja .source
.four_decode:
 and r11d,7
 shl r11d,18
 and ecx,0x3f
 shl ecx,12
 or r11d,ecx
 and r10d,0x3f
 shl r10d,6
 or r11d,r10d
 and eax,0x3f
 or r11d,eax
 mov r8d,r11d
 mov r9d,4
.classify:
 xor r10d,r10d
 cmp r8d,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_DIVIDE_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_NOT_EQUAL_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_AND_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_OR_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_NOT_CODEPOINT
 je .alias
 cmp r8d,NEBOC_UNICODE_ALIAS_XOR_CODEPOINT
 jne .store
.alias:
 mov r10d,NEBOC_UNICODE_CLASS_EXACT_ALIAS
.store:
 mov [rdx+NEBOC_UNICODE_SCAN_CODEPOINT_OFFSET],r8
 mov [rdx+NEBOC_UNICODE_SCAN_BYTE_LENGTH_OFFSET],r9
 mov [rdx+NEBOC_UNICODE_SCAN_CLASS_OFFSET],r10
 mov qword [rdx+NEBOC_UNICODE_SCAN_FLAGS_OFFSET],NEBOC_UNICODE_SCAN_FLAG_STRICT_UTF8|NEBOC_UNICODE_SCAN_FLAG_NFC_IDENTITY|NEBOC_UNICODE_SCAN_FLAG_NO_NFKC
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
