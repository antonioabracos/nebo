; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PF004 bounded copy-only aggregate helpers; no allocation or metadata
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/aggregates/programmer_type_runtime.inc"
section .text
NEBOC_ABI_FUNCTION neboc_programmer_type_copy
 test rdi,rdi
 jz .invalid_copy
 test rsi,rsi
 jz .invalid_copy
 cmp rdx,NEBOC_RUNTIME_COPY_LIMIT
 ja .limit_copy
 mov rcx,rdx
 rep movsb
 xor eax,eax
 ret
.limit_copy: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_copy: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_programmer_type_zero
 test rdi,rdi
 jz .invalid_zero
 cmp rsi,NEBOC_RUNTIME_COPY_LIMIT
 ja .limit_zero
 mov rcx,rsi
 xor eax,eax
 rep stosb
 ret
.limit_zero: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_zero: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_programmer_type_tag_validate
 test rsi,rsi
 jz .invalid_tag
 cmp rsi,8
 ja .limit_tag
 cmp rdi,rsi
 jae .source_tag
 xor eax,eax
 ret
.source_tag: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit_tag: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_tag: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
