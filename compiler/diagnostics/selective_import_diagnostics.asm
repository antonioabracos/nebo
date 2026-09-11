bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/selective_import_parser.inc"
section .text
NEBOC_ABI_FUNCTION neboc_selective_diagnostic
 test rsi,rsi
 jz .arg
 cmp rdi,1
 jb .source
 cmp rdi,15
 ja .source
 mov eax,NEBOC_SELECTIVE_DIAG_BASE
 add eax,edi
 mov [rsi],eax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; diagnostic_record(kind, packed_primary_span, related_count, out[3])
NEBOC_ABI_FUNCTION neboc_selective_diagnostic_record
 test rcx,rcx
 jz .arg
 mov qword [rcx],0
 mov qword [rcx+8],0
 mov qword [rcx+16],0
 cmp rdi,1
 jb .source
 cmp rdi,15
 ja .source
 test rsi,rsi
 jz .source
 cmp rdx,8
 ja .source
 mov rax,NEBOC_SELECTIVE_DIAG_BASE
 add rax,rdi
 mov [rcx],rax
 mov [rcx+8],rsi
 mov [rcx+16],rdx
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
