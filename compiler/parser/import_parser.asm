; IMPORT-SIMPLES-ALIASES-CAPSULES-NOMEADAS-ANONIMAS-E-RESOLUCAO-DETERMINISTICA-F01 structural canonical import classifier.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
; parse_import(bytes*, len, out_form*) -> status
NEBOC_ABI_FUNCTION neboc_import_parse
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_IMPORT_MAX_BYTES
 ja .limit
 xor ecx,ecx
 xor r8d,r8d                 ; quotes
 xor r9d,r9d                 ; braces
 xor r10d,r10d               ; export prefix
.scan:
 cmp rcx,rsi
 jae .classify
 mov al,[rdi+rcx]
 cmp al,'*'
 je .source
 cmp al,'"'
 jne .brace_open
 inc r8d
.brace_open:
 cmp al,'{'
 jne .brace_close
 inc r9d
.brace_close:
 cmp al,'}'
 jne .next
 dec r9d
 js .source
.next:
 inc rcx
 jmp .scan
.classify:
 cmp byte [rdi+rsi-1],';'
 jne .source
 test r8b,1
 jnz .source
 test r9d,r9d
 jnz .source
 cmp rsi,7
 jb .source
 cmp dword [rdi],'impo'
 jne .maybe_export
 cmp word [rdi+4],'rt'
 jne .source
 mov eax,NEBOC_IMPORT_FORM_SIMPLE
 cmp r8d,2
 jb .capsule
 cmp r8d,2
 jne .source
 ; A quoted form containing braces is selective; otherwise simple.
 xor ecx,ecx
.find_brace:
 cmp rcx,rsi
 jae .publish
 cmp byte [rdi+rcx],'{'
 je .selective
 inc rcx
 jmp .find_brace
.selective: mov eax,NEBOC_IMPORT_FORM_SELECTIVE
 jmp .publish
.capsule:
 cmp r8d,0
 jne .source
 mov eax,NEBOC_IMPORT_FORM_ANONYMOUS_CAPSULE
 cmp rsi,3
 jb .publish
 cmp byte [rdi+rsi-2],'}'
 je .publish
 mov eax,NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jmp .publish
.maybe_export:
 cmp rsi,14
 jb .source
 cmp dword [rdi],'expo'
 jne .source
 mov eax,NEBOC_IMPORT_FORM_SELECTIVE|NEBOC_IMPORT_FLAG_EXPORT
.publish:
 mov [rdx],eax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
